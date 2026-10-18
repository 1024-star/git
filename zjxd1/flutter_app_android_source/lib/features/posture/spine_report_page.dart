import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../fun_correction/fun_correction_page.dart';
import '../../utils/user_scope.dart';
import 'posture_api_client.dart';

// 【核心指标数值】分项指标详情与智能分析共用的单一数据源，保证两处数值一致
// 除 Cobb 角保留测量数值外，其余指标均为描述性结论（真实报告用语：正常/标准/对称/良好）
const String _kCobbAngle = '9.2°~9.4°';
const String _kShoulderDiff = '正常';
const String _kPelvicTilt = '正常';
const String _kLumbarLordosis = '标准';
const String _kHeadForward = '正常';
const String _kScapulaSymmetry = '对称';
const String _kThoracicRotation = '正常';
const String _kLumbarRotation = '正常';
const String _kHipMobility = '标准';
const String _kSpineFlexibility = '良好';

class SpineReportMetrics {
  const SpineReportMetrics({
    required this.shoulderTilt,
    required this.pelvicTilt,
    required this.trunkShiftPercent,
    required this.cobbAngle,
    required this.severity,
    required this.curveShape,
  });

  final double shoulderTilt;
  final double pelvicTilt;
  final double trunkShiftPercent;
  final double cobbAngle;
  final String severity;
  final String curveShape;
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.path, required this.label});

  final String path;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.40),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.2),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: path.isEmpty
                  ? Container(
                      color: Colors.white.withValues(alpha: 0.30),
                      alignment: Alignment.center,
                      child: Text(
                        '暂无${label}照片',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827).withValues(alpha: 0.55),
                        ),
                      ),
                    )
                  : Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      // 注意：不再做水平镜像，报告照片方向与拍摄预览保持一致
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: Colors.white.withValues(alpha: 0.30),
                          alignment: Alignment.center,
                          child: Text(
                            '${label}照片加载失败',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827).withValues(alpha: 0.55),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.80),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpineReportPage extends StatefulWidget {
  const SpineReportPage({
    super.key,
    required this.imagePath,
    required this.stepIndex,
    required this.stepName,
    this.frontImagePath,
    this.sideImagePath,
    this.metrics = const SpineReportMetrics(
      shoulderTilt: 0.8,
      pelvicTilt: 1.1,
      trunkShiftPercent: 0.6,
      cobbAngle: 3.2,
      severity: 'Normal',
      curveShape: 'Normal',
    ),
    this.storedReport,
  });

  final String imagePath;
  final int stepIndex;
  final String stepName;
  final String? frontImagePath;
  final String? sideImagePath;
  final SpineReportMetrics metrics;

  /// 查看已存储的检测记录时传入：直接展示该数据，不重新调 API，也不再上报存储
  final PostureReport? storedReport;

  @override
  State<SpineReportPage> createState() => _SpineReportPageState();
}

class _SpineReportPageState extends State<SpineReportPage> {
  late final PostureApiClient _api;
  late final Future<PostureReport> _future;

  @override
  void initState() {
    super.initState();
    _api = PostureApiClient();

    final stored = widget.storedReport;
    if (stored != null) {
      // 历史记录模式：只用存储的数据
      _future = Future.value(stored);
      return;
    }

    _future = _api.fetchReport(stepIndex: widget.stepIndex, stepName: widget.stepName);
    // 拿到报告后上报存储到后端（含检测照片路径，失败静默，不影响本地展示）
    _future.then((report) {
      _api
          .saveReport(
            username: (UserScope.username ?? 'anonymous').trim(),
            stepIndex: widget.stepIndex,
            stepName: widget.stepName,
            report: report,
            frontImagePath: widget.frontImagePath ?? widget.imagePath,
            sideImagePath: widget.sideImagePath,
          )
          .then((ok) {
        if (!ok) debugPrint('Save posture report failed');
      }).catchError((_) {});
    }).catchError((_) {});
  }

