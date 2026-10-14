package com.example.app_spring.posture;

import net.schmizz.sshj.SSHClient;
import net.schmizz.sshj.sftp.SFTPClient;
import net.schmizz.sshj.sftp.SFTPException;
import net.schmizz.sshj.transport.verification.PromiscuousVerifier;
import net.schmizz.sshj.xfer.FileSystemFile;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.Map;

/**
 * 脊柱筛查图片上传：App 拍完背面/下腰两张图后，一次性 multipart 上传到本服务，
 * 服务再经 SFTP 转存到远程服务器固定目录，文件名固定覆盖：
 *   背部图 -> back.{ext}
 *   下腰图 -> Backbend.{ext}
 * 扩展名沿用相机实际保存格式（JPEG -> .jpg）。
 *
 * <p>转存流程与 VideoUploadController 一致：先写远程临时文件 -> 校验大小 -> 重命名覆盖正式文件，
 * 失败重试 3 次。
 */
@RestController
@RequestMapping("/api/spine")
public class SpineImageController {

    private static final Logger log = LoggerFactory.getLogger(SpineImageController.class);

    /** 上传失败重试次数 */
    private static final int MAX_RETRIES = 3;
    /** 重试间隔（毫秒） */
    private static final long RETRY_DELAY_MS = 3_000L;
    /** SFTP 认证失败后熔断时长（毫秒）：期间直接走本地，避免每次上传都空等 */
    private static final long SFTP_DISABLE_MS = 30 * 60_000L;
    /** SFTP 建连/读写超时（毫秒） */
    private static final int SFTP_TIMEOUT_MS = 5_000;

    private final String sftpHost;
    private final int sftpPort;
    private final String sftpUser;
    private final String sftpPassword;
    private final String remoteDir;
    /** SFTP 不可用时的本地兜底目录（默认 uploads/spine，可用 app.spine.upload.local-dir 覆盖） */
    private final Path localDir;
    /** SFTP 熔断到期时间戳；未到期时跳过 SFTP 直接走本地 */
    private volatile long sftpDisabledUntilMs = 0L;

    public SpineImageController(
            @Value("${app.video.upload.sftp-host}") String sftpHost,
            @Value("${app.video.upload.sftp-port}") int sftpPort,
            @Value("${app.video.upload.sftp-user}") String sftpUser,
            @Value("${app.video.upload.sftp-password}") String sftpPassword,
            @Value("${app.spine.upload.remote-dir}") String remoteDir,
            @Value("${app.spine.upload.local-dir:uploads/spine}") String localDir) {
        this.sftpHost = sftpHost;
        this.sftpPort = sftpPort;
        this.sftpUser = sftpUser;
        this.sftpPassword = sftpPassword;
        this.remoteDir = remoteDir;
        this.localDir = Path.of(localDir).toAbsolutePath();
        // 启动即异步探测 SFTP：不可用则提前熔断，避免用户首次上传空等十几秒
        Thread probe = new Thread(this::probeSftp, "sftp-probe-spine");
        probe.setDaemon(true);
        probe.start();
    }

