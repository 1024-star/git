# 正脊行动（脊柱健康 App）项目文档

> 面向青少年脊柱侧弯的运动康复辅助应用：`脊柱检测`、`姿态矫正`、`AI 助教`、`社区` 四大功能，配合 `臀桥`、`猫式伸展` 等训练模块与闯关小游戏，帮助用户体态管理并生成体态诊断报告。

## ⚠️ 代码修改铁律（最高优先级，每次改代码前必读）

**本项目是演示项目，大量页面为静态页面、大量输出为固定内容（写死的演示数据/算法）。**

改代码时必须严格遵守以下原则：

1. **不越界、不"顺手优化"**：只修改用户明确要求的内容，严禁凭幻觉主动"修正"、重构、重命名或美化用户未提及的任何代码、页面、文案与逻辑。
2. **静态内容即契约**：写死的演示数据、固定输出、mock 逻辑是刻意为之的演示设计，**不是待修复的 bug**，不得擅自改为"真实实现"。
3. **最小改动原则**：改动范围收敛到用户指定的文件/函数/段落；牵一发动全身的连带修改，必须先向用户说明并确认。
4. **删除与移动需确认**：任何删除文件、删除代码块、移动/重命名文件的操作，未获用户明确同意一律不做（包括项目里的 `_old`、`copy` 等副本文件）。
5. **改前对照、改后自检**：动手前先读原代码确认现状；改完后核对"除用户要求的部分外，其余行为与原来完全一致"。

> 一句话：**严格按照用户的指令来，宁可少做，不可多做。**

## 1. 项目概览

| 项 | 说明 |
| --- | --- |
| 应用名 | 正脊行动（Flutter App） |
| 前端 | Flutter（Dart），目录 `flutter_app_android_source/` |
| 后端 | Spring Boot 4.0.2（Java 17），模块名 `app-spring`，目录 `app-spring/` |
| 数据库 | MySQL 8.0，库名 `zjxd_app`，端口 3306 |
| 后端端口 | 9900 |
| 目标平台 | Android（MuMu模拟器 / AVD 调试），锁竖屏 |

## 2. 目录结构

```
e:\zjxd\app\
├── app-spring/                     # Spring Boot 后端
│   ├── pom.xml                     # 依赖：JPA、MyBatis、Web、MySQL、Lombok
│   ├── startup.bat                 # 一键启动脚本
│   ├── sql/
│   │   ├── zjxd_app_schema.sql     # 表结构（DDL，唯一维护源）
│   │   └── zjxd_app数据.sql        # 数据
│   └── src/main/
│       ├── resources/
│       │   ├── application.properties   # 数据源、token、MyBatis、视频SFTP 配置
│       │   └── mapper/UserMapper.xml    # MyBatis 用户 SQL
│       └── java/com/example/app_spring/
│           ├── AppSpringApplication.java
│           ├── auth/               # 认证模块（MyBatis + HMAC token）
│           ├── ai/                 # AI 助教脚本（返回康复计划富文本块）
│           ├── posture/            # 体态算法报告 + 检测报告存储（posture_reports）
│           ├── community/          # 社区/动态（JPA）
│           ├── motion/             # 运动记录存储（motion_records）
│           ├── video/              # 训练视频上传（multipart 接收 + SFTP 转存）
│           └── config/CorsConfig.java
│
└── flutter_app_android_source/     # Flutter Android 前端
    ├── pubspec.yaml                # 依赖 + 资产目录声明
    └── lib/
        ├── main.dart               # 入口，主题，登录页
        ├── features/
        │   ├── auth/               # 登录/注册
        │   ├── home/               # 首页（Banner、功能宫格、训练瀑布流）
        │   ├── posture/            # 脊柱检测 / 拍测 / 报告
        │   ├── ai_assistant/       # AI 助教
        │   ├── community/          # 社区 + 朋友圈
        │   ├── training/           # 训练（臀桥 / 猫式伸展）
        │   ├── game/               # 闯关小游戏
        │   ├── report/             # 生成报告 / 报告码查询 / 报告主题
        │   ├── fun_correction/     # 趣味姿态矫正
        │   └── mine/               # 我的 / 运动记录
        └── utils/                  # 全局登录态、镜像相机预览等
```

## 3. 技术栈

