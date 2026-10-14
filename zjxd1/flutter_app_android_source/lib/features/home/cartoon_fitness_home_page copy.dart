import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai_assistant/ai_assistant_page.dart';
import '../community/community_page.dart';
import '../community/moments_page.dart';
import '../fun_correction/fun_correction_page.dart';
import '../game/game_menu_page.dart';
import '../mine/mine_page.dart';
import '../posture/posture_assessment_page.dart';
import '../training/cat_stretch/cat_stretch_training_page.dart';
import '../training/hip_bridge/hip_bridge_training_page.dart';

class CartoonFitnessHomePage extends StatefulWidget {
  const CartoonFitnessHomePage({super.key});

  @override
  State<CartoonFitnessHomePage> createState() => _CartoonFitnessHomePageState();
}

class _CartoonFitnessHomePageState extends State<CartoonFitnessHomePage>
    with TickerProviderStateMixin {
  int _activeFunction = 0;
  int _tabIndex = 0;
  int _bannerIndex = 0;
  bool _showAiBall = true;

  late final AnimationController _floatController;
  late final AnimationController _bannerController;
  late final AnimationController _aiBallController;
  late final PageController _pageController;
  late final Animation<double> _decorationFloat;
  late final Animation<Offset> _aiBallFloat;

  final List<_FunctionItem> _functions = const [
    _FunctionItem(name: '体态评估', asset: 'assets/images/aimage/1.png'),
    _FunctionItem(name: '姿态矫正', asset: 'assets/images/aimage/2.png'),
    _FunctionItem(name: 'AI助教', asset: 'assets/images/aimage/3.png'),
    _FunctionItem(name: '社区', asset: 'assets/images/aimage/4.png'),
  ];

  final List<_BannerItem> _bannerItems = const [
    _BannerItem(
      startColor: '#B0E0E6', // 浅蓝
      endColor: '#DDA0DD', // 紫粉
      image: 'assets/images/aimage/10.png',
      title: '今天也要挺挺背',
      subtitle: '3分钟可爱纠姿小训练',
    ),
    _BannerItem(
      startColor: '#FFB6C1', // 浅粉
      endColor: '#FF91A4', // 玫粉
      image: 'assets/images/aimage/11.png',
      title: 'AI小助手来啦',
      subtitle: '帮你发现小驼背',
    ),
    _BannerItem(
      startColor: '#FFE4B5', // 浅橙
      endColor: '#FFD39B', // 橙黄
      image: 'assets/images/aimage/13.png',
      title: '闯关训练',
      subtitle: '可爱奖励等你拿',
    ),
    _BannerItem(
      startColor: '#B0FFB0', // 浅绿
      endColor: '#87CEEB', // 天蓝
      image: 'assets/images/aimage/12.png',
      title: '成长记录',
      subtitle: '每天一点点更棒',
    ),
  ];

  final List<_ExerciseModule> _modules = const [
    _ExerciseModule(
      title: '臀桥',
      subtitle: '强化腰臀力量',
      image: 'assets/images/hip-bridge-1.png',
      duration: '15-20分钟',
      difficulty: _Difficulty.easy,
      status: _ModuleStatus.active,
      gradientColors: [
        Color(0xFFFFE5B4), // 浅橙
        Color(0xFFFCB69F), // 中橙
        Color(0xFFE67E50), // 深橙
      ],
    ),
    _ExerciseModule(
      title: '单推臀桥训练',
      subtitle: '矫正含胸驼背',
      image: 'assets/images/single-leg-hip-bridge.png',
      duration: '20-30分钟',
      difficulty: _Difficulty.hard,
      status: _ModuleStatus.locked,
      gradientColors: [
        Color(0xFFFFB3E6), // 浅粉
        Color(0xFFF093FB), // 中粉
        Color(0xFFD946EF), // 深粉
      ],
    ),
    _ExerciseModule(
      title: '猫式伸展',
      subtitle: '放松脊柱腰背',
      image: 'assets/images/cartoon-girl-cat-stretch.png',
      duration: '5-10分钟',
      difficulty: _Difficulty.easy,
      status: _ModuleStatus.active,
      gradientColors: [
        Color(0xFFE8F5E8), // 浅绿
        Color(0xFF81C784), // 中绿
        Color(0xFF4CAF50), // 深绿
      ],
    ),
    _ExerciseModule(
      title: '侧身平板支撑',
      subtitle: '收紧腰腹核心',
      image: "assets/images/side-plank-support.png",
      duration: '10-15分钟',
      difficulty: _Difficulty.medium,
      status: _ModuleStatus.active,
      gradientColors: [
        Color(0xFFE3F2FD), // 浅蓝
        Color(0xFF64B5F6), // 中蓝
        Color(0xFF2196F3), // 深蓝
      ],
    ),
    _ExerciseModule(
      title: '平衡训练',
      subtitle: '提升身体控制',
      image: 'assets/images/balance-training.png',
      duration: '15-25分钟',
      difficulty: _Difficulty.hard,
      status: _ModuleStatus.locked,
      gradientColors: [
        Color(0xFFFCE4EC), // 浅紫
        Color(0xFFBA68C8), // 中紫
        Color(0xFF9C27B0), // 深紫
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

    // 初始化轮播控制器到中间位置，实现无限循环
    _pageController = PageController(
      initialPage: _bannerItems.length * 500, // 中间位置
      viewportFraction: 1.0,
    );

    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _aiBallController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _aiBallFloat = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -10),
    ).animate(CurvedAnimation(parent: _aiBallController, curve: Curves.easeInOut));

    // Auto hide AI ball after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showAiBall = false;
        });
      }
    });

    // Auto banner
    _startBannerAutoPlay();
  }

  void _startBannerAutoPlay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      _startBannerAutoPlay();
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _bannerController.dispose();
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
    if (module.status == _ModuleStatus.locked) {
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
    setState(() {
      _tabIndex = index;
    });
  }

  void _resetAiBall() {
    setState(() {
      _showAiBall = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showAiBall = false;
        });
      }
    });
  }

  Widget _buildHomeBody(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: _resetAiBall,
      child: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE3F2FD),
                    Color(0xFFBBDEFB),
                    Color(0xFF90CAF9),
                  ],
                ),
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
                      color: Colors.white.withValues(alpha: 0.08),
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
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                );
              },
            ),
          ),
          // Safe area content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Banner carousel
                  _BannerSection(
                    bannerItems: _bannerItems,
                    pageController: _pageController,
                    breathAnimation: _decorationFloat,
                  ),
                  const SizedBox(height: 24),
                  // Function tags
                  _FunctionSection(
                    functions: _functions,
                    activeIndex: _activeFunction,
                    onSelect: _selectFunction,
                  ),
                  const SizedBox(height: 24),
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
          // AI floating ball
          if (_showAiBall)
            Positioned(
              right: 20,
              bottom: 100 + kBottomNavigationBarHeight,
              child: AnimatedBuilder(
                animation: _aiBallFloat,
                builder: (context, _) {
                  return Transform.translate(
                    offset: _aiBallFloat.value,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
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
        children: [
          _buildHomeBody(context),
          const GameMenuPage(),
          const MomentsPage(),
          const MinePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF667EEA),
        unselectedItemColor: const Color(0xFF718096),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.flag_rounded), label: '闯关'),
          BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: '朋友圈'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: '我的'),
        ],
      ),
    );
  }
}

