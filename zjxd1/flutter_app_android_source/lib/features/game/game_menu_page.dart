import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'camera_jump_challenge_page.dart';
import 'challenge_prepare_page.dart';
import 'jump_challenge_page.dart';
import '../../utils/app_logger.dart';
import '../../utils/user_scope.dart';

class GameMenuPage extends StatefulWidget {
  const GameMenuPage({super.key, this.userId = 128});

  final int userId;

  @override
  State<GameMenuPage> createState() => _GameMenuPageState();
}

class _GameMenuPageState extends State<GameMenuPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _effectsEnabled = false;

  bool _imagesPrecached = false;

  late int _userId;

  int currentSceneIndex = 0;

  int currentLevel = 0;
  int unlockedLevel = 2;

  int previousScore = 500;
  int displayScore = 1000;

  // 【核心输出变量】右上角金币数：启动时从本地读取，通关返回后自动累加刷新
  int _coin = 0;

  late List<_GameScene> gameScenes;
  late List<_GameLevel> levels;

  // 金币本地存储键（按账号隔离）
  String get _coinKey {
    final user = (UserScope.username ?? '').trim();
    return 'game_coins_${user.isEmpty ? 'guest' : user}';
  }

  Future<void> _loadCoins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_coinKey);
      final next = saved ?? displayScore;
      if (saved == null) {
        await prefs.setInt(_coinKey, next);
      }
      if (!mounted) return;
      setState(() {
        previousScore = _coin;
        _coin = next;
      });
    } catch (e, st) {
      AppLogger.e('游戏菜单', e, st);
    }
  }

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000));
    _switchDataByUserId(_userId);
    _coin = displayScore;
    _loadCoins();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _effectsEnabled = true;
        });
        _controller.repeat();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_imagesPrecached) return;
    _imagesPrecached = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final assets = <String>{
        _backgroundImage,
        'assets/images/jiuse.png',
        'assets/images/scene-selection.png',
        'assets/images/koukoutu.com-1762593085873pACSLcNH/magic-gold-coin.png',
      };

      for (var i = 0; i < levels.length; i++) {
        assets.add(_LevelPathScroll._levelImageAsset(i, _userId == 128 || _userId == 129));
      }

      for (final a in assets) {
        precacheImage(AssetImage(a), context);
      }
    });
  }

  void _switchDataByUserId(int userId) {
    if (userId == 129) {
      gameScenes = List.unmodifiable(_scenes128);
      levels = List.unmodifiable(_levels129);
      unlockedLevel = 3;
      currentLevel = unlockedLevel - 1;
      previousScore = 200;
      displayScore = 600;
    } else if (userId == 128) {
      gameScenes = List.unmodifiable(_scenes128);
      levels = List.unmodifiable(_levels128);
      unlockedLevel = 2;
      currentLevel = unlockedLevel - 1;
      previousScore = 500;
      displayScore = 1000;
    } else {
      gameScenes = List.unmodifiable(_scenes128);
      levels = List.unmodifiable(_levels128);
      unlockedLevel = 3;
      currentLevel = unlockedLevel - 1;
      previousScore = 100;
      displayScore = 300;
    }

    // 为演示账号lzf设置专门的关卡数据
    if (UserScope.isDemo && UserScope.username == 'lzf') {
      final levelsForUserB = [
        _GameLevel(id: 1, name: '井冈山', completed: false, description: '学习基本矫正方法', color: Color(0xFF4FACFE)),
        _GameLevel(id: 2, name: '遵义', completed: false, description: '伸展运动', color: Color(0xFF7C4DFF)), // 修改为"伸展运动"，账号B遵义弹窗颜色
        _GameLevel(id: 3, name: '泸定桥', completed: false, description: '应对移动平台', color: Color(0xFFFA709A)),
        _GameLevel(id: 4, name: '夹金山', completed: false, description: '多重障碍组合', color: Color(0xFFFECA57)),
        _GameLevel(id: 5, name: '松潘草地', completed: false, description: '终极跳跃挑战', color: Color(0xFFFF6B6B)),
      ];
      levels = List.unmodifiable(levelsForUserB);
      currentLevel = 2; // 第三关（索引为2）
    }

    // 为演示账号a设置遵义关卡为"腿部左右摆荡"
    if (UserScope.username == 'a') {
      levels = List.unmodifiable([
        for (final l in levels)
          (l.name == '遵义')
              ? _GameLevel(id: l.id, name: l.name, completed: l.completed, description: '腿部左右摆荡', color: l.color)
              : l,
      ]);
    }

    currentSceneIndex = 0;
  }

  String get _backgroundImage => gameScenes[currentSceneIndex].imageAsset;

  void _selectLevel(int index) {
    if (index + 1 > unlockedLevel && !(UserScope.isDemo && UserScope.username == 'lzf' && index == 2)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF333333),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '请先通过前面的关卡',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      currentLevel = index;
    });

    _showLevelDialog(levels[index]);
  }

  Future<void> _showLevelDialog(_GameLevel level) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: level.color.withOpacity(0.3), width: 2),
          ),
          elevation: 12,
          shadowColor: level.color.withOpacity(0.2),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  level.color.withOpacity(0.1),
                  level.color.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Text(
              level.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF333333),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          content: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  level.color.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              level.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF555555),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.grey.withValues(alpha: 0.1), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  foregroundColor: const Color(0xFF666666),
                ),
                child: const Text('关闭', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _startGame();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: const Text('开始', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startGame() {
    if (currentLevel + 1 > unlockedLevel && !(UserScope.isDemo && UserScope.username == 'lzf' && currentLevel == 2)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF333333),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '请先通过前面的关卡',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final level = levels[currentLevel];

    // 为不同账号设置自定义任务参数
    int targetCount = 5;  // 默认5次
    int timeLimitSeconds = 60;
    int difficulty = 1;

    // 遵义关卡特殊处理：账号a适合体力/协调能力不太好的用户，账号lzf增加难度
    if (level.name == '遵义') {
      if (UserScope.isDemo && UserScope.username == 'lzf') {
        // 账号lzf：高难度挑战
        targetCount = 20;  // 大幅增加目标数量
        timeLimitSeconds = 45;  // 大幅减少时间限制
        difficulty = 3;  // 高难度
      } else {
        // 账号a：适合体力/协调能力不太好的用户
        targetCount = 10;  // 更少的目标数量
        timeLimitSeconds = 80;  // 更多时间
        difficulty = 0;  // 较低难度
      }
    } else if (UserScope.isDemo && UserScope.username == 'lzf') {
      // 其他关卡账号lzf的设置
      switch (level.name) {
        case '井冈山':
          targetCount = 8;
          timeLimitSeconds = 50;
          difficulty = 0;
          break;
        case '泸定桥':
          targetCount = 15;  // 增加目标数量
          timeLimitSeconds = 80;  // 增加时间限制
          difficulty = 2;  // 提高难度
          break;
        case '夹金山':
          targetCount = 20;  // 增加目标数量
          timeLimitSeconds = 90;  // 增加时间限制
          difficulty = 3;  // 更高难度
          break;
        case '松潘草地':
          targetCount = 25;  // 增加目标数量
          timeLimitSeconds = 100;  // 增加时间限制
          difficulty = 4;  // 最高难度
          break;
      }
    }

    final challengeLevel = JumpChallengeLevel(
      id: level.id,
      name: level.name,
      type: 'neck',
      actionName: level.name,
      actionDescription: level.description,
      targetCount: targetCount,
      timeLimitSeconds: timeLimitSeconds,
      difficulty: difficulty,
      description: level.description,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChallengePreparePage(
          pageTitle: level.name,
          challengeLevel: challengeLevel,
          backgroundAsset: 'assets/images/sucai.png',
          levelName: level.name,
          levelDescription: level.description,
          levelColor: level.color,
        ),
      ),
    ).then((_) => _loadCoins()); // 挑战结束返回后刷新右上角金币
  }

  Future<void> _showSceneSelector() async {
    final selected = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _SceneSelectorDialog(
          scenes: gameScenes,
          currentIndex: currentSceneIndex,
        );
      },
    );

    if (!mounted) return;
    if (selected == null) return;

    setState(() {
      currentSceneIndex = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final effectsController = _effectsEnabled ? _controller : const AlwaysStoppedAnimation<double>(0.0);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _backgroundImage,
              fit: BoxFit.cover,
              alignment: const Alignment(-0.6, 0),
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.20)),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: _effectsEnabled
                  ? AnimatedBuilder(
                      animation: effectsController,
                      builder: (context, _) {
                        return RepaintBoundary(
                          child: CustomPaint(
                            painter: _SparklePainter(progress: effectsController.value),
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _LevelPathScroll(
                      controller: effectsController,
                      levels: levels,
                      currentLevel: currentLevel,
                      unlockedLevel: unlockedLevel,
                      userAvatarAsset: 'assets/images/jiuse.png',
                      useLongMarchImages: _userId == 128 || _userId == 129,
                      onSelectLevel: _selectLevel,
                      onStart: _startGame,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 8, 
                    child: Transform.scale(
                      scale: 1.5,
                      alignment: Alignment.topLeft,
                      child: _GlassPillButton(
                        onTap: _showSceneSelector,
                        iconAsset: 'assets/images/scene-selection.png',
                        text: '场景',
                        shimmer: effectsController,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Transform.scale(
                      scale: 1.5,
                      alignment: Alignment.topRight,
                      child: _ScorePill(
                        previousScore: previousScore,
                        score: _coin,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: padding.top + 12,
                    child: const IgnorePointer(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelPathScroll extends StatelessWidget {
  const _LevelPathScroll({
    required this.controller,
    required this.levels,
    required this.currentLevel,
    required this.unlockedLevel,
    required this.userAvatarAsset,
    required this.useLongMarchImages,
    required this.onSelectLevel,
    required this.onStart,
  });

  final Animation<double> controller;
  final List<_GameLevel> levels;
  final int currentLevel;
  final int unlockedLevel;
  final String userAvatarAsset;
  final bool useLongMarchImages;
  final ValueChanged<int> onSelectLevel;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final count = levels.length;
    final height = (count * 175.0) + 215.0; // 减少高度25px

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 86),
        child: Column(
          children: [
            SizedBox(
              height: height,
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final positions = List.generate(count, (i) => _nodeOffset(w, i));

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: controller,
                            builder: (context, _) {
                              return RepaintBoundary(
                                child: CustomPaint(
                                  painter: _ConnectionPainter(
                                    progress: controller.value,
                                    positions: positions,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      for (var i = 0; i < count; i++)
                        Positioned(
                          left: positions[i].dx,
                          top: positions[i].dy,
                          child: Transform(
                            transform: Matrix4.identity()
                              ..translate(-52.0, -58.0)
                              ..scale(-1.15, 1.15, 1.15), // 负的x缩放实现镜像翻转
                            alignment: Alignment.center,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                              child: _LevelNode(
                                index: i,
                                level: levels[i],
                                isLocked: (i + 1) > unlockedLevel,
                                isCurrent: currentLevel == i,
                                isCompleted: levels[i].completed,
                                levelImageAsset: _levelImageAsset(i, useLongMarchImages),
                                userAvatarAsset: userAvatarAsset,
                                onTap: () => onSelectLevel(i),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _StartGameButton(onTap: onStart),
            ),
          ],
        ),
      ),
    );
  }

  static Offset _nodeOffset(double width, int index) {
    const baseY = 100.0;
    const spacing = 180.0;
    final y = baseY + index * spacing;
    // 修复布局计算，确保节点在正确的位置且不会拉伸
    final xFrac = index.isEven ? 0.25 : 0.75; // 调整位置比例
    final xOffset = (width * xFrac).clamp(50.0, width - 180.0); // 限制x坐标范围
    return Offset(xOffset, y);
  }

  static String _levelImageAsset(int index, bool useLongMarch) {
    // 使用 images 目录下的图片作为关卡图标
    const longMarch = [
      'assets/images/jingangshang.png',  // 井冈山
      'assets/images/zunyi.png',         // 遵义
      'assets/images/ludipiao.png',      // 泸定桥
      'assets/images/jinjiashan.png',    // 夹金山
      'assets/images/songpancaodi.png', // 松潘草地
    ];

    const antiWar = [
      'assets/images/aimage/9.png',      // 沈阳
      'assets/images/aimage/10.png',     // 北平卢沟桥
      'assets/images/aimage/11.png',     // 上海
      'assets/images/aimage/12.png',     // 台儿庄
      'assets/images/aimage/13.png',     // 晋察冀
    ];

    final list = useLongMarch ? longMarch : antiWar;
    return list[index % list.length];
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.index,
    required this.level,
    required this.isLocked,
    required this.isCurrent,
    required this.isCompleted,
    required this.levelImageAsset,
    required this.userAvatarAsset,
    required this.onTap,
  });

  final int index;
  final _GameLevel level;
  final bool isLocked;
  final bool isCurrent;
  final bool isCompleted;
  final String levelImageAsset;
  final String userAvatarAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final boxShadow = <BoxShadow>[];
    if (isCurrent) {
      boxShadow.add(const BoxShadow(color: Color(0x99FFD700), blurRadius: 16, offset: Offset(0, 0)));
    } else if (isCompleted) {
      boxShadow.add(const BoxShadow(color: Color(0x804FACFE), blurRadius: 14, offset: Offset(0, 0)));
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(60),
      child: SizedBox(
        width: 120,
        child: Column(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isCurrent ? 1.05 : 1.0,
              child: Container(
                width: 120, 
                height: 120, 
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: boxShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColorFiltered(
                          colorFilter: isLocked
                              ? const ColorFilter.mode(Color(0x33000000), BlendMode.srcATop)
                              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                          child: Image.asset(
                            levelImageAsset,
                            fit: BoxFit.contain, // 改为contain避免拉伸
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF111827)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 6,
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 22,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: _levelNumberGradient(level, isLocked: isLocked, isCurrent: isCurrent, isCompleted: isCompleted),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.20),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, height: 1), // 从12增加到15 (放大25%)
                            ),
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Positioned(
                          top: 14,
                          right: 6,
                          child: Transform.scale(
                            scale: 1.5,
                            alignment: Alignment.topRight,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  userAvatarAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (isCompleted)
                        const Positioned(
                          top: -6,
                          right: -6,
                          child: Text('⭐', style: TextStyle(fontSize: 16)),
                        ),
                      // 在演示账号lzf下不显示第三关泸定桥的锁图标
                      if (isLocked && !(UserScope.isDemo && UserScope.username == 'lzf' && index == 2))
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              width: 56, 
                              height: 56, 
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.25),
                              ),
                              alignment: Alignment.center,
                              child: const Text('🔒', style: TextStyle(fontSize: 24)), // 从18增加到24 (放大1/3)
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: const BoxConstraints(maxWidth: 140),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.60),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.60),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1),
              ),
              child: Text(
                level.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Gradient _levelNumberGradient(
    _GameLevel level, {
    required bool isLocked,
    required bool isCurrent,
    required bool isCompleted,
  }) {
    if (isCompleted) {
      return const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF4DA3FF)]);
    }
    if (isLocked) {
      return const LinearGradient(colors: [Color(0xFFF77062), Color(0xFFFE5196)]);
    }
    if (isCurrent) {
      return const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFF59E0B)]);
    }
    return LinearGradient(colors: [level.color, _darken(level.color, 0.20)]);
  }

  static Color _darken(Color c, double amount) {
    final f = (1 - amount).clamp(0.0, 1.0);
    return Color.fromARGB(c.alpha, (c.red * f).round(), (c.green * f).round(), (c.blue * f).round());
  }
}

class _StartGameButton extends StatelessWidget {
  const _StartGameButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA500).withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          '开始游戏',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.size, required this.onTap, required this.child});

  final double size;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.92),
                Colors.white.withValues(alpha: 0.82),
              ],
            ),
            border: Border.all(color: Colors.black.withValues(alpha: 0.10), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 10),
              )
            ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _GlassPillButton extends StatelessWidget {
  const _GlassPillButton({
    required this.onTap,
    required this.iconAsset,
    required this.text,
    required this.shimmer,
  });

  final VoidCallback onTap;
  final String iconAsset;
  final String text;
  final Animation<double> shimmer;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.92),
                Colors.white.withValues(alpha: 0.82),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.black.withValues(alpha: 0.10), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                iconAsset,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(width: 18, height: 18),
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF333333)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.previousScore, required this.score});

  final int previousScore;
  final int score;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.92),
              Colors.white.withValues(alpha: 0.82),
            ],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.30), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFFFFC107).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 20,
              child: OverflowBox(
                maxWidth: 81,
                maxHeight: 81,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/金币.png',
                  width: 81,
                  height: 81,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 6),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: previousScore, end: score),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF8F00),
                    shadows: [Shadow(color: Color(0x4DFF8F00), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneSelectorDialog extends StatelessWidget {
  const _SceneSelectorDialog({required this.scenes, required this.currentIndex});

  final List<_GameScene> scenes;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: const Color(0xFF8A2BE2).withOpacity(0.2), width: 2),
      ),
      elevation: 16,
      shadowColor: const Color(0xFF8A2BE2).withOpacity(0.15),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        // 限制最大高度：横屏/小屏时弹窗不能超过可用高度，否则内部 Column 会溢出
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.of(context).size.height - 48,
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '选择游戏场景',
                        style: TextStyle(
                          fontSize: 20, // 从18增加到20
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36, // 从40减少到36
                        height: 36, // 从40减少到36
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(18), // 从20减少到18
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18, // 从20减少到18
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
              Flexible(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  shrinkWrap: true,
                  itemCount: scenes.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 21, 
                    mainAxisSpacing: 21, 
                    // 1.15 时格子高度≈156px，与卡片内容（图60+标题+2行描述+内外边距）几乎相等，
                    // 字形差异就会 BOTTOM OVERFLOWED 22 / 8.3 像素。降到 1.0 留出约 25px 余量。
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final s = scenes[index];
                    final active = index == currentIndex;
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(index),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16), // 从21减少到16，给内容更多空间 
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFF8F9FA),
                          border: Border.all(color: active ? const Color(0xFF8A2BE2) : Colors.transparent, width: 2),
                          gradient: active
                              ? const LinearGradient(colors: [Color(0xFFF8F9FF), Color(0xFFE8E0FF)])
                              : null,
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF8A2BE2).withValues(alpha: 0.30),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  )
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: Image.asset(
                                      s.imageAsset,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  s.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF333333)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF666666), height: 1.3),
                                ),
                              ],
                            ),
                            if (active)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8A2BE2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text('已选择', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
        ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    const cellW = 320.0;
    const cellH = 160.0;

    final cols = (size.width / cellW).ceil() + 1;
    final rows = (size.height / cellH).ceil() + 1;

    final t = (math.sin(progress * math.pi * 2) * 0.15) + 0.85;

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final base = Offset(x * cellW, y * cellH);

        for (final s in const [
          Offset(30, 40),
          Offset(140, 110),
          Offset(240, 60),
        ]) {
          final p = base + s;
          final alpha = (0.35 + ((p.dx + p.dy) % 11) / 30) * t;
          paint.color = Colors.white.withValues(alpha: alpha.clamp(0.0, 0.9));
          canvas.drawCircle(p, (((p.dx + p.dy) % 2) + 0.8) * 0.9, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConnectionPainter extends CustomPainter {
  _ConnectionPainter({required this.progress, required this.positions});

  final double progress;
  final List<Offset> positions;

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;

    for (var i = 0; i < positions.length - 1; i++) {
      final a = positions[i] + const Offset(0, 0);
      final b = positions[i + 1] + const Offset(0, 0);

      final rect = Rect.fromPoints(a, b);
      final shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.40),
          Colors.white.withValues(alpha: 0.80),
          const Color(0xFF6E9BFF).withValues(alpha: 0.80),
          Colors.white.withValues(alpha: 0.80),
          Colors.white.withValues(alpha: 0.40),
        ],
        stops: const [0, 0.25, 0.5, 0.75, 1],
        transform: _SlideGradientTransform(dx: -2 + progress * 4),
      ).createShader(rect);

      final paint = Paint()
        ..shader = shader
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.positions != positions;
  }
}

