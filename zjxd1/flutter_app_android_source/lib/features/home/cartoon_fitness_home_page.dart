import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../ai_assistant/ai_assistant_page.dart';
import '../community/community_page.dart';
import '../community/moments_page.dart';
import '../report/report_code_entry_page.dart';
import '../report/report_theme.dart';
import '../fun_correction/fun_correction_page.dart';
import '../game/game_menu_page.dart';
import '../mine/mine_page.dart';
import '../posture/posture_assessment_page.dart';
import '../training/cat_stretch/cat_stretch_training_page.dart';
import '../training/hip_bridge/hip_bridge_training_page.dart';
import '../../utils/app_route_observer.dart';
import '../../utils/user_scope.dart';

class CartoonFitnessHomePage extends StatefulWidget {
  const CartoonFitnessHomePage({super.key});

  @override
  State<CartoonFitnessHomePage> createState() => _CartoonFitnessHomePageState();
}


class _CartoonFitnessHomePageState extends State<CartoonFitnessHomePage>
    with TickerProviderStateMixin, RouteAware {
  int _activeFunction = 0;
  int _tabIndex = 0;
  int _bannerIndex = 0;

  /// 【核心输出变量】页面被遮挡标记：
  /// 首页被其他页面覆盖时暂停常驻无限动画与轮播，返回时恢复
  final ValueNotifier<bool> _pageCovered = ValueNotifier<bool>(false);

  late final AnimationController _floatController;
  late final AnimationController _aiBallController;
  late final PageController _pageController;
  late final Animation<double> _decorationFloat;
  late final Animation<Offset> _aiBallFloat;

  final List<_FunctionItem> _functions = const [
    _FunctionItem(name: '脊柱检测', asset: 'assets/images/aimage/jiance.png'),
    _FunctionItem(name: '姿态矫正', asset: 'assets/images/aimage/jiaozheng.png'),
    _FunctionItem(name: 'AI助教', asset: 'assets/images/aimage/AI.png'),
    _FunctionItem(name: '社区', asset: 'assets/images/aimage/shequ.png'),
  ];

  final List<_BannerItem> _bannerItems = const [
    _BannerItem(
      startColor: '#B0E0E6', 
      endColor: '#DDA0DD', 
      image: 'assets/images/aimage/10.png',
      title: '今天也要挺挺背',
      subtitle: '3分钟可爱纠姿小训练',
    ),
    _BannerItem(
      startColor: '#FFB6C1', 
      endColor: '#FF91A4', 
      image: 'assets/images/aimage/11.png',
      title: 'AI小助手来啦',
      subtitle: '帮你发现小驼背',
    ),
    _BannerItem(
      startColor: '#FFE4B5', 
      endColor: '#FFD39B', 
      image: 'assets/images/aimage/13.png',
      title: '闯关训练',
      subtitle: '可爱奖励等你拿',
    ),
    _BannerItem(
      startColor: '#B0FFB0', 
      endColor: '#87CEEB', 
      image: 'assets/images/aimage/12.png',
      title: '成长记录',
      subtitle: '每天一点点更棒',
    ),
  ];

  final List<_ExerciseModule> _modules = const [
    _ExerciseModule(
      title: '臀桥',
      subtitle: '强化腰臀力量',
      image: 'assets/images/aimage/tunqiao.png',
      duration: '15-20分钟',
      difficulty: _Difficulty.easy,
      status: _ModuleStatus.active,
      gradientColors: [
        Color(0xFFFF6B35), 
        Color(0xFFFF8C42), 
        Color(0xFFFFAB73), 
      ],
    ),
    _ExerciseModule(
      title: '单腿臀桥转体',
      subtitle: '矫正含胸驼背',
      image: 'assets/images/aimage/dangtuitunqiao.png',
      duration: '20-30分钟',
      difficulty: _Difficulty.hard,
      status: _ModuleStatus.locked,
      gradientColors: [
        Color(0xFFFF006E), 
        Color(0xFFFF4081), 
        Color(0xFFFF6B9D), 
      ],
    ),
    _ExerciseModule(
      title: '猫式伸展',
      subtitle: '放松脊柱腰背',
      image: 'assets/images/aimage/maoshi.png',
      duration: '5-10分钟',
      difficulty: _Difficulty.easy,
      status: _ModuleStatus.active,
      gradientColors: [
        Color(0xFF00B4D8), 
        Color(0xFF00D4FF), 
        Color(0xFF5FE3FF), 
      ],
    ),
    _ExerciseModule(
      title: '侧身平板支撑',
      subtitle: '收紧腰腹核心',
      image: 'assets/images/aimage/ceshengpb.png',
      duration: '10-15分钟',
      difficulty: _Difficulty.medium,
      status: _ModuleStatus.active,
      gradientColors: [
        Color(0xFFFFB700), 
        Color(0xFFFFC947), 
        Color(0xFFFFD93D), 
      ],
    ),
    _ExerciseModule(
      title: '平衡训练',
      subtitle: '提升身体控制',
      image: 'assets/images/aimage/pingheng.png',
      duration: '15-25分钟',
      difficulty: _Difficulty.hard,
      status: _ModuleStatus.locked,
      gradientColors: [
        Color(0xFF8338EC), 
        Color(0xFF9D4EDD), 
        Color(0xFFC77DFF), 
      ],
    ),
    _ExerciseModule(
      title: '进阶臀桥扭转',
      subtitle: '强化臀肌控制',
      image: 'assets/images/aimage/tunqiao.png',
      duration: '5-8分钟',
      difficulty: _Difficulty.easy,
      status: _ModuleStatus.locked,
      gradientColors: [
        Color(0xFF10B981),
        Color(0xFF34D399),
        Color(0xFF6EE7B7),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _decorationFloat = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );


    _pageController = PageController(
      initialPage: _bannerItems.length * 500, 
      viewportFraction: 1.0,
    );

    _aiBallController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _aiBallFloat = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -6),
    ).animate(
      CurvedAnimation(parent: _aiBallController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    // 被其他页面遮挡：暂停常驻无限动画，避免不可见时持续空转占用 UI 线程与 GPU
    _pageCovered.value = true;
    _floatController.stop();
    _aiBallController.stop();
  }

  @override
  void didPopNext() {
    // 从其他页面返回：恢复常驻动画
    _pageCovered.value = false;
    if (!_floatController.isAnimating) {
      _floatController.repeat();
    }
    if (!_aiBallController.isAnimating) {
      _aiBallController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _pageCovered.dispose();
    _floatController.dispose();
    _aiBallController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _selectFunction(int index) {
    setState(() {
      _activeFunction = index;
    });

    if (index == 0) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PostureAssessmentPage()),
      );
      return;
    }

    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FunCorrectionPage()),
      );
      return;
    }

    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AiAssistantPage()),
      );
      return;
    }

    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CommunityPage()),
      );
      return;
    }

    final name = _functions[index].name;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('进入$name（示例）')),
    );
  }

  void _enterExercise(_ExerciseModule module) {
    if (module.status == _ModuleStatus.locked && !(UserScope.isDemo && UserScope.username == 'lzf')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要完成前置训练')),
      );
      return;
    }

    if (module.title == '臀桥') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HipBridgeTrainingPage()),
      );
      return;
    }

    if (module.title == '猫式伸展') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CatStretchTrainingPage()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('开始${module.title}（示例）')),
    );
  }

  void _onTabTapped(int index) {
    if (index == _tabIndex) return;
    if (index == 2) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _tabIndex = index;
    });
  }

  Widget _buildHomeBody(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
          children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
            ),
          ),
          // Decorative blobs
          Positioned(
            top: size.height * 0.1,
            left: -60,
            child: AnimatedBuilder(
              animation: _decorationFloat,
              builder: (context, _) {
                final scale = 1.0 + _decorationFloat.value * 0.1;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFFFFB366).withValues(alpha: 0.15), 
                          Color(0xFFFFCC80).withValues(alpha: 0.08), 
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: size.height * 0.2,
            right: -80,
            child: AnimatedBuilder(
              animation: _decorationFloat,
              builder: (context, _) {
                final scale = 1.0 + (1.0 - _decorationFloat.value) * 0.15;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF81C784).withValues(alpha: 0.12), 
                          Color(0xFFA5D6A7).withValues(alpha: 0.06), 
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Safe area content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 0),
                    // Banner carousel
                    _BannerSection(
                      bannerItems: _bannerItems,
                      pageController: _pageController,
                      breathAnimation: _decorationFloat,
                      covered: _pageCovered,
                    ),
                    const SizedBox(height: 28),
                    // Function tags
                    _FunctionSection(
                      functions: _functions,
                      activeIndex: _activeFunction,
                      onSelect: _selectFunction,
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '精品训练',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Exercise modules waterfall
                    _ExerciseModulesSection(
                      modules: _modules,
                      onTap: _enterExercise,
                      minHeight: math.max(0, size.height - 580),
                      bottomInset: kBottomNavigationBarHeight + MediaQuery.paddingOf(context).bottom,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // AI floating ball
          Positioned(
            right: 20,
            bottom: 100 + kBottomNavigationBarHeight,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiAssistantPage()),
                );
              },
              child: AnimatedBuilder(
                animation: _aiBallFloat,
                builder: (context, _) {
                  return Transform.translate(
                    offset: _aiBallFloat.value,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF667EEA).withValues(alpha: 0.35), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: const Color(0xFF667EEA).withValues(alpha: 0.14),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: ClipOval(
                              child: Transform.scale(
                                scale: 1.8,
                                child: Image.asset(
                                  'assets/images/xiaoplingAI.png',
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF6F7FB),
                                        border: Border.all(color: const Color(0xFF667EEA).withValues(alpha: 0.25)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.08),
                                    Colors.white.withValues(alpha: 0.00),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'AI',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildPlaceholder(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text('$title（占位页）', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: <Widget>[
          // TickerMode：非当前 Tab 时暂停其动画，避免后台页面 Ticker/整页动画空转造成卡顿
          TickerMode(enabled: _tabIndex == 0, child: _buildHomeBody(context)),
          TickerMode(enabled: _tabIndex == 1, child: const GameMenuPage()),
          TickerMode(enabled: _tabIndex == 2, child: const ReportCodeEntryPage()),
          TickerMode(enabled: _tabIndex == 3, child: const MomentsPage()),
          TickerMode(enabled: _tabIndex == 4, child: const MinePage()),
        ],
      ),
      bottomNavigationBar: _FancyBottomNavBar(
        currentIndex: _tabIndex,
        onTap: _onTabTapped,
        items: const [
          _FancyNavItem(icon: Icons.home_outlined, label: '首页'),
          _FancyNavItem(icon: Icons.flag_outlined, label: '闯关'),
          _FancyNavItem(icon: Icons.document_scanner_outlined, label: '检测报告编码', isCenter: true),
          _FancyNavItem(icon: Icons.group_outlined, label: '朋友圈'),
          _FancyNavItem(icon: Icons.person_outline, label: '我的'),
        ],
      ),
    );
  }
}

class _FancyNavItem {
  const _FancyNavItem({required this.icon, required this.label, this.isCenter = false});

  final IconData icon;
  final String label;
  final bool isCenter;
}

class _FancyBottomNavBar extends StatelessWidget {
  const _FancyBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_FancyNavItem> items;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == currentIndex;
          final isCenter = item.isCenter;
          
          return Expanded(
            child: isCenter 
              ? _FancyCenterNavBarItem(
                  icon: item.icon,
                  label: item.label,
                  selected: selected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(index);
                  },
                )
              : _FancyBottomNavBarItem(
                  icon: item.icon,
                  label: item.label,
                  selected: selected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(index);
                  },
                ),
          );
        }),
      ),
    );
  }
}

