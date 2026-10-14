import 'package:flutter/material.dart';

import '../training/cat_stretch/cat_stretch_training_page.dart';
import '../training/hip_bridge/hip_bridge_training_page.dart';

class FunCorrectionPage extends StatefulWidget {
  const FunCorrectionPage({
    super.key,
    this.guideToHipBridge = false,
  });

  final bool guideToHipBridge;

  @override
  State<FunCorrectionPage> createState() => _FunCorrectionPageState();
}

class _FunCorrectionPageState extends State<FunCorrectionPage> with SingleTickerProviderStateMixin {
  int todayCompleted = 3;
  int todayTotal = 6;
  int streakDays = 7;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _hipBridgeKey = GlobalKey();
  bool _highlightHipBridge = false;
  OverlayEntry? _hipBridgeCoach;
  late final AnimationController _fingerController;

  late final List<_ExerciseItem> dailyExercises;
  late final List<_ComboItem> comboExercises;

  @override
  void initState() {
    super.initState();

    _fingerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    dailyExercises = <_ExerciseItem>[
      _ExerciseItem(
        name: '臀桥',
        duration: '5分钟',
        difficulty: '简单',
        completed: true,
        locked: false,
        imageAsset: 'assets/images/hip-bridge-girl-illustration.png',
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF), Color(0xFFFECFEF)],
        ),
        ribbon: const _Ribbon(text: '未完成', type: _RibbonType.completed),
      ),
      _ExerciseItem(
        name: '腰椎松动',
        duration: '3分钟',
        difficulty: '简单',
        completed: true,
        locked: false,
        imageAsset: 'assets/images/lumbar-relaxation.png',
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
        ),
        ribbon: const _Ribbon(text: '未完成', type: _RibbonType.completed),
      ),
    ];

    comboExercises = <_ComboItem>[
      _ComboItem(
        name: '热身套餐',
        totalDuration: '10分钟',
        completed: true,
        locked: false,
        exercisesCount: 3,
        imageAsset: 'assets/images/warmup-package.png',
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEAA7), Color(0xFFFAB1A0)],
        ),
        ribbon: const _Ribbon(text: '推荐', type: _RibbonType.recommend),
      ),
      _ComboItem(
        name: '拉伸组合',
        totalDuration: '15分钟',
        completed: false,
        locked: false,
        exercisesCount: 3,
        imageAsset: 'assets/images/stretch-package.png',
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
        ),
        ribbon: const _Ribbon(text: '热门', type: _RibbonType.hot),
      ),
      _ComboItem(
        name: '力量训练',
        totalDuration: '20分钟',
        completed: false,
        locked: false,
        exercisesCount: 3,
        imageAsset: 'assets/images/strength-training.png',
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF74B9FF), Color(0xFF0984E3)],
        ),
        ribbon: const _Ribbon(text: '挑战', type: _RibbonType.challenge),
      ),
      _ComboItem(
        name: '协调游戏',
        totalDuration: '12分钟',
        completed: false,
        locked: true,
        exercisesCount: 3,
        imageAsset: 'assets/images/coordination-game.png',
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFD79A8), Color(0xFFE84393)],
        ),
        ribbon: const _Ribbon(text: '解锁中', type: _RibbonType.locked),
      ),
    ];

    if (widget.guideToHipBridge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _highlightHipBridge = true;
        setState(() {});
        _scrollToHipBridge();
        Future<void>.delayed(const Duration(milliseconds: 520), () {
          if (!mounted) return;
          _showHipBridgeCoachMark();
        });
      });
    }
  }

  @override
  void dispose() {
    _hipBridgeCoach?.remove();
    _fingerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHipBridge() {
    final ctx = _hipBridgeKey.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject();
    if (box is! RenderBox) return;

    final pos = box.localToGlobal(Offset.zero);
    final topPadding = MediaQuery.paddingOf(context).top;
    final target = (_scrollController.offset + pos.dy - topPadding - 120).clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _hideHipBridgeCoach() {
    _hipBridgeCoach?.remove();
    _hipBridgeCoach = null;
    if (_highlightHipBridge) {
      setState(() {
        _highlightHipBridge = false;
      });
    }
  }

  void _showHipBridgeCoachMark() {
    if (_hipBridgeCoach != null) return;

    final ctx = _hipBridgeKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox) return;

    final topLeft = box.localToGlobal(Offset.zero);
    final rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, box.size.width, box.size.height).inflate(6);

    _hipBridgeCoach = OverlayEntry(
      builder: (context) {
        final size = MediaQuery.sizeOf(context);

        final bubbleW = (size.width - 36).clamp(260.0, 420.0);
        final bubbleLeft = 18.0;
        final bubbleTop = (rect.bottom + 12).clamp(12.0, size.height - 180);

        final fingerBase = Offset(
          rect.right - 52,
          rect.bottom - 52,
        );

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _hideHipBridgeCoach,
                  child: CustomPaint(
                    painter: _CoachMarkPainter(focusRect: rect),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: rect,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _hideHipBridgeCoach();
                    _startDaily(dailyExercises.firstWhere((e) => e.name == '臀桥'));
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFF7A18), width: 2.6),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFF7A18).withValues(alpha: 0.40), blurRadius: 26, offset: const Offset(0, 12)),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: bubbleLeft,
                top: bubbleTop,
                child: Container(
                  width: bubbleW,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 10))],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('新手引导', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                      SizedBox(height: 8),
                      Text(
                        '请先选择“臀桥训练”。\n\n点击上方框选区域即可开始。',
                        style: TextStyle(fontSize: 16, height: 1.55, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              AnimatedBuilder(
                animation: _fingerController,
                builder: (context, _) {
                  final t = _fingerController.value;
                  final dy = -10 * (0.5 - (t - 0.5).abs());
                  final pulse = 0.92 + 0.10 * (0.5 - (t - 0.5).abs()) * 2;

                  return Positioned(
                    left: fingerBase.dx,
                    top: fingerBase.dy + dy,
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: pulse,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 10,
                              top: 28,
                              child: Opacity(
                                opacity: (0.25 + 0.25 * (0.5 - (t - 0.5).abs()) * 2).clamp(0.0, 0.5),
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1.2),
                                  ),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.touch_app_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                            const Positioned(
                              left: 0,
                              top: 0,
                              child: Icon(
                                Icons.touch_app_rounded,
                                size: 44,
                                color: Color(0xFFFF7A18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_hipBridgeCoach!);
  }

  void _startDaily(_ExerciseItem item) {
    if (item.locked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该项目尚未解锁')));
      return;
    }

    if (item.name == '臀桥') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HipBridgeTrainingPage()),
      );
      return;
    }

    if (item.name == '猫式伸展') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CatStretchTrainingPage()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('开始${item.name}（示例）')),
    );
  }

  void _startCombo(_ComboItem item) {
    if (item.locked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该组合尚未解锁')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('开始${item.name}（示例）')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(
                  height: 220 + topPadding,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                          child: Image.asset(
                            'assets/images/AmusementPark.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) {
                              return Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFFF9A9E), Color(0xFFA8EDEA)],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(28),
                              bottomRight: Radius.circular(28),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.10),
                                Colors.black.withValues(alpha: 0.22),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: topPadding + 22,
                        right: 18,
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Image.asset(
                            'assets/images/balloon_title.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, _, __) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      Positioned(
                        top: topPadding + 30,
                        left: 12,
                        child: Text(
                          '☁️',
                          style: TextStyle(fontSize: 38, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ),
                      Positioned(
                        top: topPadding + 58,
                        right: 120,
                        child: Text(
                          '☁️',
                          style: TextStyle(fontSize: 32, color: Colors.white.withValues(alpha: 0.80)),
                        ),
                      ),
                      Positioned(
                        top: topPadding + 98,
                        left: 160,
                        child: Text(
                          '☁️',
                          style: TextStyle(fontSize: 34, color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(18, topPadding + 64, 18, 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '趣味矫正乐园',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '和小伙伴一起快乐运动吧！',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  shadows: const [Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  _ProgressChip(
                                    emoji: '⭐',
                                    text: '今日完成 $todayCompleted/$todayTotal',
                                  ),
                                  _ProgressChip(
                                    emoji: '🎯',
                                    text: '连续打卡 $streakDays 天',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                    child: Column(
                      children: [
                        _Section(
                          icon: '🌟',
                          title: '每日必练',
                          desc: '坚持每天练习，养成好习惯',
                          child: _CardGrid(
                            itemCount: dailyExercises.length,
                            itemBuilder: (context, index) {
                              final item = dailyExercises[index];
                              final shouldGuide = widget.guideToHipBridge && item.name == '臀桥';
                              return _ExerciseCard(
                                key: shouldGuide ? _hipBridgeKey : null,
                                title: item.name,
                                subtitleLeft: item.duration,
                                subtitleRight: item.difficulty,
                                imageAsset: item.imageAsset,
                                gradient: item.gradient,
                                ribbon: item.ribbon,
                                locked: item.locked,
                                completed: item.completed,
                                highlight: shouldGuide && _highlightHipBridge,
                                onTap: () {
                                  if (shouldGuide && _highlightHipBridge) {
                                    setState(() {
                                      _highlightHipBridge = false;
                                    });
                                  }
                                  _startDaily(item);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        _Section(
                          icon: '🎪',
                          title: '组合练习',
                          desc: '多种动作组合，全面提升',
                          child: _CardGrid(
                            itemCount: comboExercises.length,
                            itemBuilder: (context, index) {
                              final item = comboExercises[index];
                              return _ExerciseCard(
                                title: item.name,
                                subtitleLeft: '${item.exercisesCount}个动作',
                                subtitleRight: item.totalDuration,
                                imageAsset: item.imageAsset,
                                gradient: item.gradient,
                                completed: item.completed,
                                locked: item.locked,
                                ribbon: item.ribbon,
                                completionEmoji: '🏆',
                                buttonText: item.locked
                                    ? '🔒 解锁中'
                                    : (item.completed ? '再次挑战' : '开始组合'),
                                buttonGradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
                                ),
                                onTap: () => _startCombo(item),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 18 + MediaQuery.paddingOf(context).bottom),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topPadding + 12,
            left: 12,
            child: _BackBubble(
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackBubble extends StatelessWidget {
  const _BackBubble({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: const Color(0xFFFFD1DC).withValues(alpha: 0.65), width: 1.2),
          ),
          alignment: Alignment.center,
          child: const Text(
            '←',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4A5568)),
          ),
        ),
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.38), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.desc,
    required this.child,
  });

  final String icon;
  final String title;
  final String desc;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4A5568)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF718096)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: itemBuilder,
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.title,
    required this.subtitleLeft,
    required this.subtitleRight,
    required this.imageAsset,
    required this.gradient,
    required this.completed,
    required this.locked,
    required this.ribbon,
    this.completionEmoji = '✅',
    this.buttonText = '开始训练',
    this.buttonGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
    ),
    required this.onTap,
    this.highlight = false,
  });

  final String title;
  final String subtitleLeft;
  final String subtitleRight;
  final String imageAsset;
  final LinearGradient gradient;
  final bool completed;
  final bool locked;
  final _Ribbon? ribbon;
  final String completionEmoji;
  final String buttonText;
  final LinearGradient buttonGradient;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(22);

    final highlightBorder = highlight
        ? BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: const Color(0xFFFF7A18), width: 2.2),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFF7A18).withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10)),
            ],
          )
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: locked ? 0.65 : 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (highlightBorder != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(decoration: highlightBorder),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Column(
                          children: [
                            Expanded(
                              flex: 7,
                              child: DecoratedBox(
                                decoration: BoxDecoration(gradient: gradient),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            center: Alignment.topLeft,
                                            radius: 1.2,
                                            colors: [
                                              Colors.white.withValues(alpha: 0.35),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.center,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final targetW = (150.0 * 1.728).clamp(0.0, constraints.maxWidth);
                                          final targetH = (115.0 * 1.728).clamp(0.0, constraints.maxHeight);

                                          return Image.asset(
                                            imageAsset,
                                            width: targetW,
                                            height: targetH,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, _, __) {
                                              return const Icon(Icons.sports_gymnastics, size: 54, color: Colors.white);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 6,
                              child: ColoredBox(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const SizedBox(height: 6),
                              Expanded(
                                child: const SizedBox.shrink(),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF4A5568),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _MetaPill(
                                            text: subtitleLeft,
                                            background: const Color(0xFF718096),
                                            alpha: 0.10,
                                            foreground: const Color(0xFF718096),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _MetaPill(
                                            text: subtitleRight,
                                            background: const Color(0xFF805AD5),
                                            alpha: 0.10,
                                            foreground: const Color(0xFF805AD5),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _StartButton(
                                      text: buttonText,
                                      gradient: buttonGradient,
                                      disabled: locked,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (ribbon != null)
                Positioned(
                  top: 10,
                  right: -22,
                  child: Transform.rotate(
                    angle: 0.65,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: _ribbonGradient(ribbon!.type),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        ribbon!.text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: ribbon!.type == _RibbonType.hot ? const Color(0xFF2D3436) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              if (completed)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF68D391), Color(0xFF38B2AC)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF68D391).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(completionEmoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.text,
    required this.background,
    required this.alpha,
    required this.foreground,
  });

  final String text;
  final Color background;
  final double alpha;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.text, required this.gradient, required this.disabled});

  final String text;
  final LinearGradient gradient;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: disabled
            ? const LinearGradient(colors: [Color(0xFFCBD5E0), Color(0xFFA0AEC0)])
            : gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF4A5568)),
      ),
    );
  }
}

LinearGradient _ribbonGradient(_RibbonType type) {
  switch (type) {
    case _RibbonType.completed:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF68D391), Color(0xFF38B2AC)],
      );
    case _RibbonType.recommend:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFBB6CE), Color(0xFFF093FB)],
      );
    case _RibbonType.hot:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFEAA7), Color(0xFFFAB1A0)],
      );
    case _RibbonType.challenge:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
      );
    case _RibbonType.locked:
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFCBD5E0), Color(0xFFA0AEC0)],
      );
  }
}

