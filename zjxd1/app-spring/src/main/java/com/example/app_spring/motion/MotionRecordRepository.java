package com.example.app_spring.motion;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface MotionRecordRepository extends JpaRepository<MotionRecordEntity, Long> {

    /** 按用户查询运动记录，最新在前；用户名为空时返回全部 */
    @Query("SELECT r FROM MotionRecordEntity r " +
            "WHERE (:username IS NULL OR :username = '' OR r.username = :username) " +
            "ORDER BY r.createdAtMs DESC")
    List<MotionRecordEntity> findRecords(@Param("username") String username);
}