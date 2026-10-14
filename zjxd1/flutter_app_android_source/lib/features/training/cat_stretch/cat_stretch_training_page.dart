import 'dart:math' as math;

import 'package:flutter/material.dart';

class CatStretchTrainingPage extends StatefulWidget {
  const CatStretchTrainingPage({super.key});

  @override
  State<CatStretchTrainingPage> createState() => _CatStretchTrainingPageState();
}

class _CatStretchTrainingPageState extends State<CatStretchTrainingPage> with SingleTickerProviderStateMixin {
  bool showRulesModal = false;

  int completedDays = 15;
  int totalMinutes = 180;
  int bestStreak = 7;
  String growthCm = '1.2cm';

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showPreview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('播放动作预览（示例）')),
    );
  }

  void _showGoals() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('查看训练目标（示例）')),
    );
  }

  void _showRecords() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('查看训练记录（示例）')),
    );
  }

  Future<void> _startTraining() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('开始训练'),
          content: const Text('准备好开始12分钟的拉伸训练了吗？'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('开始')),
          ],
        );
      },
    );

    if (!mounted) return;
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('训练开始！（示例）')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF9A9E),
              Color(0xFFFAD0C4),
              Color(0xFFFFEEF8),
              Color(0xFFF8E6FF),
            ],
            stops: [0.0, 0.25, 0.60, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _TopScene(
                      controller: _controller,
                      onPreview: _showPreview,
                    ),
                    const SizedBox(height: 16),
                    const _InfoSection(),
                    const SizedBox(height: 12),
                    _FeaturesSection(
                      onRules: () => setState(() => showRulesModal = true),
                      onGoals: _showGoals,
                      onRecords: _showRecords,
                    ),
                    const SizedBox(height: 8),
                    _StatsGrid(
                      completedDays: completedDays,
                      totalMinutes: totalMinutes,
                      bestStreak: bestStreak,
                      growthCm: growthCm,
                    ),
                    const SizedBox(height: 14),
                    _StartSection(onStart: _startTraining),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              Positioned(
                top: math.max(8, top * 0.2),
                left: 12,
                child: _BackFab(onTap: () => Navigator.of(context).pop()),
              ),
              if (showRulesModal)
                Positioned.fill(
                  child: _RulesModal(
                    onClose: () => setState(() => showRulesModal = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopScene extends StatelessWidget {
  const _TopScene({required this.controller, required this.onPreview});

  final Animation<double> controller;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final height = math.min(240.0, w * 0.55);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.transparent)),
            Center(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final t = controller.value;
                  final dy = math.sin(t * math.pi * 2) * -8;
                  final scale = 1.0 + (math.sin(t * math.pi * 2) * 0.015);
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.scale(
                      scale: scale,
                      child: Image.asset(
                        'assets/images/cartoon-girl-cat-stretch.png',
                        width: math.min(w * 1.17, 507),
                        height: math.min(height * 1.365, 351),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.self_improvement, size: 187, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Center(
                child: _PreviewOverlay(onTap: onPreview),
              ),
            ),
            _SceneDecoration(controller: controller, emoji: '🌸', base: const Offset(0.18, 0.22), delay: 0.0),
            _SceneDecoration(controller: controller, emoji: '🌿', base: const Offset(0.78, 0.28), delay: 0.25),
            _SceneDecoration(controller: controller, emoji: '💫', base: const Offset(0.14, 0.72), delay: 0.5),
            _SceneDecoration(controller: controller, emoji: '✨', base: const Offset(0.80, 0.76), delay: 0.75),
          ],
        ),
      ),
    );
  }
}