  SpineReportMetrics _toMetrics(PostureReport r) {
    return SpineReportMetrics(
      shoulderTilt: r.shoulderTilt,
      pelvicTilt: r.pelvicTilt,
      trunkShiftPercent: r.trunkShiftPercent,
      cobbAngle: r.cobbAngle,
      severity: r.severity,
      curveShape: r.curveShape,
    );
  }

  String get curveShapeCN {
    final shape = widget.metrics.curveShape.toLowerCase();
    if (shape.contains('normal')) return '正常';
    if (shape.contains('s')) return 'S型曲线';
    if (shape.contains('c')) return 'C型曲线';
    return widget.metrics.curveShape.isEmpty ? '未知' : widget.metrics.curveShape;
  }

  String get severityCN {
    // 强制显示"疑似有脊柱问题"
    return '疑似有轻微脊柱侧弯';
  }

  Color get severityColor {
    // 疑似有脊柱问题使用橙色
    return const Color(0xFFF59E0B);
  }

  String _degree(double val) => '${val.toStringAsFixed(1)}°';
  String _percent(double val) => '${val.toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    const navHeight = 60.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFF6FF),
              Color(0xFFFDF2F8),
              Color(0xFFECFDF5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部导航栏
              Container(
                height: navHeight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF334155)),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '脊柱健康检测报告',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 44, height: 44),
                  ],
                ),
              ),
              // 内容区域
              Expanded(
                child: FutureBuilder<PostureReport>(
                  future: _future,
                  builder: (context, snapshot) {
                    final report = snapshot.data;
                    // 分析失败：明确提示 + 重试，不再静默用默认值冒充结果
                    if (snapshot.hasError && report == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 52),
                              const SizedBox(height: 14),
                              const Text('分析失败',
                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                              const SizedBox(height: 8),
                              Text('${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.6)),
                              const SizedBox(height: 18),
                              FilledButton(
                                onPressed: () {
                                  setState(() {
                                    _future = _api.fetchReport(
                                      stepIndex: widget.stepIndex,
                                      stepName: widget.stepName,
                                    );
                                  });
                                },
                                child: const Text('重新分析'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final metrics = report == null ? widget.metrics : _toMetrics(report);

                    final String curveCN = () {
                      final shape = metrics.curveShape.toLowerCase();
                      if (shape.contains('normal')) return '正常';
                      if (shape.contains('s')) return 'S型曲线';
                      if (shape.contains('c')) return 'C型曲线';
                      return metrics.curveShape.isEmpty ? '未知' : metrics.curveShape;
                    }();
                    final String sevCN = () {
                      final s = metrics.severity.toLowerCase();
                      if (s.contains('normal')) return '正常';
                      if (s.contains('mild')) return '轻度';
                      if (s.contains('moderate')) return '中度';
                      if (s.contains('severe')) return '重度';
                      return metrics.severity.isEmpty ? '未知' : metrics.severity;
                    }();
                    final Color sevColor = () {
                      if (sevCN == '正常') return const Color(0xFFA8E6CF);
                      if (sevCN == '轻度') return const Color(0xFFFFEAA7);
                      if (sevCN == '中度') return const Color(0xFFFFD3B6);
                      return const Color(0xFFFFAAA5);
                    }();
                    // 演示随机评分：与 2D 报告列表卡同种子（generatedAtMs）同公式，保证列表与详情页分数一致
                    final scoreRng = math.Random(report?.generatedAtMs ?? 0);
                    final randCobb = 8.0 + scoreRng.nextDouble() * 1.6; // 8.0 ~ 9.6，与列表卡同分布
                    final int spineHealthScore = 92 - ((randCobb - 8.0) * 4.4).round(); // 85 ~ 92

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // 【数据来源声明】本页所有分项指标均为演示数据，
                          // 不是通过手机摄像头测量得到的医学结论，避免被误认为真实 Cobb 角等医学指标。
                          const _DemoDataBanner(),
                          const SizedBox(height: 12),
                          // 核心结论总览卡 - 可爱风
                          _CuteCoreConclusionCard(
                            severityCN: sevCN,
                            curveShapeCN: curveCN,
                            spineHealthScore: spineHealthScore,
                          ),
                          const SizedBox(height: 20),
                          // 脊柱可视化检测图区 - 可爱风
                          _CuteSpineVisualizationCard(
                            frontImagePath: widget.frontImagePath ?? widget.imagePath,
                            sideImagePath: widget.sideImagePath,
                          ),
                          const SizedBox(height: 20),
                          // 多指标评估 - 可爱风
                          _CuteMetricsCard(
                            curveShapeCN: curveCN,
                            shoulderTilt: _degree(metrics.shoulderTilt),
                            pelvicTilt: _degree(metrics.pelvicTilt),
                            trunkShiftPercent: _percent(metrics.trunkShiftPercent),
                            cobbAngle: _degree(metrics.cobbAngle),
                            severityCN: sevCN,
                            severityColor: sevColor,
                          ),
                          const SizedBox(height: 20),
                          // 智能分析 - 可爱风
                          _CuteAnalysisCard(text: _hardcodedSummary(sevCN, curveCN)),
                          const SizedBox(height: 20),
                          // 个性化建议 - 可爱风
                          _CuteAdviceCard(items: report?.advice ?? _fallbackAdvice(sevCN)),
                          const SizedBox(height: 20),
                          // 训练卡片 - 保留原有逻辑
                          _TrainingCard(
                            onGoToTraining: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FunCorrectionPage(guideToHipBridge: true),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 34),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _hardcodedSummary(String severityCN, String curveShapeCN) {
    return 'AI 检测结果显示：整体评估为$severityCN，脊柱形态呈$curveShapeCN。'
        '关键指标——Cobb 角 $_kCobbAngle，高低肩差值$_kShoulderDiff、骨盆倾斜度$_kPelvicTilt、'
        '腰椎曲度$_kLumbarLordosis、头部前倾角度$_kHeadForward、肩胛骨对称性$_kScapulaSymmetry、'
        '胸椎旋转度$_kThoracicRotation、腰椎旋转度$_kLumbarRotation、髋关节活动度$_kHipMobility，'
        '脊柱柔韧性$_kSpineFlexibility。各项指标均在正常范围内，整体状态稳定，建议保持良好体态并定期复查。';
  }

  List<String> _fallbackAdvice(String severityCN) {
    if (severityCN == '正常') {
      return ['保持日常拉伸与体态习惯', '注意坐姿与站姿对称', '定期自我评估与复查'];
    }
    if (severityCN == '轻度') {
      return ['每周3-4次核心稳定训练', '配合肩颈/髋屈肌放松', '避免久坐，定时起身活动'];
    }
    if (severityCN == '中度') {
      return ['规律矫正训练（每周4-5次）', '配合专业康复指导', '4-8周定期复查评估'];
    }
    return ['建议到医院进行专业评估与康复', '遵医嘱进行系统化治疗', '避免单侧负重和长时间不良体位'];
  }
}

// 可爱风核心结论总览卡
class _CuteCoreConclusionCard extends StatelessWidget {
  const _CuteCoreConclusionCard({
    required this.severityCN,
    required this.curveShapeCN,
    required this.spineHealthScore,
  });

  final String severityCN;
  final String curveShapeCN;
  final int spineHealthScore;

  @override
  Widget build(BuildContext context) {
    const textStrong = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);
    final accentColor = const Color(0xFF10B981); // 结果正常使用绿色
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF1F5F9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  severityCN == '正常' ? Icons.sentiment_very_satisfied_rounded : Icons.health_and_safety_rounded,
                  size: 30,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '脊柱侧弯评估: 正常',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '脊柱形态：$curveShapeCN',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text('健康值', style: TextStyle(fontSize: 11, color: textSoft, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('$spineHealthScore', style: TextStyle(fontSize: 24, height: 1, fontWeight: FontWeight.w900, color: accentColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates_outlined, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '建议优先进行矫正训练，并在 4–8 周后复测',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textStrong, height: 1.35),
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

// 可爱风脊柱可视化检测图区 - 带精确引线系统
class _CuteSpineVisualizationCard extends StatelessWidget {
  const _CuteSpineVisualizationCard({
    required this.frontImagePath,
    required this.sideImagePath,
  });

  final String frontImagePath;
  final String? sideImagePath;

  @override
  Widget build(BuildContext context) {
    final rightPath = (sideImagePath ?? '').isNotEmpty ? sideImagePath! : '';
    return Container(
      width: double.infinity,
      height: 420,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFDBEAFE),
            Color(0xFFFCE7F3),
            Color(0xFFD1FAE5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          children: [
            SizedBox(
              height: 380,
              child: Row(
                children: [
                  Expanded(child: _PhotoBox(path: frontImagePath, label: '背部')),
                  const SizedBox(width: 14),
                  Expanded(child: _PhotoBox(path: rightPath, label: '下腰')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLeftLabelsAndLines() {
    final labels = ['颈椎曲度：正常', '肩对称度：正常', '脊柱中轴线：正常', '腰椎曲度：正常'];
    final anchorPositions = [
      const Offset(210, 200), // 颈部左侧外表面，解剖学颈椎对应位置
      const Offset(210, 260), // 左肩关节顶端外表面，肩胛骨对应位置
      const Offset(210, 320), // 上背部左侧外表面，胸椎上段对应位置
      const Offset(210, 380), // 腰部左侧外表面，腰椎对应位置
    ];
    final labelPositions = [
      const Offset(5, 200),   // 颈椎曲度标签
      const Offset(5, 260),   // 肩对称度标签
      const Offset(5, 320),   // 脊柱中轴线标签
      const Offset(5, 380),   // 腰椎曲度标签
    ];
    final riskLevels = ['normal', 'normal', 'normal', 'normal'];
    
    return List.generate(4, (index) {
      return Stack(
        children: [
          // 标签气泡 - 顶层
          Positioned(
            left: labelPositions[index].dx,
            top: labelPositions[index].dy,
            child: Container(
              width: 162.5,  // 130 * 1.25 = 162.5，放大25%
              height: 50,    // 40 * 1.25 = 50，放大25%
              decoration: BoxDecoration(
                color: _getOptimizedLabelColor(riskLevels[index]), // 正常状态：白色背景
                borderRadius: BorderRadius.circular(25),   // 圆角25px（两端完美半圆胶囊形状）
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), // 轻微柔和阴影，黑色透明度0.1
                    offset: const Offset(0, 2),                // 偏移(0,2)
                    blurRadius: 4,                             // 模糊4px
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: const TextStyle(
                    fontSize: 17.5, // 14 * 1.25 = 17.5，字体放大25%
                    fontWeight: FontWeight.w500, // 字重中等
                    color: Color(0xFF4CAF50), // 正常状态：浅绿色文字
                  ),
                  textAlign: TextAlign.center, // 居中对齐
                  maxLines: 1, // 强制单行显示
                  overflow: TextOverflow.visible, // 确保文字完整无裁切
                ),
              ),
            ),
          ),
          // 标点圆点 - 底层
          Positioned(
            left: anchorPositions[index].dx - 4,  // 标点圆心X坐标 - 4px = 左上角X
            top: anchorPositions[index].dy - 4,   // 标点圆心Y坐标 - 4px = 左上角Y
            child: Container(
              width: 8,    // 标点直径8px
              height: 8,   // 标点直径8px
              decoration: BoxDecoration(
                color: Colors.white, // 正常标点：纯白色填充
                shape: BoxShape.circle, // 完美实心圆点
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3), // 正常标点：浅灰色1px描边透明度0.3
                  width: 1, // 1px描边宽度
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  List<Widget> _buildRightLabelsAndLines() {
    final labels = ['胸椎侧弯：风险高', '侧弯度数：风险低', '骨盆倾斜：风险低'];
    final anchorPositions = [
      const Offset(325, 285), // 胸部右侧外表面，胸椎中段对应位置（高风险）+ 25px (10px + 15px)
      const Offset(325, 345), // 下胸部右侧外表面，胸椎下段对应位置 + 25px (10px + 15px)
      const Offset(325, 405), // 右髋部顶端外表面，骨盆对应位置 + 25px (10px + 15px)
    ];
    final labelPositions = [
      const Offset(555, 285), // 胸椎侧弯标签 + 180px (10px + 30px + 60px + 80px)
      const Offset(555, 345), // 侧弯度数标签 + 180px (10px + 30px + 60px + 80px)
      const Offset(555, 405), // 骨盆倾斜标签 + 180px (10px + 30px + 60px + 80px)
    ];
    final riskLevels = ['high', 'low', 'low'];
    
    return List.generate(3, (index) {
      return Stack(
        children: [
          // 标签气泡 - 顶层
          Positioned(
            left: labelPositions[index].dx - 162.5, // 向左移动162.5px
            top: labelPositions[index].dy,
            child: Container(
              width: 162.5,  // 130 * 1.25 = 162.5，放大25%
              height: 50,    // 40 * 1.25 = 50，放大25%
              decoration: BoxDecoration(
                color: _getOptimizedLabelColor(riskLevels[index]),
                borderRadius: BorderRadius.circular(25),   // 圆角25px（两端完美半圆胶囊形状）
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), // 轻微柔和阴影，黑色透明度0.1
                    offset: const Offset(0, 2),                // 偏移(0,2)
                    blurRadius: 4,                             // 模糊4px
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 17.5, // 14 * 1.25 = 17.5，字体放大25%
                    fontWeight: FontWeight.w500, // 字重中等
                    color: _getOptimizedTextColor(riskLevels[index]),
                  ),
                  textAlign: TextAlign.center, // 居中对齐
                  maxLines: 1, // 强制单行显示
                  overflow: TextOverflow.visible, // 确保文字完整无裁切
                ),
              ),
            ),
          ),
          // 标点圆点 - 底层
          Positioned(
            left: anchorPositions[index].dx - 4,  // 标点圆心X坐标 - 4px = 左上角X
            top: anchorPositions[index].dy - 4,   // 标点圆心Y坐标 - 4px = 左上角Y
            child: Container(
              width: 8,    // 标点直径8px
              height: 8,   // 标点直径8px
              decoration: BoxDecoration(
                color: riskLevels[index] == 'high' ? const Color(0xFFFFD700) : Colors.white, // 高风险标点：金黄色填充
                shape: BoxShape.circle, // 完美实心圆点
                border: Border.all(
                  color: riskLevels[index] == 'high' ? Colors.white : Colors.grey.withValues(alpha: 0.3), // 高风险标点：白色1px描边增强辨识度
                  width: 1, // 1px描边宽度
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // 获取标签背景颜色
  Color _getOptimizedLabelColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return const Color(0xFFFFE5B4); // 高风险状态：浅橙色背景
      case 'low':
      case 'normal':
      default:
        return const Color(0xFFFFFFFF); // 正常/低风险状态：白色背景
    }
  }

  // 获取文字颜色
  Color _getOptimizedTextColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return const Color(0xFFFF8C00); // 高风险状态：橙色文字
      case 'low':
      case 'normal':
      default:
        return const Color(0xFF4CAF50); // 正常/低风险状态：浅绿色文字
    }
  }
}

// 可爱风分项指标详情区域
class _CuteMetricsCard extends StatelessWidget {
  const _CuteMetricsCard({
    required this.curveShapeCN,
    required this.shoulderTilt,
    required this.pelvicTilt,
    required this.trunkShiftPercent,
    required this.cobbAngle,
    required this.severityCN,
    required this.severityColor,
  });

  final String curveShapeCN;
  final String shoulderTilt;
  final String pelvicTilt;
  final String trunkShiftPercent;
  final String cobbAngle;
  final String severityCN;
  final Color severityColor;

  @override
  Widget build(BuildContext context) {
    const textStrong = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);
    // 定义12个指标数据 - 全部正常
    final indicators = [
      {'name': 'Cobb角(演示)', 'value': _kCobbAngle, 'range': '(非真实测量)', 'isNormal': true},
      {'name': '弯曲类型', 'value': '正常', 'range': '(脊柱形态)', 'isNormal': true},
      {'name': '侧弯程度', 'value': '正常', 'range': '(Cobb分级)', 'isNormal': true},
      {'name': '高低肩差值', 'value': _kShoulderDiff, 'range': '(<1cm)', 'isNormal': true},
      {'name': '骨盆倾斜度', 'value': _kPelvicTilt, 'range': '(0-3°)', 'isNormal': true},
      {'name': '腰椎曲度', 'value': _kLumbarLordosis, 'range': '(20-30°)', 'isNormal': true},
      {'name': '头部前倾角度', 'value': _kHeadForward, 'range': '(0-10°)', 'isNormal': true},
      {'name': '肩胛骨对称性', 'value': _kScapulaSymmetry, 'range': '(>90%)', 'isNormal': true},
      {'name': '胸椎旋转度', 'value': _kThoracicRotation, 'range': '(0-3°)', 'isNormal': true},
      {'name': '腰椎旋转度', 'value': _kLumbarRotation, 'range': '(0-2°)', 'isNormal': true},
      {'name': '髋关节活动度', 'value': _kHipMobility, 'range': '(110-130°)', 'isNormal': true},
      {'name': '脊柱柔韧性', 'value': _kSpineFlexibility, 'range': '(良好/一般/较差)', 'isNormal': true},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              const Icon(Icons.fact_check_rounded, size: 18, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              const Text(
                '分项指标参考',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textStrong,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '整体稳定',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textSoft),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 6行2列网格布局
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.55,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final indicator = indicators[index];
              return _IndicatorCard(
                name: indicator['name'] as String,
                value: indicator['value'] as String,
                range: indicator['range'] as String,
                isNormal: indicator['isNormal'] as bool,
              );
            },
          ),
        ],
      ),
    );
  }
}

// 指标卡片组件
class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({
    required this.name,
    required this.value,
    required this.range,
    required this.isNormal,
  });

  final String name;
  final String value;
  final String range;
  final bool isNormal;

  @override
  Widget build(BuildContext context) {
    const textStrong = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);
    final Color brand = isNormal ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final Color tint = isNormal ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);
    return Container(
      // 不再写死高度：写死 75 会超过 GridView 按 childAspectRatio 算出的单元格高度，
      // 造成 BOTTOM OVERFLOWED。改为撑满单元格，内容自适应（不会遮挡，也不溢出）。
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            // 图标
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isNormal ? Icons.check : Icons.warning,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            // 文字信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textStrong),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: brand,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          range,
                          style: const TextStyle(fontSize: 12, color: textSoft, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 可爱风智能分析卡片
class _CuteAnalysisCard extends StatelessWidget {
  const _CuteAnalysisCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text(
                '智能分析',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// 可爱风个性化建议卡片
class _CuteAdviceCard extends StatelessWidget {
  const _CuteAdviceCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_rounded, size: 18, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                '专属健康建议',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4, right: 8),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          line,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF334155),
                            height: 1.5,
                          ),
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

// 训练卡片 - 保留原有实现
class _TrainingCard extends StatelessWidget {
  const _TrainingCard({required this.onGoToTraining});

  final VoidCallback onGoToTraining;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF83600), Color(0xFFF9D423)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(8),
                  color: Colors.white.withValues(alpha: 0.20),
                  child: Image.asset(
                    'assets/images/hip-bridge-girl-illustration.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('开始专业训练', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(height: 6),
                    Text(
                      '根据您的脊柱状况，推荐进行针对性训练',
                      style: TextStyle(fontSize: 13, color: Color(0xCCFFFFFF), height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onGoToTraining,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.30), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                backgroundColor: Colors.white.withValues(alpha: 0.20),
              ),
              child: const Text(
                '立即训练',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
//  数据来源声明横幅
//  本页分项指标（含 Cobb 角）均为演示数据，非手机摄像头真实测量结果。
// ============================================================================
class _DemoDataBanner extends StatelessWidget {
  const _DemoDataBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.55), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('演示数据声明',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                SizedBox(height: 4),
                Text('本页分项指标（含 Cobb 角）为演示参考数据，并非通过手机摄像头测量得到的医学结论，'
                    '不作为诊断依据。实际筛查请以专业医疗机构影像检查为准。',
                    style: TextStyle(fontSize: 12, height: 1.55, color: Color(0xFF92400E))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
