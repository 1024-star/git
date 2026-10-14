import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../utils/app_logger.dart';

/// 用户个性化档案数据来源标注
class ProfileSource {
  const ProfileSource({required this.icon, required this.label, this.isAI = false});

  /// 图标标识：hospital/edit/assign/book/ai（前端映射为矢量图标）
  final String icon;
  final String label;
  final bool isAI;

  factory ProfileSource.fromJson(Map<String, dynamic> json) {
    return ProfileSource(
      icon: (json['icon'] as String?) ?? 'ai',
      label: (json['label'] as String?) ?? '',
      isAI: json['isAI'] == true,
    );
  }
}

/// 键值信息行（主诉/节段/Cobb角 等）
class ProfileKV {
  const ProfileKV({required this.label, required this.value});

  final String label;
  final String value;
}

/// 体测指标（含对比上次的涨跌）
class ProfileMetric {
  const ProfileMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.good,
    this.delta,
  });

  final String label;
  final String value;
  final String unit;
  final String? delta;
  final bool good;
}

/// 本周训练计划项
class ProfilePlanItem {
  const ProfilePlanItem({required this.weekday, required this.name, required this.meta});

  final String weekday;
  final String name;
  final String meta;
}

/// 沟通激励策略项
class ProfileStrategy {
  const ProfileStrategy({required this.iconKey, required this.title, required this.desc});

  /// 图标标识：smile/family/trophy（前端映射为矢量图标）
  final String iconKey;
  final String title;
  final String desc;
}

/// 用户个性化档案聚合模型（头信息 + 四大板块）
class UserProfileArchive {
  const UserProfileArchive({
    required this.nickname,
    required this.age,
    required this.gender,
    required this.grade,
    required this.diagnosis,
    required this.typeTags,
    required this.stageIndex,
    required this.totalWeeks,
    required this.currentWeek,
    required this.progressionRisk,
    required this.anxietyLevel,
    required this.spineScore,
    required this.painScore,
    required this.fitnessScore,
    required this.adherenceLevel,
    required this.churnRisk,
    required this.aiSummary,
    required this.aiVersion,
    required this.aiSources,
    required this.spineSummary,
    required this.spineInfo,
    required this.cobbLabels,
    required this.cobbValues,
    required this.cobbNote,
    required this.spineSources,
    required this.fitnessSummary,
    required this.metrics,
    required this.radarLabels,
    required this.radarValues,
    required this.radarNote,
    required this.fitnessSources,
    required this.rehabSummary,
    required this.rehabInfo,
    required this.contraindicationTitle,
    required this.contraindications,
    required this.weeklyPlan,
    required this.rehabNote,
    required this.rehabSources,
    required this.personaSummary,
    required this.personaInfo,
    required this.personaTags,
    required this.weekLabels,
    required this.weekAdherence,
    required this.adherenceTarget,
    required this.adherenceNote,
    required this.adherenceSources,
    required this.strategies,
    required this.personaSources,
  });

  // ---- 用户信息 ----
  final String nickname;
  final int age;
  final String gender;
  final String grade;
  final String diagnosis;
  final List<String> typeTags;
  final int stageIndex;
  final int totalWeeks;
  final int currentWeek;
  final String progressionRisk;
  final String anxietyLevel;
  final int spineScore;
  final int painScore;
  final int fitnessScore;
  final String adherenceLevel;
  final String churnRisk;

  // ---- AI 综合评估 ----
  final String aiSummary;
  final String aiVersion;
  final List<ProfileSource> aiSources;

  // ---- 脊柱状态 ----
  final String spineSummary;
  final List<ProfileKV> spineInfo;
  final List<String> cobbLabels;
  final List<double> cobbValues;
  final String cobbNote;
  final List<ProfileSource> spineSources;

  // ---- 体能情况 ----
  final String fitnessSummary;
  final List<ProfileMetric> metrics;
  final List<String> radarLabels;
  final List<double> radarValues;
  final String radarNote;
  final List<ProfileSource> fitnessSources;

  // ---- 康复需求 ----
  final String rehabSummary;
  final List<ProfileKV> rehabInfo;
  final String contraindicationTitle;
  final List<String> contraindications;
  final List<ProfilePlanItem> weeklyPlan;
  final String rehabNote;
  final List<ProfileSource> rehabSources;

  // ---- 用户画像 ----
  final String personaSummary;
  final List<ProfileKV> personaInfo;
  final List<String> personaTags;
  final List<String> weekLabels;
  final List<double> weekAdherence;
  final double adherenceTarget;
  final String adherenceNote;
  final List<ProfileSource> adherenceSources;
  final List<ProfileStrategy> strategies;
  final List<ProfileSource> personaSources;

  // ================= JSON 解析 =================

