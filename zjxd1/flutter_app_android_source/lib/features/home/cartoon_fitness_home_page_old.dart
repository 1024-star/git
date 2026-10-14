import 'dart:math' as math;

import 'package:flutter/material.dart';

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

  late final PageController _bannerPageController;

  late final AnimationController _floatController;
  late final AnimationController _bannerController;
  late final AnimationController _aiBallController;
  late final Animation<double> _decorationFloat;
  late final Animation<Offset> _aiBallFloat;

  final List<_FunctionItem> _functions = const [
    _FunctionItem(name: '体态评估', asset: 'assets/images/aimage/1.png'),
    _FunctionItem(name: '姿态矫正', asset: 'assets/images/aimage/2.png'),
    _FunctionItem(name: 'AI助教', asset: 'assets/images/aimage/3.png'),
    _FunctionItem(name: '社区', asset: 'assets/images/aimage/4.png'),
  ];

  final List<String> _bannerAssets = const [
    'assets/images/aimage/10.png',
    'assets/images/aimage/11.png',
    'assets/images/aimage/12.png',
    'assets/images/aimage/13.png',
  ];

  final List<_ExerciseModule> _modules = const [
    _ExerciseModule(
      title: '臀桥',
      duration: '15-20分钟',
      difficulty: _Difficulty.easy,
      status: _ModuleStatus.active,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF86D4FF), Color(0xFF4AAEF7)],
      ),
      displayTitle: '臀桥',
      displaySubtitle: '强化腰背力量',
      shadowColor: Color(0xFF58B8FF),
    ),
    _ExerciseModule(
      title: '高级训练',
      duration: '20-30分钟',
      difficulty: _Difficulty.hard,
      status: _ModuleStatus.locked,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF88B5), Color(0xFFFF5FA2)],
      ),
      displayTitle: '高级训练《单腿臀桥转体》',
      displaySubtitle: '矫正含胸驼背',
      shadowColor: Color(0xFFFF69A9),
    ),
    _ExerciseModule(
      title: '猫式伸展',
      duration: '5-10分钟',
      difficulty: _Difficulty.easy,
      status: _ModuleStatus.active,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFD67A), Color(0xFFFFB74D)],
      ),
      displayTitle: '猫式伸展',
      displaySubtitle: '放松脊柱腰背',
      shadowColor: Color(0xFFFFC35A),
    ),
    _ExerciseModule(
      title: '侧生平板支撑',
      duration: '10-15分钟',
      difficulty: _Difficulty.medium,
      status: _ModuleStatus.active,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7BEE7F), Color(0xFF37D65A)],
      ),
      displayTitle: '侧生平板支撑',
      displaySubtitle: '收紧腰腹核心',
      shadowColor: Color(0xFF52E56A),
    ),
    _ExerciseModule(
      title: '平衡训练',
      duration: '6-10分钟',
      difficulty: _Difficulty.easy,
      status: _ModuleStatus.active,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD27BFF), Color(0xFFB65CF6)],
      ),
      displayTitle: '平衡训练',
      displaySubtitle: '提升身体控制',
      shadowColor: Color(0xFFC06BFF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController(initialPage: 0);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _decorationFloat = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
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
      setState(() {
        _bannerIndex = (_bannerIndex + 1) % _bannerAssets.length;
      });

      if (_bannerPageController.hasClients) {
        _bannerPageController.animateToPage(
          _bannerIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

      _startBannerAutoPlay();
    });
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    _floatController.dispose();
    _bannerController.dispose();
    _aiBallController.dispose();
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
                    Color(0xFFFDF6FB),
                    Color(0xFFF3F6FF),
                    Color(0xFFEFF7FF),
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
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 6, 18, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '小小脊柱守护者',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Banner carousel
                  _BannerSection(
                    banners: _bannerAssets,
                    currentIndex: _bannerIndex,
                    controller: _bannerPageController,
                    onIndexChanged: (index) {
                      setState(() {
                        _bannerIndex = index;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  // Function tags
                  _FunctionSection(
                    functions: _functions,
                    activeIndex: _activeFunction,
                    onSelect: _selectFunction,
                  ),
                  const SizedBox(height: 18),
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

class _BannerSection extends StatelessWidget {
  const _BannerSection({
    required this.banners,
    required this.currentIndex,
    required this.controller,
    required this.onIndexChanged,
  });

  final List<String> banners;
  final int currentIndex;
  final PageController controller;
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 182,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 150,
              child: PageView.builder(
                controller: controller,
                itemCount: banners.length,
                onPageChanged: (index) {
                  onIndexChanged(index);
                },
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.65),
                          blurRadius: 12,
                          offset: const Offset(-4, -4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        banners[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFB3C7), Color(0xFFFF8FB3)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image, size: 48, color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              final isActive = index == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive ? const Color(0xFFFF6B9A) : Colors.white.withValues(alpha: 0.55),
                ),
              );
            }),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: List.generate(functions.length, (index) {
          final f = functions[index];
          final isActive = index == activeIndex;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 6,
                right: index == functions.length - 1 ? 0 : 6,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelect(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getFunctionColor(index).withValues(alpha: 0.38),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: isActive ? 2.6 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getFunctionColor(index).withValues(alpha: isActive ? 0.28 : 0.16),
                        blurRadius: isActive ? 18 : 12,
                        offset: Offset(0, isActive ? 9 : 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -4,
                        child: Transform.translate(
                          offset: const Offset(0, 18),
                          child: Image.asset(
                            f.asset,
                            width: 78,
                            height: 78,
                            fit: BoxFit.contain,
                            errorBuilder: (context, _, __) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 4,
                        child: Text(
                          f.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF5B4A3A).withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _getFunctionColor(int index) {
    const colors = [
      Color(0xFFFFB74D), // Peach
      Color(0xFF81C784), // Mint
      Color(0xFFBA68C8), // Lavender
      Color(0xFFFFD54F), // Cream
    ];
    return colors[index % colors.length];
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const crossAxisSpacing = 12.0;
          const mainAxisSpacing = 12.0;
          const itemHeight = 164.0;

          final itemWidth = (constraints.maxWidth - crossAxisSpacing) / 2;
          final childAspectRatio = itemWidth / itemHeight;

          return Column(
            children: [
              GridView.builder(
                itemCount: modules.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final module = modules[index];
                  return _ExerciseModuleCard(
                    module: module,
                    onTap: () => onTap(module),
                  );
                },
              ),
              SizedBox(height: 24 + bottomInset),
            ],
          );
        },
      ),
    );
  }
}

class _ExerciseModuleCard extends StatelessWidget {
  const _ExerciseModuleCard({required this.module, required this.onTap});

  final _ExerciseModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = module.status == _ModuleStatus.locked;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: locked ? 0.65 : 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 164,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: module.gradient,
                boxShadow: [
                  BoxShadow(
                    color: module.shadowColor.withValues(alpha: 0.35),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(
                      module.displayTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      module.displaySubtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              right: 16,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
            ),
            Positioned(
              right: -18,
              bottom: -18,
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
            if (locked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: Colors.black.withValues(alpha: 0.4),
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

class _FunctionItem {
  const _FunctionItem({required this.name, required this.asset});

  final String name;
  final String asset;
}

class _ExerciseModule {
  const _ExerciseModule({
    required this.title,
    required this.duration,
    required this.difficulty,
    required this.status,
    required this.gradient,
    required this.displayTitle,
    required this.displaySubtitle,
    required this.shadowColor,
  });

  final String title;
  final String duration;
  final _Difficulty difficulty;
  final _ModuleStatus status;
  final Gradient gradient;
  final String displayTitle;
  final String displaySubtitle;
  final Color shadowColor;
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
