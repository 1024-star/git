import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/app_logger.dart';
import '../../utils/user_scope.dart';
import 'user_profile_api_client.dart';

/// ============================================================
/// 用户个性化档案页
/// 位于「我的」模块下，展示：用户信息 / 脊柱状态 / 体能情况 / 康复需求 / 用户画像
/// 数据从后端 GET /api/profile/archive 获取（数据库 user_profile_archives 表）；
/// 请求失败或无档案时回退到内置兜底数据
/// ============================================================
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

/// 页面字号与圆角（青少年向，与「我的」页风格一致）
abstract final class _ProfileStyle {
  static const double radiusLg = 24;
  static const double radiusMd = 20;

  static const double navTitle = 20;
  static const double userName = 26;
  static const double sectionTitle = 21;
  static const double body = 17;
  static const double bodySm = 15;
  static const double caption = 13;

  /// 页头渐变：与「我的」页保持一致
  static const headerGradient = [
    Color(0xFFFF8FB1),
    Color(0xFFB794F6),
    Color(0xFF60A5FA),
  ];

  static const pageBg = Color(0xFFF3F0FF);
  static const cardBorder = Color(0xFFE9D5FF);

  /// 各板块主题色
  static const spineColor = Color(0xFF7C6BF0); // 脊柱 · 紫
  static const fitnessColor = Color(0xFF14B8A6); // 体能 · 青
  static const rehabColor = Color(0xFFF97316); // 康复 · 橙
  static const personaColor = Color(0xFFEC4899); // 画像 · 粉
  static const aiColor = Color(0xFF6366F1); // AI · 靛
}

/// 档案页签
enum _ProfileTab {
  overview('概览', Icons.dashboard_rounded),
  spine('脊柱', Icons.accessibility_new_rounded),
  fitness('体能', Icons.fitness_center_rounded),
  rehab('康复需求', Icons.healing_rounded),
  persona('用户画像', Icons.psychology_rounded);

