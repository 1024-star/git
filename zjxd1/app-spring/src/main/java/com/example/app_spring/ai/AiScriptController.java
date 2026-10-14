package com.example.app_spring.ai;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/ai")
public class AiScriptController {

    @GetMapping("/script")
    public Map<String, Object> script() {
        final long now = Instant.now().toEpochMilli();

        final String thinkingTitle = "完成思考";

        final String thinkingText = String.join("\n\n",
                "好的，用户是个 16 岁的男生，脊柱侧弯 C 弯 11.2 度，想通过运动康复。首先需要确认他的情况是否适合单纯运动干预。21.2 度属于中度，青少年仍处于生长期，及时干预效果通常较好，但要避免不当训练导致弯曲加重。",
                "康复应以矫正性姿势训练为主，结合针对 C 弯的专项练习。同时要提醒注意日常姿势调整，如正确坐姿、均衡背负书包等，这些细节虽常被忽略，却对维持脊柱平衡至关重要。",
                "从 C 弯的特点来看，胸椎和腰椎凸向相反，因此需要针对性强化凹侧肌群、放松凸侧。一周的训练安排要兼顾频率与恢复，每天可安排轻度姿势训练，而强度较高的矫正练习建议隔天进行。"
        );

        final String mainText = String.join("\n\n",
                "根据国际脊柱侧凸研究学会（SRS）标准，Cobb 角≥10° 即可诊断为青少年特发性脊柱侧凸（AIS）。你最近几次的初筛和 3D 筛查度数变化在9.1°~10.5°度之间，大概率有轻度侧弯的问题，此阶段是通过运动疗法干预的最佳窗口期，可有效延缓或阻止侧弯进展 [1]。",
                "针对 C 型单弯（单主弯）患者，运动计划应以模式特异性矫正为基础，结合个体曲线类型进行定制。以下为基于当前循证医学证据的一周运动计划框架，重点推荐腰椎松动疗法或臀桥，因其在改善 Cobb 角和躯干外观方面证据等级较高。"
        );

        // 训练计划日期：以当天为起点，动态计算最近 7 天（今天 ~ 今天+6）
        final LocalDate today = LocalDate.now();
        final DateTimeFormatter dateFmt = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        final String[] weekLabels = {"周一", "周二", "周三", "周四", "周五", "周六", "周日"};

        final String[][] planRows = {
                {"腿部左右摆荡", "15 分钟", "中等", "改善骨盆与腰椎灵活性，平衡双侧肌力", "摆荡幅度两侧对称，动作缓慢，避免腰椎代偿"},
                {"臀桥", "20 分钟", "中等", "增强骨盆稳定性，平衡腰椎肌力", "臀部收紧，避免腰椎过度伸展"},
                {"休息或轻柔步行", "50 分钟", "低", "促进恢复", "避免剧烈运动"},
                {"侧平板支撑", "15 分钟", "中等", "增强侧弯对侧肌肉耐力", "若为右侧弯，重点练左侧；保持身体成直线"},
                {"仰卧交替屈膝伸腿", "15 分钟", "中等", "改善双下肢对称性与动态平衡", "保持躯干中立，避免向侧弯侧倾斜"},
                {"腰椎松动术", "10 分钟", "低", "增强腰椎灵活性，辅助姿势矫正", "动作轻柔，避免暴力扭转"},
                {"休息或轻柔步行", "-", "低", "促进恢复", "避免剧烈运动"}
        };

        final List<Map<String, Object>> planTable = new ArrayList<>();
        for (int i = 0; i < planRows.length; i++) {
            LocalDate day = today.plusDays(i);
            planTable.add(row(day.format(dateFmt), planRows[i][0], planRows[i][1], planRows[i][2], planRows[i][3], planRows[i][4]));
        }

        final List<Map<String, Object>> chart = new ArrayList<>();
        chart.add(chartItem(weekLabels[today.getDayOfWeek().getValue() - 1], "腿部左右摆荡", "中等", 15));
        chart.add(chartItem(weekLabels[today.plusDays(1).getDayOfWeek().getValue() - 1], "臀桥", "中等", 20));
        chart.add(chartItem(weekLabels[today.plusDays(2).getDayOfWeek().getValue() - 1], "休息", "轻度", 0));
        chart.add(chartItem(weekLabels[today.plusDays(3).getDayOfWeek().getValue() - 1], "侧平板支撑", "中等", 15));
        chart.add(chartItem(weekLabels[today.plusDays(4).getDayOfWeek().getValue() - 1], "仰卧交替屈膝伸腿", "中等", 15));
        chart.add(chartItem(weekLabels[today.plusDays(5).getDayOfWeek().getValue() - 1], "腰椎松动术", "轻度", 10));
        chart.add(chartItem(weekLabels[today.plusDays(6).getDayOfWeek().getValue() - 1], "休息", "轻度", 0));

        final String keyAdvice = String.join("\n\n",
                "关键建议：",
                "规范训练：研究表明，在姿势与动作方向正确、训练持续性良好的情况下，专项矫正训练可显著降低脊柱侧弯进展风险。训练过程中应注重动作精确性与呼吸节奏，避免随意发力或错误姿势导致代偿 [2]。",
                "结合螺旋成角呼吸：所有训练应配合三维呼吸训练，吸气时重点扩张侧弯凹侧胸廓，以辅助脊柱矫正 [3]。",
                "目前证据显示，臀桥和腰椎松动术在改善 Cobb 角方面效果最佳，腰椎松动疗法在网状 Meta 分析中排序最优 [3]。可进行个性化评估与训练指导，实现最佳康复效果。"
        );

        final List<Map<String, Object>> citations = List.of(
                Map.of(
                        "index", 1,
                        "tag", "",
                        "text", "用于青少年特发性脊柱侧凸保守治疗的理疗脊柱侧凸特定运动方法及其有效性：当前研究和实践的扩展文献综述\nSeleviciene V, Cesnaviciute A, Strukcinskiene B et al.\nInt J Environ Res Public Health. 2022 Jul 28;19 (15):9240."
                ),
                Map.of(
                        "index", 2,
                        "tag", "系统综述",
                        "text", "治疗性运动对青少年特发性脊柱侧凸进展的影响：系统评价的方案\nAndrade RM, Callegari Ferreira ME, Piras L et al.\nBMJ Open. 2024 Dec 5;14 (12):e083282."
                ),
                Map.of(
                        "index", 3,
                        "tag", "Meta-Analysis",
                        "text", "不同康复运动训练对青少年特发性脊柱侧凸患者干预效果的网状 Meta 分析\n黄静\n中华现代护理杂志. 2025;31 (04):470-477."
                )
        );

        final List<Map<String, Object>> blocks = List.of(
                block("thinking", 650, Map.of(
                        "title", thinkingTitle,
                        "text", thinkingText,
                        "collapsed", true
                )),
                block("paragraph", 900, Map.of("text", mainText)),
                block("heading", 800, Map.of("text", "专项脊柱侧弯康复训练计划")),
                block("table", 150, Map.of(
                        "columns", List.of("时间", "训练内容", "时长", "强度", "目标", "注意事项"),
                        "rows", planTable
                )),
                block("heading", 700, Map.of("text", "一周康复训练计划")),
                block("chart", 150, Map.of(
                        "title", "一周康复训练强度分布",
                        "items", chart
                )),
                block("paragraph", 700, Map.of("text", keyAdvice)),
                block("citations", 650, Map.of(
                        "title", "全部引用",
                        "items", citations,
                        "collapsed", true
                ))
        );

        return Map.of(
                "id", "scoliosis_plan_v1",
                "generatedAtMs", now,
                "blocks", blocks
        );
    }

    private static Map<String, Object> block(String type, int delayMs, Map<String, Object> data) {
        return Map.of(
                "type", type,
                "delayMs", delayMs,
                "data", data
        );
    }

    private static Map<String, Object> row(String date, String content, String duration, String intensity, String goal, String notes) {
        return Map.of(
                "date", date,
                "content", content,
                "duration", duration,
                "intensity", intensity,
                "goal", goal,
                "notes", notes
        );
    }

    private static Map<String, Object> chartItem(String day, String name, String intensity, int minutes) {
        return Map.of(
                "day", day,
                "name", name,
                "intensity", intensity,
                "minutes", minutes
        );
    }
}