### 后端（Spring Boot）
- **Spring Boot 4.0.2 + Java 17**
- 登录模块用 **MyBatis**（操作 `users` 表）；社区用 **Spring Data JPA**
- Lombok 注解 + Constructor 注入
- 无 Spring Security，token 校验在 `AuthService.me()` 中手动解析验证
- 表结构 `sql/zjxd_app_schema.sql` 统一维护，`spring.jpa.hibernate.ddl-auto=none`（禁自动建表）

### 前端（Flutter）
- **Dart SDK ^3.10.7**
- 关键依赖：`camera`、`audioplayers`、`video_player`、`http`、`flutter_soloud`、`shared_preferences`
- 无路由框架/状态管理库，采用 `Navigator.push` + 单例 `UserScope` 全局状态
- 底部导航：首页 / 闯关 / 检测报告编码 / 朋友圈 / 我的（`IndexedStack`）
- 资产：`assets/images/`（含 `aimage/`、`yundongdakazhaopan/` 等子目录）

## 4. 后端关键配置

`application.properties` 核心项：

```properties
server.port=9900
spring.datasource.url=jdbc:mysql://localhost:3306/zjxd_app?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
spring.datasource.username=root
spring.datasource.password=123456
spring.jpa.hibernate.ddl-auto=none

# token：签名密钥与有效期
app.auth.token-secret=zjxd-app-token-secret-please-change-me-2026
app.auth.token-ttl-hours=720        # 30 天，App 自动登录免密

mybatis.configuration.map-underscore-to-camel-case=true
mybatis.mapper-locations=classpath*:mapper/*.xml

# 视频上传（multipart 接收 + SFTP 转存远程服务器）
spring.servlet.multipart.max-file-size=1024MB
spring.servlet.multipart.max-request-size=1024MB
app.video.upload.sftp-host=10.196.101.54
app.video.upload.sftp-port=22
app.video.upload.sftp-user=yczxserver
app.video.upload.sftp-password=***
app.video.upload.remote-dir=/media/yczxserver/DC94EC1E94EBF942/wjf/data/task0
```

> ⚠️ **注意：数据库密码与 token 密钥均为硬编码明文**，入库密码也是明文。生产部署务必替换随机强密钥、改为加密存储。

## 5. 数据库表（`zjxd_app`）

### users（用户表，MyBatis 访问）
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | bigint PK AUTO_INCREMENT | 主键 |
| username | varchar(32) 唯一 | 登录账号（3-20 位字母/数字/下划线） |
| password | varchar(64) | 登录密码（**明文存储**） |
| nickname | varchar(32) 可空 | 昵称，为空回退显示用户名 |
| avatar | varchar(255) | 头像资源路径 |
| status | tinyint | 1=正常 0=禁用 |
| created_at_ms / last_login_at_ms | bigint | 毫秒时间戳 |

### community_posts（社区动态，JPA 访问）
| 字段 | 说明 |
| --- | --- |
| id | 主键 |
| user_name / user_avatar | 发布者 |
| content | 动态正文 |
| time_ago | 发布时间友好文本 |
| featured | 是否精选 |
| likes / comments | 点赞 / 评论数 |
| liked | 当前用户是否已点赞 |
| created_at_ms | 创建时间 |

关联表：
- `community_post_images`（post_id, image, sort_index）— 动态图片
- `community_post_like_users`（post_id, user_name, sort_index）— 点赞用户

### posture_reports（脊柱检测报告存储，JPA 访问）
| 字段 | 说明 |
| --- | --- |
| id | 主键 |
| username / step_index / step_name | 检测用户名、步骤索引（0=站立前屈 1=正面下腰）、步骤名 |
| score / severity / curve_shape | 评分 / 严重程度（Normal/Mild/Moderate/Severe） / 弯曲类型（Normal/C/S） |
| shoulder_tilt / pelvic_tilt / trunk_shift_percent / cobb_angle | 肩倾 / 骨盆倾 / 躯干偏移% / Cobb角 |
| summary | 检测总结 |
| front_image_path / side_image_path | 正面（背部）/侧面（下腰）检测照片路径 |
| created_at_ms | 检测时间 |

### motion_records（运动训练记录，JPA 访问）
| 字段 | 说明 |
| --- | --- |
| id | 主键 |
| username / motion_name | 训练用户名 / 训练名称 |
| actual_count / target_count | 完成次数 / 目标次数（定数模式） |
| actual_time_seconds | 训练时长秒（定时模式） |
| is_count_mode | 1=定数 0=定时 |
| created_at_ms | 训练完成时间 |