  const _ProfileTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _UserProfilePageState extends State<UserProfilePage> {
  _ProfileTab _currentTab = _ProfileTab.overview;

  /// 档案数据：初始为内置兜底数据，加载成功后替换为后端数据
  UserProfileArchive _data = UserProfileArchive.demo();

  final UserProfileApiClient _apiClient = UserProfileApiClient();

  /// 分型标签配色与图标（按顺序循环取用）
  static const List<(Color, IconData)> _tagPalette = [
    (_ProfileStyle.spineColor, Icons.accessibility_new_rounded),
    (Color(0xFF3B82F6), Icons.menu_book_rounded),
    (_ProfileStyle.personaColor, Icons.favorite_rounded),
    (_ProfileStyle.fitnessColor, Icons.fitness_center_rounded),
    (_ProfileStyle.rehabColor, Icons.flag_rounded),
  ];

  /// 画像话题标签配色（背景，前景）
  static const List<(Color, Color)> _personaTagPalette = [
    (Color(0xFFFEF2F2), Color(0xFFEF4444)),
    (Color(0xFFFDF2F8), Color(0xFFEC4899)),
    (Color(0xFFEFF6FF), Color(0xFF3B82F6)),
    (Color(0xFFECFDF5), Color(0xFF10B981)),
    (Color(0xFFF8F7FF), Color(0xFF7C6BF0)),
  ];

  /// 激励策略行图标配色
  static const List<Color> _strategyColors = [
    _ProfileStyle.personaColor,
    Color(0xFF7C6BF0),
    Color(0xFFF59E0B),
  ];

  @override
  void initState() {
    super.initState();
    _loadArchive();
  }

  /// 从后端拉取当前用户档案（无档案/失败时保持兜底数据）
  Future<void> _loadArchive() async {
    final username = (UserScope.username ?? '').trim();
    if (username.isEmpty) return; // 未登录态：保持兜底数据

    try {
      final archive = await _apiClient.fetchArchive(username: username);
      if (!mounted) return;
      setState(() {
        _data = archive;
      });
    } catch (e) {
      // 404（该用户无档案）或网络失败：保持兜底数据
      AppLogger.i('档案页', '后端档案不可用，使用兜底数据（$e）');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileStyle.pageBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(context),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildTabBar(),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: _buildTabContent(_currentTab),
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimer(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 页头：导航栏 + 用户信息卡
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top + 4, 0, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _ProfileStyle.headerGradient,
        ),
      ),
      child: Column(
        children: [
          _buildNavBar(context),
          const SizedBox(height: 14),
          _buildUserCard(),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          const Expanded(
            child: Text(
              '用户个性化档案',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: _ProfileStyle.navTitle,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _NavPillButton(
            icon: Icons.edit_rounded,
            label: '编辑',
            onTap: () => _toast('编辑档案（占位）'),
          ),
          const SizedBox(width: 6),
          _NavPillButton(
            icon: Icons.ios_share_rounded,
            label: '分享',
            onTap: () => _toast('分享档案（占位）'),
          ),
        ],
      ),
    );
  }

  /// 用户信息卡（头像 + 基本信息 + 类型标签 + 康复阶段 + 风险 + 评分胶囊）
  Widget _buildUserCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ProfileStyle.radiusLg),
          border: Border.all(color: _ProfileStyle.cardBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C6BF0).withValues(alpha: 0.14),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 基本信息 ---
            Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _data.nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: _ProfileStyle.userName,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _MiniTag(text: '${_data.age}岁', bg: const Color(0xFFEFF6FF), fg: const Color(0xFF3B82F6)),
                          const SizedBox(width: 4),
                          _MiniTag(text: _data.gender, bg: const Color(0xFFFDF2F8), fg: const Color(0xFFEC4899)),
                          const SizedBox(width: 4),
                          _MiniTag(text: _data.grade, bg: const Color(0xFFECFDF5), fg: const Color(0xFF10B981)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 14, color: _ProfileStyle.aiColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'AI 智能诊断分型：${_data.diagnosis}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _ProfileStyle.aiColor,
                                fontSize: _ProfileStyle.bodySm,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // --- 用户分型标签（来自模型分析） ---
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _data.typeTags.length; i++)
                  _MiniTag(
                    text: _data.typeTags[i],
                    bg: _tagPalette[i % _tagPalette.length].$1.withValues(alpha: 0.12),
                    fg: _tagPalette[i % _tagPalette.length].$1,
                    icon: _tagPalette[i % _tagPalette.length].$2,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // --- 康复阶段进度 ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FF),
                borderRadius: BorderRadius.circular(_ProfileStyle.radiusMd),
                border: Border.all(color: _ProfileStyle.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded, size: 16, color: _ProfileStyle.rehabColor),
                      const SizedBox(width: 6),
                      Text(
                        '康复阶段：第${_data.stageIndex}阶段 / 全程${_data.totalWeeks}周',
                        style: TextStyle(
                          color: const Color(0xFF1F2937).withValues(alpha: 0.85),
                          fontSize: _ProfileStyle.bodySm,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '第${_data.currentWeek}周',
                        style: TextStyle(
                          color: _ProfileStyle.rehabColor,
                          fontSize: _ProfileStyle.bodySm,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Stack(
                        children: [
                          Container(color: const Color(0xFFFFE7D6)),
                          FractionallySizedBox(
                            widthFactor: (_data.totalWeeks <= 0
                                    ? 0.0
                                    : _data.currentWeek / _data.totalWeeks)
                                .clamp(0.0, 1.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFFFFB27C), _ProfileStyle.rehabColor]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // --- 风险提示 ---
            Row(
              children: [
                _RiskPill(
                  icon: Icons.warning_amber_rounded,
                  text: '侧弯进展风险：${_data.progressionRisk}',
                  fg: const Color(0xFFF59E0B),
                  bg: const Color(0xFFFFFBEB),
                ),
                const SizedBox(width: 8),
                _RiskPill(
                  icon: Icons.sentiment_neutral_rounded,
                  text: '焦虑水平：${_data.anxietyLevel}',
                  fg: const Color(0xFF10B981),
                  bg: const Color(0xFFECFDF5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // --- 综合评分胶囊 ---
            Row(
              children: [
                _ScoreChip(label: '脊柱', value: '${_data.spineScore}', color: _ProfileStyle.spineColor),
                const SizedBox(width: 6),
                _ScoreChip(label: '疼痛', value: '${_data.painScore}', color: const Color(0xFFEF4444)),
                const SizedBox(width: 6),
                _ScoreChip(label: '体能', value: '${_data.fitnessScore}', color: _ProfileStyle.fitnessColor),
                const SizedBox(width: 6),
                _ScoreChip(label: '依从性', value: _data.adherenceLevel, color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 6),
                _ScoreChip(label: '流失风险', value: _data.churnRisk, color: const Color(0xFF64748B)),
              ],
            ),
            const SizedBox(height: 10),
            // --- 数据来源标注 ---
            Row(
              children: [
                const Icon(
                  Icons.cloud_done_rounded,
                  size: 13,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 4),
                Text(
                  '云端档案 · 由 AI 模型与知识库分析生成',
                  style: TextStyle(
                    color: const Color(0xFF6B7280).withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 头像（演示用渐变占位）
  Widget _buildAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8FB1), Color(0xFFB794F6)],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF63B6).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _data.nickname.isEmpty ? '友' : _data.nickname.substring(0, 1),
        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
      ),
    );
  }

  // ============================================================
  // 页签栏
  // ============================================================

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _ProfileStyle.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C6BF0).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final tab in _ProfileTab.values)
              GestureDetector(
                onTap: () => setState(() => _currentTab = tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: _currentTab == tab ? _ProfileStyle.spineColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 15,
                        color: _currentTab == tab ? Colors.white : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: _currentTab == tab ? Colors.white : const Color(0xFF6B7280),
                          fontSize: _ProfileStyle.bodySm,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 页签内容
  // ============================================================

  Widget _buildTabContent(_ProfileTab tab) {
    switch (tab) {
      case _ProfileTab.overview:
        return _buildOverviewTab();
      case _ProfileTab.spine:
        return _buildSpineTab();
      case _ProfileTab.fitness:
        return _buildFitnessTab();
      case _ProfileTab.rehab:
        return _buildRehabTab();
      case _ProfileTab.persona:
        return _buildPersonaTab();
    }
  }

  // ---------------- 概览 ----------------

  Widget _buildOverviewTab() {
    return Column(
      key: const ValueKey(_ProfileTab.overview),
      children: [
        // --- AI 综合评估（模型生成） ---
        _AICard(
          title: 'AI 综合评估',
          summary: _data.aiSummary,
          version: _data.aiVersion,
          sources: _data.aiSources,
        ),
        const SizedBox(height: 14),
        // --- 四大板块速览 ---
        _OverviewNavCard(
          icon: Icons.accessibility_new_rounded,
          color: _ProfileStyle.spineColor,
          title: '脊柱状态',
          desc: _data.spineSummary,
          scoreText: '${_data.spineScore}分',
          tab: _ProfileTab.spine,
          onGo: _switchTab,
        ),
        const SizedBox(height: 10),
        _OverviewNavCard(
          icon: Icons.fitness_center_rounded,
          color: _ProfileStyle.fitnessColor,
          title: '体能情况',
          desc: _data.fitnessSummary,
          scoreText: '${_data.fitnessScore}分',
          tab: _ProfileTab.fitness,
          onGo: _switchTab,
        ),
        const SizedBox(height: 10),
        _OverviewNavCard(
          icon: Icons.healing_rounded,
          color: _ProfileStyle.rehabColor,
          title: '康复需求',
          desc: _data.rehabSummary,
          tab: _ProfileTab.rehab,
          onGo: _switchTab,
        ),
        const SizedBox(height: 10),
        _OverviewNavCard(
          icon: Icons.psychology_rounded,
          color: _ProfileStyle.personaColor,
          title: '用户画像',
          desc: _data.personaSummary,
          tab: _ProfileTab.persona,
          onGo: _switchTab,
        ),
      ],
    );
  }

  void _switchTab(_ProfileTab tab) => setState(() => _currentTab = tab);

  // ---------------- 来源标注辅助 ----------------

  /// ProfileSource.icon 标识 → 矢量图标
  IconData _sourceIconOf(String key) => switch (key) {
        'hospital' => Icons.medical_services_rounded,
        'edit' => Icons.edit_note_rounded,
        'assign' => Icons.assignment_rounded,
        'book' => Icons.menu_book_rounded,
        'ai' => Icons.auto_awesome_rounded,
        _ => Icons.verified_rounded,
      };

  /// ProfileStrategy.iconKey 标识 → 矢量图标
  IconData _strategyIconOf(String key) => switch (key) {
        'smile' => Icons.emoji_emotions_rounded,
        'family' => Icons.family_restroom_rounded,
        'trophy' => Icons.emoji_events_rounded,
        'group' => Icons.groups_rounded,
        _ => Icons.volunteer_activism_rounded,
      };

  /// 来源标注列表 → 卡片来源胶囊
  List<_SourceChip> _sourceChips(List<ProfileSource> sources) => [
        for (final s in sources)
          _SourceChip(icon: _sourceIconOf(s.icon), label: s.label, isAI: s.isAI),
      ];

  // ---------------- 脊柱状态 ----------------

  Widget _buildSpineTab() {
    return Column(
      key: const ValueKey(_ProfileTab.spine),
      children: [
        _SectionCard(
          accent: _ProfileStyle.spineColor,
          icon: Icons.accessibility_new_rounded,
          title: '脊柱状态',
          sourceChips: _sourceChips(_data.spineSources),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final kv in _data.spineInfo) _KVRow(label: kv.label, value: kv.value),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _GhostButton(
                      icon: Icons.image_rounded,
                      label: '查看影像',
                      color: _ProfileStyle.spineColor,
                      onTap: () => _toast('查看影像（占位）'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GhostButton(
                      icon: Icons.assignment_rounded,
                      label: '查看量表',
                      color: _ProfileStyle.spineColor,
                      onTap: () => _toast('查看量表（占位）'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          accent: _ProfileStyle.spineColor,
          icon: Icons.trending_down_rounded,
          title: 'Cobb 角变化趋势',
          subtitle: '近${_data.cobbValues.length}次门诊评估 · 胸弯主弯',
          sourceChips: const [
            _SourceChip(icon: Icons.auto_awesome_rounded, label: 'AI 趋势预测：继续下降', isAI: true),
          ],
          child: Column(
            children: [
              SizedBox(
                height: 210,
                width: double.infinity,
                child: CustomPaint(
                  painter: _LineChartPainter(
                    values: _data.cobbValues,
                    labels: _data.cobbLabels,
                    lineColor: _ProfileStyle.spineColor,
                    unit: '°',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _ProfileStyle.spineColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insights_rounded, size: 16, color: _ProfileStyle.spineColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _data.cobbNote,
                        style: TextStyle(
                          color: const Color(0xFF1F2937).withValues(alpha: 0.8),
                          fontSize: _ProfileStyle.caption,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          accent: _ProfileStyle.spineColor,
          icon: Icons.straighten_rounded,
          title: '脊柱形态示意',
          subtitle: 'AI 姿态识别标注（T6-T11 / L1-L4）',
          sourceChips: const [
            _SourceChip(icon: Icons.auto_awesome_rounded, label: 'AI 姿态识别 · 2D keypoints', isAI: true),
          ],
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: _SpineCurvePainter(
                highlightColor: _ProfileStyle.spineColor,
                secondaryColor: const Color(0xFF3B82F6),
                // Cobb 标注取最近一次测量值（2D/3D 报告）
                cobbLabel: _data.cobbValues.isEmpty
                    ? 'Cobb --'
                    : 'Cobb ${_data.cobbValues.last.toStringAsFixed(1)}°',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- 体能情况 ----------------

  Widget _buildFitnessTab() {
    return Column(
      key: const ValueKey(_ProfileTab.fitness),
      children: [
        _SectionCard(
          accent: _ProfileStyle.fitnessColor,
          icon: Icons.monitor_heart_rounded,
          title: '体测数据',
          subtitle: '对比上次体测',
          sourceChips: _sourceChips(_data.fitnessSources),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final tileW = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final m in _data.metrics)
                    SizedBox(
                      width: tileW,
                      child: _FitnessTile(
                        label: m.label,
                        value: m.value,
                        unit: m.unit,
                        delta: m.delta,
                        good: m.good,
                        color: _ProfileStyle.fitnessColor,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          accent: _ProfileStyle.fitnessColor,
          icon: Icons.radar_rounded,
          title: '体能五维雷达',
          subtitle: '综合体能 ${_data.fitnessScore} 分 · 同龄参考',
          sourceChips: const [
            _SourceChip(icon: Icons.auto_awesome_rounded, label: 'AI 模型综合评估', isAI: true),
            _SourceChip(icon: Icons.menu_book_rounded, label: '知识库·体测标准'),
          ],
          child: Column(
            children: [
              SizedBox(
                height: 250,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RadarPainter(
                    labels: _data.radarLabels,
                    values: _data.radarValues,
                    color: _ProfileStyle.fitnessColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _ProfileStyle.fitnessColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates_rounded, size: 16, color: _ProfileStyle.fitnessColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _data.radarNote,
                        style: TextStyle(
                          color: const Color(0xFF1F2937).withValues(alpha: 0.8),
                          fontSize: _ProfileStyle.caption,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- 康复需求 ----------------

  Widget _buildRehabTab() {
    return Column(
      key: const ValueKey(_ProfileTab.rehab),
      children: [
        _SectionCard(
          accent: _ProfileStyle.rehabColor,
          icon: Icons.healing_rounded,
          title: '康复需求',
          sourceChips: _sourceChips(_data.rehabSources),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final kv in _data.rehabInfo)
                _KVRow(label: kv.label, value: kv.value, color: _ProfileStyle.rehabColor),
              const SizedBox(height: 12),
              // --- 训练禁忌（高亮） ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.block_rounded, size: 18, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _data.contraindicationTitle,
                            style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: _ProfileStyle.bodySm,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _data.contraindications.join(' · '),
                            style: TextStyle(
                              color: const Color(0xFFB91C1C).withValues(alpha: 0.85),
                              fontSize: _ProfileStyle.caption,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          accent: _ProfileStyle.rehabColor,
          icon: Icons.event_available_rounded,
          title: '本周训练安排',
          subtitle: 'AI 智能排课 · 结合课业与偏好',
          sourceChips: const [
            _SourceChip(icon: Icons.auto_awesome_rounded, label: 'AI 智能排课', isAI: true),
          ],
          child: Column(
            children: [
              for (final plan in _data.weeklyPlan)
                _PlanRow(weekday: plan.weekday, name: plan.name, meta: plan.meta),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _ProfileStyle.rehabColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.music_note_rounded, size: 16, color: _ProfileStyle.rehabColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _data.rehabNote,
                        style: TextStyle(
                          color: const Color(0xFF1F2937).withValues(alpha: 0.8),
                          fontSize: _ProfileStyle.caption,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- 用户画像 ----------------

  Widget _buildPersonaTab() {
    return Column(
      key: const ValueKey(_ProfileTab.persona),
      children: [
        _SectionCard(
          accent: _ProfileStyle.personaColor,
          icon: Icons.psychology_rounded,
          title: '用户画像',
          subtitle: '由 AI 模型基于行为与量表数据生成',
          sourceChips: _sourceChips(_data.personaSources),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final kv in _data.personaInfo)
                _KVRow(label: kv.label, value: kv.value, color: _ProfileStyle.personaColor),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < _data.personaTags.length; i++)
                    _MiniTag(
                      text: _data.personaTags[i],
                      bg: _personaTagPalette[i % _personaTagPalette.length].$1,
                      fg: _personaTagPalette[i % _personaTagPalette.length].$2,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          accent: _ProfileStyle.personaColor,
          icon: Icons.bar_chart_rounded,
          title: '本周训练依从性',
          subtitle: '周中低 · 周末高（工作日课业占用）',
          sourceChips: _sourceChips(_data.adherenceSources),
          child: Column(
            children: [
              SizedBox(
                height: 190,
                width: double.infinity,
                child: CustomPaint(
                  painter: _BarChartPainter(
                    labels: _data.weekLabels,
                    values: _data.weekAdherence,
                    barColor: _ProfileStyle.personaColor,
                    targetValue: _data.adherenceTarget,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _ProfileStyle.personaColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_rounded, size: 16, color: _ProfileStyle.personaColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _data.adherenceNote,
                        style: TextStyle(
                          color: const Color(0xFF1F2937).withValues(alpha: 0.8),
                          fontSize: _ProfileStyle.caption,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // --- 沟通与激励策略 ---
        _SectionCard(
          accent: _ProfileStyle.personaColor,
          icon: Icons.volunteer_activism_rounded,
          title: '沟通与激励策略',
          subtitle: 'AI 生成的个性化沟通建议',
          sourceChips: const [
            _SourceChip(icon: Icons.auto_awesome_rounded, label: 'AI 激励策略生成', isAI: true),
          ],
          child: Column(
            children: [
              for (var i = 0; i < _data.strategies.length; i++)
                _StrategyRow(
                  icon: _strategyIconOf(_data.strategies[i].iconKey),
                  color: _strategyColors[i % _strategyColors.length],
                  title: _data.strategies[i].title,
                  desc: _data.strategies[i].desc,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 底部说明
  // ============================================================

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(_ProfileStyle.radiusMd),
        border: Border.all(color: _ProfileStyle.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: _ProfileStyle.aiColor),
              const SizedBox(width: 6),
              Text(
                '数据来源说明',
                style: TextStyle(
                  color: _ProfileStyle.aiColor,
                  fontSize: _ProfileStyle.bodySm,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '本档案由 AI 模型基于知识库《青少年特发性脊柱侧弯康复指南》'
            '与您的测评数据（影像分析、体测录入、心理量表、训练记录）提取分析生成，'
            '仅供康复参考，不能替代专业医疗建议。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF6B7280).withValues(alpha: 0.9),
              fontSize: _ProfileStyle.caption,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

// ============================================================
// 通用小组件
// ============================================================

/// 导航栏胶囊按钮（编辑 / 分享）
class _NavPillButton extends StatelessWidget {
  const _NavPillButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

/// 迷你标签
class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text, required this.bg, required this.fg, this.icon});

  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

/// 风险胶囊
class _RiskPill extends StatelessWidget {
  const _RiskPill({required this.icon, required this.text, required this.fg, required this.bg});

  final IconData icon;
  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 评分胶囊（脊柱68 / 疼痛2 / 体能62 ...）
class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900, height: 1),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF6B7280).withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 板块卡片（含标题 + 数据来源标注 + 内容）
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.sourceChips = const [],
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<_SourceChip> sourceChips;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ProfileStyle.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: _ProfileStyle.sectionTitle,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            color: const Color(0xFF6B7280).withValues(alpha: 0.9),
                            fontSize: _ProfileStyle.caption,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // --- 数据来源标注（体现知识库 / 模型分析） ---
          if (sourceChips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: sourceChips,
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// 数据来源标注胶囊
class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.icon, required this.label, this.isAI = false});

  final IconData icon;
  final String label;

  /// 是否为 AI 模型来源（AI 来源使用靛蓝高亮）
  final bool isAI;

  @override
  Widget build(BuildContext context) {
    final color = isAI ? _ProfileStyle.aiColor : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// 键值信息行
class _KVRow extends StatelessWidget {
  const _KVRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFF64748B)).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color ?? const Color(0xFF475569),
                fontSize: _ProfileStyle.caption,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: _ProfileStyle.bodySm,
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 描边按钮（查看影像 / 查看量表）
class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: _ProfileStyle.bodySm, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

/// 体能指标卡片
class _FitnessTile extends StatelessWidget {
  const _FitnessTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.delta,
    required this.good,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final String? delta;

  /// 变化方向是否为「向好」
  final bool good;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF6B7280).withValues(alpha: 0.9),
              fontSize: _ProfileStyle.caption,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(color: const Color(0xFF1F2937), fontSize: 23, fontWeight: FontWeight.w900, height: 1),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: const Color(0xFF6B7280).withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: (good ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        good ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 10,
                        color: good ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        delta!,
                        style: TextStyle(
                          color: good ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 训练计划行
class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.weekday, required this.name, required this.meta});

  final String weekday;
  final String name;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _ProfileStyle.rehabColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _ProfileStyle.rehabColor.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: Text(
              weekday,
              style: const TextStyle(
                color: _ProfileStyle.rehabColor,
                fontSize: _ProfileStyle.bodySm,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: _ProfileStyle.bodySm,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: TextStyle(
                    color: const Color(0xFF6B7280).withValues(alpha: 0.9),
                    fontSize: _ProfileStyle.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

/// 激励策略行
class _StrategyRow extends StatelessWidget {
  const _StrategyRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: _ProfileStyle.bodySm,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    color: const Color(0xFF6B7280).withValues(alpha: 0.95),
                    fontSize: _ProfileStyle.caption,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// AI 综合评估卡（模型生成内容 + 来源标注）
class _AICard extends StatelessWidget {
  const _AICard({
    required this.title,
    required this.summary,
    required this.sources,
    this.version = '',
  });

  final String title;
  final String summary;
  final List<ProfileSource> sources;

  /// 模型版本号（空则不显示角标）
  final String version;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3F0FF), Color(0xFFF0F9FF)],
        ),
        borderRadius: BorderRadius.circular(_ProfileStyle.radiusLg),
        border: Border.all(color: _ProfileStyle.aiColor.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: _ProfileStyle.aiColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'AI 综合评估',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: _ProfileStyle.sectionTitle,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (version.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _ProfileStyle.aiColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '模型生成 · $version',
                    style: TextStyle(
                      color: _ProfileStyle.aiColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: _ProfileStyle.bodySm,
              fontWeight: FontWeight.w600,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in sources)
                _MiniTag(
                  text: s.label,
                  bg: Colors.white,
                  fg: _ProfileStyle.aiColor,
                  icon: Icons.verified_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 概览板块速览卡（点击切换到对应页签）
class _OverviewNavCard extends StatelessWidget {
  const _OverviewNavCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.tab,
    required this.onGo,
    this.scoreText,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final _ProfileTab tab;
  final ValueChanged<_ProfileTab> onGo;
  final String? scoreText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onGo(tab),
      borderRadius: BorderRadius.circular(_ProfileStyle.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ProfileStyle.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: _ProfileStyle.body,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (scoreText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            scoreText!,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF6B7280).withValues(alpha: 0.9),
                      fontSize: _ProfileStyle.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 自绘图表（项目无图表库依赖，与报告页保持一致用 CustomPainter）
// ============================================================

/// 折线图：Cobb 角趋势（含渐变填充、数据点标注、网格）
class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.labels,
    required this.lineColor,
    this.unit = '',
  });

  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0, right = 10.0, top = 20.0, bottom = 24.0;
    final chartW = size.width - left - right;
    final chartH = size.height - top - bottom;
    if (values.isEmpty || chartW <= 0 || chartH <= 0) return;

    final lo = (values.reduce(math.min) - 2).floorToDouble();
    final hi = (values.reduce(math.max) + 2).ceilToDouble();
    double x(int i) => left + chartW * i / (values.length - 1).clamp(1, 1 << 30);
    double y(double v) => top + chartH * (1 - (v - lo) / (hi - lo).clamp(0.001, 1 << 30));

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    final textStyle = TextStyle(
      color: const Color(0xFF9CA3AF).withValues(alpha: 0.9),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    );

    // 横向网格线与纵轴刻度
    for (var i = 0; i <= 2; i++) {
      final v = lo + (hi - lo) * i / 2;
      final yy = y(v);
      canvas.drawLine(Offset(left, yy), Offset(size.width - right, yy), gridPaint);
      TextPainter(
        text: TextSpan(text: v.toStringAsFixed(0), style: textStyle),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(2, yy - 6));
    }

    // 渐变填充
    final fillPath = Path()
      ..moveTo(x(0), y(values.first));
    for (var i = 1; i < values.length; i++) {
      fillPath.lineTo(x(i), y(values[i]));
    }
    fillPath
      ..lineTo(x(values.length - 1), size.height - bottom)
      ..lineTo(x(0), size.height - bottom)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.22),
            lineColor.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // 折线
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final linePath = Path()..moveTo(x(0), y(values.first));
    for (var i = 1; i < values.length; i++) {
      linePath.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(linePath, linePaint);

    // 数据点与数值标签
    for (var i = 0; i < values.length; i++) {
      final cx = x(i);
      final cy = y(values[i]);
      canvas.drawCircle(Offset(cx, cy), 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = lineColor);

      TextPainter(
        text: TextSpan(
          text: '${values[i].toStringAsFixed(0)}$unit',
          style: TextStyle(color: lineColor, fontSize: 12, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(cx - 9, cy - 20));

      TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(cx - 8, size.height - bottom + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.lineColor != lineColor;
}

/// 雷达图：体能五维（含网格、轴标签、数值填充）
class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.labels,
    required this.values,
    required this.color,
  });

  final List<String> labels;
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);
    final radius = math.min(size.width, size.height) / 2 - 34;
    final n = labels.length;
    if (n == 0 || radius <= 0) return;

    double axAngle(int i) => -math.pi / 2 + 2 * math.pi * i / n;
    Offset axPoint(int i, double frac) =>
        center + Offset(math.cos(axAngle(i)), math.sin(axAngle(i))) * radius * frac;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 网格多边形（25/50/75/100）
    for (final level in const [0.25, 0.5, 0.75, 1.0]) {
      final path = Path()
        ..moveTo(axPoint(0, level).dx, axPoint(0, level).dy);
      for (var i = 1; i < n; i++) {
        path.lineTo(axPoint(i, level).dx, axPoint(i, level).dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 轴线
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, axPoint(i, 1.0), gridPaint);
    }

    // 数据填充多边形
    final dataPath = Path()..moveTo(axPoint(0, values[0] / 100).dx, axPoint(0, values[0] / 100).dy);
    for (var i = 1; i < n; i++) {
      dataPath.lineTo(axPoint(i, values[i] / 100).dx, axPoint(i, values[i] / 100).dy);
    }
    dataPath.close();
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    // 数据点 + 数值
    for (var i = 0; i < n; i++) {
      final p = axPoint(i, values[i] / 100);
      canvas.drawCircle(p, 3.5, Paint()..color = color);

      // 数值标签
      TextPainter(
        text: TextSpan(
          text: values[i].toStringAsFixed(0),
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, p + const Offset(6, -14));

      // 轴标签
      final lp = axPoint(i, 1.22);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: const Color(0xFF6B7280).withValues(alpha: 0.95),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lp.dx - tp.width / 2, lp.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

/// 柱状图：本周训练依从性（含目标线）
class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.labels,
    required this.values,
    required this.barColor,
    required this.targetValue,
  });

  final List<String> labels;
  final List<double> values;
  final Color barColor;
  final double targetValue;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 26.0, right = 8.0, top = 12.0, bottom = 22.0;
    final chartW = size.width - left - right;
    final chartH = size.height - top - bottom;
    if (values.isEmpty || chartW <= 0 || chartH <= 0) return;

    const maxValue = 100.0;
    final slotW = chartW / values.length;
    final barW = slotW * 0.52;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    final textStyle = TextStyle(
      color: const Color(0xFF9CA3AF).withValues(alpha: 0.9),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    );

    // 横向网格
    for (var i = 0; i <= 2; i++) {
      final yy = top + chartH * i / 2;
      canvas.drawLine(Offset(left, yy), Offset(size.width - right, yy), gridPaint);
      TextPainter(
        text: TextSpan(
          text: (100 - 100 * i / 2).toStringAsFixed(0),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(2, yy - 6));
    }

    // 柱体（圆角 + 渐变，周末高亮）
    for (var i = 0; i < values.length; i++) {
      final v = values[i].clamp(0, maxValue);
      final barH = chartH * v / maxValue;
      final barLeft = left + slotW * i + (slotW - barW) / 2;
      final barTop = top + chartH - barH;
      final isWeekend = i >= 5;
      final rect = Rect.fromLTWH(barLeft, barTop, barW, barH);
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isWeekend
                ? [barColor, barColor.withValues(alpha: 0.55)]
                : [barColor.withValues(alpha: 0.45), barColor.withValues(alpha: 0.20)],
          ).createShader(rect),
      );

      // 数值
      TextPainter(
        text: TextSpan(
          text: v.toStringAsFixed(0),
          style: TextStyle(
            color: isWeekend ? barColor : const Color(0xFF9CA3AF),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(barLeft + barW / 2 - 6, barTop - 14));

      // 星期标签
      TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(left + slotW * i + slotW / 2 - 6, size.height - bottom + 6));
    }

    // 目标线（依从性目标 80%）
    final targetY = top + chartH * (1 - targetValue / maxValue);
    final dashPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.6)
      ..strokeWidth = 1.4;
    for (double dx = left; dx < size.width - right; dx += 8) {
      canvas.drawLine(Offset(dx, targetY), Offset(math.min(dx + 4, size.width - right), targetY), dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.barColor != barColor;
}

/// 脊柱形态示意图：S型曲线 + 椎体节段 + 高亮节段（T6-T11 / L1-L4）
class _SpineCurvePainter extends CustomPainter {
  _SpineCurvePainter({
    required this.highlightColor,
    required this.secondaryColor,
    this.cobbLabel = 'Cobb 18°',
  });

  final Color highlightColor;
  final Color secondaryColor;

  /// 侧弯角度标注（取自最近一次 2D/3D 报告）
  final String cobbLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final spineX = w * 0.36;

    // S 型曲线控制点
    final top = Offset(spineX, h * 0.08);
    final midT = Offset(spineX + w * 0.10, h * 0.30);
    final mid = Offset(spineX, h * 0.52);
    final midL = Offset(spineX - w * 0.06, h * 0.72);
    final bottom = Offset(spineX, h * 0.92);

    final curvePaint = Paint()
      ..color = const Color(0xFF9CA3AF).withValues(alpha: 0.55)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..cubicTo(midT.dx, midT.dy, mid.dx, mid.dy, mid.dx, mid.dy)
      ..cubicTo(mid.dx, mid.dy, midL.dx, midL.dy, bottom.dx, bottom.dy);
    canvas.drawPath(path, curvePaint);

    // 椎体刻度（横线）
    final tickPaint = Paint()
      ..color = const Color(0xFF9CA3AF).withValues(alpha: 0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const vertebraCount = 14;
    for (var i = 0; i <= vertebraCount; i++) {
      final t = i / vertebraCount;
      final evaluator = path.computeMetrics().first;
      final pos = evaluator.getTangentForOffset(evaluator.length * t)!.position;
      canvas.drawLine(
        Offset(pos.dx - 9, pos.dy),
        Offset(pos.dx + 9, pos.dy),
        tickPaint,
      );
    }

    // 高亮节段：T6-T11（上段，紫色）与 L1-L4（下段，蓝色）
    final metrics = path.computeMetrics().first;
    void drawSegment(double t0, double t1, Color color) {
      final seg = metrics.extractPath(metrics.length * t0, metrics.length * t1);
      canvas.drawPath(
        seg,
        Paint()
          ..color = color
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    drawSegment(0.18, 0.50, highlightColor);
    drawSegment(0.60, 0.84, secondaryColor);

    // 节段标注
    void label(String text, Offset anchor, Color color, {bool leftSide = false}) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          leftSide ? anchor.dx - tp.width - 14 : anchor.dx + 14,
          anchor.dy - tp.height / 2,
        ),
      );
    }

    label('胸椎 T6-T11', Offset(spineX + w * 0.06, h * 0.32), highlightColor);
    label('腰椎 L1-L4', Offset(spineX - w * 0.03, h * 0.72), secondaryColor, leftSide: true);

    // 侧弯标注（AI 测量）
    final aiTp = TextPainter(
      text: TextSpan(
        text: cobbLabel,
        style: TextStyle(color: highlightColor, fontSize: 11, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    aiTp.paint(canvas, Offset(w * 0.72, h * 0.24));
    canvas.drawLine(
      Offset(w * 0.72 - 4, h * 0.24 + 8),
      Offset(spineX + w * 0.10, h * 0.30),
      Paint()
        ..color = highlightColor.withValues(alpha: 0.5)
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _SpineCurvePainter oldDelegate) =>
      oldDelegate.highlightColor != highlightColor || oldDelegate.cobbLabel != cobbLabel;
}