class _PreviewOverlay extends StatelessWidget {
  const _PreviewOverlay({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.90),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: const Text('▶️', style: TextStyle(fontSize: 25)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '预览动作',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneDecoration extends StatelessWidget {
  const _SceneDecoration({
    required this.controller,
    required this.emoji,
    required this.base,
    required this.delay,
  });

  final Animation<double> controller;
  final String emoji;
  final Offset base;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final t = (controller.value + delay) % 1.0;
            final dy = math.sin(t * math.pi * 2) * -12;
            final opacity = 0.7 + (math.sin(t * math.pi * 2) * 0.25);
            final angle = t * math.pi;

            return Positioned(
              left: w * base.dx,
              top: h * base.dy,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.rotate(
                    angle: angle,
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Text(
            '拉伸长高训练',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: const [
              _TagChip(
                emoji: '⏰',
                text: '12分钟',
                gradient: LinearGradient(colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)]),
              ),
              _TagChip(
                emoji: '📊',
                text: '中等',
                gradient: LinearGradient(colors: [Color(0xFFFFEAA7), Color(0xFFFAB1A0)]),
              ),
              _TagChip(
                emoji: '🏆',
                text: '排行榜',
                gradient: LinearGradient(colors: [Color(0xFFFBB6CE), Color(0xFFF093FB)]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFB6C1).withValues(alpha: 0.20), width: 1.5),
            ),
            child: const Text(
              '通过科学的拉伸动作，帮助小朋友改善体态，促进身高增长，让身体更加挺拔健康！',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: Color(0xFF718096), height: 1.6, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.emoji, required this.text, required this.gradient});

  final String emoji;
  final String text;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 19)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4A5568))),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection({required this.onRules, required this.onGoals, required this.onRecords});

  final VoidCallback onRules;
  final VoidCallback onGoals;
  final VoidCallback onRecords;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _FeatureCard(
            emoji: '📋',
            title: '互动规则',
            desc: '了解训练规则和注意事项',
            onTap: onRules,
          ),
          const SizedBox(height: 10),
          _FeatureCard(
            emoji: '🎯',
            title: '训练目标',
            desc: '查看个人训练目标和进度',
            onTap: onGoals,
          ),
          const SizedBox(height: 10),
          _FeatureCard(
            emoji: '📈',
            title: '训练记录',
            desc: '查看历史训练数据和成长',
            onTap: onRecords,
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFB6C1).withValues(alpha: 0.20), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9A9E).withValues(alpha: 0.15),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4)]),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9A9E).withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4A5568))),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF718096), height: 1.3)),
                ],
              ),
            ),
            const Text('>', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFFCBD5E0))),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.completedDays,
    required this.totalMinutes,
    required this.bestStreak,
    required this.growthCm,
  });

  final int completedDays;
  final int totalMinutes;
  final int bestStreak;
  final String growthCm;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('训练天数', '$completedDays'),
      ('累计时长', '$totalMinutes'),
      ('最长连续', '$bestStreak'),
      ('身高增长', growthCm),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (context, index) {
          final label = items[index].$1;
          final value = items[index].$2;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFB6C1).withValues(alpha: 0.20), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9A9E).withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFFE91E63)),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF718096)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StartSection extends StatelessWidget {
  const _StartSection({required this.onStart});

  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () => onStart(),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFF093FB)]),
                border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9A9E).withValues(alpha: 0.40),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('开始训练', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(width: 10),
                  Text('🚀', style: TextStyle(fontSize: 23)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEB3B).withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFEB3B).withValues(alpha: 0.30), width: 1.5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('💡', style: TextStyle(fontSize: 21)),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    '建议在空旷安全的地方进行训练',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF57F17)),
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

class _RulesModal extends StatelessWidget {
  const _RulesModal({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final rules = const [
      ('1. 训练准备', '穿着宽松舒适的运动服，选择安全的训练环境'),
      ('2. 动作要求', '按照示范动作进行，保持动作标准，避免过度拉伸'),
      ('3. 呼吸配合', '配合深呼吸，拉伸时缓慢呼气，放松时吸气'),
      ('4. 安全提醒', '如感到不适请立即停止，循序渐进，不要勉强'),
    ];

    return Material(
      color: Colors.black.withValues(alpha: 0.50),
      child: InkWell(
        onTap: onClose,
        child: Center(
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: math.min(MediaQuery.sizeOf(context).width - 48, 360),
              constraints: const BoxConstraints(maxHeight: 460),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  )
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '📋 互动规则',
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF4A5568)),
                          ),
                        ),
                        InkWell(
                          onTap: onClose,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF5F5F5),
                              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                            ),
                            alignment: Alignment.center,
                            child: const Text('×', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF999999))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rules.length,
                      itemBuilder: (context, index) {
                        final title = rules[index].$1;
                        final desc = rules[index].$2;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF4A5568))),
                              const SizedBox(height: 6),
                              Text(desc, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF718096), height: 1.5)),
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
        ),
      ),
    );
  }
}

class _BackFab extends StatelessWidget {
  const _BackFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.92),
            border: Border.all(color: const Color(0xFFFFB6C1).withValues(alpha: 0.30), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          alignment: Alignment.center,
          child: const Text('←', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF4A5568))),
        ),
      ),
    );
  }
}
