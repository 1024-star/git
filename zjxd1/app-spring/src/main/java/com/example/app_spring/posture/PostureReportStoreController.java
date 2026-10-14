package com.example.app_spring.posture;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;
import java.util.Map;

/** 脊柱检测报告存储：检测完成上报保存，报告中心按用户查询历史记录 */
@RestController
@RequestMapping("/api/posture")
public class PostureReportStoreController {

    private final PostureReportRepository repo;

    public PostureReportStoreController(PostureReportRepository repo) {
        this.repo = repo;
    }

    public record SaveRequest(
            String username,
            Integer stepIndex,
            String stepName,
            Integer score,
            String severity,
            String curveShape,
            Double shoulderTilt,
            Double pelvicTilt,
            Double trunkShiftPercent,
            Double cobbAngle,
            String summary,
            String frontImagePath,
            String sideImagePath,
            Long generatedAtMs
    ) {
    }

    /** 列表返回结构：比检测报告多携带步骤信息与检测照片路径 */
    public record StoredReportDto(
            int score,
            String severity,
            String curveShape,
            double shoulderTilt,
            double pelvicTilt,
            double trunkShiftPercent,
            double cobbAngle,
            String summary,
            List<String> riskFindings,
            List<String> advice,
            long generatedAtMs,
            int stepIndex,
            String stepName,
            String frontImagePath,
            String sideImagePath
    ) {
    }

    /** 检测完成后保存一条报告记录 */
    @PostMapping("/save")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> save(@RequestBody SaveRequest req) {
        final String username = (req.username() == null || req.username().isBlank())
                ? "anonymous" : req.username().trim();
        final int stepIndex = req.stepIndex() == null ? 0 : Math.max(0, req.stepIndex());
        final String stepName = req.stepName() == null ? "" : req.stepName().trim();
        final long now = req.generatedAtMs() == null || req.generatedAtMs() <= 0
                ? Instant.now().toEpochMilli() : req.generatedAtMs();

        final PostureReportDto dto = new PostureReportDto(
                req.score() == null ? 0 : req.score(),
                req.severity() == null ? "" : req.severity(),
                req.curveShape() == null ? "" : req.curveShape(),
                req.shoulderTilt() == null ? 0.0 : req.shoulderTilt(),
                req.pelvicTilt() == null ? 0.0 : req.pelvicTilt(),
                req.trunkShiftPercent() == null ? 0.0 : req.trunkShiftPercent(),
                req.cobbAngle() == null ? 0.0 : req.cobbAngle(),
                req.summary() == null ? "" : req.summary(),
                List.of(),
                List.of(),
                now
        );

        final PostureReportEntity saved = repo.save(new PostureReportEntity(
                username, stepIndex, stepName,
                req.frontImagePath(), req.sideImagePath(), dto));
        return Map.of(
                "message", "保存成功",
                "id", saved.getId()
        );
    }

    /** 报告中心查询用户检测记录（最新在前） */
    @GetMapping("/list")
    public List<StoredReportDto> list(@RequestParam(value = "username", required = false) String username) {
        final String user = (username == null || username.isBlank()) ? "" : username.trim();
        return repo.findReports(user).stream()
                .map(e -> new StoredReportDto(
                        e.getScore(),
                        e.getSeverity(),
                        e.getCurveShape(),
                        e.getShoulderTilt(),
                        e.getPelvicTilt(),
                        e.getTrunkShiftPercent(),
                        e.getCobbAngle(),
                        e.getSummary(),
                        List.of(),
                        List.of(),
                        e.getCreatedAtMs(),
                        e.getStepIndex(),
                        e.getStepName(),
                        e.getFrontImagePath(),
                        e.getSideImagePath()
                ))
                .toList();
    }
}
