import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class JumpChallengeLevel {
  const JumpChallengeLevel({
    required this.id,
    required this.name,
    required this.type,
    required this.actionName,
    required this.actionDescription,
    required this.targetCount,
    required this.timeLimitSeconds,
    required this.difficulty,
    required this.description,
  });

  final int id;
  final String name;
  final String type;
  final String actionName;
  final String actionDescription;
  final int targetCount;
  final int timeLimitSeconds;
  final int difficulty;
  final String description;
}

class JumpChallengePage extends StatefulWidget {
  const JumpChallengePage({
    super.key,
    required this.level,
    this.backgroundAsset = 'assets/images/game-background-4.png',
  });

  final JumpChallengeLevel level;
  final String backgroundAsset;

  @override
  State<JumpChallengePage> createState() => _JumpChallengePageState();
}

class _JumpChallengePageState extends State<JumpChallengePage> with TickerProviderStateMixin {
  static const _characterAsset = 'assets/images/jiuse.png';
  static const _startIconAsset = 'assets/images/correction-exercise.png';

  Timer? _timer;
  Timer? _simulate;

  bool isExercising = false;
  bool isPaused = false;

  bool showResult = false;

  int remainingTime = 60;
  int correctCount = 0;
  int totalCount = 0;

  double climberX = 220;
  double climberY = 100;
  int characterDirection = 1;

  bool isPanelHidden = true;
  double _touchStartY = 0;
  double _touchMoveY = 0;

  bool showDebugPanel = false;
  bool debugMinimized = false;
  Offset debugPos = const Offset(12, 160);

  late final AnimationController _jump;
  double _jumpBaseY = 0;
  double _jumpHeight = 0;

