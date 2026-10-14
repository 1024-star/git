import 'dart:io';

import 'package:flutter/material.dart';

import 'posture_assessment_models.dart';
import 'posture_api_client.dart';
import 'spine_report_page.dart';

class PostureAssessmentResultsPage extends StatefulWidget {
  const PostureAssessmentResultsPage({super.key, required this.photos});

  final List<CapturedAssessmentImage> photos;

  @override
  State<PostureAssessmentResultsPage> createState() => _PostureAssessmentResultsPageState();
}

class _PostureAssessmentResultsPageState extends State<PostureAssessmentResultsPage> {
  late final PostureApiClient _api;

  @override
  void initState() {
    super.initState();
    _api = PostureApiClient();
  }

  String _severityCN(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('normal')) return '正常';
    if (s.contains('mild')) return '轻度';
    if (s.contains('moderate')) return '中度';
    if (s.contains('severe')) return '重度';
    return severity.trim().isEmpty ? '未知' : severity;
  }

  Color _severityColor(String severityCN) {
    if (severityCN == '正常') return const Color(0xFF4CAF50);
    if (severityCN == '轻度') return const Color(0xFFF0B400);
    if (severityCN == '中度') return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _shortError(Object? e) {
    if (e == null) return '';
    var s = e.toString().trim();
    if (s.length > 80) s = s.substring(0, 80);
    return s;
  }

  Widget _buildAnalysisSummary(CapturedAssessmentImage p) {
    return FutureBuilder<PostureReport>(
      future: _api.fetchReport(stepIndex: p.stepIndex, stepName: p.stepName),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.only(top: 10),
            child: _SummaryHint(text: 'AI 分析中...'),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _SummaryHint(text: 'AI 分析失败：${_shortError(snapshot.error)}'),
          );
        }

        final r = snapshot.data;
        if (r == null) {
          return const Padding(
            padding: EdgeInsets.only(top: 10),
            child: _SummaryHint(text: '暂无分析数据'),
          );
        }

        final sevCN = _severityCN(r.severity);
        final sevColor = _severityColor(sevCN);

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _SummaryChip(label: '评分', value: '${r.score}', color: const Color(0xFF3B82F6)),
              _SummaryChip(label: '风险', value: sevCN, color: sevColor),
              _SummaryChip(label: '侧弯角度', value: '${r.cobbAngle.toStringAsFixed(1)}°', color: const Color(0xFF6D28D9)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('筛查结果'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.photos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final p = widget.photos[index];
          final photo1 = widget.photos
              .where((e) => e.stepIndex == 0)
              .map((e) => e.path)
              .firstWhere((path) => path.isNotEmpty, orElse: () => '');
          final photo2 = widget.photos
              .where((e) => e.stepIndex == 1)
              .map((e) => e.path)
              .firstWhere((path) => path.isNotEmpty, orElse: () => '');
          return InkWell(
            onTap: p.path.isEmpty
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SpineReportPage(
                          imagePath: p.path,
                          stepIndex: p.stepIndex,
                          stepName: p.stepName,
                          frontImagePath: photo1.isNotEmpty ? photo1 : p.path,
                          sideImagePath: photo2,
                        ),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      color: const Color(0xFFF3F4F6),
                      child: Text(
                        '${p.stepIndex + 1}. ${p.stepName}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: p.path.isEmpty
                          ? const SizedBox(height: 120, child: Center(child: Text('无照片')))
                          : Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 240),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 4 / 3,
                                    // 不再做水平镜像，缩略图方向与保存原图/报告页一致
                                    child: Image.file(
                                      File(p.path),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) {
                                        return const Center(child: Text('图片加载失败'));
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                      child: _buildAnalysisSummary(p),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SummaryHint extends StatelessWidget {
  const _SummaryHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F7), width: 1.1),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w700),
      ),
    );
  }
}
