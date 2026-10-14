package com.example.app_spring.posture;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/posture")
public class PostureReportController {

    @GetMapping("/report")
    public PostureReportDto report(
            @RequestParam(value = "stepIndex", required = false) Integer stepIndex,
            @RequestParam(value = "stepName", required = false) String stepName
    ) {
        final int step = stepIndex == null ? 0 : Math.max(0, stepIndex);
        final String name = stepName == null ? "" : stepName.trim();

        final long now = Instant.now().toEpochMilli();

        final boolean isFront = name.contains("正面") || name.contains("前");
        final int baseScore = 92 - (step * 3) - (isFront ? 2 : 0);

        final double shoulderTilt = clamp(0.6 + step * 0.9 + (isFront ? 0.5 : 0.0), 0.4, 6.8);
        final double pelvicTilt = clamp(0.8 + step * 1.0 + (isFront ? 0.7 : 0.0), 0.5, 7.2);
        final double trunkShift = clamp(0.4 + step * 0.55 + (isFront ? 0.4 : 0.0), 0.3, 6.0);
        final double cobbAngle = clamp(2.6 + step * 2.2 + (isFront ? 0.8 : 0.0), 1.8, 22.0);

        final String severity;
        final String curveShape;
        final int score;

        if (cobbAngle < 6.0) {
            severity = "Normal";
            curveShape = "Normal";
            score = clampScore(baseScore + 3);
        } else if (cobbAngle < 12.0) {
            severity = "Mild";
            curveShape = (step % 2 == 0) ? "C" : "S";
            score = clampScore(baseScore - 2);
        } else if (cobbAngle < 18.0) {
            severity = "Moderate";
            curveShape = (step % 2 == 0) ? "S" : "C";
            score = clampScore(baseScore - 8);
        } else {
            severity = "Severe";
            curveShape = "S";
            score = clampScore(baseScore - 14);
        }

        final String summary = buildSummary(severity, curveShape, shoulderTilt, pelvicTilt, trunkShift, cobbAngle);
        final List<String> findings = buildFindings(severity, shoulderTilt, pelvicTilt, trunkShift, cobbAngle);
        final List<String> advice = buildAdvice(severity);

        return new PostureReportDto(
                score,
                severity,
                curveShape,
                shoulderTilt,
                pelvicTilt,
                trunkShift,
                cobbAngle,
                summary,
                findings,
                advice,
                now
        );
    }

    private static String buildSummary(String severity, String curveShape, double shoulderTilt, double pelvicTilt, double trunkShift, double cobbAngle) {
        final String sev;
        if (severity.equalsIgnoreCase("Normal")) sev = "整体对称性良好";
        else if (severity.equalsIgnoreCase("Mild")) sev = "存在轻度体态偏移";
        else if (severity.equalsIgnoreCase("Moderate")) sev = "存在中度体态偏移";
        else sev = "存在明显体态偏移";

        final String shape;
        final String c = curveShape.toLowerCase();
        if (c.contains("normal")) shape = "脊柱曲线形态正常";
        else if (c.contains("s")) shape = "脊柱呈 S 型曲线趋势";
        else if (c.contains("c")) shape = "脊柱呈 C 型曲线趋势";
        else shape = "曲线形态待进一步确认";

        return "分析结果显示：" + sev + "，" + shape + "。肩部倾斜约" + fmt(shoulderTilt) + "°，骨盆倾斜约" + fmt(pelvicTilt)
                + "°，躯干偏移约" + fmt(trunkShift) + "%" + "，Cobb 角约" + fmt(cobbAngle) + "°。";
    }

    private static List<String> buildFindings(String severity, double shoulderTilt, double pelvicTilt, double trunkShift, double cobbAngle) {
        if (severity.equalsIgnoreCase("Normal")) {
            return List.of(
                    "肩线与骨盆线基本水平，左右对称性良好",
                    "躯干中心线偏移在可接受范围内",
                    "脊柱侧弯角度未见明显异常"
            );
        }

        if (severity.equalsIgnoreCase("Mild")) {
            return List.of(
                    "肩部轻度不对称（约" + fmt(shoulderTilt) + "°）",
                    "骨盆轻度倾斜（约" + fmt(pelvicTilt) + "°），可能与久坐/单侧受力有关",
                    "躯干偏移（约" + fmt(trunkShift) + "%），建议加强核心稳定"
            );
        }

        if (severity.equalsIgnoreCase("Moderate")) {
            return List.of(
                    "肩部倾斜较明显（约" + fmt(shoulderTilt) + "°），存在代偿姿势",
                    "骨盆倾斜（约" + fmt(pelvicTilt) + "°），可能伴随髋屈肌紧张",
                    "侧弯角度（约" + fmt(cobbAngle) + "°）提示需持续跟踪"
            );
        }

        return List.of(
                "肩/骨盆不对称明显，建议尽快进行专业评估",
                "躯干偏移（约" + fmt(trunkShift) + "%）较大，存在代偿风险",
                "侧弯角度（约" + fmt(cobbAngle) + "°）偏高，建议到医院进一步检查"
        );
    }

    private static List<String> buildAdvice(String severity) {
        if (severity.equalsIgnoreCase("Normal")) {
            return List.of(
                    "保持日常拉伸与体态习惯（胸椎伸展、背阔肌放松）",
                    "注意坐姿/站姿对称，避免长期单侧背包",
                    "建议每2-4周复测一次，观察趋势"
            );
        }

        if (severity.equalsIgnoreCase("Mild")) {
            return List.of(
                    "建议每周3-4次核心稳定训练（平板支撑/死虫式）",
                    "配合肩颈与髋屈肌放松（拉伸+泡沫轴）",
                    "避免久坐，保持每45-60分钟起身活动"
            );
        }

        if (severity.equalsIgnoreCase("Moderate")) {
            return List.of(
                    "建议每周4-5次矫正训练（核心稳定+背部力量）",
                    "优先纠正日常不对称负重与长期低头习惯",
                    "建议4-8周复测，必要时咨询康复/体态教练"
            );
        }

        return List.of(
                "建议尽快到医院骨科/康复科进行评估与影像检查",
                "遵医嘱进行系统化康复训练或矫形干预",
                "避免单侧负重、长时间不良体位与剧烈冲击运动"
        );
    }

    private static double clamp(double v, double min, double max) {
        return Math.max(min, Math.min(max, v));
    }

    private static int clampScore(int score) {
        if (score < 60) return 60;
        if (score > 98) return 98;
        return score;
    }

    private static String fmt(double v) {
        return String.format("%.1f", v);
    }
}
