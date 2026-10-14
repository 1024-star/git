package com.example.app_spring.ai;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface AiChatSessionRepository extends JpaRepository<AiChatSessionEntity, Long> {

    /** 按用户查询会话历史，最近更新在前；用户名为空时返回全部 */
    @Query("SELECT s FROM AiChatSessionEntity s " +
            "WHERE (:username IS NULL OR :username = '' OR s.username = :username) " +
            "ORDER BY s.updatedAtMs DESC")
    List<AiChatSessionEntity> findSessions(@Param("username") String username);

    List<AiChatSessionEntity> findBySessionId(String sessionId);
}