  @override
  void initState() {
    super.initState();
    remainingTime = widget.level.timeLimitSeconds;

    _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _jump.addListener(() {
      final t = _jump.value;
      final y = _jumpBaseY + (_jumpHeight * math.sin(math.pi * t));
      setState(() {
        climberY = y;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _simulate?.cancel();
    _jump.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  int get accuracy => totalCount > 0 ? ((correctCount / totalCount) * 100).round() : 0;

  double get progressPercent {
    if (widget.level.targetCount <= 0) return 0;
    return math.min((correctCount / widget.level.targetCount) * 100, 100);
  }

  double get timerProgress {
    final total = widget.level.timeLimitSeconds;
    if (total <= 0) return 0;
    return ((total - remainingTime) / total).clamp(0.0, 1.0);
  }

  int get climbSteps => (correctCount * 1.5).floor();

  _Grade get grade {
    if (accuracy >= 90) return const _Grade(level: 'S', color: Color(0xFFFFD700), text: '完美');
    if (accuracy >= 80) return const _Grade(level: 'A', color: Color(0xFF32CD32), text: '优秀');
    if (accuracy >= 70) return const _Grade(level: 'B', color: Color(0xFF4169E1), text: '良好');
    if (accuracy >= 60) return const _Grade(level: 'C', color: Color(0xFFFFA500), text: '及格');
    return const _Grade(level: 'D', color: Color(0xFFDC143C), text: '需加油');
  }

  void _start() {
    setState(() {
      showResult = false;
      isExercising = true;
      isPaused = false;
      isPanelHidden = false;
      remainingTime = widget.level.timeLimitSeconds;
      correctCount = 0;
      totalCount = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (!isExercising || isPaused) return;
      if (remainingTime <= 0) {
        _finish();
        return;
      }
      setState(() {
        remainingTime -= 1;
      });
    });

    _simulate?.cancel();
    _simulate = Timer.periodic(const Duration(milliseconds: 1400), (t) {
      if (!mounted) return;
      if (!isExercising || isPaused) return;

      setState(() {
        totalCount += 1;
        if (math.Random().nextDouble() <= 0.82) {
          correctCount += 1;
        }
      });

      _jumpOnce(60);
      _climbStep();

      if (correctCount >= widget.level.targetCount) {
        _finish();
      }
    });
  }

  void _finish() {
    if (!isExercising) return;

    _timer?.cancel();
    _simulate?.cancel();

    setState(() {
      isExercising = false;
      isPaused = false;
      showResult = true;
    });
  }

  void _stop() {
    _timer?.cancel();
    _simulate?.cancel();

    setState(() {
      isExercising = false;
      isPaused = false;
    });
  }

  void _pause() {
    if (!isExercising) return;
    setState(() {
      isPaused = true;
    });
  }

  void _resume() {
    if (!isExercising) return;
    setState(() {
      isPaused = false;
    });
  }

  void _restart() {
    _stop();
    _start();
  }

  void _climbStep() {
    setState(() {
      climberY = climberY + 24;
      climberX = (climberX + (math.Random().nextBool() ? 16 : -16)).clamp(20.0, 340.0);
      characterDirection = math.Random().nextBool() ? 1 : -1;
    });
  }

  void _jumpOnce(double height) {
    _jump.stop();
    _jumpBaseY = climberY;
    _jumpHeight = height;
    _jump.value = 0;
    _jump.forward();
  }

  Future<void> _showGuide() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('动作指导'),
          content: Text(widget.level.actionDescription.isEmpty ? '这里展示动作指导内容（示例）' : widget.level.actionDescription),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('知道了')),
          ],
        );
      },
    );
  }

  Future<bool> _confirmExitIfNeeded() async {
    if (!isExercising) return true;

    final res = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 280,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF5F5),
                  Color(0xFFFFE5E5),
                  Color(0xFFFFD5D5),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '确认退出训练？',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '运动检测正在进行中，退出将丢失当前进度',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            foregroundColor: const Color(0xFF6B7280),
                          ),
                          child: const Text(
                            '继续训练',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            '确认退出',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
        );
      },
    );

    if (res == true) {
      _stop();
    }

    return res == true;
  }

  void _handlePanelStart(DragStartDetails d) {
    _touchStartY = d.globalPosition.dy;
    _touchMoveY = _touchStartY;
  }

  void _handlePanelMove(DragUpdateDetails d) {
    _touchMoveY = d.globalPosition.dy;
  }

  void _handlePanelEnd(DragEndDetails d) {
    final delta = _touchMoveY - _touchStartY;
    const threshold = 50.0;

    if (delta.abs() > threshold) {
      setState(() {
        isPanelHidden = delta > 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const panelHeight = 360.0;

    return WillPopScope(
      onWillPop: () async {
        return _confirmExitIfNeeded();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                widget.backgroundAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
              ),
            ),
            Positioned.fill(child: ColoredBox(color: Colors.black.withValues(alpha: 0.10))),
            Positioned.fill(
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      left: climberX,
                      bottom: climberY,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(characterDirection.toDouble(), 1, 1),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Image.asset(
                            _characterAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox(width: 44, height: 44),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _BackButtonGlass(
                        onTap: () async {
                          final ok = await _confirmExitIfNeeded();
                          if (!ok) return;
                          if (!mounted) return;
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Positioned(
                      top: 90,
                      right: 12,
                      child: _DebugToggle(
                        active: showDebugPanel,
                        onTap: () => setState(() => showDebugPanel = !showDebugPanel),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        transform: Matrix4.translationValues(0, isPanelHidden ? (panelHeight - 72) : 0, 0),
                        child: _MainControlPanel(
                          level: widget.level,
                          isExercising: isExercising,
                          remainingTime: remainingTime,
                          progressPercent: progressPercent,
                          timeText: _formatTime(remainingTime),
                          timerProgress: timerProgress,
                          onDragStart: _handlePanelStart,
                          onDragMove: _handlePanelMove,
                          onDragEnd: _handlePanelEnd,
                          onStart: _start,
                          onStop: _stop,
                          onGuide: _showGuide,
                          onPause: _pause,
                        ),
                      ),
                    ),
                    if (showResult)
                      Positioned.fill(
                        child: _ResultModal(
                          correctCount: correctCount,
                          totalCount: totalCount,
                          accuracy: accuracy,
                          climbSteps: climbSteps,
                          grade: grade,
                          onClose: () => setState(() => showResult = false),
                          onAnalysis: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('查看AI分析（示例）')));
                          },
                          onRetry: _restart,
                        ),
                      ),
                    if (isPaused)
                      Positioned.fill(
                        child: _PauseOverlay(
                          onResume: _resume,
                          onStop: _stop,
                        ),
                      ),
                    if (showDebugPanel)
                      Positioned(
                        left: debugPos.dx,
                        top: debugPos.dy,
                        child: _DebugPanel(
                          minimized: debugMinimized,
                          opacity: 0.98,
                          onMove: (d) {
                            setState(() {
                              debugPos = Offset(
                                (debugPos.dx + d.dx).clamp(0.0, MediaQuery.sizeOf(context).width - 180),
                                (debugPos.dy + d.dy).clamp(0.0, MediaQuery.sizeOf(context).height - 100),
                              );
                            });
                          },
                          onToggleMinimize: () => setState(() => debugMinimized = !debugMinimized),
                          onClose: () => setState(() => showDebugPanel = false),
                          onJump: () => _jumpOnce(70),
                          onReset: () => setState(() {
                            climberX = 220;
                            climberY = 100;
                            characterDirection = 1;
                          }),
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
}

class _MainControlPanel extends StatelessWidget {
  const _MainControlPanel({
    required this.level,
    required this.isExercising,
    required this.remainingTime,
    required this.progressPercent,
    required this.timeText,
    required this.timerProgress,
    required this.onDragStart,
    required this.onDragMove,
    required this.onDragEnd,
    required this.onStart,
    required this.onStop,
    required this.onGuide,
    required this.onPause,
  });

  final JumpChallengeLevel level;
  final bool isExercising;
  final int remainingTime;
  final double progressPercent;
  final String timeText;
  final double timerProgress;

  final ValueChanged<DragStartDetails> onDragStart;
  final ValueChanged<DragUpdateDetails> onDragMove;
  final ValueChanged<DragEndDetails> onDragEnd;

  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onGuide;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: onDragStart,
      onVerticalDragUpdate: onDragMove,
      onVerticalDragEnd: onDragEnd,
      child: Container(
        height: 360,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, -10)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 6,
              decoration: BoxDecoration(color: const Color(0xFFD0D0D0), borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(height: 14),
            _LevelInfo(level: level, progressPercent: progressPercent),
            const SizedBox(height: 16),
            _TimerRow(remainingTime: remainingTime, timeText: timeText, progress: timerProgress),
            const SizedBox(height: 16),
            if (!isExercising)
              _StartButton(onTap: onStart)
            else
              _StopButton(onTap: onStop),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HelperButton(icon: '❓', text: '动作指导', onTap: onGuide),
                if (isExercising) _HelperButton(icon: '⏸️', text: '暂停', onTap: onPause),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelInfo extends StatelessWidget {
  const _LevelInfo({required this.level, required this.progressPercent});

  final JumpChallengeLevel level;
  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(level.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(18)),
              child: Text(_typeText(level.type), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text('目标：${level.targetCount}个标准动作', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
            ),
            Text('${progressPercent.round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF4FACFE))),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: Color(0xFFE5E5E5))),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (progressPercent / 100).clamp(0.0, 1.0),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)])),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _typeText(String type) {
    switch (type) {
      case 'neck':
        return '颈椎';
      case 'scoliosis':
        return '侧弯';
      case 'back':
        return '背部';
      default:
        return type;
    }
  }
}

class _TimerRow extends StatelessWidget {
  const _TimerRow({required this.remainingTime, required this.timeText, required this.progress});

  final int remainingTime;
  final String timeText;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(timeText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 4),
              const Text('剩余时间', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
            ],
          ),
        ),
        _TimerCircle(seconds: remainingTime, progress: progress),
      ],
    );
  }
}

class _TimerCircle extends StatelessWidget {
  const _TimerCircle({required this.seconds, required this.progress});

  final int seconds;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: const [Color(0xFF4FACFE), Color(0xFF4FACFE), Color(0xFFE5E5E5), Color(0xFFE5E5E5)],
          stops: [0, p, p, 1],
        ),
      ),
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          alignment: Alignment.center,
          child: Text('$seconds', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF4FACFE))),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [Color(0xFFF83600), Color(0xFFF9D423)]),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF9D423).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                _JumpChallengePageState._startIconAsset,
                width: 34,
                height: 34,
                fit: BoxFit.contain,
                color: Colors.white,
                errorBuilder: (_, __, ___) => const Text('🏃', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('开始运动', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(height: 6),
                  Text('点击开始脊柱健康训练', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xDFFFFFFF))),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1),
              ),
              alignment: Alignment.center,
              child: const Text('→', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)]),
          boxShadow: [
            BoxShadow(color: const Color(0xFFFF6B6B).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1),
              ),
              alignment: Alignment.center,
              child: const Text('⏹️', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('停止运动', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(height: 6),
                  Text('结束当前训练', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xDFFFFFFF))),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1),
              ),
              alignment: Alignment.center,
              child: const Text('■', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelperButton extends StatelessWidget {
  const _HelperButton({required this.icon, required this.text, required this.onTap});

  final String icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
          ],
        ),
      ),
    );
  }
}

