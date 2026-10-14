import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../utils/app_logger.dart';
import 'posture_api_client.dart';
import 'posture_assessment_models.dart';
import 'posture_camera_page.dart';
import 'spine_report_page.dart';

class PostureAssessmentPage extends StatefulWidget {
  const PostureAssessmentPage({super.key});

  @override
  State<PostureAssessmentPage> createState() => _PostureAssessmentPageState();
}

class _PostureAssessmentPageState extends State<PostureAssessmentPage> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _showOverlay = true;
  bool _showResultLoading = false;

  Timer? _resultLoadingTimer;

  final List<CapturedAssessmentImage> _capturedImages = [];

  final AudioPlayer _player = AudioPlayer();

  late final AnimationController _pulseController;

  final List<AssessmentStep> _steps = const [
    AssessmentStep(
      name: '站立前屈',
      tip: '请背面对准镜头，双腿伸直站立。',
      buttonText: '拍摄背面脊柱',
      audioAsset: 'assets/images/1764121805137.mp3',
      overlayImageAsset: 'assets/images/back-silhouette.png',
    ),
    AssessmentStep(
      name: '正面朝向下腰',
      tip: '请双脚与肩同宽，慢慢下腰，拍摄脊柱弯曲姿势。',
      buttonText: '拍摄朝向正面下腰姿势',
      audioAsset: 'assets/images/front-bend.mp3',
      overlayImageAsset: 'assets/images/yaobupaishe.png',
    ),
  ];

  AssessmentStep get _currentStepData {
    if (_currentStep < 0 || _currentStep >= _steps.length) {
      return const AssessmentStep(
        name: '',
        tip: '',
        buttonText: '',
        audioAsset: '',
        overlayImageAsset: '',
      );
    }
    return _steps[_currentStep];
  }

  bool get _isCompleted => _currentStep >= _steps.length;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _resultLoadingTimer?.cancel();
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAssessment() {
    setState(() {
      _showOverlay = false;
      _currentStep = 0;
      _capturedImages.clear();
    });
  }

  Future<void> _playCompletionSound() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('images/new-level-opening-sound.mp3'));
    } catch (e, st) {
      AppLogger.e('体态测评', e, st);
    }
  }

  Future<void> _handleCapture() async {
    if (_isCompleted) return;

    final step = _currentStepData;
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PostureCameraPage(
          stepName: step.name,
          tip: step.tip,
          overlayImageAsset: step.overlayImageAsset,
          audioAsset: step.audioAsset,
        ),
      ),
    );

    if (!mounted) return;
    if (path == null || path.isEmpty) return;

    setState(() {
      _capturedImages.add(
        CapturedAssessmentImage(stepIndex: _currentStep, stepName: step.name, path: path),
      );

      if (_currentStep < _steps.length - 1) {
        _currentStep++;
      } else {
        _currentStep = _steps.length;
      }
    });

    if (_isCompleted) {
      await _playCompletionSound();
      // 两张图拍完，后台静默上传到后端（后端 SFTP 固定文件名覆盖转存），不阻塞报告流程
      _uploadImagesInBackground();
      _resultLoadingTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _showResultLoading = true;
      });
    }
  }

  /// 两张筛查图拍完后后台静默上传到后端（后端再 SFTP 转存到远程服务器，
  /// 固定文件名 back/Backbend 覆盖旧图）。失败只记日志，不影响报告展示。
  void _uploadImagesInBackground() {
    final backPath = _capturedImages
        .where((e) => e.stepIndex == 0)
        .map((e) => e.path)
        .firstWhere((path) => path.isNotEmpty, orElse: () => '');
    final backbendPath = _capturedImages
        .where((e) => e.stepIndex == 1)
        .map((e) => e.path)
        .firstWhere((path) => path.isNotEmpty, orElse: () => '');
    if (backPath.isEmpty || backbendPath.isEmpty) return;

    unawaited(() async {
      try {
        final ok = await PostureApiClient().uploadImages(
          backImagePath: backPath,
          backbendImagePath: backbendPath,
        );
        if (!ok) {
          AppLogger.e('脊柱筛查图片上传失败', '后端返回异常状态');
        }
      } catch (e, st) {
        AppLogger.e('脊柱筛查图片上传失败', e, st);
      }
    }());
  }

  Future<void> _exitAssessment() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: const Color(0xFF2196F3).withValues(alpha: 0.4), width: 2.5),
          ),
          elevation: 20,
          shadowColor: const Color(0xFF2196F3).withValues(alpha: 0.25),
          backgroundColor: Colors.white,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题区域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Text(
                      '确认退出',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 内容区域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 图标区域
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3), width: 2),
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            size: 40,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // 主标题
                        const Text(
                          '确定要退出体态评估吗？',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.4,
                            color: Color(0xFF212121),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // 副标题
                        const Text(
                          '退出后当前的评估进度将会丢失\n需要重新开始评估',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 按钮区域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 取消按钮
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.5), width: 2),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                foregroundColor: const Color(0xFF2196F3),
                              ),
                              child: const Text(
                                '取消',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // 退出按钮
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF44336), Color(0xFFE91E63)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF44336).withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                '退出',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (ok == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _viewResults() {
    if (_capturedImages.isEmpty) return;

    final p = _capturedImages.last;
    final photo1 = _capturedImages
        .where((e) => e.stepIndex == 0)
        .map((e) => e.path)
        .firstWhere((path) => path.isNotEmpty, orElse: () => '');
    final photo2 = _capturedImages
        .where((e) => e.stepIndex == 1)
        .map((e) => e.path)
        .firstWhere((path) => path.isNotEmpty, orElse: () => '');
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
  }

  void _backToHome() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF42A5F5),
              Color(0xFF21CBF3),
              Color(0xFF4FC3F7),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: _isCompleted
                    ? (_showResultLoading
                        ? _ResultLoadingSection(
                            onTap: () {
                              if (!mounted) return;
                              setState(() {
                                _showResultLoading = false;
                              });
                            },
                          )
                        : _CompletionSection(
                            onViewResults: _viewResults,
                            onBackToHome: _backToHome,
                          ))
                    : Column(
                        children: [
                          _TipSection(text: _currentStepData.tip),
                          const SizedBox(height: 16),
                          _StepIndicator(currentStep: _currentStep, totalSteps: _steps.length),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _GuideSection(
                              imageAsset: _currentStepData.overlayImageAsset,
                              buttonText: _currentStepData.buttonText,
                              pulse: _pulseController,
                              onCapture: _handleCapture,
                              onExit: _exitAssessment,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_showOverlay)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _startAssessment,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.85),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {},
                      child: _StartOverlayCard(onStart: _startAssessment),
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

class _ResultLoadingSection extends StatelessWidget {
  const _ResultLoadingSection({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 90),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.20), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withValues(alpha: 0.18),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '正在分析...',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1976D2)),
              ),
              const SizedBox(height: 10),
              const Text(
                'AI 正在生成您的脊柱健康报告请稍候',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 10),
              Text(
                '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1976D2).withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipSection extends StatelessWidget {
  const _TipSection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.30), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.20),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF21CBF3).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.99),
            Colors.white.withValues(alpha: 0.94),
            const Color(0xFFF3F8FF),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2196F3).withValues(alpha: 0.05),
              const Color(0xFF21CBF3).withValues(alpha: 0.08),
              const Color(0xFF4FC3F7).withValues(alpha: 0.03),
            ],
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            height: 1.6,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1565C0),
            shadows: [
              Shadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final completed = index < currentStep;
        final active = index == currentStep;

        final Color bg;
        final Color fg;
        final List<BoxShadow> shadows;

        if (active) {
          bg = const Color(0xFF2196F3);
          fg = Colors.white;
          shadows = [
            BoxShadow(
              color: const Color(0xFF2196F3).withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ];
        } else if (completed) {
          bg = const Color(0xFF4CAF50);
          fg = Colors.white;
          shadows = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ];
        } else {
          bg = const Color(0xFFE0E0E0);
          fg = const Color(0xFF9E9E9E);
          shadows = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ];
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: active ? 52 : 46,
            height: active ? 52 : 46,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                ...shadows,
                if (active) BoxShadow(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.30),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
                if (active) BoxShadow(
                  color: const Color(0xFF21CBF3).withValues(alpha: 0.20),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              gradient: active ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2196F3),
                  const Color(0xFF21CBF3),
                  const Color(0xFF64B5F6),
                ],
              ) : completed ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4CAF50),
                  const Color(0xFF66BB6A),
                ],
              ) : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bg,
                  bg.withValues(alpha: 0.8),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              completed ? '✓' : '${index + 1}',
              style: TextStyle(
                color: fg,
                fontSize: completed ? 20 : 17,
                fontWeight: FontWeight.w900,
                shadows: active ? [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : completed ? [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.imageAsset,
    required this.buttonText,
    required this.pulse,
    required this.onCapture,
    required this.onExit,
  });

  final String imageAsset;
  final String buttonText;
  final Animation<double> pulse;
  final Future<void> Function() onCapture;
  final Future<void> Function() onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2196F3).withValues(alpha: 0.10),
              const Color(0xFF21CBF3).withValues(alpha: 0.15),
            ],
          ),
          border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.40), width: 1.5),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 520,
              child: Stack(
                children: [
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withValues(alpha: 0.25),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.98),
                              Colors.white.withValues(alpha: 0.88),
                            ],
                          ),
                        ),
                        child: const Text(
                          '姿势示意图',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 72, 12, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            height: 420,
                            width: double.infinity,
                            child: Image.asset(
                              imageAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (context, _, __) {
                                return Center(
                                  child: Text(
                                    '图片加载失败',
                                    style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 14),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ButtonSection(
              pulse: pulse,
              buttonText: buttonText,
              onCapture: onCapture,
              onExit: onExit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ButtonSection extends StatelessWidget {
  const _ButtonSection({
    required this.pulse,
    required this.buttonText,
    required this.onCapture,
    required this.onExit,
  });

  final Animation<double> pulse;
  final String buttonText;
  final Future<void> Function() onCapture;
  final Future<void> Function() onExit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              final t = pulse.value;
              final scale = 1.0 + (math.sin(t * math.pi) * 0.02);
              final glow = 0.30 + (math.sin(t * math.pi) * 0.10);

              return Transform.scale(
                scale: scale,
                child: SizedBox(
                  height: 64,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withValues(alpha: glow),
                          blurRadius: 32,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => onCapture(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      ),
                      child: Text(
                        buttonText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 140,
          height: 64,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF44336), Color(0xFFE91E63)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF44336).withValues(alpha: 0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => onExit(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
              child: const Text(
                '退出评估',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StartOverlayCard extends StatelessWidget {
  const _StartOverlayCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.82,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 35,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.98),
            Colors.white.withValues(alpha: 0.92),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2196F3).withValues(alpha: 0.05),
                  const Color(0xFF21CBF3).withValues(alpha: 0.08),
                ],
              ),
            ),
            child: const Text(
              '我们要开始操作指导了',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1976D2)),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '请准备好，按照提示进行拍摄',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.40),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text(
                  '开始评估',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionSection extends StatelessWidget {
  const _CompletionSection({required this.onViewResults, required this.onBackToHome});

  final VoidCallback onViewResults;
  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.20), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withValues(alpha: 0.18),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text(
              '拍摄完成！',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1976D2)),
            ),
            const SizedBox(height: 10),
            const Text(
              'AI 将自动分析您的脊柱健康状况。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 18),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(27),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: onViewResults,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                      ),
                      child: const Text(
                        '查看结果',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: onBackToHome,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: const Color(0xFF2196F3).withValues(alpha: 0.30), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                      backgroundColor: Colors.white.withValues(alpha: 0.80),
                    ),
                    child: const Text(
                      '返回主页',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1976D2)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentStep {
  const _AssessmentStep({
    required this.name,
    required this.tip,
    required this.buttonText,
    required this.audioAsset,
    required this.overlayImageAsset,
  });

  const _AssessmentStep.empty()
      : name = '',
        tip = '',
        buttonText = '',
        audioAsset = '',
        overlayImageAsset = '';

  final String name;
  final String tip;
  final String buttonText;
  final String audioAsset;
  final String overlayImageAsset;
}

class _CapturedImage {
  const _CapturedImage({required this.stepIndex, required this.stepName, required this.path});

  final int stepIndex;
  final String stepName;
  final String path;
}
