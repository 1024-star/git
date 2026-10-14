package com.example.app_spring.ai;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/** AI助教会话历史：会话级真实存储（upsert 保存 / 按用户列表 / 删除） */
@RestController
@RequestMapping("/api/ai/chat")
public class AiChatSessionController {

    private final AiChatSessionRepository repo;
    private final AiRuleEngine ruleEngine;

    public AiChatSessionController(AiChatSessionRepository repo, AiRuleEngine ruleEngine) {
        this.repo = repo;
        this.ruleEngine = ruleEngine;
    }

    /**
     * 小灵问答：本地规则引擎（离线可用，不依赖大模型/网络）。
     * 请求 {"question":"我今天应该做哪些训练？"}
     * 返回 {"ok":true,"answer":"...","matched":"今天","source":"rule"}
     *
     * 后续若要接大模型，只需改这里（前端与接口签名不变）。
     */
    @PostMapping("/ask")
    public Map<String, Object> ask(@RequestBody AskRequest req) {
        final String question = (req == null || req.question() == null) ? "" : req.question().trim();
        if (question.isEmpty()) {
            return Map.of("ok", false, "answer", "请先输入你的问题");
        }
        final Map<String, Object> r = ruleEngine.reply(question);
        return Map.of(
                "ok", true,
                "answer", r.get("answer"),
                "matched", r.get("matched") == null ? "" : r.get("matched"),
                "source", "rule"
        );
    }

    /** 问答请求体 */
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record AskRequest(String question) {
    }

    /** 保存/更新一个会话（按 sessionId upsert，同一会话反复保存不产生重复记录） */
    @PostMapping("/save")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> save(
            @RequestParam(value = "username", required = false) String username,
            @RequestBody SaveRequest req) {
        final String user = (username == null || username.isBlank()) ? "anonymous" : username.trim();
        if (req.sessionId() == null || req.sessionId().isBlank()) {
            return Map.of("message", "sessionId 不能为空");
        }

        final String title = (req.title() == null || req.title().isBlank())
                ? "新的对话" : req.title().trim();
        final String messagesJson = req.messages() == null ? "[]" : req.messages();
        final long now = System.currentTimeMillis();
        final long createdAt = (req.createdAtMs() != null && req.createdAtMs() > 0)
                ? req.createdAtMs() : now;
        final long updatedAt = (req.updatedAtMs() != null && req.updatedAtMs() > 0)
                ? req.updatedAtMs() : now;

        final List<AiChatSessionEntity> existing = repo.findBySessionId(req.sessionId().trim());
        AiChatSessionEntity entity;
        if (existing.isEmpty()) {
            entity = new AiChatSessionEntity(req.sessionId().trim(), user, title, messagesJson, createdAt, updatedAt);
        } else {
            entity = existing.get(0);
            entity.setTitle(title);
            entity.setMessagesJson(messagesJson);
            entity.setUpdatedAtMs(updatedAt);
        }
        final AiChatSessionEntity saved = repo.save(entity);
        return Map.of("message", "保存成功", "id", saved.getId());
    }

    /** 查询用户会话历史（最近更新在前，含完整消息，点击即回显） */
    @GetMapping("/list")
    public List<SessionDto> list(@RequestParam(value = "username", required = false) String username) {
        final String user = (username == null || username.isBlank()) ? "" : username.trim();
        return repo.findSessions(user).stream()
                .map(e -> new SessionDto(
                        e.getSessionId(),
                        e.getTitle(),
                        e.getMessagesJson(),
                        e.getCreatedAtMs(),
                        e.getUpdatedAtMs()
                ))
                .toList();
    }

    /** 删除一个会话 */
    @PostMapping("/delete")
    public Map<String, Object> delete(@RequestParam("sessionId") String sessionId) {
        final List<AiChatSessionEntity> existing = repo.findBySessionId(sessionId == null ? "" : sessionId.trim());
        if (existing.isEmpty()) {
            return Map.of("message", "会话不存在");
        }
        repo.deleteAll(existing);
        return Map.of("message", "删除成功");
    }

    /** 保存请求体 */
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record SaveRequest(
            String sessionId,
            String title,
            String messages,
            Long createdAtMs,
            Long updatedAtMs) {
    }

    /** 会话列表项（messages 为原始 JSON 字符串，由客户端解析成消息模型） */
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record SessionDto(
            String sessionId,
            String title,
            String messages,
            Long createdAtMs,
            Long updatedAtMs) {
    }
}