class _BannerSection extends StatefulWidget {
  const _BannerSection({
    required this.bannerItems,
    required this.pageController,
    required this.breathAnimation,
  });

  final List<_BannerItem> bannerItems;
  final PageController pageController;
  final Animation<double> breathAnimation;

  @override
  State<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<_BannerSection> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 监听页面变化
    widget.pageController.addListener(() {
      final page = widget.pageController.page;
      if (page != null) {
        setState(() {
          _currentIndex = page!.round() % widget.bannerItems.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 0.35; // 132.w + 80.w = 212.w
    final horizontalMargin = screenWidth * 0.04; // 4.w
    final bannerWidth = screenWidth - (horizontalMargin * 2); // 屏幕宽度减去左右边距
    final imageSize = screenWidth * 1.084; // 390.625.w (假设屏幕基准360.w)
    
    return AnimatedBuilder(
      animation: widget.breathAnimation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, widget.breathAnimation.value * -2), // 轻微呼吸动画 -2.w
          child: Container(
            height: bannerHeight,
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
            child: Stack(
              children: [
                PageView.builder(
                  controller: widget.pageController,
                  itemCount: widget.bannerItems.length * 1000, // 无限循环
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
                        borderRadius: BorderRadius.circular(screenWidth * 0.08), // 28.w
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [startColor, endColor],
                        ),
                        boxShadow: [
                          // 主阴影（彩色投影）
                          BoxShadow(
                            color: startColor.withValues(alpha: 0.35),
                            blurRadius: screenWidth * 0.022, // 22.w
                            offset: Offset(0, screenWidth * 0.01), // 10.w
                          ),
                          // 高光阴影（白色提亮）
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.85),
                            blurRadius: screenWidth * 0.012, // 12.w
                            offset: Offset(-screenWidth * 0.004, -screenWidth * 0.004), // -4.w, -4.w
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // 背景图片（全屏显示）
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
                        ],
                      ),
                    );
                  },
                ),
                // 底部圆点指示器
                Positioned(
                  bottom: screenWidth * 0.025, // 9.w
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
                          color: isActive ? const Color(0xFFFF9BB3) : Colors.white.withValues(alpha: 0.4),
                          boxShadow: isActive ? [
                            BoxShadow(
                              color: const Color(0xFFFF9BB3).withValues(alpha: 0.5),
                              blurRadius: screenWidth * 0.008, // 3.w
                              offset: const Offset(0, 1),
                            ),
                          ] : null,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  // 4个主题色系：桃色、薄荷绿、奶油色、薰衣草紫
  static const List<List<Color>> _themeColors = [
    [Color(0xFFFFD4A3), Color(0xFFFFB74D), Color(0xFFFF9800)], // 桃色系
    [Color(0xFFC8E6C9), Color(0xFF81C784), Color(0xFF4CAF50)], // 薄荷绿
    [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFFC107)], // 奶油色
    [Color(0xFFE1BEE7), Color(0xFFBA68C8), Color(0xFF9C27B0)], // 薰衣草紫
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(functions.length, (index) {
          final f = functions[index];
          final isActive = index == activeIndex;
          
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.012),
              child: _FunctionModuleCard(
                function: f,
                isActive: isActive,
                themeColors: _themeColors[index],
                onTap: () => onSelect(index),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FunctionModuleCard extends StatefulWidget {
  const _FunctionModuleCard({
    required this.function,
    required this.isActive,
    required this.themeColors,
    required this.onTap,
  });

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
          return Transform.scale(
            scale: _pressAnimation.value,
            child: Container(
              height: MediaQuery.of(context).size.width * 0.667 / 4, // 宽度的三分之二再除以4（四等分）
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.032),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.themeColors.map((color) => 
                    color.withValues(alpha: widget.isActive ? 1.0 : 0.7)
                  ).toList(),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: widget.isActive ? 0.8 : 0.4),
                  width: widget.isActive ? 2.0 : 1.5,
                ),
                boxShadow: [
                  // 彩色主阴影
                  BoxShadow(
                    color: widget.themeColors.last.withValues(alpha: 
                      widget.isActive ? 0.3 : 0.15),
                    blurRadius: widget.isActive ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                  // 白色高光阴影
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
                  // 内部细描边
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.028),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                  
                  // 斜向高光罩
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.032),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.4),
                            Colors.white.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // 右上角泡泡
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.6),
                            Colors.white.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // 左下角泡泡
                  Positioned(
                    bottom: -6,
                    left: -6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  
                  // 图片（居中显示）
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.18, // 放大50% (0.12 * 1.5 = 0.18)
                      height: MediaQuery.of(context).size.width * 0.18,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.012),
                        child: Image.asset(
                          widget.function.asset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print('图片加载失败: ${widget.function.asset}');
                            print('错误信息: $error');
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: MediaQuery.of(context).size.width * 0.06,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '图片未找到',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  // 文字标签（底部居中）
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Text(
                      widget.function.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF5D4037).withValues(alpha: 0.8),
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      child: MasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
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
    )..repeat(reverse: true);
    
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
    final cardWidth = (screenWidth - 32 - 12) / 2; // 减去左右边距和列间距
    final cardHeight = cardWidth; // 高度等于宽度，形成正方形

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(28),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: locked ? 0.65 : 1,
        child: AnimatedBuilder(
          animation: _breathAnimation,
          builder: (context, _) {
            return Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.module.gradientColors,
                ),
                boxShadow: [
                  // 彩色外发光阴影
                  BoxShadow(
                    color: widget.module.gradientColors.last.withValues(alpha: _breathAnimation.value),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  // 白色高光阴影
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
                  // 模块图片（背景层，避免被遮挡）
                  if (widget.module.image != null)
                    Positioned(
                      top: widget.module.title == '猫式伸展' ? -50 : (widget.module.title == '侧身平板支撑' ? 20 : (widget.module.title == '平衡训练' ? -20 : -100)), // 侧身平板支撑调整位置到20px
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: widget.module.title == '侧身平板支撑' ? 200 : (widget.module.title == '侧身平板支撑' ? 200 : 288), // 侧身平板支撑增大容器到200
                          height: widget.module.title == '侧身平板支撑' ? 200 : (widget.module.title == '侧身平板支撑' ? 200 : 288),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(widget.module.title == '侧身平板支撑' ? 20 : 30), // 侧身平板支撑增大圆角
                            child: Image.asset(
                              widget.module.image!,
                              width: widget.module.title == '侧身平板支撑' ? 180 : 288, // 侧身平板支撑增大图片到180
                              height: widget.module.title == '侧身平板支撑' ? 180 : 288,
                              fit: BoxFit.contain, // 侧身平板支撑使用contain确保完整显示
                              errorBuilder: (context, error, stackTrace) {
                                print('模块图片加载失败: ${widget.module.image}');
                                print('错误信息: $error');
                                return Container(
                                  width: widget.module.title == '侧身平板支撑' ? 180 : 288,
                                  height: widget.module.title == '侧身平板支撑' ? 180 : 288,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(widget.module.title == '侧身平板支撑' ? 20 : 30),
                                  ),
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: Colors.white,
                                    size: widget.module.title == '侧身平板支撑' ? 80 : 120,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // 顶部反光条
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.4),
                            Colors.white.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // 右下角半透明大泡泡
                  Positioned(
                    right: -15,
                    bottom: -15,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  
                  // 左上角白色小图标
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  // 文字内容（左下角）
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.module.title,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.module.subtitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.module.duration,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _difficultyText(widget.module.difficulty),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 锁定状态覆盖层
                  if (locked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '🔒',
                          style: TextStyle(fontSize: 32),
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
  });

  final String title;
  final String subtitle;
  final String? image;
  final String duration;
  final _Difficulty difficulty;
  final _ModuleStatus status;
  final List<Color> gradientColors;
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
