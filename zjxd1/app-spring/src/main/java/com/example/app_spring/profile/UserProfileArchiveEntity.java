package com.example.app_spring.profile;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** 用户个性化档案实体（表 user_profile_archives，结构见 sql/结构.sql） */
@Entity
@Table(name = "user_profile_archives")
public class UserProfileArchiveEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 32, unique = true)
    private String username;

    @Column(nullable = false, length = 32)
    private String nickname;

    @Column(nullable = false)
    private int age;

    @Column(nullable = false, length = 8)
    private String gender;

    @Column(nullable = false, length = 16)
    private String grade;

    @Column(nullable = false, length = 64)
    private String diagnosis;

    /** 用户分型标签，逗号分隔 */
    @Column(nullable = false, length = 255)
    private String typeTags;

    @Column(nullable = false)
    private int stageIndex;

    @Column(nullable = false)
    private int totalWeeks;

    @Column(nullable = false)
    private int currentWeek;

    @Column(nullable = false, length = 16)
    private String progressionRisk;

    @Column(nullable = false, length = 16)
    private String anxietyLevel;

    @Column(nullable = false)
    private int spineScore;

    @Column(nullable = false)
    private int painScore;

    @Column(nullable = false)
    private int fitnessScore;

    @Column(nullable = false, length = 8)
    private String adherenceLevel;

    @Column(nullable = false, length = 8)
    private String churnRisk;

    @Column(nullable = false, length = 2000)
    private String aiSummary;

    @Column(nullable = false, length = 16)
    private String aiVersion;

    /** JSON 列（结构见 sql/结构.sql 字段注释），读取时由 Controller 反序列化 */
    @Column(columnDefinition = "json")
    private String aiSourcesJson;

    @Column(columnDefinition = "json")
    private String spineJson;

    @Column(columnDefinition = "json")
    private String fitnessJson;

    @Column(columnDefinition = "json")
    private String rehabJson;

    @Column(columnDefinition = "json")
    private String personaJson;

    @Column(nullable = false)
    private long createdAtMs;

    @Column(nullable = false)
    private long updatedAtMs;

    protected UserProfileArchiveEntity() {
    }

    public Long getId() {
        return id;
    }

    public String getUsername() {
        return username;
    }

    public String getNickname() {
        return nickname;
    }

    public int getAge() {
        return age;
    }

    public String getGender() {
        return gender;
    }

    public String getGrade() {
        return grade;
    }

    public String getDiagnosis() {
        return diagnosis;
    }

    public String getTypeTags() {
        return typeTags;
    }

    public int getStageIndex() {
        return stageIndex;
    }

    public int getTotalWeeks() {
        return totalWeeks;
    }

    public int getCurrentWeek() {
        return currentWeek;
    }

    public String getProgressionRisk() {
        return progressionRisk;
    }

    public String getAnxietyLevel() {
        return anxietyLevel;
    }

    public int getSpineScore() {
        return spineScore;
    }

    public int getPainScore() {
        return painScore;
    }

    public int getFitnessScore() {
        return fitnessScore;
    }

    public String getAdherenceLevel() {
        return adherenceLevel;
    }

    public String getChurnRisk() {
        return churnRisk;
    }

    public String getAiSummary() {
        return aiSummary;
    }

    public String getAiVersion() {
        return aiVersion;
    }

    public String getAiSourcesJson() {
        return aiSourcesJson;
    }

    public String getSpineJson() {
        return spineJson;
    }

    public String getFitnessJson() {
        return fitnessJson;
    }

    public String getRehabJson() {
        return rehabJson;
    }

    public String getPersonaJson() {
        return personaJson;
    }

    public long getCreatedAtMs() {
        return createdAtMs;
    }

    public long getUpdatedAtMs() {
        return updatedAtMs;
    }
}
