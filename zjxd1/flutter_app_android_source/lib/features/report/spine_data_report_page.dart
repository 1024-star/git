import 'package:flutter/material.dart';

class SpineReportIssue {
  const SpineReportIssue({
    required this.label,
    required this.level,
    required this.color,
  });

  final String label;
  final String level;
  final Color color;
}

class SpineReportData {
  const SpineReportData({
    required this.score,
    required this.risk,
    required this.headline,
    required this.subline,
    required this.primaryImpact,
    required this.recommendation,
    required this.issues,
    required this.visualAssets,
    this.cobbAngle = 3.2,
    this.curveType = '无明显侧弯',
    this.scoliosisSeverity = '正常',
  });

  final String score;
  final String risk;
  final String headline;
  final String subline;
  final String primaryImpact;
  final String recommendation;
  final List<SpineReportIssue> issues;
  final List<String> visualAssets;
  final double cobbAngle;
  final String curveType;
  final String scoliosisSeverity;
}

class SpineDataReportView extends StatelessWidget {
  const SpineDataReportView({
    super.key,
    required this.data,
    this.reportTimeText,
    this.padding,
  });

  final SpineReportData data;
  final String? reportTimeText;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _HeroSummaryCard(
          score: data.score,
          risk: data.risk,
          headline: data.headline,
          subline: data.subline,
          reportTimeText: reportTimeText,
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '异常点汇总',
          description: '本次检测中发现的异常指标，建议重点关注并针对性改善。这些异常可能会影响您的日常生活和健康，请根据建议进行相应的训练和调整。',
          trailing: _Pill(text: '${data.issues.length}项', color: const Color(0xFF6B7280)),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final issue in data.issues)
                    _IssueChip(label: issue.label, level: issue.level, color: issue.color),
                ],
              ),
              const SizedBox(height: 12),
              _ScoliosisSummary(
                cobbAngle: data.cobbAngle,
                curveType: data.curveType,
                severity: data.scoliosisSeverity,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _DataRow(label: '主要影响', value: data.primaryImpact),
                    const SizedBox(height: 10),
                    _DataRow(label: '建议优先', value: data.recommendation),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '各项指标数值',
          description: '详细数值分析，帮助了解具体改善空间。',
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MetricItem(
                            label: 'Cobb角',
                            value: '${data.cobbAngle.toStringAsFixed(1)}°',
                            status: data.scoliosisSeverity,
                            statusColor: _scoliosisStatusColor(data.cobbAngle),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricItem(
                            label: '弯曲类型',
                            value: '标准',
                            status: '评估结果',
                            statusColor: _scoliosisStatusColor(data.cobbAngle),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricItem(
                            label: '侧弯程度',
                            value: '标准',
                            status: 'Cobb分级',
                            statusColor: _scoliosisStatusColor(data.cobbAngle),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricItem(
                            label: '头部前倾',
                            value: '轻度',
                            status: '轻度',
                            statusColor: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricItem(
                            label: '圆肩程度',
                            value: '8.2°',
                            status: '正常',
                            statusColor: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricItem(
                            label: '胸椎后凸',
                            value: '轻度',
                            status: '可改善',
                            statusColor: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricItem(
                            label: '骨盆前倾',
                            value: '正常',
                            status: '正常',
                            statusColor: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricItem(
                            label: '肩斜度',
                            value: '轻度',
                            status: '正常',
                            statusColor: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricItem(
                            label: '肩部平衡',
                            value: '标准',
                            status: '正常',
                            statusColor: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: const Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '指标以评估结果呈现，建议重点关注标注为“可改善”或“轻度”的项目并针对性训练',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF3B82F6),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '可视呈现',
          description: '左右滑动切换本次检测的多维可视化结果。',
          child: _VisualCarousel(assets: data.visualAssets),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '关键指标',
          description: '用于快速定位主要问题点。',
          child: Column(
            children: const [
              _ProgressMetricRow(
                label: '头部前倾',
                valueText: '轻度',
                value: 0.35,
                color: Color(0xFF3B82F6),
              ),
              SizedBox(height: 10),
              _ProgressMetricRow(
                label: '圆肩程度',
                valueText: '正常',
                value: 0.15,
                color: Color(0xFF10B981),
              ),
              SizedBox(height: 10),
              _ProgressMetricRow(
                label: '胸椎后凸',
                valueText: '可改善',
                value: 0.42,
                color: Color(0xFFF59E0B),
              ),
              SizedBox(height: 10),
              _ProgressMetricRow(
                label: '骨盆前倾',
                valueText: '轻度',
                value: 0.38,
                color: Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '改善建议',
          description: '用最少的动作，先把关键点纠正好。',
          trailing: _Pill(text: '今日', color: const Color(0xFF10B981)),
          child: Column(
            children: const [
              _BulletItem(
                title: '日常姿势',
                content: '屏幕抬高至视线水平，避免含胸低头；坐姿腰背贴靠。',
              ),
              SizedBox(height: 10),
              _BulletItem(
                title: '拉伸放松',
                content: '胸小肌、上斜方肌每日 2 次，每次 30-45 秒。',
              ),
              SizedBox(height: 10),
              _BulletItem(
                title: '力量激活',
                content: '下斜方肌、臀中肌与腹横肌优先激活，避免腰部代偿。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            foregroundColor: const Color(0xFF111827),
            textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            backgroundColor: Colors.white,
          ),
          child: const Text('下载数据数据报告'),
        ),
      ],
    );
  }
}

Color _scoliosisStatusColor(double cobbAngle) {
  if (cobbAngle < 10) return const Color(0xFF10B981);
  if (cobbAngle < 20) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

class _VisualCarousel extends StatefulWidget {
  const _VisualCarousel({required this.assets});

  final List<String> assets;

  @override
  State<_VisualCarousel> createState() => _VisualCarouselState();
}

class _VisualCarouselState extends State<_VisualCarousel> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assets = widget.assets;
    if (assets.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: const Color(0xFFF3F4F6),
            alignment: Alignment.center,
            child: Icon(Icons.image_outlined, size: 34, color: Colors.black.withValues(alpha: 0.35)),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: PageView.builder(
                controller: _controller,
                itemCount: assets.length,
                onPageChanged: (index) => setState(() => _current = index),
                itemBuilder: (context, index) {
                  return Image.asset(
                    assets[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, _, __) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined, size: 34, color: Colors.black.withValues(alpha: 0.35)),
                          const SizedBox(height: 10),
                          Text(
                            assets[index].split('/').last,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827).withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(assets.length, (index) {
            final active = index == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF6366F1) : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ScoliosisSummary extends StatelessWidget {
  const _ScoliosisSummary({
    required this.cobbAngle,
    required this.curveType,
    required this.severity,
  });

  final double cobbAngle;
  final String curveType;
  final String severity;

  @override
  Widget build(BuildContext context) {
    final color = _scoliosisStatusColor(cobbAngle);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '脊柱侧弯评估：Cobb角 ${cobbAngle.toStringAsFixed(1)}°，$curveType，侧弯程度为$severity。',
        style: TextStyle(
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827).withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class SpineDataReportPage extends StatelessWidget {
  const SpineDataReportPage({
    super.key,
    this.data,
    this.reportTimeText,
  });

  final SpineReportData? data;
  final String? reportTimeText;

  static const SpineReportData _defaultData = SpineReportData(
    score: '86',
    risk: '低风险',
    headline: '整体状态良好',
    subline: '建议重点关注：头部前倾、骨盆前倾',
    primaryImpact: '颈肩紧张 / 腰背代偿',
    recommendation: '矫正姿态 + 核心稳定',
    issues: [
      SpineReportIssue(label: '头部前倾', level: '轻度', color: Color(0xFF3B82F6)),
      SpineReportIssue(label: '胸椎后凸', level: '可改善', color: Color(0xFFF59E0B)),
      SpineReportIssue(label: '圆肩程度', level: '正常', color: Color(0xFF10B981)),
    ],
    visualAssets: [
      'assets/images/wwjceshen3D.png',
      'assets/images/3d.png',
      'assets/images/beibu.png',
    ],
  );

  @override
  Widget build(BuildContext context) {
    final resolved = data ?? _defaultData;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('检测报告'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
      ),
      body: SafeArea(
        child: SpineDataReportView(
          data: resolved,
          reportTimeText: reportTimeText,
        ),
      ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.score,
    required this.risk,
    required this.headline,
    required this.subline,
    this.reportTimeText,
  });

  final String score;
  final String risk;
  final String headline;
  final String subline;
  final String? reportTimeText;

  @override
  Widget build(BuildContext context) {
    final timeText = (reportTimeText ?? '').trim().isNotEmpty ? reportTimeText!.trim() : '刚刚';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE7D6),
            Color(0xFFE9E6FF),
            Color(0xFFE6F6FF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '评分',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827).withValues(alpha: 0.60),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Pill(text: risk, color: const Color(0xFF10B981)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827).withValues(alpha: 0.62),
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
              ),
              child: Text(
                timeText,
                style: TextStyle(
                  fontSize: 19.5,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111827).withValues(alpha: 0.70),
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.description,
    required this.child,
    this.trailing,
  });

  final String title;
  final String description;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827).withValues(alpha: 0.60),
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _IssueChip extends StatelessWidget {
  const _IssueChip({
    required this.label,
    required this.level,
    required this.color,
  });

  final String label;
  final String level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF111827).withValues(alpha: 0.86),
              height: 1.0,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            level,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
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
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827).withValues(alpha: 0.60),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ProgressMetricRow extends StatelessWidget {
  const _ProgressMetricRow({
    required this.label,
    required this.valueText,
    required this.value,
    required this.color,
  });

  final String label;
  final String valueText;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827).withValues(alpha: 0.70),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.status,
    required this.statusColor,
  });

  final String label;
  final String value;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
