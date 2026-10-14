package com.example.app_spring.profile;

import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 用户个性化档案接口：
 * GET /api/profile/archive?username=b1
 * 返回档案头信息（结构化列）+ 各板块 JSON（脊柱/体能/康复/画像，含 AI/知识库来源标注）。
 */
@RestController
@RequestMapping("/api/profile")
public class UserProfileArchiveController {

    private final UserProfileArchiveRepository repo;
    private final ObjectMapper objectMapper;

    public UserProfileArchiveController(UserProfileArchiveRepository repo, ObjectMapper objectMapper) {
        this.repo = repo;
        this.objectMapper = objectMapper;
    }

    /** 查询用户个性化档案；不存在时返回 404（前端回退本地演示数据） */
    @GetMapping("/archive")
    public ResponseEntity<Map<String, Object>> archive(@RequestParam(value = "username") String username) {
        final String user = (username == null || username.isBlank()) ? "" : username.trim();
        if (user.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "username 不能为空"));
        }

        final UserProfileArchiveEntity e = repo.findFirstByUsername(user).orElse(null);
        if (e == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "档案不存在"));
        }

        final Map<String, Object> dto = new LinkedHashMap<>();
        dto.put("username", e.getUsername());
        dto.put("nickname", e.getNickname());
        dto.put("age", e.getAge());
        dto.put("gender", e.getGender());
        dto.put("grade", e.getGrade());
        dto.put("diagnosis", e.getDiagnosis());
        dto.put("typeTags", splitTags(e.getTypeTags()));
        dto.put("stageIndex", e.getStageIndex());
        dto.put("totalWeeks", e.getTotalWeeks());
        dto.put("currentWeek", e.getCurrentWeek());
        dto.put("progressionRisk", e.getProgressionRisk());
        dto.put("anxietyLevel", e.getAnxietyLevel());
        dto.put("spineScore", e.getSpineScore());
        dto.put("painScore", e.getPainScore());
        dto.put("fitnessScore", e.getFitnessScore());
        dto.put("adherenceLevel", e.getAdherenceLevel());
        dto.put("churnRisk", e.getChurnRisk());
        dto.put("aiSummary", e.getAiSummary());
        dto.put("aiVersion", e.getAiVersion());
        dto.put("aiSources", parseMapList(e.getAiSourcesJson()));
        dto.put("spine", parseObject(e.getSpineJson()));
        dto.put("fitness", parseObject(e.getFitnessJson()));
        dto.put("rehab", parseObject(e.getRehabJson()));
        dto.put("persona", parseObject(e.getPersonaJson()));
        dto.put("createdAtMs", e.getCreatedAtMs());
        dto.put("updatedAtMs", e.getUpdatedAtMs());
        return ResponseEntity.ok(dto);
    }

    /** 逗号分隔的分型标签转数组 */
    private static List<String> splitTags(String raw) {
        final List<String> tags = new ArrayList<>();
        if (raw != null) {
            for (String t : raw.split(",")) {
                if (!t.isBlank()) {
                    tags.add(t.trim());
                }
            }
        }
        return tags;
    }

    /** JSON 列反序列化为对象；失败返回空对象，不阻断接口 */
    private Map<String, Object> parseObject(String json) {
        if (json == null || json.isBlank()) {
            return Map.of();
        }
        try {
            final Map<String, Object> v = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {
            });
            return v == null ? Map.of() : v;
        } catch (Exception ignored) {
            return Map.of();
        }
    }

    /** JSON 列反序列化为数组；失败返回空数组，不阻断接口 */
    private List<Map<String, Object>> parseMapList(String json) {
        if (json == null || json.isBlank()) {
            return List.of();
        }
        try {
            final List<Map<String, Object>> v = objectMapper.readValue(json,
                    new TypeReference<List<Map<String, Object>>>() {
                    });
            return v == null ? List.of() : v;
        } catch (Exception ignored) {
            return List.of();
        }
    }
}
