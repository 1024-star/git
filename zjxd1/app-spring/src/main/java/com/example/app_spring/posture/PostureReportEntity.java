package com.example.app_spring.posture;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** 脊柱检测报告存储实体（表 posture_reports，结构见 sql/zjxd_app_schema.sql） */
@Entity
@Table(name = "posture_reports")
public class PostureReportEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 32)
    private String username;

    @Column(nullable = false)
    private int stepIndex;

    @Column(nullable = false, length = 64)
    private String stepName;

    @Column(nullable = false)
    private int score;

    @Column(nullable = false, length = 16)
    private String severity;

    @Column(nullable = false, length = 16)
    private String curveShape;

    @Column(nullable = false)
    private double shoulderTilt;

    @Column(nullable = false)
    private double pelvicTilt;

    @Column(nullable = false)
    private double trunkShiftPercent;

    @Column(nullable = false)
    private double cobbAngle;

    @Column(nullable = false, length = 2000)
    private String summary;

    @Column(nullable = false, length = 255)
    private String frontImagePath;

    @Column(nullable = false, length = 255)
    private String sideImagePath;

    @Column(nullable = false)
    private long createdAtMs;

    protected PostureReportEntity() {
    }

    public PostureReportEntity(String username, int stepIndex, String stepName, String frontImagePath,
                               String sideImagePath, PostureReportDto dto) {
        this.username = username;
        this.stepIndex = stepIndex;
        this.stepName = stepName == null ? "" : stepName;
        this.frontImagePath = frontImagePath == null ? "" : frontImagePath;
        this.sideImagePath = sideImagePath == null ? "" : sideImagePath;
        this.score = dto.score();
        this.severity = dto.severity() == null ? "" : dto.severity();
        this.curveShape = dto.curveShape() == null ? "" : dto.curveShape();
        this.shoulderTilt = dto.shoulderTilt();
        this.pelvicTilt = dto.pelvicTilt();
        this.trunkShiftPercent = dto.trunkShiftPercent();
        this.cobbAngle = dto.cobbAngle();
        this.summary = dto.summary() == null ? "" : dto.summary();
        this.createdAtMs = dto.generatedAtMs();
    }

    public Long getId() {
        return id;
    }

    public String getUsername() {
        return username;
    }

    public int getStepIndex() {
        return stepIndex;
    }

    public String getStepName() {
        return stepName;
    }

    public int getScore() {
        return score;
    }

    public String getSeverity() {
        return severity;
    }

    public String getCurveShape() {
        return curveShape;
    }

    public double getShoulderTilt() {
        return shoulderTilt;
    }

    public double getPelvicTilt() {
        return pelvicTilt;
    }

    public double getTrunkShiftPercent() {
        return trunkShiftPercent;
    }

    public double getCobbAngle() {
        return cobbAngle;
    }

    public String getSummary() {
        return summary;
    }

    public String getFrontImagePath() {
        return frontImagePath;
    }

    public String getSideImagePath() {
        return sideImagePath;
    }

    public long getCreatedAtMs() {
        return createdAtMs;
    }
}