  factory UserProfileArchive.fromJson(Map<String, dynamic> json) {
    List<T> listOf<T>(Object? raw, T Function(Map<String, dynamic>) map) =>
        raw is List ? raw.whereType<Map>().map((e) => map(e.cast<String, dynamic>())).toList() : const [];

    List<String> stringList(Object? raw) =>
        raw is List ? raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList() : const [];

    List<double> doubleList(Object? raw) =>
        raw is List ? raw.map((e) => ((e as num?) ?? 0).toDouble()).toList() : const [];

    List<ProfileSource> sourceList(Object? raw) =>
        listOf(raw, ProfileSource.fromJson);

    List<ProfileKV> kvList(Object? raw) => listOf(
          raw,
          (m) => ProfileKV(label: (m['label'] as String?) ?? '', value: (m['value'] as String?) ?? ''),
        );

    // 各板块 JSON 对象（后端为结构化列 + 板块 JSON 列）
    final spine = (json['spine'] as Map?)?.cast<String, dynamic>() ?? const {};
    final fitness = (json['fitness'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rehab = (json['rehab'] as Map?)?.cast<String, dynamic>() ?? const {};
    final persona = (json['persona'] as Map?)?.cast<String, dynamic>() ?? const {};
    final trend = (spine['cobbTrend'] as Map?)?.cast<String, dynamic>() ?? const {};
    final radar = (fitness['radar'] as Map?)?.cast<String, dynamic>() ?? const {};
    final adherence = (persona['adherence'] as Map?)?.cast<String, dynamic>() ?? const {};

    return UserProfileArchive(
      nickname: (json['nickname'] as String?) ?? '',
      age: ((json['age'] as num?) ?? 0).toInt(),
      gender: (json['gender'] as String?) ?? '',
      grade: (json['grade'] as String?) ?? '',
      diagnosis: (json['diagnosis'] as String?) ?? '',
      typeTags: stringList(json['typeTags']),
      stageIndex: ((json['stageIndex'] as num?) ?? 1).toInt(),
      totalWeeks: ((json['totalWeeks'] as num?) ?? 24).toInt(),
      currentWeek: ((json['currentWeek'] as num?) ?? 0).toInt(),
      progressionRisk: (json['progressionRisk'] as String?) ?? '',
      anxietyLevel: (json['anxietyLevel'] as String?) ?? '',
      spineScore: ((json['spineScore'] as num?) ?? 0).toInt(),
      painScore: ((json['painScore'] as num?) ?? 0).toInt(),
      fitnessScore: ((json['fitnessScore'] as num?) ?? 0).toInt(),
      adherenceLevel: (json['adherenceLevel'] as String?) ?? '',
      churnRisk: (json['churnRisk'] as String?) ?? '',
      aiSummary: (json['aiSummary'] as String?) ?? '',
      aiVersion: (json['aiVersion'] as String?) ?? '',
      aiSources: sourceList(json['aiSources']),
      spineSummary: (spine['summary'] as String?) ?? '',
      spineInfo: kvList(spine['info']),
      cobbLabels: stringList(trend['labels']),
      cobbValues: doubleList(trend['values']),
      cobbNote: (spine['cobbNote'] as String?) ?? '',
      spineSources: sourceList(spine['sources']),
      fitnessSummary: (fitness['summary'] as String?) ?? '',
      metrics: listOf(
        fitness['metrics'],
        (m) => ProfileMetric(
              label: (m['label'] as String?) ?? '',
              value: (m['value'] as String?) ?? '',
              unit: (m['unit'] as String?) ?? '',
              good: m['good'] == true,
              delta: m['delta'] as String?,
            ),
      ),
      radarLabels: stringList(radar['labels']),
      radarValues: doubleList(radar['values']),
      radarNote: (fitness['radarNote'] as String?) ?? '',
      fitnessSources: sourceList(fitness['sources']),
      rehabSummary: (rehab['summary'] as String?) ?? '',
      rehabInfo: kvList(rehab['info']),
      contraindicationTitle: (rehab['contraindicationTitle'] as String?) ?? '训练禁忌',
      contraindications: stringList(rehab['contraindications']),
      weeklyPlan: listOf(
        rehab['weeklyPlan'],
        (m) => ProfilePlanItem(
              weekday: (m['weekday'] as String?) ?? '',
              name: (m['name'] as String?) ?? '',
              meta: (m['meta'] as String?) ?? '',
            ),
      ),
      rehabNote: (rehab['planNote'] as String?) ?? '',
      rehabSources: sourceList(rehab['sources']),
      personaSummary: (persona['summary'] as String?) ?? '',
      personaInfo: kvList(persona['info']),
      personaTags: stringList(persona['tags']),
      weekLabels: stringList(adherence['labels']),
      weekAdherence: doubleList(adherence['values']),
      adherenceTarget: ((adherence['target'] as num?) ?? 80).toDouble(),
      adherenceNote: (adherence['note'] as String?) ?? '',
      adherenceSources: sourceList(adherence['sources']),
      strategies: listOf(
        persona['strategies'],
        (m) => ProfileStrategy(
              iconKey: (m['iconKey'] as String?) ?? '',
              title: (m['title'] as String?) ?? '',
              desc: (m['desc'] as String?) ?? '',
            ),
      ),
      personaSources: sourceList(persona['sources']),
    );
  }

  // ================= 内置兜底数据（请求失败 / 无档案时使用，lzf 演示账号 · 小学三年级女性档案） =================

  factory UserProfileArchive.demo() {
    return UserProfileArchive(
      nickname: '小晨同学',
      age: 9,
      gender: '女',
      grade: '三年级',
      diagnosis: '青少年特发性脊柱侧弯型',
      typeTags: const ['侧弯型', '久坐学习型', '体像焦虑型'],
      stageIndex: 1,
      totalWeeks: 24,
      currentWeek: 6,
      progressionRisk: '中',
      anxietyLevel: '中低',
      spineScore: 68,
      painScore: 2,
      fitnessScore: 62,
      adherenceLevel: '中',
      churnRisk: '中',
      aiSummary: '小晨同学为青少年特发性脊柱侧弯（胸弯18°/腰弯12°），目前处于康复第1阶段。'
          '结合近4次评估，主弯Cobb角呈缓慢下降趋势，训练方向正确。'
          '建议：以施罗斯姿势再教育 + 核心稳定训练为主，控制久坐时长，每45分钟起身活动；'
          '结合体像焦虑中低水平，宜采用鼓励式反馈与音乐跟练提升依从性。',
      aiVersion: 'v2.3',
      aiSources: const [
        ProfileSource(icon: 'book', label: '知识库《青少年脊柱侧弯康复指南》'),
        ProfileSource(icon: 'ai', label: 'AI 模型分析 · 报告解读', isAI: true),
      ],
      spineSummary: '胸弯18° · 腰弯12° · 高低肩/圆肩/驼背',
      spineInfo: const [
        ProfileKV(label: '主诉', value: '久坐肩颈酸、腰酸'),
        ProfileKV(label: '节段', value: '胸椎T6-T11 / 腰椎L1-L4'),
        ProfileKV(label: 'Cobb角', value: '胸弯18° · 腰弯12°'),
        ProfileKV(label: 'Risser征', value: '0级（骨骼未成熟）'),
        ProfileKV(label: 'ATR', value: '7°（躯干旋转角）'),
        ProfileKV(label: '体态', value: '高低肩 · 圆肩 · 驼背'),
      ],
      cobbLabels: const ['3月', '5月', '7月', '9月'],
      cobbValues: const [22, 20, 19, 18],
      cobbNote: '模型解读：4个月内主弯下降4°，平均每月约1°，属有效控制范围。',
      spineSources: const [
        ProfileSource(icon: 'hospital', label: '医院影像报告 · OCR提取'),
        ProfileSource(icon: 'ai', label: 'AI 模型测量分析', isAI: true),
      ],
      fitnessSummary: 'BMI 16.2 · 握力12kg · 平板支撑25s',
      metrics: const [
        ProfileMetric(label: '身高', value: '136', unit: 'cm', delta: '+3', good: true),
        ProfileMetric(label: '体重', value: '30', unit: 'kg', delta: '+0.5', good: true),
        ProfileMetric(label: 'BMI', value: '16.2', unit: '', good: true),
        ProfileMetric(label: '握力', value: '12', unit: 'kg', delta: '+1', good: true),
        ProfileMetric(label: '平板支撑', value: '25', unit: 's', delta: '+5', good: true),
        ProfileMetric(label: '坐位体前屈', value: '8', unit: 'cm', delta: '-0.5', good: false),
        ProfileMetric(label: '跳绳', value: '105', unit: '/min', delta: '+8', good: true),
        ProfileMetric(label: '50米跑', value: '10.6', unit: 's', delta: '-0.3', good: true),
        ProfileMetric(label: '立定跳远', value: '138', unit: 'cm', delta: '+4', good: true),
      ],
      radarLabels: const ['核心力量', '柔韧性', '心肺耐力', '下肢力量', '平衡稳定'],
      radarValues: const [62, 55, 58, 65, 60],
      radarNote: '模型解读：柔韧性最弱（55），建议增加胸椎灵活性训练与腘绳肌拉伸。',
      fitnessSources: const [
        ProfileSource(icon: 'edit', label: '体测录入 · 2026-09-08'),
        ProfileSource(icon: 'ai', label: 'AI 模型综合评估', isAI: true),
        ProfileSource(icon: 'book', label: '知识库·体测标准'),
      ],
      rehabSummary: '24周 · 每周3次 · 居家+门诊 · 短视频跟练',
      rehabInfo: const [
        ProfileKV(label: '目标', value: '控制侧弯进展、改善体态'),
        ProfileKV(label: '周期', value: '24周'),
        ProfileKV(label: '频次', value: '每周3次'),
        ProfileKV(label: '场景', value: '居家 + 门诊'),
        ProfileKV(label: '偏好', value: '短视频跟练 · 音乐训练'),
      ],
      contraindicationTitle: '训练禁忌（知识库安全规则）',
      contraindications: const ['大重量负重', '不对称负重', '过度前屈'],
      weeklyPlan: const [
        ProfilePlanItem(weekday: '周三', name: '施罗斯矫正操 · 短视频跟练', meta: '20分钟 · 居家'),
        ProfilePlanItem(weekday: '周五', name: '核心稳定训练（臀桥/平板）', meta: '25分钟 · 居家'),
        ProfilePlanItem(weekday: '周六', name: '门诊复查 + 姿势再教育', meta: '40分钟 · 门诊'),
      ],
      rehabNote: '已按偏好开启「音乐训练」模式，训练BGM将自动匹配节奏。',
      rehabSources: const [
        ProfileSource(icon: 'ai', label: 'AI 需求匹配引擎', isAI: true),
        ProfileSource(icon: 'book', label: '知识库·处方模板'),
      ],
      personaSummary: '久坐学习型 · 体像焦虑 · 家长驱动',
      personaInfo: const [
        ProfileKV(label: '类型', value: '侧弯型 + 久坐型 + 体像焦虑'),
        ProfileKV(label: '心理', value: '学业压力高 · 体像焦虑中'),
        ProfileKV(label: '行为', value: '平日依从性低 · 周末较好'),
        ProfileKV(label: '动机', value: '家长要求  + 外观改善'),
      ],
      personaTags: const ['#学业压力高', '#体像焦虑', '#久坐>8h', '#体育中考', '#家长督促'],
      weekLabels: const ['一', '二', '三', '四', '五', '六', '日'],
      weekAdherence: const [40, 30, 50, 20, 35, 90, 85],
      adherenceTarget: 80,
      adherenceNote: '模型建议：把主要训练安排到周末 + 周三短时段（10分钟微训练），符合课业节奏。',
      adherenceSources: const [
        ProfileSource(icon: 'ai', label: 'AI 行为模式分析', isAI: true),
      ],
      strategies: const [
        ProfileStrategy(
          iconKey: 'smile',
          title: '鼓励式反馈',
          desc: '体像焦虑人群避免「弯度加重」等负面表述，多用进步对比（如Cobb角-4°）。',
        ),
        ProfileStrategy(
          iconKey: 'family',
          title: '家长协同',
          desc: '每周向家长推送进步周报，强化「家长要求」这一核心动机。',
        ),
        ProfileStrategy(
          iconKey: 'trophy',
          title: '游戏化激励',
          desc: '对接体育考试目标，用徽章与连击机制维持周末训练热度。',
        ),
      ],
      personaSources: const [
        ProfileSource(icon: 'ai', label: 'AI 用户画像模型', isAI: true),
        ProfileSource(icon: 'assign', label: '心理量表 · SAS/SAI'),
      ],
    );
  }
}

class UserProfileApiException implements Exception {
  UserProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 用户个性化档案 API 客户端（GET /api/profile/archive）
class UserProfileApiClient {
  UserProfileApiClient({
    http.Client? client,
    this.baseUrl = kApiBaseUrl,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// 拉取用户个性化档案；档案不存在（404）时抛 UserProfileApiException
  Future<UserProfileArchive> fetchArchive({required String username}) async {
    final uri = Uri.parse('$baseUrl/api/profile/archive').replace(
      queryParameters: {'username': username},
    );

    final http.Response resp;
    try {
      resp = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (e, st) {
      AppLogger.e('档案API', e, st);
      throw UserProfileApiException('网络请求失败');
    }

    final Object? decoded;
    try {
      final text = utf8.decode(resp.bodyBytes);
      decoded = text.trim().isEmpty ? null : jsonDecode(text);
    } catch (e, st) {
      AppLogger.e('档案API', e, st);
      throw UserProfileApiException('响应格式错误');
    }

    if (resp.statusCode != 200) {
      final message = decoded is Map ? (decoded['message'] as String?) : null;
      throw UserProfileApiException(message ?? '请求失败(${resp.statusCode})');
    }

    if (decoded is! Map) {
      throw UserProfileApiException('响应格式错误');
    }
    return UserProfileArchive.fromJson(decoded.cast<String, dynamic>());
  }
}