    /**
     * 接收 App 上传的脊柱筛查两张图片并转存到远程服务器（固定文件名，覆盖旧图）。
     *
     * @param back     背部图（站立前屈背面脊柱）
     * @param backbend 下腰图（正面朝向下腰姿势）
     */
    @PostMapping("/upload")
    public ResponseEntity<Map<String, Object>> upload(
            @RequestParam("back") MultipartFile back,
            @RequestParam("backbend") MultipartFile backbend) {
        if (back == null || back.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "背部图片为空"));
        }
        if (backbend == null || backbend.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "下腰图片为空"));
        }

        // 远程文件名固定，扩展名按图片实际保存格式（JPEG -> .jpg）
        final String backName = "back" + extOf(back.getOriginalFilename());
        final String backbendName = "Backbend" + extOf(backbend.getOriginalFilename());

        Path tmpBack = null;
        Path tmpBackbend = null;
        try {
            // multipart 先落本地临时文件，再用 SFTP 流式转存
            tmpBack = Files.createTempFile("spine_back_", extOf(back.getOriginalFilename()));
            back.transferTo(tmpBack.toFile());
            tmpBackbend = Files.createTempFile("spine_backbend_", extOf(backbend.getOriginalFilename()));
            backbend.transferTo(tmpBackbend.toFile());

            if (isSftpDisabled()) {
                final Path savedBack = saveLocal(tmpBack, backName);
                final Path savedBackbend = saveLocal(tmpBackbend, backbendName);
                log.info("SFTP 处于熔断期，脊柱图片直接存本地: {}, {} -> {}", savedBack, savedBackbend, localDir);
                return ResponseEntity.ok(Map.of(
                        "message", "上传成功（本地）",
                        "backPath", savedBack.toString(),
                        "backbendPath", savedBackbend.toString(),
                        "local", true
                ));
            }
            try {
                uploadWithRetry(tmpBack, backName);
                uploadWithRetry(tmpBackbend, backbendName);

                log.info("脊柱筛查图片上传成功: {} ({} 字节), {} ({} 字节) -> {}",
                        backName, Files.size(tmpBack), backbendName, Files.size(tmpBackbend), remoteDir);
                return ResponseEntity.ok(Map.of(
                        "message", "上传成功",
                        "backPath", remoteDir + "/" + backName,
                        "backbendPath", remoteDir + "/" + backbendName
                ));
            } catch (InterruptedException ie) {
                throw ie;
            } catch (Exception sftpError) {
                // 远程服务器不可用（例如 SFTP 凭据失效）时降级为本地存储，保证演示流程不中断
                log.warn("SFTP 上传失败，降级为本地存储: {}", sftpError.getMessage());
                markSftpDisabled(sftpError);
                final Path savedBack = saveLocal(tmpBack, backName);
                final Path savedBackbend = saveLocal(tmpBackbend, backbendName);
                log.info("脊柱图片已存本地: {}, {} -> {}", savedBack, savedBackbend, localDir);
                return ResponseEntity.ok(Map.of(
                        "message", "上传成功（本地）",
                        "backPath", savedBack.toString(),
                        "backbendPath", savedBackbend.toString(),
                        "local", true
                ));
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "上传被中断"));
        } catch (Exception e) {
            log.error("脊柱筛查图片上传失败: {}, {}", backName, backbendName, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "上传失败: " + e.getMessage()));
        } finally {
            for (Path tmp : new Path[]{tmpBack, tmpBackbend}) {
                if (tmp != null) {
                    try {
                        Files.deleteIfExists(tmp);
                    } catch (IOException ignored) {
                    }
                }
            }
        }
    }

    /** 异步探测 SFTP 是否可用（只连一次，失败即熔断） */
    private void probeSftp() {
        try (SSHClient ssh = new SSHClient()) {
            ssh.addHostKeyVerifier(new PromiscuousVerifier());
            ssh.setConnectTimeout(SFTP_TIMEOUT_MS);
            ssh.setTimeout(SFTP_TIMEOUT_MS);
            ssh.connect(sftpHost, sftpPort);
            ssh.authPassword(sftpUser, sftpPassword);
            log.info("SFTP 探测成功: {}@{}:{}", sftpUser, sftpHost, sftpPort);
        } catch (Exception e) {
            log.warn("SFTP 启动探测失败: {}", e.getMessage());
            markSftpDisabled(e);
        }
    }

    /** SFTP 是否处于熔断期（认证失败后短时间内不再尝试） */
    private boolean isSftpDisabled() {
        return System.currentTimeMillis() < sftpDisabledUntilMs;
    }

    /** 标记 SFTP 不可用，短时间内直接走本地兜底 */
    private void markSftpDisabled(Exception e) {
        sftpDisabledUntilMs = System.currentTimeMillis() + SFTP_DISABLE_MS;
        log.warn("SFTP 熔断 {} 分钟（原因：{}）", SFTP_DISABLE_MS / 60_000L, e.getMessage());
    }

    /** 认证类失败重试无意义 */
    private static boolean isAuthFailure(Throwable e) {
        for (Throwable t = e; t != null; t = t.getCause()) {
            if (t instanceof net.schmizz.sshj.userauth.UserAuthException) {
                return true;
            }
        }
        return false;
    }

    /** SFTP 不可用时的本地兜底：把图片复制到本地目录 */
    private Path saveLocal(Path source, String name) throws IOException {
        Files.createDirectories(localDir);
        final Path target = localDir.resolve(name);
        Files.copy(source, target, StandardCopyOption.REPLACE_EXISTING);
        return target;
    }

    /** 取小写扩展名，无扩展名时默认 .jpg（相机 takePicture 固定保存 JPEG） */
    private static String extOf(String originalFilename) {
        if (originalFilename == null) {
            return ".jpg";
        }
        final int dot = originalFilename.lastIndexOf('.');
        return (dot >= 0) ? originalFilename.substring(dot).toLowerCase(Locale.ROOT) : ".jpg";
    }

    /** 失败重试 MAX_RETRIES 次 */
    private void uploadWithRetry(Path local, String remoteName) throws Exception {
        Exception last = null;
        for (int attempt = 1; attempt <= MAX_RETRIES; attempt++) {
            try {
                doUpload(local, remoteName);
                return;
            } catch (Exception e) {
                last = e;
                log.warn("图片上传第 {} 次尝试失败 ({}): {}", attempt, remoteName, e.getMessage());
                if (isAuthFailure(e)) {
                    break; // 认证失败重试无意义，立刻降级
                }
                if (attempt < MAX_RETRIES) {
                    Thread.sleep(RETRY_DELAY_MS);
                }
            }
        }
        throw last;
    }

    /** 单次上传：远程临时文件 + 大小校验 + 重命名覆盖正式文件 */
    private void doUpload(Path local, String remoteName) throws IOException {
        try (SSHClient ssh = new SSHClient()) {
            // 内网演示环境：信任所有主机密钥
            ssh.addHostKeyVerifier(new PromiscuousVerifier());
            ssh.setConnectTimeout(SFTP_TIMEOUT_MS);
            ssh.setTimeout(SFTP_TIMEOUT_MS);
            ssh.connect(sftpHost, sftpPort);
            ssh.authPassword(sftpUser, sftpPassword);

            try (SFTPClient sftp = ssh.newSFTPClient()) {
                ensureRemoteDir(sftp, remoteDir);

                final String remotePath = remoteDir + "/" + remoteName;
                final String tmpPath = remotePath + ".uploading.tmp";

                // 上传到临时文件，不直接写正式文件
                sftp.put(new FileSystemFile(local.toFile()), tmpPath);

                // 校验大小
                final long localSize = Files.size(local);
                final long remoteSize = sftp.lstat(tmpPath).getSize();
                if (remoteSize != localSize) {
                    try {
                        sftp.rm(tmpPath);
                    } catch (IOException ignored) {
                    }
                    throw new IOException("临时文件大小不一致 local=" + localSize + " remote=" + remoteSize);
                }

                // 重命名为正式文件（先删除同名旧文件，sshj 的 rename 不覆盖）
                try {
                    sftp.rm(remotePath);
                } catch (SFTPException ignored) {
                    // 正式文件不存在，正常
                } catch (IOException ignored) {
                    // 删除失败也继续尝试 rename
                }
                sftp.rename(tmpPath, remotePath);
            }
        }
    }

    /** 确保远程目录存在，不存在则逐级创建 */
    private void ensureRemoteDir(SFTPClient sftp, String dir) throws IOException {
        try {
            sftp.stat(dir);
            return;
        } catch (SFTPException notExist) {
            // 继续逐级创建
        }
        String current = "";
        for (final String part : dir.split("/")) {
            if (part.isEmpty()) {
                continue;
            }
            current = current + "/" + part;
            try {
                sftp.stat(current);
            } catch (SFTPException e) {
                try {
                    sftp.mkdir(current);
                } catch (IOException ignored) {
                    // 并发创建冲突等场景忽略
                }
            }
        }
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleError(Exception e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("message", e.getMessage() == null ? "请求失败" : e.getMessage()));
    }
}
