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

 Date: 14/09/2026 20:24:45
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
-- Records of ai_chat_sessions
-- ----------------------------
INSERT INTO `ai_chat_sessions` VALUES (1, '1789294384227_950665', 'a', '1', '[{\"role\":\"user\",\"content\":\"1\",\"blocks\":[],\"isStreaming\":false},{\"role\":\"ai\",\"content\":\"\",\"blocks\":[{\"type\":\"thinking\",\"text\":\"好的，用户是个 16 岁的男生，脊柱侧弯 C 弯 11.2 度，想通过运动康复。首先需要确认他的情况是否适合单纯运动干预。21.2 度属于中度，青少年仍处于生长期，及时干预效果通常较好，但要避免不当训练导致弯曲加重。\\n\\n康复应以矫正性姿势训练为主，结合针对 C 弯的专项练习。同时要提醒注意日常姿势调整，如正确坐姿、均衡背负书包等，这些细节虽常被忽略，却对维持脊柱平衡至关重要。\\n\\n从 C 弯的特点来看，胸椎和腰椎凸向相反，因此需要针对性强化凹侧肌群、放松凸侧。一周的训练安排要兼顾频率与恢复，每天可安排轻度姿势训练，而强度较高的矫正练习建议隔天进行。\",\"title\":\"完成思考\",\"collapsed\":true,\"columns\":null,\"rows\":null,\"chartItems\":null,\"citations\":null},{\"type\":\"paragraph\",\"text\":\"根据国际脊柱侧凸研究学会（SRS）标准，Cobb 角≥10° 即可诊断为青少年特发性脊柱侧凸（AIS）。你最近几次的初筛和 3D 筛查度数变化在 9 到 20 度之间，大概率有轻度侧弯的问题，此阶段是通过运动疗法干预的最佳窗口期，可有效延缓或阻止侧弯进展 [1]。\\n\\n针对 C 型单弯（单主弯）患者，运动计划应以模式特异性矫正为基础，结合个体曲线类型进行定制。以下为基于当前循证医学证据的一周运动计划框架，重点推荐腰椎松动疗法或臀桥，因其在改善 Cobb 角和躯干外观方面证据等级较高。\",\"title\":null,\"collapsed\":null,\"columns\":null,\"rows\":null,\"chartItems\":null,\"citations\":null},{\"type\":\"heading\",\"text\":\"专项脊柱侧弯康复训练计划\",\"title\":null,\"collapsed\":null,\"columns\":null,\"rows\":null,\"chartItems\":null,\"citations\":null},{\"type\":\"table\",\"text\":null,\"title\":null,\"collapsed\":null,\"columns\":[\"时间\",\"训练内容\",\"时长\",\"强度\",\"目标\",\"注意事项\"],\"rows\":[{\"intensity\":\"中等\",\"duration\":\"15 分钟\",\"content\":\"腿部左右摆荡\",\"goal\":\"改善骨盆与腰椎灵活性，平衡双侧肌力\",\"notes\":\"摆荡幅度两侧对称，动作缓慢，避免腰椎代偿\",\"date\":\"2026-09-13\"},{\"intensity\":\"中等\",\"duration\":\"20 分钟\",\"content\":\"臀桥\",\"goal\":\"增强骨盆稳定性，平衡腰椎肌力\",\"notes\":\"臀部收紧，避免腰椎过度伸展\",\"date\":\"2026-09-14\"},{\"intensity\":\"低\",\"duration\":\"50 分钟\",\"content\":\"休息或轻柔步行\",\"goal\":\"促进恢复\",\"notes\":\"避免剧烈运动\",\"date\":\"2026-09-15\"},{\"intensity\":\"中等\",\"duration\":\"15 分钟\",\"content\":\"侧平板支撑\",\"goal\":\"增强侧弯对侧肌肉耐力\",\"notes\":\"若为右侧弯，重点练左侧；保持身体成直线\",\"date\":\"2026-09-16\"},{\"intensity\":\"中等\",\"duration\":\"15 分钟\",\"content\":\"仰卧交替屈膝伸腿\",\"goal\":\"改善双下肢对称性与动态平衡\",\"notes\":\"保持躯干中立，避免向侧弯侧倾斜\",\"date\":\"2026-09-17\"},{\"intensity\":\"低\",\"duration\":\"10 分钟\",\"content\":\"腰椎松动术\",\"goal\":\"增强腰椎灵活性，辅助姿势矫正\",\"notes\":\"动作轻柔，避免暴力扭转\",\"date\":\"2026-09-18\"},{\"intensity\":\"低\",\"duration\":\"-\",\"content\":\"休息或轻柔步行\",\"goal\":\"促进恢复\",\"notes\":\"避免剧烈运动\",\"date\":\"2026-09-19\"}],\"chartItems\":null,\"citations\":null},{\"type\":\"heading\",\"text\":\"一周康复训练计划\",\"title\":null,\"collapsed\":null,\"columns\":null,\"rows\":null,\"chartItems\":null,\"citations\":null},{\"type\":\"chart\",\"text\":null,\"title\":\"一周康复训练强度分布\",\"collapsed\":null,\"columns\":null,\"rows\":null,\"chartItems\":[{\"day\":\"周日\",\"name\":\"腿部左右摆荡\",\"intensity\":\"中等\",\"minutes\":15},{\"day\":\"周一\",\"name\":\"臀桥\",\"intensity\":\"中等\",\"minutes\":20},{\"day\":\"周二\",\"name\":\"休息\",\"intensity\":\"轻度\",\"minutes\":0},{\"day\":\"周三\",\"name\":\"侧平板支撑\",\"intensity\":\"中等\",\"minutes\":15},{\"day\":\"周四\",\"name\":\"仰卧交替屈膝伸腿\",\"intensity\":\"中等\",\"minutes\":15},{\"day\":\"周五\",\"name\":\"腰椎松动术\",\"intensity\":\"轻度\",\"minutes\":10},{\"day\":\"周六\",\"name\":\"休息\",\"intensity\":\"轻度\",\"minutes\":0}],\"citations\":null}],\"isStreaming\":true},{\"role\":\"user\",\"content\":\"请基于我的个人信息，生成一周的个性化康复训练计划。\",\"blocks\":[],\"isStreaming\":false},{\"role\":\"ai\",\"content\":\"\",\"blocks\":[{\"type\":\"thinking\",\"text\":\"好的，用户是个 16 岁的男生，脊柱侧弯 C 弯 11.2 度，想通过运动康复。首先需要确认他的情况是否适合单纯运动干预。21.2 度属于中度，青少年仍处于生长期，及时干预效果通常较好，但要避免不当训练导致弯曲加重。\\n\\n康复应以矫正性姿势训练为主，结合针对 C 弯的专项练习。同时要提醒注意日常姿势调整，如正确坐姿、均衡背负书包等，这些细节虽常被忽略，却对维持脊柱平衡至关重要。\\n\\n从 C 弯的特点来看，胸椎和腰椎凸向相反，因此需要针对性强化凹侧肌群、放松凸侧。一周的训练安排要兼顾频率与恢复，每天可安排轻度姿势训练，而强度较高的矫正练习建议隔天进行。\",\"title\":\"完成思考\",\"collapsed\":true,\"columns\":null,\"rows\":null,\"chartItems\":null,\"citations\":null},{\"type\":\"paragraph\",\"text\":\"根据国际脊柱侧凸研究学会（SRS）标准，Cobb 角≥10° 即可诊断为青少年特发性脊柱侧凸（AIS）。你最近几次的初筛和 3D 筛查度数变化在 9 到 20 度之间，大概率有轻度侧弯的问题，此阶段是通过运动疗法干预的最佳窗口期，可有效延缓或阻止侧弯进展 [1]。\\n\\n针对 C 型单弯（单主弯）患者，运动计划应以模式特异性矫正为基础，结合个体曲线类型进行定制。以下为基于当前循证医学证据的一周运动计划框架，重点推荐腰椎松动疗法或臀桥，因其在改善 Cobb 角和躯干外观方面证据等级较高。\",\"title\":null,\"collapsed\":null,\"columns\":null,\"rows\":null,\"chartItems\":null,\"citations\":null},{\"type\":\"heading\",\"text\":\"专项脊柱侧弯康复训练计划\",\"title\":null,\"collapsed\":null,\"columns\":null,\"rows\":null,\"chartItems\":null,\"citations\":null},{\"type\":\"table\",\"text\":null,\"title\":null,\"collapsed\":null,\"columns\":[\"时间\",\"训练内容\",\"时长\",\"强度\",\"目标\",\"注意事项\"],\"rows\":[{\"intensity\":\"中等\",\"duration\":\"15 分钟\",\"content\":\"腿部左右摆荡\",\"goal\":\"改善骨盆与腰椎灵活性，平衡双侧肌力\",\"notes\":\"摆荡幅度两侧对称，动作缓慢，避免腰椎代偿\",\"date\":\"2026-09-13\"},{\"intensity\":\"中等\",\"duration\":\"20 分钟\",\"content\":\"臀桥\",\"goal\":\"增强骨盆稳定性，平衡腰椎肌力\",\"notes\":\"臀部收紧，避免腰椎过度伸展\",\"date\":\"2026-09-14\"},{\"intensity\":\"低\",\"duration\":\"50 分钟\",\"content\":\"休息或轻柔步行\",\"goal\":\"促进恢复\",\"notes\":\"避免剧烈运动\",\"date\":\"2026-09-15\"},{\"intensity\":\"中等\",\"duration\":\"15 分钟\",\"content\":\"侧平板支撑\",\"goal\":\"增强侧弯对侧肌肉耐力\",\"notes\":\"若为右侧弯，重点练左侧；保持身体成直线\",\"date\":\"2026-09-16\"},{\"intensity\":\"中等\",\"duration\":\"15 分钟\",\"content\":\"仰卧交替屈膝伸腿\",\"goal\":\"改善双下肢对称性与动态平衡\",\"notes\":\"保持躯干中立，避免向侧弯侧倾斜\",\"date\":\"2026-09-17\"},{\"intensity\":\"低\",\"duration\":\"10 分钟\",\"content\":\"腰椎松动术\",\"goal\":\"增强腰椎灵活性，辅助姿势矫正\",\"notes\":\"动作轻柔，避免暴力扭转\",\"date\":\"2026-09-18\"},{\"intensity\":\"低\",\"duration\":\"-\",\"content\":\"休息或轻柔步行\",\"goal\":\"促进恢复\",\"notes\":\"避免剧烈运动\",\"date\":\"2026-09-19\"}],\"chartItems\":null,\"citations\":null},{\"type\":\"heading\",\"text\":\"一周康复训练计划\",\"title\":null,\"collapsed\":null,\"columns\":null,\"rows\":null,\"chartItems\":null,\"citations\":null},{\"type\":\"chart\",\"text\":null,\"title\":\"一周康复训练强度分布\",\"collapsed\":null,\"columns\":null,\"rows\":null,\"chartItems\":[{\"day\":\"周日\",\"name\":\"腿部左右摆荡\",\"intensity\":\"中等\",\"minutes\":15},{\"day\":\"周一\",\"name\":\"臀桥\",\"intensity\":\"中等\",\"minutes\":20},{\"day\":\"周二\",\"name\":\"休息\",\"intensity\":\"轻度\",\"minutes\":0},{\"day\":\"周三\",\"name\":\"侧平板支撑\",\"intensity\":\"中等\",\"minutes\":15},{\"day\":\"周四\",\"name\":\"仰卧交替屈膝伸腿\",\"intensity\":\"中等\",\"minutes\":15},{\"day\":\"周五\",\"name\":\"腰椎松动术\",\"intensity\":\"轻度\",\"minutes\":10},{\"day\":\"周六\",\"name\":\"休息\",\"intensity\":\"轻度\",\"minutes\":0}],\"citations\":null},{\"type\":\"paragraph\",\"text\":\"关键建议：\\n\\n规范训练：研究表明，在姿势与动作方向正确、训练持续性良好的情况下，专项矫正训练可显著降低脊柱侧弯进展风险。训练过程中应注重动作精确性与呼吸节奏，避免随意发力或错误姿势导致代偿 [2]。\\n\\n结合螺旋成角呼吸：所有训练应配合三维呼吸训练，吸气时重点扩张侧弯凹侧胸廓，以辅助脊柱矫正 [3]。\\n\\n目前证据显示，臀桥和腰椎松动术在改善 Cobb 角方面效果最佳，腰椎松动疗法在网状 Meta 分析中排序最优 [3]。可进行个性化评估与训练指导，实现最佳康复效果。\",\"title\":null,\"collapsed\":null,\"columns\":null,\"rows\":null,\"chartItems\":null,\"citations\":null},{\"type\":\"citations\",\"text\":null,\"title\":\"全部引用\",\"collapsed\":true,\"columns\":null,\"rows\":null,\"chartItems\":null,\"citations\":[{\"index\":1,\"tag\":\"\",\"text\":\"用于青少年特发性脊柱侧凸保守治疗的理疗脊柱侧凸特定运动方法及其有效性：当前研究和实践的扩展文献综述\\nSeleviciene V, Cesnaviciute A, Strukcinskiene B et al.\\nInt J Environ Res Public Health. 2022 Jul 28;19 (15):9240.\"},{\"index\":2,\"tag\":\"系统综述\",\"text\":\"治疗性运动对青少年特发性脊柱侧凸进展的影响：系统评价的方案\\nAndrade RM, Callegari Ferreira ME, Piras L et al.\\nBMJ Open. 2024 Dec 5;14 (12):e083282.\"},{\"index\":3,\"tag\":\"Meta-Analysis\",\"text\":\"不同康复运动训练对青少年特发性脊柱侧凸患者干预效果的网状 Meta 分析\\n黄静\\n中华现代护理杂志. 2025;31 (04):470-477.\"}]}],\"isStreaming\":false}]', 1789294384227, 1789306003146);
INSERT INTO `ai_chat_sessions` VALUES (2, '1789294384227_950665', 'a', '1', '[{\"role\":\"user\",\"content\":\"1\",\"blocks\":[],\"isStreaming\":false},{\"role\":\"ai\",\"content\":\"\",\"blocks\":[],\"isStreaming\":true}]', 1789294384227, 1789294384232);

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
-- Records of community_post_images
-- ----------------------------
INSERT INTO `community_post_images` VALUES (1, 'assets/images/hip-bridge-1.png', 0);
INSERT INTO `community_post_images` VALUES (2, 'assets/images/side-plank-support.png', 0);
INSERT INTO `community_post_images` VALUES (2, 'assets/images/balance-training.png', 1);
INSERT INTO `community_post_images` VALUES (3, 'assets/images/jinggangshan.png', 0);

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
-- Records of community_post_like_users
-- ----------------------------
INSERT INTO `community_post_like_users` VALUES (1, '小恐龙', 0);
INSERT INTO `community_post_like_users` VALUES (1, '运动女孩', 1);
INSERT INTO `community_post_like_users` VALUES (1, '健康生活', 2);
INSERT INTO `community_post_like_users` VALUES (2, '运动达人', 0);
INSERT INTO `community_post_like_users` VALUES (2, '健康女孩', 1);
INSERT INTO `community_post_like_users` VALUES (3, '小恐龙', 0);
INSERT INTO `community_post_like_users` VALUES (3, '健身小达人', 1);
INSERT INTO `community_post_like_users` VALUES (3, '运动女孩', 2);
INSERT INTO `community_post_like_users` VALUES (3, '跑步小子', 3);

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
-- Records of community_posts
-- ----------------------------
INSERT INTO `community_posts` VALUES (1, '健身小达人', 'assets/images/user-avatar-2.jpg', '今天完成了30分钟的臀桥训练，感觉核心力量提升了很多！大家也要坚持运动哦~ 💪', '5分钟前', 1, 24, 8, 1, 1788009572919);
INSERT INTO `community_posts` VALUES (2, '瑜伽小仙女', 'assets/images/user-avatar-3.png', '晨练瑜伽结束！今天的拉伸让身体特别舒服，推荐给大家这组动作~ ✨', '1小时前', 0, 18, 5, 0, 1788006272919);
INSERT INTO `community_posts` VALUES (3, '跑步爱好者', 'assets/images/user-avatar-4.jpg', '完成今天的5公里跑步！天气很好，心情也很棒~ 🌞', '2小时前', 0, 32, 12, 1, 1788002672919);

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
-- Records of motion_records
-- ----------------------------
INSERT INTO `motion_records` VALUES (1, 'a', '臀桥训练', 4, 10, 3, 0, 1788082857551);
INSERT INTO `motion_records` VALUES (2, 'a', '臀桥训练', 10, 10, 8, 0, 1789294331450);
INSERT INTO `motion_records` VALUES (3, 'a', '臀桥训练', 10, 10, 25, 0, 1789303008138);
INSERT INTO `motion_records` VALUES (4, 'a', '臀桥训练', 10, 10, 17, 0, 1789307420859);
INSERT INTO `motion_records` VALUES (5, 'a', '臀桥训练', 9, 10, 3, 0, 1789345631121);
INSERT INTO `motion_records` VALUES (6, 'a', '臀桥训练', 11, 10, 2, 0, 1789346309742);
INSERT INTO `motion_records` VALUES (7, 'a', '臀桥训练', 10, 10, 23, 0, 1789348955927);
INSERT INTO `motion_records` VALUES (8, 'a', '臀桥训练', 10, 10, 23, 0, 1789352675220);
INSERT INTO `motion_records` VALUES (9, 'a', '臀桥训练', 0, 10, 43, 0, 1789369805370);
INSERT INTO `motion_records` VALUES (10, 'a', '臀桥训练', 9, 10, 42, 0, 1789369871783);
INSERT INTO `motion_records` VALUES (11, 'a', '臀桥训练', 0, 10, 60, 0, 1789369966104);
INSERT INTO `motion_records` VALUES (12, 'a', '臀桥训练', 7, 10, 7, 0, 1789370569468);
INSERT INTO `motion_records` VALUES (13, 'a', '臀桥训练', 0, 10, 20, 0, 1789370855989);
INSERT INTO `motion_records` VALUES (14, 'a', '臀桥训练', 5, 10, 4, 0, 1789372156729);
INSERT INTO `motion_records` VALUES (15, 'a', '臀桥训练', 11, 10, 3, 0, 1789372710005);
INSERT INTO `motion_records` VALUES (16, 'a', '臀桥训练', 10, 10, 23, 0, 1789372894006);

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
-- Records of posture_reports
-- ----------------------------
INSERT INTO `posture_reports` VALUES (1, 'b', 1, '正面朝向下腰', 90, 'Normal', 'Normal', 2, 2.5, 1.35, 5.6000000000000005, '分析结果显示：整体对称性良好，脊柱曲线形态正常。肩部倾斜约2.0°，骨盆倾斜约2.5°，躯干偏移约1.4%，Cobb 角约5.6°。', '/data/user/0/com.example.flutter_app/cache/CAP4466878683008921932.jpg', '/data/user/0/com.example.flutter_app/cache/CAP566954242464165541.jpg', 1788078894766);
INSERT INTO `posture_reports` VALUES (2, 'a', 1, '正面朝向下腰', 90, 'Normal', 'Normal', 2, 2.5, 1.35, 5.6000000000000005, '分析结果显示：整体对称性良好，脊柱曲线形态正常。肩部倾斜约2.0°，骨盆倾斜约2.5°，躯干偏移约1.4%，Cobb 角约5.6°。', '/data/user/0/com.example.flutter_app/cache/CAP3340931889914808783.jpg', '/data/user/0/com.example.flutter_app/cache/CAP1005958161517658155.jpg', 1789303226800);
INSERT INTO `posture_reports` VALUES (3, 'a', 1, '正面朝向下腰', 90, 'Normal', 'Normal', 2, 2.5, 1.35, 5.6000000000000005, '分析结果显示：整体对称性良好，脊柱曲线形态正常。肩部倾斜约2.0°，骨盆倾斜约2.5°，躯干偏移约1.4%，Cobb 角约5.6°。', '/data/user/0/com.example.flutter_app/cache/CAP3848792182333698070.jpg', '/data/user/0/com.example.flutter_app/cache/CAP4880453401089438752.jpg', 1789307652107);
INSERT INTO `posture_reports` VALUES (4, 'a', 1, '正面朝向下腰', 90, 'Normal', 'Normal', 2, 2.5, 1.35, 5.6000000000000005, '分析结果显示：整体对称性良好，脊柱曲线形态正常。肩部倾斜约2.0°，骨盆倾斜约2.5°，躯干偏移约1.4%，Cobb 角约5.6°。', '/data/user/0/com.example.flutter_app/cache/CAP2819418266401537952.jpg', '/data/user/0/com.example.flutter_app/cache/CAP8696448016727880251.jpg', 1789346280384);
INSERT INTO `posture_reports` VALUES (5, 'a', 1, '正面朝向下腰', 90, 'Normal', 'Normal', 2, 2.5, 1.35, 5.6000000000000005, '分析结果显示：整体对称性良好，脊柱曲线形态正常。肩部倾斜约2.0°，骨盆倾斜约2.5°，躯干偏移约1.4%，Cobb 角约5.6°。', '/data/user/0/com.example.flutter_app/cache/CAP290451109962844892.jpg', '/data/user/0/com.example.flutter_app/cache/CAP6030946800430065234.jpg', 1789349189596);
INSERT INTO `posture_reports` VALUES (6, 'a', 1, '正面朝向下腰', 90, 'Normal', 'Normal', 2, 2.5, 1.35, 5.6000000000000005, '分析结果显示：整体对称性良好，脊柱曲线形态正常。肩部倾斜约2.0°，骨盆倾斜约2.5°，躯干偏移约1.4%，Cobb 角约5.6°。', '/data/user/0/com.example.flutter_app/cache/CAP8535709798884739836.jpg', '/data/user/0/com.example.flutter_app/cache/CAP5625977139880671335.jpg', 1789352918391);
INSERT INTO `posture_reports` VALUES (7, 'a', 1, '正面朝向下腰', 90, 'Normal', 'Normal', 2, 2.5, 1.35, 5.6000000000000005, '分析结果显示：整体对称性良好，脊柱曲线形态正常。肩部倾斜约2.0°，骨盆倾斜约2.5°，躯干偏移约1.4%，Cobb 角约5.6°。', '/data/user/0/com.example.flutter_app/cache/CAP4862391039463469691.jpg', '/data/user/0/com.example.flutter_app/cache/CAP627752209286520067.jpg', 1789373133068);
INSERT INTO `posture_reports` VALUES (8, 'a', 1, '正面朝向下腰', 90, 'Normal', 'Normal', 2, 2.5, 1.35, 5.6000000000000005, '分析结果显示：整体对称性良好，脊柱曲线形态正常。肩部倾斜约2.0°，骨盆倾斜约2.5°，躯干偏移约1.4%，Cobb 角约5.6°。', '/data/user/0/com.example.flutter_app/cache/CAP6707585318808208278.jpg', '/data/user/0/com.example.flutter_app/cache/CAP3643845985284702597.jpg', 1789385925847);
INSERT INTO `posture_reports` VALUES (9, 'a', 1, '正面朝向下腰', 90, 'Normal', 'Normal', 2, 2.5, 1.35, 5.6000000000000005, '分析结果显示：整体对称性良好，脊柱曲线形态正常。肩部倾斜约2.0°，骨盆倾斜约2.5°，躯干偏移约1.4%，Cobb 角约5.6°。', '/data/user/0/com.example.flutter_app/cache/CAP6059220545072337061.jpg', '/data/user/0/com.example.flutter_app/cache/CAP6084750075191210052.jpg', 1789386318407);
INSERT INTO `posture_reports` VALUES (10, 'a', 1, '正面朝向下腰', 90, 'Normal', 'Normal', 2, 2.5, 1.35, 5.6000000000000005, '分析结果显示：整体对称性良好，脊柱曲线形态正常。肩部倾斜约2.0°，骨盆倾斜约2.5°，躯干偏移约1.4%，Cobb 角约5.6°。', '/data/user/0/com.example.flutter_app/cache/CAP7472927748581196746.jpg', '/data/user/0/com.example.flutter_app/cache/CAP8315802798372231092.jpg', 1789386518988);
INSERT INTO `posture_reports` VALUES (11, 'a', 1, '正面朝向下腰', 90, 'Normal', 'Normal', 2, 2.5, 1.35, 5.6000000000000005, '分析结果显示：整体对称性良好，脊柱曲线形态正常。肩部倾斜约2.0°，骨盆倾斜约2.5°，躯干偏移约1.4%，Cobb 角约5.6°。', '/data/user/0/com.example.flutter_app/cache/CAP6326924851033956963.jpg', '/data/user/0/com.example.flutter_app/cache/CAP7808221526982463213.jpg', 1789386814726);

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
-- Records of user_profile_archives
-- ----------------------------
INSERT INTO `user_profile_archives` VALUES (1, 'b1', '小明同学', 14, '男', '初二', '青少年特发性脊柱侧弯型', '侧弯型,久坐学习型,体像焦虑型', 1, 24, 6, '中', '中低', 68, 2, 62, '中', '中', '林同学为青少年特发性脊柱侧弯（胸弯18°/腰弯12°），目前处于康复第1阶段。结合近4次评估，主弯Cobb角呈缓慢下降趋势，训练方向正确。建议：以施罗斯姿势再教育 + 核心稳定训练为主，控制久坐时长，每45分钟起身活动；结合体像焦虑中低水平，宜采用鼓励式反馈与音乐跟练提升依从性。', 'v2.3', '[{\"icon\":\"book\",\"label\":\"知识库《青少年脊柱侧弯康复指南》\",\"isAI\":false},{\"icon\":\"ai\",\"label\":\"AI 模型分析 · 报告解读\",\"isAI\":true}]', '{\"summary\":\"胸弯18° · 腰弯12° · 高低肩/圆肩/驼背\",\"info\":[{\"label\":\"主诉\",\"value\":\"久坐肩颈酸、腰酸\"},{\"label\":\"节段\",\"value\":\"胸椎T6-T11 / 腰椎L1-L4\"},{\"label\":\"Cobb角\",\"value\":\"胸弯18° · 腰弯12°\"},{\"label\":\"Risser征\",\"value\":\"2级（骨骼成熟度中低）\"},{\"label\":\"ATR\",\"value\":\"7°（躯干旋转角）\"},{\"label\":\"体态\",\"value\":\"高低肩 · 圆肩 · 驼背\"}],\"cobbTrend\":{\"labels\":[\"3月\",\"5月\",\"7月\",\"9月\"],\"values\":[22,20,19,18]},\"cobbNote\":\"模型解读：4个月内主弯下降4°，平均每月约1°，属有效控制范围。\",\"sources\":[{\"icon\":\"hospital\",\"label\":\"医院影像报告 · OCR提取\",\"isAI\":false},{\"icon\":\"ai\",\"label\":\"AI 模型测量分析\",\"isAI\":true}]}', '{\"summary\":\"BMI 19.2 · 握力20kg · 平板支撑40s\",\"metrics\":[{\"label\":\"身高\",\"value\":\"158\",\"unit\":\"cm\",\"delta\":\"+1\",\"good\":true},{\"label\":\"体重\",\"value\":\"48\",\"unit\":\"kg\",\"delta\":\"-0.5\",\"good\":false},{\"label\":\"BMI\",\"value\":\"19.2\",\"unit\":\"\",\"good\":true},{\"label\":\"握力\",\"value\":\"20\",\"unit\":\"kg\",\"delta\":\"+2\",\"good\":true},{\"label\":\"平板支撑\",\"value\":\"40\",\"unit\":\"s\",\"delta\":\"+5\",\"good\":true},{\"label\":\"坐位体前屈\",\"value\":\"10\",\"unit\":\"cm\",\"delta\":\"-1\",\"good\":false},{\"label\":\"跳绳\",\"value\":\"130\",\"unit\":\"/min\",\"delta\":\"+6\",\"good\":true},{\"label\":\"50米跑\",\"value\":\"8.9\",\"unit\":\"s\",\"delta\":\"-0.2\",\"good\":true},{\"label\":\"立定跳远\",\"value\":\"165\",\"unit\":\"cm\",\"delta\":\"+3\",\"good\":true}],\"radar\":{\"labels\":[\"核心力量\",\"柔韧性\",\"心肺耐力\",\"下肢力量\",\"平衡稳定\"],\"values\":[62,55,58,65,60]},\"radarNote\":\"模型解读：柔韧性最弱（55），建议增加胸椎灵活性训练与腘绳肌拉伸。\",\"sources\":[{\"icon\":\"edit\",\"label\":\"体测录入 · 2026-09-08\",\"isAI\":false},{\"icon\":\"ai\",\"label\":\"AI 模型综合评估\",\"isAI\":true},{\"icon\":\"book\",\"label\":\"知识库·体测标准\",\"isAI\":false}]}', '{\"summary\":\"24周 · 每周3次 · 居家+门诊 · 短视频跟练\",\"info\":[{\"label\":\"目标\",\"value\":\"控制侧弯进展、改善体态\"},{\"label\":\"周期\",\"value\":\"24周\"},{\"label\":\"频次\",\"value\":\"每周3次\"},{\"label\":\"场景\",\"value\":\"居家 + 门诊\"},{\"label\":\"偏好\",\"value\":\"短视频跟练 · 音乐训练\"}],\"contraindicationTitle\":\"训练禁忌（知识库安全规则）\",\"contraindications\":[\"大重量负重\",\"不对称负重\",\"过度前屈\"],\"weeklyPlan\":[{\"weekday\":\"周三\",\"name\":\"施罗斯矫正操 · 短视频跟练\",\"meta\":\"20分钟 · 居家\"},{\"weekday\":\"周五\",\"name\":\"核心稳定训练（臀桥/平板）\",\"meta\":\"25分钟 · 居家\"},{\"weekday\":\"周六\",\"name\":\"门诊复查 + 姿势再教育\",\"meta\":\"40分钟 · 门诊\"}],\"planNote\":\"已按偏好开启「音乐训练」模式，训练BGM将自动匹配节奏。\",\"sources\":[{\"icon\":\"ai\",\"label\":\"AI 需求匹配引擎\",\"isAI\":true},{\"icon\":\"book\",\"label\":\"知识库·处方模板\",\"isAI\":false}]}', '{\"summary\":\"久坐学习型 · 体像焦虑 · 家长驱动+体育考试\",\"info\":[{\"label\":\"类型\",\"value\":\"侧弯型 + 久坐型 + 体像焦虑\"},{\"label\":\"心理\",\"value\":\"学业压力高 · 体像焦虑中\"},{\"label\":\"行为\",\"value\":\"平日依从性低 · 周末较好\"},{\"label\":\"动机\",\"value\":\"家长要求 + 体育考试 + 外观改善\"}],\"tags\":[\"#学业压力高\",\"#体像焦虑\",\"#久坐>8h\",\"#体育中考\",\"#家长督促\"],\"adherence\":{\"labels\":[\"一\",\"二\",\"三\",\"四\",\"五\",\"六\",\"日\"],\"values\":[40,30,50,20,35,90,85],\"target\":80,\"note\":\"模型建议：把主要训练安排到周末 + 周三短时段（10分钟微训练），符合课业节奏。\",\"sources\":[{\"icon\":\"ai\",\"label\":\"AI 行为模式分析\",\"isAI\":true}]},\"strategies\":[{\"iconKey\":\"smile\",\"title\":\"鼓励式反馈\",\"desc\":\"体像焦虑人群避免「弯度加重」等负面表述，多用进步对比（如Cobb角-4°）。\"},{\"iconKey\":\"family\",\"title\":\"家长协同\",\"desc\":\"每周向家长推送进步周报，强化「家长要求」这一核心动机。\"},{\"iconKey\":\"trophy\",\"title\":\"游戏化激励\",\"desc\":\"对接体育考试目标，用徽章与连击机制维持周末训练热度。\"}],\"sources\":[{\"icon\":\"ai\",\"label\":\"AI 用户画像模型\",\"isAI\":true},{\"icon\":\"assign\",\"label\":\"心理量表 · SAS/SAI\",\"isAI\":false}]}', 1789300000000, 1789389000000);