class _ResultModal extends StatelessWidget {
  const _ResultModal({
    required this.correctCount,
    required this.totalCount,
    required this.accuracy,
    required this.climbSteps,
    required this.grade,
    required this.onClose,
    required this.onAnalysis,
    required this.onRetry,
  });

  final int correctCount;
  final int totalCount;
  final int accuracy;
  final int climbSteps;
  final _Grade grade;
  final VoidCallback onClose;
  final VoidCallback onAnalysis;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.80),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('运动完成！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                        SizedBox(height: 6),
                        Text('你的表现：', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF5F5F5)),
                      alignment: Alignment.center,
                      child: const Text('✕', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF999999))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                children: [
                  _StatCard(label: '正确动作', value: '$correctCount'),
                  _StatCard(label: '总动作数', value: '$totalCount'),
                  _StatCard(label: '准确率', value: '$accuracy%'),
                  _StatCard(label: '爬升阶梯', value: '$climbSteps'),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: grade.color),
                    alignment: Alignment.center,
                    child: Text(grade.level, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(grade.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  _ActionButton.primary(text: '查看AI分析', onTap: onAnalysis),
                  const SizedBox(height: 10),
                  _ActionButton.secondary(text: '再试一次', onTap: onRetry),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF4FACFE))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton._({required this.text, required this.onTap, required this.background, required this.foreground});

  factory _ActionButton.primary({required String text, required VoidCallback onTap}) {
    return _ActionButton._(
      text: text,
      onTap: onTap,
      background: const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]),
      foreground: Colors.white,
    );
  }

  factory _ActionButton.secondary({required String text, required VoidCallback onTap}) {
    return _ActionButton._(
      text: text,
      onTap: onTap,
      background: const LinearGradient(colors: [Color(0xFFF1F5F9), Color(0xFFF1F5F9)]),
      foreground: const Color(0xFF64748B),
    );
  }

  final String text;
  final VoidCallback onTap;
  final Gradient background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 46,
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: background),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: foreground)),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onStop});

  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.80),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('运动暂停', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 16),
              _ActionButton.primary(text: '继续', onTap: onResume),
              const SizedBox(height: 10),
              _ActionButton.secondary(text: '结束', onTap: onStop),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButtonGlass extends StatelessWidget {
  const _BackButtonGlass({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 18, offset: const Offset(0, 10))],
            ),
            alignment: Alignment.center,
            child: const Text('←', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _DebugToggle extends StatelessWidget {
  const _DebugToggle({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: active ? const [Color(0xFF667EEA), Color(0xFF764BA2)] : const [Color(0xFF667EEA), Color(0xFF667EEA)]),
          boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        alignment: Alignment.center,
        child: const Text('🎮', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({
    required this.minimized,
    required this.opacity,
    required this.onMove,
    required this.onToggleMinimize,
    required this.onClose,
    required this.onJump,
    required this.onReset,
  });

  final bool minimized;
  final double opacity;
  final ValueChanged<Offset> onMove;
  final VoidCallback onToggleMinimize;
  final VoidCallback onClose;
  final VoidCallback onJump;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onPanUpdate: (d) => onMove(Offset(d.delta.dx, d.delta.dy)),
          child: Container(
            width: minimized ? 140 : 180,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(minimized ? '🎮 调试' : '🎮 调试面板', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF333333))),
                    ),
                    InkWell(onTap: onToggleMinimize, child: Text(minimized ? '□' : '－', style: const TextStyle(fontWeight: FontWeight.w900))),
                    const SizedBox(width: 10),
                    InkWell(onTap: onClose, child: const Text('✕', style: TextStyle(fontWeight: FontWeight.w900))),
                  ],
                ),
                if (!minimized) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _Mini(text: '跳跃', onTap: onJump)),
                      const SizedBox(width: 8),
                      Expanded(child: _Mini(text: '重置', onTap: onReset)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('可拖拽移动', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
        ),
        alignment: Alignment.center,
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }
}

class _Grade {
  const _Grade({required this.level, required this.color, required this.text});

  final String level;
  final Color color;
  final String text;
}
