package com.example.app_spring.ai;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** AI助教会话历史实体（表 ai_chat_sessions，结构见 sql/zjxd_app_schema.sql） */
@Entity
@Table(name = "ai_chat_sessions")
public class AiChatSessionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 客户端生成的会话唯一标识（同一会话多次保存按此 upsert） */
    @Column(nullable = false, length = 64)
    private String sessionId;

    @Column(nullable = false, length = 32)
    private String username;

    /** 会话标题（取首条用户消息摘要） */
    @Column(nullable = false, length = 255)
    private String title;

    /** 完整消息列表 JSON（含富文本 blocks） */
    @Column(nullable = false, columnDefinition = "mediumtext")
    private String messagesJson;

    @Column(nullable = false)
    private long createdAtMs;

    @Column(nullable = false)
    private long updatedAtMs;

    protected AiChatSessionEntity() {
    }

    public AiChatSessionEntity(String sessionId, String username, String title,
                               String messagesJson, long createdAtMs, long updatedAtMs) {
        this.sessionId = sessionId;
        this.username = username;
        this.title = title;
        this.messagesJson = messagesJson;
        this.createdAtMs = createdAtMs;
        this.updatedAtMs = updatedAtMs;
    }

    public Long getId() {
        return id;
    }

    public String getSessionId() {
        return sessionId;
    }

    public String getUsername() {
        return username;
    }

    public String getTitle() {
        return title;
    }

    public String getMessagesJson() {
        return messagesJson;
    }

    public long getCreatedAtMs() {
        return createdAtMs;
    }

    public long getUpdatedAtMs() {
        return updatedAtMs;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public void setMessagesJson(String messagesJson) {
        this.messagesJson = messagesJson;
    }

    public void setUpdatedAtMs(long updatedAtMs) {
        this.updatedAtMs = updatedAtMs;
    }
}