INSERT INTO `user_profile_archives` VALUES (2, 'a', '小晨同学', 9, '女', '三年级', '无脊柱侧弯（体态不良型）', '体态不良型,活泼开朗型,运动爱好型', 1, 12, 3, '低', '低', 86, 1, 78, '高', '低', '小晨同学为9岁三年级学生，2D居家初筛 Cobb 9.2°~9.4°、3D扫描 Cobb 9.3°，均低于10°诊断阈值，无脊柱侧弯；主要问题为头部前倾、轻度骨盆前倾与胸椎后凸，属体态不良范畴。建议以姿势再教育 + 核心稳定训练为主，无需侧弯专项干预；结合活泼开朗的行为特征，采用游戏化闯关与竞技类任务可显著提升训练参与度。', 'v2.3', '[{\"icon\":\"book\",\"label\":\"知识库《青少年体态矫正训练指导》\",\"isAI\":false},{\"icon\":\"ai\",\"label\":\"AI 模型分析 · 报告解读\",\"isAI\":true}]', '{\"summary\":\"Cobb 9.2°~9.4° · 无侧弯 · 头前倾/骨盆前倾\",\"info\":[{\"label\":\"主诉\",\"value\":\"久坐后颈肩紧张、腰背酸\"},{\"label\":\"2D居家初筛\",\"value\":\"Cobb 9.2°~9.4° · 肩倾斜2.0° · 骨盆倾斜2.5°\"},{\"label\":\"3D扫描\",\"value\":\"Cobb 9.3° · 无侧弯 · 躯干偏移1.4cm\"},{\"label\":\"体态\",\"value\":\"头前倾(轻度) · 圆肩8.2°(正常)\"},{\"label\":\"其他\",\"value\":\"胸椎后凸(轻度) · 肩部平衡标准 · 肩斜度轻度\"},{\"label\":\"ATR\",\"value\":\"3°（躯干旋转角，正常）\"}],\"cobbTrend\":{\"labels\":[\"3月\",\"5月\",\"7月\",\"9月\"],\"values\":[10.2,9.8,9.5,9.3]},\"cobbNote\":\"模型解读：近4次3D扫描 Cobb 角均在10°以下且平稳小幅下降，无侧弯进展风险，属正常波动范围。\",\"sources\":[{\"icon\":\"hospital\",\"label\":\"2D居家初筛报告 · 2026-09-14\",\"isAI\":false},{\"icon\":\"assign\",\"label\":\"3D脊柱扫描报告 · 2026-09-12\",\"isAI\":false},{\"icon\":\"ai\",\"label\":\"AI 模型测量分析\",\"isAI\":true}]}', '{\"summary\":\"BMI 20.4 · 握力38kg · 平板支撑72s\",\"metrics\":[{\"label\":\"身高\",\"value\":\"175\",\"unit\":\"cm\",\"delta\":\"+2\",\"good\":true},{\"label\":\"体重\",\"value\":\"62.5\",\"unit\":\"kg\",\"delta\":\"+1\",\"good\":true},{\"label\":\"BMI\",\"value\":\"20.4\",\"unit\":\"\",\"good\":true},{\"label\":\"握力\",\"value\":\"38\",\"unit\":\"kg\",\"delta\":\"+3\",\"good\":true},{\"label\":\"平板支撑\",\"value\":\"72\",\"unit\":\"s\",\"delta\":\"+8\",\"good\":true},{\"label\":\"坐位体前屈\",\"value\":\"14\",\"unit\":\"cm\",\"delta\":\"+2\",\"good\":true},{\"label\":\"跳绳\",\"value\":\"156\",\"unit\":\"/min\",\"delta\":\"+10\",\"good\":true},{\"label\":\"50米跑\",\"value\":\"7.4\",\"unit\":\"s\",\"delta\":\"-0.3\",\"good\":true},{\"label\":\"立定跳远\",\"value\":\"228\",\"unit\":\"cm\",\"delta\":\"+6\",\"good\":true}],\"radar\":{\"labels\":[\"核心力量\",\"柔韧性\",\"心肺耐力\",\"下肢力量\",\"平衡稳定\"],\"values\":[76,68,74,80,72]},\"radarNote\":\"模型解读：柔韧性相对最弱（68），建议训练后增加胸椎伸展与腘绳肌拉伸，配合改善头前倾与骨盆前倾。\",\"sources\":[{\"icon\":\"edit\",\"label\":\"体测录入 · 2026-09-12\",\"isAI\":false},{\"icon\":\"ai\",\"label\":\"AI 模型综合评估\",\"isAI\":true},{\"icon\":\"book\",\"label\":\"知识库·体测标准\",\"isAI\":false}]}', '{\"summary\":\"12周 · 每周4次 · 居家+校园 · 游戏化跟练\",\"info\":[{\"label\":\"目标\",\"value\":\"改善头前倾与骨盆前倾、强化核心稳定\"},{\"label\":\"周期\",\"value\":\"12周\"},{\"label\":\"频次\",\"value\":\"每周4次\"},{\"label\":\"场景\",\"value\":\"居家 + 校园课间\"},{\"label\":\"偏好\",\"value\":\"游戏化闯关 · 音乐训练 · 短视频跟练\"}],\"contraindicationTitle\":\"训练禁忌（知识库安全规则）\",\"contraindications\":[\"长时间低头练习\",\"大负荷负重\",\"训练中憋气发力\"],\"weeklyPlan\":[{\"weekday\":\"周二\",\"name\":\"收下巴颈深屈肌训练 · 短视频跟练\",\"meta\":\"15分钟 · 居家\"},{\"weekday\":\"周四\",\"name\":\"核心稳定训练（死虫式/平板）\",\"meta\":\"20分钟 · 居家\"},{\"weekday\":\"周六\",\"name\":\"体态闯关挑战（游戏化）\",\"meta\":\"25分钟 · 居家\"},{\"weekday\":\"周日\",\"name\":\"体态复评 + 校园活动\",\"meta\":\"30分钟 · 校园\"}],\"planNote\":\"已按偏好开启「游戏化闯关 + 音乐训练」模式，完成训练可获双倍积分。\",\"sources\":[{\"icon\":\"ai\",\"label\":\"AI 需求匹配引擎\",\"isAI\":true},{\"icon\":\"book\",\"label\":\"知识库·体态矫正处方\",\"isAI\":false}]}', '{\"summary\":\"活泼开朗型 · 运动爱好型 · 游戏驱动\",\"info\":[{\"label\":\"类型\",\"value\":\"体态不良型 + 活泼开朗型 + 运动爱好型\"},{\"label\":\"心理\",\"value\":\"学业压力中 · 自信开朗\"},{\"label\":\"行为\",\"value\":\"训练参与度高 · 偏好竞技类任务\"},{\"label\":\"动机\",\"value\":\"兴趣驱动 + 体育中考 + 游戏化奖励\"}],\"tags\":[\"#活泼开朗\",\"#运动爱好\",\"#游戏化激励\",\"#体育中考\",\"#同伴影响\"],\"adherence\":{\"labels\":[\"一\",\"二\",\"三\",\"四\",\"五\",\"六\",\"日\"],\"values\":[75,70,80,65,72,95,88],\"target\":80,\"note\":\"模型建议：周中安排竞技/挑战类短训练维持热度，周末侧重系统训练与复评。\",\"sources\":[{\"icon\":\"ai\",\"label\":\"AI 行为模式分析\",\"isAI\":true}]},\"strategies\":[{\"iconKey\":\"trophy\",\"title\":\"游戏化激励\",\"desc\":\"活泼型用户对竞赛与积分敏感，用闯关连击与徽章机制维持训练热度。\"},{\"iconKey\":\"smile\",\"title\":\"正向即时反馈\",\"desc\":\"即时肯定训练完成度，突出「Cobb角平稳」等积极信号，强化自信开朗特质。\"},{\"iconKey\":\"group\",\"title\":\"同伴协同\",\"desc\":\"支持与同学组队打卡，利用同伴影响提升周中训练完成率。\"}],\"sources\":[{\"icon\":\"ai\",\"label\":\"AI 用户画像模型\",\"isAI\":true},{\"icon\":\"assign\",\"label\":\"行为日志分析\",\"isAI\":false}]}', 1789300000000, 1789390000000);

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

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO `users` VALUES (1, 'admin', 'admin123', '系统管理员', 'assets/images/user-avatar-1.jpg', 1, 1788009823843, NULL);
INSERT INTO `users` VALUES (2, 'b', 'b', '演示账号', 'assets/images/user-avatar-1.jpg', 1, 1788009823843, NULL);
INSERT INTO `users` VALUES (3, 'demo', '123456', '体验用户', 'assets/images/user-avatar-1.jpg', 1, 1788009823843, NULL);
INSERT INTO `users` VALUES (4, 'a', 'a', NULL, 'assets/images/user-avatar-1.jpg', 1, 1788080917380, 1789388611985);
INSERT INTO `users` VALUES (5, 'b1', 'b1', '林同学', 'assets/images/user-avatar-1.jpg', 1, 1789300000000, 1789389000000);

SET FOREIGN_KEY_CHECKS = 1;
