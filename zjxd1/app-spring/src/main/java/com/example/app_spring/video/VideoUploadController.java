package com.example.app_spring.video;

import net.schmizz.sshj.SSHClient;
import net.schmizz.sshj.sftp.RemoteResourceInfo;
import net.schmizz.sshj.sftp.SFTPClient;
import net.schmizz.sshj.sftp.SFTPException;
import net.schmizz.sshj.transport.verification.PromiscuousVerifier;
import net.schmizz.sshj.xfer.FileSystemFile;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Comparator;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Stream;

/**
 * 训练视频上传：App 通过 multipart 上传到本服务，
 * 服务再经 SFTP 原子转存到远程服务器（替代原 PC 端 watchdog + paramiko 脚本）。
 *
 * <p>上传流程与原脚本一致：先写远程临时文件 -> 校验大小 -> 重命名为正式文件，
 * 失败重试 3 次，绝不删除服务器上已有的好文件。
 */
@RestController
@RequestMapping("/api/video")
public class VideoUploadController {

    private static final Logger log = LoggerFactory.getLogger(VideoUploadController.class);

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
    /** SFTP 不可用时的本地兜底目录（默认 uploads/video，可用 app.video.upload.local-dir 覆盖） */
    private final Path localDir;
    /** SFTP 熔断到期时间戳；未到期时跳过 SFTP 直接走本地 */
    private volatile long sftpDisabledUntilMs = 0L;

    public VideoUploadController(
            @Value("${app.video.upload.sftp-host}") String sftpHost,
            @Value("${app.video.upload.sftp-port}") int sftpPort,
            @Value("${app.video.upload.sftp-user}") String sftpUser,
            @Value("${app.video.upload.sftp-password}") String sftpPassword,
            @Value("${app.video.upload.remote-dir}") String remoteDir,
            @Value("${app.video.upload.local-dir:uploads/video}") String localDir) {
        this.sftpHost = sftpHost;
        this.sftpPort = sftpPort;
        this.sftpUser = sftpUser;
        this.sftpPassword = sftpPassword;
        this.remoteDir = remoteDir;
        this.localDir = Path.of(localDir).toAbsolutePath();
        // 启动即异步探测 SFTP：不可用则提前熔断，避免用户首次上传空等十几秒
        Thread probe = new Thread(this::probeSftp, "sftp-probe-video");
        probe.setDaemon(true);
        probe.start();
    }