class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform({required this.dx});

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * dx, 0, 0);
  }
}

class _GameScene {
  const _GameScene({required this.id, required this.name, required this.imageAsset, required this.description});

  final int id;
  final String name;
  final String imageAsset;
  final String description;
}

class _GameLevel {
  const _GameLevel({
    required this.id,
    required this.name,
    required this.description,
    required this.completed,
    required this.color,
  });

  final int id;
  final String name;
  final String description;
  final bool completed;
  final Color color;
}

const _scenes128 = [
  _GameScene(
    id: 1,
    name: '长征之路',
    imageAsset: 'assets/images/changzheng.png',
    description: '重走革命先辈的长征之路',
  ),
  _GameScene(
    id: 2,
    name: '井冈山基地',
    imageAsset: 'assets/images/jingangshang.png',
    description: '革命摇篮，星火燎原之地',
  ),
  _GameScene(
    id: 3,
    name: '泸定桥',
    imageAsset: 'assets/images/ludipiao.png',
    description: '飞夺泸定桥，英勇无畏',
  ),
  _GameScene(
    id: 4,
    name: '夹金山',
    imageAsset: 'assets/images/jinjiashan.png',
    description: '翻越雪山，挑战极限',
  ),
  _GameScene(
    id: 5,
    name: '松潘草地',
    imageAsset: 'assets/images/songpancaodi.png',
    description: '穿越草地，艰苦跋涉',
  ),
];