class _FancyBottomNavBarItem extends StatelessWidget {
  const _FancyBottomNavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFF111827);
    const unselectedColor = Color(0xFF9CA3AF);
    const dotColor = Color(0xFFFBBF24);
    const warmTint = Color(0xFFB45309);

    return InkResponse(
      onTap: onTap,
      radius: 32,
      splashColor: dotColor.withValues(alpha: 0.18),
      highlightColor: dotColor.withValues(alpha: 0.10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              scale: selected ? 1.12 : 1.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: selected ? const Offset(0, -0.06) : Offset.zero,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
                      builder: (context, t, _) {
                        final base = Color.lerp(unselectedColor, selectedColor, t) ?? selectedColor;
                        final tint = Color.lerp(base, warmTint, t * 0.55) ?? base;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: dotColor.withValues(alpha: 0.18 * t),
                                blurRadius: 18 * t,
                                offset: Offset(0, 8 * t),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            size: 34,
                            color: tint,
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: -2,
                      right: -6,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        scale: selected ? 1.0 : 0.0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 160),
                          opacity: selected ? 1.0 : 0.0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? selectedColor : unselectedColor,
                height: 1.0,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _FancyCenterNavBarItem extends StatelessWidget {
  const _FancyCenterNavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFF111827);
    const unselectedColor = Color(0xFF9CA3AF);
    const centerColor = ReportTheme.primary; // 娣辩豢鑹诧紝绗﹀悎鏂囨。鎵弿鐨勪笓涓氭劅
    const centerBgColor = ReportTheme.primaryLight; // 娴呯豢鑹茶儗鏅?

    return InkResponse(
      onTap: onTap,
      radius: 32,
      splashColor: centerColor.withValues(alpha: 0.18),
      highlightColor: centerColor.withValues(alpha: 0.10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(selected ? 12 : 8),
              decoration: BoxDecoration(
                color: selected ? centerColor : centerBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected ? [
                  BoxShadow(
                    color: centerColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                scale: selected ? 1.1 : 1.0,
                child: Icon(
                  icon,
                  size: selected ? 32 : 28,
                  color: selected ? Colors.white : centerColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? centerColor : unselectedColor,
                height: 1.0,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerSection extends StatefulWidget {
  const _BannerSection({
    required this.bannerItems,
    required this.pageController,
    required this.breathAnimation,
    required this.covered,
  });

  final List<_BannerItem> bannerItems;
  final PageController pageController;
  final Animation<double> breathAnimation;

  /// 首页被其他页面遮挡时为 true，自动轮播暂停翻页
  final ValueListenable<bool> covered;

  @override
  State<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<_BannerSection> {
  int _currentIndex = 0;
  Timer? _autoTimer;
  Timer? _resumeTimer;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startAutoPlay();
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      if (_userInteracting) return;
      // 页面被其他页面遮挡时不做翻页动画，避免不可见时的无效渲染
      if (widget.covered.value) return;
      if (!widget.pageController.hasClients) return;

      final current = widget.pageController.page?.round() ?? widget.pageController.initialPage;
      widget.pageController.animateToPage(
        current + 1,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _pauseAutoPlay() {
    _userInteracting = true;
    _resumeTimer?.cancel();
  }

  void _scheduleResumeAutoPlay() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 3), () {
      _userInteracting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = (screenWidth * 0.42 * 1.25).clamp(185.0, 300.0);
    final horizontalMargin = screenWidth * 0.0; // 4.w
    final bannerWidth = screenWidth - (horizontalMargin * 2); // 灞忓箷瀹藉害鍑忓幓宸﹀彸杈硅窛
    final imageSize = screenWidth * 1.084; // 390.625.w 

    return Container(
      height: bannerHeight,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: Transform.translate(
        offset: const Offset(0, 0),
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  _pauseAutoPlay();
                } else if (notification is ScrollEndNotification) {
                  _scheduleResumeAutoPlay();
                } else if (notification is UserScrollNotification) {
                  if (notification.direction == ScrollDirection.idle) {
                    _scheduleResumeAutoPlay();
                  } else {
                    _pauseAutoPlay();
                  }
                }
                return false;
              },
              child: PageView.builder(
                controller: widget.pageController,
                itemCount: widget.bannerItems.length * 1000, // 鏃犻檺寰幆
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index % widget.bannerItems.length;
                  });
                },
                itemBuilder: (context, index) {
                  final realIndex = index % widget.bannerItems.length;
                  final item = widget.bannerItems[realIndex];
                  final startColor = _colorFromHex(item.startColor);
                  final endColor = _colorFromHex(item.endColor);

                  return Container(
                    width: bannerWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [startColor, endColor],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: screenWidth * 0.030,
                          offset: Offset(0, screenWidth * 0.012),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.55),
                          blurRadius: screenWidth * 0.018,
                          offset: Offset(-screenWidth * 0.003, -screenWidth * 0.003),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            item.image,
                            width: bannerWidth,
                            height: bannerHeight,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [startColor, endColor],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  size: screenWidth * 0.12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.02),
                                  Colors.black.withValues(alpha: 0.12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 搴曢儴鍦嗙偣鎸囩ず鍣?
            Positioned(
              bottom: screenWidth * 0.020,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.bannerItems.length, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.008), // 3.w
                    width: isActive ? screenWidth * 0.05 : screenWidth * 0.019, // 18.w : 7.w
                    height: screenWidth * 0.019, // 7.w
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.004), // 1.5.w
                      color: isActive ? const Color(0xFFFF9BB3) : Colors.white.withValues(alpha: 0.45),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF9BB3).withValues(alpha: 0.45),
                                blurRadius: screenWidth * 0.010,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFromHex(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

class _FunctionSection extends StatelessWidget {
  const _FunctionSection({
    required this.functions,
    required this.activeIndex,
    required this.onSelect,
  });

  final List<_FunctionItem> functions;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  // 4涓富棰樿壊绯伙細闈掑皯骞存椿鍔涜壊褰?
  static const List<List<Color>> _themeColors = [
    [Color(0xFFFF6B6B), Color(0xFFFF8787), Color(0xFFFFA5A5)], // 娲诲姏绾?
    [Color(0xFF4ECDC4), Color(0xFF6FE6DE), Color(0xFF8FFCF5)], // 娓呮柊闈?
    [Color(0xFFFFD93D), Color(0xFFFFE066), Color(0xFFFFE99F)], // 闃冲厜榛?
    [Color(0xFFA8E6CF), Color(0xFFC3F0CA), Color(0xFFDFFAE7)], // 钖勮嵎缁?
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 24.0;
            final maxSquare = (constraints.maxWidth - gap * 3) / 4;
            final squareSize = math.min(maxSquare, maxSquare);
            final contentWidth = squareSize * 4 + gap * 3;

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: Row(
                  children: List.generate(functions.length, (index) {
                    final f = functions[index];
                    final isActive = index == activeIndex;
                    final baseTheme = _themeColors[index % _themeColors.length];
                    final themed = baseTheme
                        .map((c) => Color.lerp(c, Colors.white, 0.68)!)
                        .toList(growable: false);

                    // 统一宽度（4 等分）；高度不再等于宽度 —— 正方形放不下 4 个字标题，
                    // 改为按「图标 + 2 行标题」预留足够高度，长名称可自动换行。
                    final cardHeight = squareSize * 1.40;
                    return Padding(
                      padding: EdgeInsets.only(right: index == functions.length - 1 ? 0 : gap),
                      child: SizedBox(
                        width: squareSize,
                        height: cardHeight,
                        child: _FunctionModuleCard(
                          size: squareSize,
                          cardHeight: cardHeight,
                          function: f,
                          isActive: isActive,
                          themeColors: themed,
                          onTap: () => onSelect(index),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FunctionModuleCard extends StatefulWidget {
  const _FunctionModuleCard({
    required this.size,
    required this.cardHeight,
    required this.function,
    required this.isActive,
    required this.themeColors,
    required this.onTap,
  });

  final double size;
  final double cardHeight;
  final _FunctionItem function;
  final bool isActive;
  final List<Color> themeColors;
  final VoidCallback onTap;

  @override
  State<_FunctionModuleCard> createState() => _FunctionModuleCardState();
}

class _FunctionModuleCardState extends State<_FunctionModuleCard> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _pressController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    _pressController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, _) {
          const accent = Color(0xFF9CA3AF);
          final surface = widget.themeColors.isNotEmpty
              ? widget.themeColors.first
              : const Color(0xFFF6F7FB);
          final shadowTint = widget.themeColors.length >= 2
              ? widget.themeColors[1]
              : const Color(0xFF9CA3AF);
          return Transform.scale(
            scale: _pressAnimation.value,
            child: Container(
              height: widget.cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.size * 0.26),
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.transparent,
                  width: 0.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowTint.withValues(alpha: widget.isActive ? 0.22 : 0.14),
                    blurRadius: widget.isActive ? 16 : 12,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: const SizedBox.shrink(),
                  ),
                  // 鍐呴儴缁嗘弿杈?
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.size * 0.23),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                  
                  // 鏂滃悜楂樺厜缃?
                  const SizedBox.shrink(),
                  
                  // 宸︿笅瑙掓场娉?
                  Positioned(
                    bottom: -6,
                    left: -6,
                    child: const SizedBox.shrink(),
                  ),

                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: widget.size * 0.66,
                          height: widget.size * 0.66,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: widget.size * 0.66,
                                height: widget.size * 0.66,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(widget.size * 0.18),
                                  color: surface.withValues(alpha: 0.55),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1),
                                ),
                              ),
                              SizedBox(
                                width: widget.size * 0.44,
                                height: widget.size * 0.44,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(widget.size * 0.18),
                                  child: Image.asset(
                                    widget.function.asset,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.image,
                                          color: accent.withValues(alpha: 0.55),
                                          size: widget.size * 0.175,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // 标题固定一行显示：
                        // 用 FittedBox(scaleDown) 把整段文字等比缩放到刚好放进卡片宽度，
                        // 不会出现「姿...」这种截断（没有 ellipsis），也不会折行。
                        // fontSize 17 是上限，卡片窄时自动缩，宽时保持 17。
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                widget.function.name,
                                textAlign: TextAlign.center,
                                softWrap: false,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827)
                                      .withValues(alpha: widget.isActive ? 0.92 : 0.78),
                                  height: 1.15,
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
          );
        },
      ),
    );
  }
}

class _ExerciseModulesSection extends StatelessWidget {
  const _ExerciseModulesSection({
    required this.modules,
    required this.onTap,
    required this.minHeight,
    required this.bottomInset,
  });

  final List<_ExerciseModule> modules;
  final ValueChanged<_ExerciseModule> onTap;
  final double minHeight;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.52,
        ),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          return _ExerciseModuleCard(
            module: module,
            onTap: () => onTap(module),
          );
        },
      ),
    );
  }
}

class _ExerciseModuleCard extends StatefulWidget {
  const _ExerciseModuleCard({required this.module, required this.onTap});

  final _ExerciseModule module;
  final VoidCallback onTap;

  @override
  State<_ExerciseModuleCard> createState() => _ExerciseModuleCardState();
}

class _ExerciseModuleCardState extends State<_ExerciseModuleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    // 注意：卡片并无呼吸缩放视觉，原 repeat 会空转 6 个 Ticker 并每帧整卡重建，故不启动

    _breathAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.module.status == _ModuleStatus.locked;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 12) / 2;
    final cardHeight = cardWidth * 0.66;

    final baseColors = widget.module.gradientColors;
    final gradientColors = <Color>[baseColors.first, baseColors.last];

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(28),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: 1,
        child: AnimatedBuilder(
          animation: _breathAnimation,
          builder: (context, _) {
            return Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(-2, -4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: (widget.module.image == null || widget.module.image!.isEmpty)
                        ? const SizedBox.shrink()
                        : Image.asset(
                            widget.module.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    right: 14,
                    child: widget.module.hideLabel
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.module.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                  height: 1.40,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 7),
                              Text(
                                widget.module.subtitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                  height: 1.45,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                children: [],
                              ),
                            ],
                          ),
                  ),
                  if (locked && !(UserScope.isDemo && UserScope.username == 'lzf'))
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '🔒',
                            style: TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

String _difficultyText(_Difficulty difficulty) {
  switch (difficulty) {
    case _Difficulty.easy:
      return '简单';
    case _Difficulty.medium:
      return '中等';
    case _Difficulty.hard:
      return '困难';
  }
}

enum _ModuleStatus { active, completed, locked }

enum _Difficulty { easy, medium, hard }

class _BannerItem {
  const _BannerItem({
    required this.startColor,
    required this.endColor,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final String startColor;
  final String endColor;
  final String image;
  final String title;
  final String subtitle;
}

class _FunctionItem {
  const _FunctionItem({required this.name, required this.asset});

  final String name;
  final String asset;
}

class _ExerciseModule {
  const _ExerciseModule({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.duration,
    required this.difficulty,
    required this.status,
    required this.gradientColors,
    this.hideLabel = false,
  });

  final String title;
  final String subtitle;
  final String? image;
  final String duration;
  final _Difficulty difficulty;
  final _ModuleStatus status;
  final List<Color> gradientColors;
  final bool hideLabel;
}

// Simple Masonry Grid fallback
class MasonryGrid {
  static Widget count({
    required int crossAxisCount,
    required double mainAxisSpacing,
    required double crossAxisSpacing,
    required int itemCount,
    required NullableWidgetBuilder itemBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
        
        return Wrap(
          spacing: crossAxisSpacing,
          runSpacing: mainAxisSpacing,
          children: List.generate(itemCount, (index) {
            return SizedBox(
              width: itemWidth,
              child: itemBuilder(context, index),
            );
          }),
        );
      },
    );
  }
}

typedef NullableWidgetBuilder = Widget Function(BuildContext context, int index);