    /**
     * 接收 App 上传的训练视频并转存到远程服务器。
     * 远程文件名：{用户名}_{yyyyMMdd_HHmmss}{扩展名}，避免多用户互相覆盖。
     */
    @PostMapping("/upload")
    public ResponseEntity<Map<String, Object>> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "username", required = false, defaultValue = "anonymous") String username) {
        if (file == null || file.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "视频文件为空"));
        }

        // 按需求：上传到服务器的视频文件名为 test（覆盖服务器已有同名视频），
        // 保留视频本身的扩展名（如 test.mp4），由前端传入的原始文件名决定
        final String original = file.getOriginalFilename() == null ? "" : file.getOriginalFilename();
        final int dot = original.lastIndexOf('.');
        final String ext = (dot >= 0) ? original.substring(dot).toLowerCase(Locale.ROOT) : ".mp4";
        final String remoteName = "test" + ext;

        Path temp = null;
        try {
            // multipart 先落本地临时文件，再用 SFTP 流式转存
            temp = Files.createTempFile("video_upload_", ext);
            file.transferTo(temp.toFile());

            if (isSftpDisabled()) {
                final Path saved = saveLocal(temp, remoteName);
                log.info("SFTP 处于熔断期，视频直接存本地: {} -> {}", remoteName, saved);
                return ResponseEntity.ok(Map.of(
                        "message", "上传成功（本地）",
                        "remotePath", saved.toString(),
                        "local", true
                ));
            }
            try {
                uploadWithRetry(temp, remoteName);

                final String remotePath = remoteDir + "/" + remoteName;
                log.info("视频上传成功: {} ({} 字节) -> {}", remoteName, Files.size(temp), remotePath);
                return ResponseEntity.ok(Map.of(
                        "message", "上传成功",
                        "remotePath", remotePath
                ));
            } catch (InterruptedException ie) {
                throw ie;
            } catch (Exception sftpError) {
                // 远程服务器不可用（例如 SFTP 凭据失效）时降级为本地存储，保证演示流程不中断
                log.warn("SFTP 上传失败，降级为本地存储: {}", sftpError.getMessage());
                markSftpDisabled(sftpError);
                final Path saved = saveLocal(temp, remoteName);
                log.info("视频已存本地: {} ({} 字节) -> {}", remoteName, Files.size(saved), saved);
                return ResponseEntity.ok(Map.of(
                        "message", "上传成功（本地）",
                        "remotePath", saved.toString(),
                        "local", true
                ));
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "上传被中断"));
        } catch (Exception e) {
            log.error("视频上传失败: {}", remoteName, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "上传失败: " + e.getMessage()));
        } finally {
            if (temp != null) {
                try {
                    Files.deleteIfExists(temp);
                } catch (IOException ignored) {
                }
            }
        }
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
                log.warn("视频上传第 {} 次尝试失败 ({}): {}", attempt, remoteName, e.getMessage());
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

    /** 单次上传：临时文件 + 大小校验 + 原子重命名 */
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

                // 上传到临时文件，不直接覆盖正式文件
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

                // 重命名为正式文件（先尝试删除同名旧文件，sshj 的 rename 不覆盖）
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

    // ==================== 历史回放：/api/video/get ====================

    /** 回放缓存锁：同一时刻只允许一个线程向本地缓存写文件 */
    private final Object serveCacheLock = new Object();

    /** 最近一次从远程服务器拉到本地的视频缓存 */
    private Path serveCacheFile;
    private String serveCacheName;
    private long serveCacheSize = -1;
    private long serveCacheMtime = -1;

    /**
     * 供 App 历史记录回放：把远程服务器上最新上传的训练视频（test.*）拉到本地并流式返回。
     * 返回 FileSystemResource，Spring 会自动处理 Range 请求（支持播放器拖动进度条）。
     * 远程文件未变化时直接复用本地缓存，避免每次回放都重新 SFTP 下载。
     */
    @GetMapping("/get")
    public ResponseEntity<Object> get() {
        Path serveFile;
        String name;
        if (isSftpDisabled()) {
            final Path local = newestLocalVideo();
            if (local == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("message", "本地暂无训练视频"));
            }
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + local.getFileName() + "\"")
                    .contentType(mediaTypeOf(local.getFileName().toString()))
                    .body(new FileSystemResource(local));
        }
        try {
            synchronized (serveCacheLock) {
                refreshServeCache();
            }
            serveFile = serveCacheFile;
            name = serveCacheName;
        } catch (Exception e) {
            // 远程不可用时回退到本地兜底目录，保证演示时仍能回放
            final Path local = newestLocalVideo();
            if (local == null) {
                log.error("视频回放拉取失败", e);
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body(Map.of("message", "拉取服务器视频失败: " + e.getMessage()));
            }
            log.warn("SFTP 不可用，改为回放本地文件: {} ({})", local, e.getMessage());
            markSftpDisabled(e);
            serveFile = local;
            name = local.getFileName().toString();
        }

        if (serveFile == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "服务器暂无训练视频"));
        }

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + name + "\"")
                .contentType(mediaTypeOf(name))
                .body(new FileSystemResource(serveFile));
    }

    /** 检查远程最新视频是否变化，变化则重新下载到本地缓存（需持有 serveCacheLock） */
    private void refreshServeCache() throws Exception {
        try (SSHClient ssh = new SSHClient()) {
            // 内网演示环境：信任所有主机密钥
            ssh.addHostKeyVerifier(new PromiscuousVerifier());
            ssh.connect(sftpHost, sftpPort);
            ssh.authPassword(sftpUser, sftpPassword);

            try (SFTPClient sftp = ssh.newSFTPClient()) {
                // 上传固定命名为 test + 扩展名，目录里取修改时间最新的一份
                RemoteResourceInfo newest = null;
                for (RemoteResourceInfo info : sftp.ls(remoteDir)) {
                    if (info.isDirectory()) {
                        continue;
                    }
                    if (!info.getName().startsWith("test.")) {
                        continue;
                    }
                    if (newest == null
                            || info.getAttributes().getMtime() > newest.getAttributes().getMtime()) {
                        newest = info;
                    }
                }

                if (newest == null) {
                    // 远程没有视频了，清空缓存
                    deleteServeCacheFile();
                    serveCacheFile = null;
                    serveCacheName = null;
                    serveCacheSize = -1;
                    serveCacheMtime = -1;
                    return;
                }

                final long size = newest.getAttributes().getSize();
                final long mtime = newest.getAttributes().getMtime();
                if (serveCacheFile != null
                        && newest.getName().equals(serveCacheName)
                        && size == serveCacheSize
                        && mtime == serveCacheMtime
                        && Files.exists(serveCacheFile)) {
                    return; // 远程没变，直接复用本地缓存
                }

                final Path tmp = Files.createTempFile("video_serve_", extOf(newest.getName()));
                sftp.get(newest.getPath(), tmp.toString());
                tmp.toFile().deleteOnExit();

                deleteServeCacheFile();
                serveCacheFile = tmp;
                serveCacheName = newest.getName();
                serveCacheSize = size;
                serveCacheMtime = mtime;
                log.info("视频回放缓存更新: {} ({} 字节)", serveCacheName, size);
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

    /** SFTP 不可用时的本地兜底：把上传文件复制到本地目录 */
    private Path saveLocal(Path source, String name) throws IOException {
        Files.createDirectories(localDir);
        final Path target = localDir.resolve(name);
        Files.copy(source, target, StandardCopyOption.REPLACE_EXISTING);
        return target;
    }

    /** 本地兜底目录中最新的 test.* 视频（供回放），没有则返回 null */
    private Path newestLocalVideo() {
        if (!Files.isDirectory(localDir)) {
            return null;
        }
        try (Stream<Path> files = Files.list(localDir)) {
            return files
                    .filter(Files::isRegularFile)
                    .filter(p -> p.getFileName().toString().startsWith("test."))
                    .max(Comparator.comparingLong(p -> p.toFile().lastModified()))
                    .orElse(null);
        } catch (IOException e) {
            return null;
        }
    }

    private void deleteServeCacheFile() {
        if (serveCacheFile != null) {
            try {
                Files.deleteIfExists(serveCacheFile);
            } catch (IOException ignored) {
            }
        }
    }

    private static String extOf(String name) {
        final int dot = name.lastIndexOf('.');
        return (dot >= 0) ? name.substring(dot) : ".mp4";
    }

    private static MediaType mediaTypeOf(String name) {
        final String ext = extOf(name).toLowerCase(Locale.ROOT);
        return switch (ext) {
            case ".webm" -> MediaType.parseMediaType("video/webm");
            case ".mov" -> MediaType.parseMediaType("video/quicktime");
            case ".3gp" -> MediaType.parseMediaType("video/3gpp");
            default -> MediaType.parseMediaType("video/mp4");
        };
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleError(Exception e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("message", e.getMessage() == null ? "请求失败" : e.getMessage()));
    }
}