## 6. 后端 API

### 认证 `/api/auth`
| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | /register | 注册并直接返回登录态（201） |
| POST | /login | 登录，明文密码比对 |
| GET | /me | 用 `Authorization: Bearer <token>` 校验并返回用户，冷启动自动登录 |
| POST | /logout | 语义端点，客户端清本地凭证 |

token 为无状态 **HMAC-SHA256 签名** token：`base64url(payload) + "." + base64url(hmac)`
payload = `用户ID | 用户名 | 过期时间戳`（用户名已排除 `|` 分隔符冲突）。

### 社区 `/api/community`
| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | /posts | 动态列表（按时间倒序） |
| POST | /posts | 发动态（`X-User-Name`/`X-User-Avatar` 请求头传身份） |
| POST | /posts/{id}/like | 点赞/取消点赞切换 |

### 体态 `/api/posture`
| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | /report | 按 `stepIndex`/`stepName` 算法生成体态报告（分数、Cobb 角、严重级别、建议等） |
| POST | /save | 检测完成上报存储一条检测报告（含照片路径） |
| GET | /list?username= | 查询某用户的检测记录（最新在前，含照片路径） |

> 该接口为**演示算法**：根据检测步骤数推算肩/骨盆倾斜、Cobb 角等指标并分级，非真实影像测量。

### 运动记录 `/api/motion`
| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | /save?username= | 训练完成上报一条运动记录 |
| GET | /list?username= | 查询某用户的运动记录（最新在前） |

### 训练视频 `/api/video`
| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | /upload | multipart 接收训练视频（`file`+`username`），经 SFTP 转存到远程服务器，文件名固定为 `test.<原始扩展名>` 并覆盖服务器已有同名文件 |

### AI 助教 `/api/ai`
| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | /script | 返回一份结构化的脊柱侧弯康复计划（thinking / paragraph / heading / table / chart / citations 等富文本块，带延迟动画） |

> 演示内容要点：计划表格日期为**当天起算的最近 7 天**（`LocalDate.now()` 动态生成），第一天固定为「腿部左右摆荡」；引用脚注 `[1]`/`[2]`/`[3]` 按正文出现顺序与文献内容对齐（PSSE 综述 / 系统综述 / 网状 Meta 分析）。

## 7. 前端主要页面与流程

- **首页** `home/cartoon_fitness_home_page.dart`：Banner 自动轮播、四大功能宫格（脊柱检测→姿态评估、姿态矫正→趣味矫正、AI助教、社区）、精品训练瀑布流（臀桥/猫式伸展可用，其余锁定），右侧浮动 AI 球。
- **认证** `auth/login_page.dart`：登录/注册；`utils/user_scope.dart` 单例保存登录用户信息、token、demo 标记（demo 用户可解锁全部训练）。注册/登录用户名密码**不再有最小长度与字符集限制**（仅要求非空）。
- **体态** `posture/`：检测（正/侧面拍照）→ 结果页/动态脊柱报告，报告数据来自 `/api/posture/report`，检测完成后自动上报存储（含照片路径）到后端。
- **AI 助教** `ai_assistant/`：拉取 `/api/ai/script` 分块渲染 AI 康复计划。输出节奏由 `_speedFactor`（当前 2.8）统一控制，完整输出约 **35 秒**，调大更慢、调小更快。
- **训练** `training/hip_bridge` 与 `training/cat_stretch`：含引导、训练过程、结果页。臀桥训练结束后自动上报运动记录并存档视频（上传 `test.<扩展名>`）。
- **臀桥结算页** `hip_bridge_training_result_page.dart`：
  - 成绩 Hero 区：紫粉渐变横幅，环形**综合得分**（星级 40% + 目标完成度 60%）+ 星级 + 评语 + **目标达成进度条**；
  - 指标 2×2 网格：完成次数/训练时长、星级、评价、消耗热量(估)（约 10 千卡/分钟，不足 8 千卡按 8 千卡显示）；
  - 「本次运动分析」Tab：AI 流式输出五板块报告——规范性评分（含与结算页同口径的综合评分）、正向评价、训练亮点、改进建议、风险提示（红色风险行 + 绿色规避方案）。
