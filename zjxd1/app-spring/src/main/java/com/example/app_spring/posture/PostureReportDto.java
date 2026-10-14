package com.example.app_spring.posture;

import java.util.List;

public record PostureReportDto(
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
        long generatedAtMs
) {
}
