import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/app_logger.dart';
import '../../utils/user_scope.dart';
import '../posture/posture_api_client.dart';
import '../posture/spine_report_page.dart';
import 'spine_data_report_page.dart';

/// 检测报告中心：Tab 切换设计
/// - 左 Tab「2D报告」：脊柱检测实际存储记录（来自后端 posture_reports 表）
/// - 右 Tab「3D报告」：3D 报告（本地 mock 数据）
class ReportHistoryPage extends StatelessWidget {
  const ReportHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const textStrong = Color(0xFF0F172A);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF6FF),
        appBar: AppBar(
          title: const Text('检测报告'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: textStrong,
          bottom: TabBar(
            labelColor: textStrong,
            unselectedLabelColor: const Color(0xFF94A3B8),
            indicatorColor: const Color(0xFF6366F1),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(icon: Icon(Icons.bar_chart_rounded, size: 20), text: '2D报告'),
              Tab(icon: Icon(Icons.view_in_ar_rounded, size: 20), text: '3D报告'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TwoDReportsTab(),
            _ThreeDReportsTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 2D 报告：后端已存储的脊柱检测记录
// ============================================================
class _TwoDReportsTab extends StatefulWidget {
  const _TwoDReportsTab();

  @override
  State<_TwoDReportsTab> createState() => _TwoDReportsTabState();
}

class _TwoDReportsTabState extends State<_TwoDReportsTab> {
  late final PostureApiClient _api;
  List<PostureReport>? _reports;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = PostureApiClient();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final username = (UserScope.username ?? '').trim();
      final list = await _api.listReports(username: username);
      if (!mounted) return;
      setState(() {
        _reports = list;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.e('报告', e, st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openReport(PostureReport report) {
    final front = (report.frontImagePath ?? '').isNotEmpty
        ? report.frontImagePath!
        : report.sideImagePath ?? '';
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        // 2D 报告：用脊柱检测报告页展示存储的记录（含检测照片，不再调 API、不再重复上报）
        builder: (_) => SpineReportPage(
          imagePath: front,
          stepIndex: report.stepIndex ?? 0,
          stepName: report.stepName ?? '',
          frontImagePath: front,
          sideImagePath: (report.sideImagePath ?? '').isNotEmpty ? report.sideImagePath : null,
          storedReport: report,
        ),
      ),
    );
  }

  static String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }

  @override
  Widget build(BuildContext context) {
    const textStrong = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 44, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text('加载检测记录失败', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textStrong)),
              const SizedBox(height: 6),
              Text('请确认后端服务已启动', style: const TextStyle(fontSize: 13, color: textSoft)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _load,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final reports = _reports ?? const <PostureReport>[];

    if (reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner_rounded, size: 44, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              const Text('暂无检测记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textStrong)),
              const SizedBox(height: 6),
              const Text('完成一次脊柱检测后，记录会自动保存在这里',
                  style: TextStyle(fontSize: 13, color: textSoft)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _load,
                child: const Text('刷新'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          for (final r in reports) ...[
            _TwoDReportCard(report: r, onTap: () => _openReport(r)),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _TwoDReportCard extends StatelessWidget {
  const _TwoDReportCard({required this.report, required this.onTap});

  final PostureReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6366F1);
    const textStrong = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);

    // 演示随机数值：围绕基准小范围浮动（基准与 2D 详情页一致，差距不大），评分随 Cobb 角联动
    final rng = math.Random(report.generatedAtMs);
    final cobb = 8.0 + rng.nextDouble() * 1.6; // 8.0 ~ 9.6
    final shoulderTilt = 0.4 + rng.nextDouble() * 0.5; // 0.4 ~ 0.9
    final pelvicTilt = 2.0 + rng.nextDouble() * 0.9; // 2.0 ~ 2.9
    final score = 92 - ((cobb - 8.0) * 4.4).round(); // 85 ~ 92，随 Cobb 角联动
    final sevCN = _severityCN(report.severity);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _TwoDReportsTabState._formatDate(report.generatedAtMs),
                    style: const TextStyle(color: textSoft, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '脊柱检测报告',
                    style: const TextStyle(color: textStrong, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(report.stepName ?? '').isEmpty ? '完整检测' : report.stepName} · $sevCN',
                    style: const TextStyle(color: textSoft, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(color: textStrong, fontSize: 48, fontWeight: FontWeight.w900, height: 0.95),
                      ),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text('评分', style: TextStyle(color: textSoft, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetricLine(
                    label: 'Cobb角',
                    value: cobb.toStringAsFixed(1),
                    unit: '°',
                    accent: accent,
                  ),
                  const SizedBox(height: 10),
                  _MetricLine(
                    label: '肩部倾斜',
                    value: shoulderTilt.toStringAsFixed(1),
                    unit: 'cm',
                    accent: accent,
                  ),
                  const SizedBox(height: 10),
                  _MetricLine(
                    label: '骨盆倾斜',
                    value: pelvicTilt.toStringAsFixed(1),
                    unit: '°',
                    accent: accent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _severityCN(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('normal')) return '正常';
    if (s.contains('mild')) return '轻度';
    if (s.contains('moderate')) return '中度';
    if (s.contains('severe')) return '重度';
    return severity.isEmpty ? '未知' : severity;
  }
}

// ============================================================
// 3D 报告：原有 mock 报告列表
// ============================================================
class _ThreeDReportsTab extends StatelessWidget {
  const _ThreeDReportsTab();

  List<_ReportListItemData> _buildMockReports({int count = 8}) {
    final now = DateTime.now();
    final rng = math.Random(now.millisecondsSinceEpoch);

    String _two(int v) => v.toString().padLeft(2, '0');

    bool _isSameDay(DateTime date1, DateTime date2) {
      return date1.year == date2.year &&
          date1.month == date2.month &&
          date1.day == date2.day;
    }

    double _nextDouble(double min, double max) => min + rng.nextDouble() * (max - min);
    int _nextInt(int min, int maxInclusive) => min + rng.nextInt(maxInclusive - min + 1);

    double _clampDouble(double v, double min, double max) {
      if (v < min) return min;
      if (v > max) return max;
      return v;
    }

    double _lerp(double a, double b, double t) => a + (b - a) * t;

    String _riskText(int score) {
      if (score >= 92) return '低风险';
      if (score >= 85) return '中风险';
      return '需关注';
    }

    SpineReportData _makeReport(int score, double cobb, double shiftCm, double rotation, {String? curveTypeOverride}) {
      String headline;
      String subline;
      String recommendation;
      String primaryImpact = '';
      List<SpineReportIssue> issues;
      final curveType = curveTypeOverride ?? (cobb < 10 ? '无明显侧弯' : cobb < 20 ? 'C 型侧弯' : 'S 型侧弯');
      final scoliosisSeverity = cobb < 10 ? '正常' : cobb < 20 ? '轻度' : '中度';

      if (score >= 90) {
        headline = '整体状态很棒';
        subline = '继续保持：规律运动 + 端正姿势';
        primaryImpact = '风险较低';
        recommendation = '巩固核心稳定';
        issues = const [
          SpineReportIssue(label: '姿势习惯', level: '保持', color: Color(0xFF10B981)),
          SpineReportIssue(label: '书包负重', level: '注意', color: Color(0xFFF59E0B)),
        ];
      } else if (score >= 75) {
        headline = '整体状态良好';
        subline = '建议重点关注：久坐与含胸';
        primaryImpact = '颈肩紧张 / 腰背代偿';
        recommendation = '矫正姿态 + 核心稳定';
        issues = const [
          SpineReportIssue(label: '头部前倾', level: '轻度', color: Color(0xFF3B82F6)),
          SpineReportIssue(label: '圆肩', level: '关注', color: Color(0xFFF59E0B)),
        ];
      } else {
        headline = '需要多注意哦';
        subline = '建议跟着训练计划，逐步改善';
        primaryImpact = '体态偏移 / 肌力失衡';
        recommendation = '先做拉伸放松，再做力量激活';
        issues = const [
          SpineReportIssue(label: '含胸圆肩', level: '明显', color: Color(0xFFEF4444)),
          SpineReportIssue(label: '胸椎后凸', level: '可改善', color: Color(0xFFF59E0B)),
          SpineReportIssue(label: '头部前倾', level: '中度', color: Color(0xFF3B82F6)),
        ];
      }

      return SpineReportData(
        score: score.toString(),
        risk: _riskText(score),
        headline: headline,
        subline: subline,
        primaryImpact: primaryImpact,
        recommendation: recommendation,
        issues: issues,
        visualAssets: const [
          'assets/images/wwjceshen3D.png',
          'assets/images/3d.png',
          'assets/images/beibu.png',
        ],
        cobbAngle: cobb,
        curveType: curveType,
        scoliosisSeverity: scoliosisSeverity,
      );
    }

    final items = <_ReportListItemData>[];
    final usedDates = <DateTime>{};
    DateTime? firstReportDate;

    for (var i = 0; i < count; i++) {
      DateTime dt;
      int attempts = 0;

      if (i == 0) {
        // 最新一条：固定取当天日期
        dt = DateTime(
          now.year,
          now.month,
          now.day,
          _nextInt(0, 23),
          _nextInt(0, 59),
        );
        firstReportDate = dt;
        usedDates.add(dt);

        final score = 89;
        final cobb = 9.3;
        final shift = 1.4;
        final rotation = 5.6;

        items.add(
          _ReportListItemData(
            generatedAt: dt,
            score: score,
            cobbAngle: cobb,
            trunkShiftCm: shift,
            rotationDeg: rotation,
            data: _makeReport(score, cobb, shift, rotation, curveTypeOverride: '正常'),
          ),
        );
        continue;
      } else {
        do {
          final totalHoursAgo = _nextInt(2, 24 * 45);
          final daysAgo = totalHoursAgo ~/ 24;
          final hoursAgo = totalHoursAgo % 24;

          dt = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour - hoursAgo,
            now.minute - _nextInt(0, 59),
          ).subtract(Duration(days: daysAgo));

          attempts++;
          if (attempts > 100) {
            break;
          }
        } while (usedDates.contains(dt) ||
            (firstReportDate != null && _isSameDay(dt, firstReportDate!)));

        usedDates.add(dt);
      }

      final score = _nextInt(78, 98);
      final t = ((score - 78) / (98 - 78)).clamp(0.0, 1.0);

      final cobbBase = _lerp(18.5, 1.0, t);
      final shiftBase = _lerp(2.8, 0.1, t);
      final rotationBase = _lerp(8.8, 0.4, t);

      final cobb = _clampDouble(cobbBase + _nextDouble(-1.2, 1.2), 0.8, 20.0);
      final shift = _clampDouble(shiftBase + _nextDouble(-0.35, 0.35), 0.0, 3.5);
      final rotation = _clampDouble(rotationBase + _nextDouble(-0.9, 0.9), 0.0, 10.0);

      items.add(
        _ReportListItemData(
          generatedAt: dt,
          score: score,
          cobbAngle: cobb,
          trunkShiftCm: shift,
          rotationDeg: rotation,
          data: _makeReport(score, cobb, shift, rotation),
        ),
      );
    }
    items.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return items;
  }

  void _openReport(BuildContext context, _ReportListItemData item) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SpineDataReportPage(
          data: item.data,
          reportTimeText: item.timeText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFFEFF6FF);
    const bgMid = Color(0xFFFDF2F8);
    const bgBottom = Color(0xFFECFDF5);

    const card = Colors.white;
    const accent = Color(0xFF6366F1);
    const accentWarm = Color(0xFFF59E0B);
    const textStrong = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);

    final reports = _buildMockReports(count: 3);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bgTop,
            bgMid,
            bgBottom,
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          children: [
            for (final item in reports) ...[
              InkWell(
                onTap: () => _openReport(context, item),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.timeText,
                              style: const TextStyle(
                                color: textSoft,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '脊柱发育的评分',
                              style: TextStyle(
                                color: textStrong,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item.score.toString(),
                                  style: const TextStyle(
                                    color: textStrong,
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    height: 0.95,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: List.generate(
                                      5,
                                      (index) {
                                        final filled = index < item.stars;
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 2),
                                          child: Icon(
                                            Icons.star,
                                            size: 18,
                                            color: filled ? accentWarm : const Color(0xFFE2E8F0),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MetricLine(
                              label: '脊柱侧弯角（Cobb角）',
                              value: item.cobbAngle.toStringAsFixed(1),
                              unit: '°',
                              accent: accent,
                            ),
                            const SizedBox(height: 12),
                            _MetricLine(
                              label: '躯干偏移（cm）',
                              value: item.trunkShiftCm.toStringAsFixed(1),
                              unit: 'cm',
                              accent: accent,
                            ),
                            const SizedBox(height: 12),
                            _MetricLine(
                              label: '脊柱旋转度（°）',
                              value: item.rotationDeg.toStringAsFixed(1),
                              unit: '°',
                              accent: accent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportListItemData {
  const _ReportListItemData({
    required this.generatedAt,
    required this.score,
    required this.cobbAngle,
    required this.trunkShiftCm,
    required this.rotationDeg,
    required this.data,
  });

  final DateTime generatedAt;
  final int score;
  final double cobbAngle;
  final double trunkShiftCm;
  final double rotationDeg;
  final SpineReportData data;

  String get timeText {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${generatedAt.year}-${two(generatedAt.month)}-${two(generatedAt.day)}';
  }

  int get stars {
    if (score >= 92) return 5;
    if (score >= 86) return 4;
    if (score >= 78) return 3;
    if (score >= 70) return 2;
    return 1;
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value, required this.unit, required this.accent});

  final String label;
  final String value;
  final String unit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF334155),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 26,
          child: Text(
            unit,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
