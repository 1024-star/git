package com.example.app_spring.motion;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** 运动训练记录实体（表 motion_records，结构见 sql/zjxd_app_schema.sql） */
@Entity
@Table(name = "motion_records")
public class MotionRecordEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 32)
    private String username;

    @Column(nullable = false, length = 64)
    private String motionName;

    @Column(nullable = false)
    private int actualCount;

    @Column(nullable = false)
    private int targetCount;

    @Column(nullable = false)
    private int actualTimeSeconds;

    @Column(nullable = false)
    private boolean isCountMode;

    @Column(nullable = false)
    private long createdAtMs;

    protected MotionRecordEntity() {
    }

    public MotionRecordEntity(String username, MotionRecordDto dto) {
        this.username = username;
        this.motionName = dto.motionName() == null ? "" : dto.motionName();
        this.actualCount = dto.actualCountValue();
        this.targetCount = dto.targetCountValue();
        this.actualTimeSeconds = dto.actualTimeSecondsValue();
        this.isCountMode = dto.isCountModeValue();
        this.createdAtMs = dto.createdAtMs() != null && dto.createdAtMs() > 0
                ? dto.createdAtMs() : System.currentTimeMillis();
    }

    public Long getId() {
        return id;
    }

    public String getUsername() {
        return username;
    }

    public String getMotionName() {
        return motionName;
    }

    public int getActualCount() {
        return actualCount;
    }

    public int getTargetCount() {
        return targetCount;
    }

    public int getActualTimeSeconds() {
        return actualTimeSeconds;
    }

    public boolean isCountMode() {
        return isCountMode;
    }

    public long getCreatedAtMs() {
        return createdAtMs;
    }
}