- **闯关** `game/`：跳挑战、相机跳挑战（`camera` 插件）、准备/结果/分享页。遵义关卡根据账号区分——a 用户显示"腿部左右摆荡"(10 次)，b 用户显示"伸展运动"(20 次腿部左右伸展)且弹窗视频/播报用独立资源 `zunyi-b-digital-person.mp4`。
- **报告** `report/`：`ReportHistoryPage` 为 **Tab 切换设计**：
  - 左 Tab「2D报告」：真实存储的脊柱检测记录（来自后端 `/api/posture/list`），点进去用 `SpineReportPage` 展示检测照片+指标（含照片路径）。
  - 右 Tab「3D报告」：本地 mock 数据（最新一条固定取当天日期，评分 89 / Cobb 角 9.3° / 弯曲类型"正常"），点进去用 `SpineDataReportPage`。
  - 报告内部评分与外部列表一致（取真实 `report.score`）。
- **我的** `mine/`：页面含运动记录（改为读后端真实记录 `motion_records`）、退出登录按钮（二次确认后清空登录态跳回登录页）。
- **社区** `community/`：动态列表 + 发帖，`community_api_client.dart` 与后端交互；`moments_page.dart` 朋友圈。

## 8. 共享封装

- **API 客户端模式**：`auth_api_client.dart`、`posture_api_client.dart`、`ai_api_client.dart`、`community_api_client.dart`、`mine/motion_api_client.dart` 各自封装 baseUrl 与 `http` 请求、JSON 解码、错误信息提取。
- 默认 baseUrl 统一由 `lib/config/app_config.dart` 的 `kApiBaseUrl`（`http://10.0.2.2:9900`，AVD 别名）集中管理；所有 API 客户端（`auth`/`posture`/`ai`/`community`/`motion`/臀桥视频上传）均引用该常量。真实设备/非安卓模拟器调试时，**只需改这一处**为本机局域网 IP。请求需带超时，否则不可达地址会永久挂起。
- **Android 明文 HTTP**：Android 9+（API 28+）默认禁 `http://`，`AndroidManifest.xml` 需 `android:usesCleartextTraffic="true"`。

## 9. 启动与调试

### 后端
```bash
cd app-spring
./mvnw spring-boot:run        # 或双击 startup.bat
# 监听 0.0.0.0:9900
```

先导入 `sql/zjxd_app_schema.sql` 建库建表。

### 前端
```bash
cd flutter_app_android_source
flutter pub get
flutter run -d <设备ID>       # MuMu模拟器如 flutter run 127.0.0.1:16416
flutter analyze               # 只看 error 级；本项目长期有 200+ info/warning，属正常
```

修改 Dart 后热重启 `R` 即可，无需重编 APK。

### 常见踩坑（详见 `.workbuddy/memory/`）
- `10.0.2.2` 仅官方 AVD 识别，MuMu模拟器/真机不认 → 用 `ipconfig` 本机 IPv4（如 `192.168.111.84`）
- 相对 import 层级：`lib/features/<模块>/` 引用 `lib/config/` 需两级 `../../config/app_config.dart`
- 防火墙需放行 TCP 9900 入站，或 `adb reverse tcp:9900 tcp:9900`

## 10. 注意事项 / 技术债

- ⚠️ 用户密码明文存储、无加密，建议后续引入哈希（如 BCrypt）。
- ⚠️ token 密钥、数据库口令、**SFTP 密码**均硬编码在配置/代码中，生产需外置环境变量并做 SSH 主机指纹校验（当前用 `PromiscuousVerifier` 信任所有主机）。
- 视频上传后端统一命名 `test.<扩展名>` 并覆盖服务器同名文件（演示模式）；若需保留多份需改回唯一命名。
- 体态报告与 AI 计划为**写死的演示数据/算法**，未接真实 AI 或影像检测；脊柱检测照片存的是**设备本地路径**（未上传图片本身）。
- 首页文件存在旧副本与副本文件（`cartoon_fitness_home_page_old.dart`、`cartoon_fitness_home_page copy.dart`），部分与现行实现重复，可清理。
- 臀桥结算页改造后 `_BigCountMetric`、`_StarsRow`、`_ActionTile`、`_InfoDialog` 已无引用（analyzer 8 个 warning），确认后可清理。
- Import 相对路径、无路由统一管理，页面跳转分散在各页面的 `Navigator.push` 中。