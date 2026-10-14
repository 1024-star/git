/*
 Navicat MySQL Dump SQL

 Source Server         : localhost_3306
 Source Server Type    : MySQL
 Source Server Version : 80023 (8.0.23)
 Source Host           : localhost:3306
 Source Schema         : zjxd_app

 Target Server Type    : MySQL
 Target Server Version : 80023 (8.0.23)
 File Encoding         : 65001

 Date: 14/09/2026 20:24:54
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for ai_chat_sessions
-- ----------------------------
DROP TABLE IF EXISTS `ai_chat_sessions`;
CREATE TABLE `ai_chat_sessions`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `session_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '会话唯一标识（客户端生成，重复保存按此 upsert）',
  `username` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '所属用户名',
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '新的对话' COMMENT '会话标题（首条用户消息摘要）',
  `messages_json` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '完整消息列表 JSON（含富文本 blocks）',
  `created_at_ms` bigint NOT NULL COMMENT '会话创建时间（毫秒时间戳）',
  `updated_at_ms` bigint NOT NULL COMMENT '会话最近更新时间（毫秒时间戳）',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_ai_chat_sessions_user`(`username` ASC) USING BTREE,
  INDEX `idx_ai_chat_sessions_updated`(`updated_at_ms` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'AI助教会话历史表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for community_post_images
-- ----------------------------
DROP TABLE IF EXISTS `community_post_images`;
CREATE TABLE `community_post_images`  (
  `post_id` bigint NOT NULL COMMENT '所属动态 ID',
  `image` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '图片资源路径',
  `sort_index` int NOT NULL DEFAULT 0 COMMENT '图片顺序',
  PRIMARY KEY (`post_id`, `sort_index`) USING BTREE,
  CONSTRAINT `fk_community_post_images_post` FOREIGN KEY (`post_id`) REFERENCES `community_posts` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '社区动态图片表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for community_post_like_users
-- ----------------------------
DROP TABLE IF EXISTS `community_post_like_users`;
CREATE TABLE `community_post_like_users`  (
  `post_id` bigint NOT NULL COMMENT '所属动态 ID',
  `user_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '点赞用户名',
  `sort_index` int NOT NULL DEFAULT 0 COMMENT '顺序',
  PRIMARY KEY (`post_id`, `sort_index`) USING BTREE,
  CONSTRAINT `fk_community_post_like_users_post` FOREIGN KEY (`post_id`) REFERENCES `community_posts` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '社区动态点赞用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for community_posts
-- ----------------------------
DROP TABLE IF EXISTS `community_posts`;
CREATE TABLE `community_posts`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '发布者昵称/用户名',
  `user_avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '发布者头像',
  `content` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '动态正文',
  `time_ago` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '发布时间的友好显示文本',
  `featured` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否精选',
  `likes` int NOT NULL DEFAULT 0 COMMENT '点赞数',
  `comments` int NOT NULL DEFAULT 0 COMMENT '评论数',
  `liked` tinyint(1) NOT NULL DEFAULT 0 COMMENT '当前用户是否已点赞',
  `created_at_ms` bigint NOT NULL COMMENT '创建时间（毫秒时间戳）',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_community_posts_created`(`created_at_ms` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '社区动态表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for motion_records
-- ----------------------------
DROP TABLE IF EXISTS `motion_records`;
CREATE TABLE `motion_records`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '训练用户名',
  `motion_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '训练名称',
  `actual_count` int NOT NULL DEFAULT 0 COMMENT '完成次数（定数模式）',
  `target_count` int NOT NULL DEFAULT 0 COMMENT '目标次数',
  `actual_time_seconds` int NOT NULL DEFAULT 0 COMMENT '训练时长（秒，定时模式）',
  `is_count_mode` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否定数模式（1=定数 0=定时）',
  `created_at_ms` bigint NOT NULL COMMENT '训练完成时间（毫秒时间戳）',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_motion_records_user`(`username` ASC) USING BTREE,
  INDEX `idx_motion_records_created`(`created_at_ms` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 17 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '运动训练记录表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for posture_reports
-- ----------------------------
DROP TABLE IF EXISTS `posture_reports`;
CREATE TABLE `posture_reports`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '检测用户名',
  `step_index` int NOT NULL DEFAULT 0 COMMENT '检测步骤（0=站立前屈 1=正面下腰）',
  `step_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '检测步骤名称',
  `score` int NOT NULL DEFAULT 0 COMMENT '体态评分',
  `severity` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '严重程度：Normal/Mild/Moderate/Severe',
  `curve_shape` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '弯曲类型：Normal/C/S',
  `shoulder_tilt` double NOT NULL DEFAULT 0 COMMENT '肩部倾斜角（度）',
  `pelvic_tilt` double NOT NULL DEFAULT 0 COMMENT '骨盆倾斜角（度）',
  `trunk_shift_percent` double NOT NULL DEFAULT 0 COMMENT '躯干偏移百分比',
  `cobb_angle` double NOT NULL DEFAULT 0 COMMENT 'Cobb角（度）',
  `summary` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '总结',
  `front_image_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '正面（背部）检测照片路径',
  `side_image_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '侧面（下腰）检测照片路径',
  `created_at_ms` bigint NOT NULL COMMENT '检测时间（毫秒时间戳）',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_posture_reports_user`(`username` ASC) USING BTREE,
  INDEX `idx_posture_reports_created`(`created_at_ms` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '脊柱检测报告存储表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for user_profile_archives
-- ----------------------------
DROP TABLE IF EXISTS `user_profile_archives`;
CREATE TABLE `user_profile_archives`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '档案所属用户名（唯一）',
  `nickname` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '昵称',
  `age` int NOT NULL DEFAULT 0 COMMENT '年龄',
  `gender` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '性别',
  `grade` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '年级',
  `diagnosis` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT 'AI 诊断分型',
  `type_tags` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '用户分型标签（逗号分隔）',
  `stage_index` int NOT NULL DEFAULT 1 COMMENT '当前康复阶段',
  `total_weeks` int NOT NULL DEFAULT 24 COMMENT '康复全程周数',
  `current_week` int NOT NULL DEFAULT 0 COMMENT '当前康复周',
  `progression_risk` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '侧弯进展风险：低/中/高',
  `anxiety_level` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '焦虑水平：低/中低/中/高',
  `spine_score` int NOT NULL DEFAULT 0 COMMENT '脊柱健康评分（0-100）',
  `pain_score` int NOT NULL DEFAULT 0 COMMENT '疼痛评分',
  `fitness_score` int NOT NULL DEFAULT 0 COMMENT '体能评分（0-100）',
  `adherence_level` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '依从性：低/中/高',
  `churn_risk` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '流失风险：低/中/高',
  `ai_summary` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT 'AI 综合评估文本（模型生成）',
  `ai_version` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '模型版本号',
  `ai_sources_json` json NULL COMMENT 'AI 综合评估数据来源标注 JSON 数组 [{icon,label,isAI}]',
  `spine_json` json NULL COMMENT '脊柱状态板块 JSON {summary,info,cobbTrend,cobbNote,sources}',
  `fitness_json` json NULL COMMENT '体能情况板块 JSON {summary,metrics,radar,radarNote,sources}',
  `rehab_json` json NULL COMMENT '康复需求板块 JSON {summary,info,contraindications,weeklyPlan,planNote,sources}',
  `persona_json` json NULL COMMENT '用户画像板块 JSON {summary,info,tags,adherence,strategies,sources}',
  `created_at_ms` bigint NOT NULL COMMENT '创建时间（毫秒时间戳）',
  `updated_at_ms` bigint NOT NULL COMMENT '更新时间（毫秒时间戳）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_profile_archives_username`(`username` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户个性化档案表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '登录账号，唯一',
  `password` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '登录密码（明文存储）',
  `nickname` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '昵称，为空时前端回退显示用户名',
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'assets/images/user-avatar-1.jpg' COMMENT '头像资源路径',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '账号状态：1=正常 0=禁用',
  `created_at_ms` bigint NOT NULL COMMENT '注册时间（毫秒时间戳）',
  `last_login_at_ms` bigint NULL DEFAULT NULL COMMENT '最近一次登录时间（毫秒时间戳）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_users_username`(`username` ASC) USING BTREE,
  INDEX `idx_users_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户表（密码明文）' ROW_FORMAT = DYNAMIC;

SET FOREIGN_KEY_CHECKS = 1;