const _levels128 = [
  _GameLevel(id: 1, name: '井冈山', completed: false, description: '学习基本矫正方法', color: Color(0xFF4FACFE)),
  _GameLevel(id: 2, name: '遵义', completed: false, description: '腰椎松动', color: Color(0xFF43E97B)),
  _GameLevel(id: 3, name: '泸定桥', completed: false, description: '应对移动平台', color: Color(0xFFFA709A)),
  _GameLevel(id: 4, name: '夹金山', completed: false, description: '多重障碍组合', color: Color(0xFFFECA57)),
  _GameLevel(id: 5, name: '松潘草地', completed: false, description: '终极跳跃挑战', color: Color(0xFFFF6B6B)),
];

const _levels129 = [
  _GameLevel(id: 1, name: '井冈山', completed: false, description: '学习基本矫正方法', color: Color(0xFFFF4757)),
  _GameLevel(id: 2, name: '遵义', completed: false, description: '脊柱侧向伸展', color: Color(0xFF2ED573)),
  _GameLevel(id: 3, name: '泸定桥', completed: false, description: '应对移动平台', color: Color(0xFFFFA502)),
  _GameLevel(id: 4, name: '夹金山', completed: false, description: '多重障碍组合', color: Color(0xFF3742FA)),
  _GameLevel(id: 5, name: '松潘草地', completed: false, description: '终极跳跃挑战', color: Color(0xFFFF3838)),
];
