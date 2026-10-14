package com.example.app_spring.posture;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface PostureReportRepository extends JpaRepository<PostureReportEntity, Long> {

    /** 按用户查询检测记录，最新在前；用户名为空时返回全部 */
    @Query("SELECT r FROM PostureReportEntity r " +
            "WHERE (:username IS NULL OR :username = '' OR r.username = :username) " +
            "ORDER BY r.createdAtMs DESC")
    List<PostureReportEntity> findReports(@Param("username") String username);
}