enum _RibbonType { completed, recommend, hot, challenge, locked }

class _Ribbon {
  const _Ribbon({required this.text, required this.type});

  final String text;
  final _RibbonType type;
}

class _CoachMarkPainter extends CustomPainter {
  const _CoachMarkPainter({required this.focusRect});

  final Rect focusRect;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = const Color(0xFF000000).withValues(alpha: 0.62);

    final hole = RRect.fromRectAndRadius(
      focusRect,
      const Radius.circular(22),
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(hole)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, scrim);

    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawRRect(hole, halo);
  }

  @override
  bool shouldRepaint(covariant _CoachMarkPainter oldDelegate) {
    return oldDelegate.focusRect != focusRect;
  }
}

class _ExerciseItem {
  _ExerciseItem({
    required this.name,
    required this.duration,
    required this.difficulty,
    required this.completed,
    required this.locked,
    required this.imageAsset,
    required this.gradient,
    required this.ribbon,
  });

  final String name;
  final String duration;
  final String difficulty;
  final bool completed;
  final bool locked;
  final String imageAsset;
  final LinearGradient gradient;
  final _Ribbon? ribbon;
}

class _ComboItem {
  _ComboItem({
    required this.name,
    required this.totalDuration,
    required this.completed,
    required this.locked,
    required this.exercisesCount,
    required this.imageAsset,
    required this.gradient,
    required this.ribbon,
  });

  final String name;
  final String totalDuration;
  final bool completed;
  final bool locked;
  final int exercisesCount;
  final String imageAsset;
  final LinearGradient gradient;
  final _Ribbon? ribbon;
}
