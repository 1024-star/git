import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class GameSharePage extends StatefulWidget {
  const GameSharePage({super.key, this.playerScore = 120, this.earnedStars = 3});

  final int playerScore;
  final int earnedStars;

  @override
  State<GameSharePage> createState() => _GameSharePageState();
}

class _GameSharePageState extends State<GameSharePage> {
  bool _animateIn = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _animateIn = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          const Positioned.fill(child: _ShareBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: _NavHeader(
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 72,
                          child: _AnimatedIn(
                            enabled: _animateIn,
                            child: _PostcardFocusArea(
                              score: widget.playerScore,
                              stars: widget.earnedStars,
                              onEnlarge: () => _showEnlarged(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          flex: 28,
                          child: _ShareArea(
                            onWeChat: () => _toast(context, '微信分享（示例）'),
                            onQQ: () => _toast(context, 'QQ分享（示例）'),
                            onSave: () => _toast(context, '保存成功（示例）'),
                            onXiaotiancai: () => _toast(context, '小天才分享（示例）'),
                            onLater: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  static void _showEnlarged(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.80),
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: MediaQuery.sizeOf(context).width * 0.90,
                height: MediaQuery.sizeOf(context).height * 0.76,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 26,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/user-postcard.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.60),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text('×', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavHeader extends StatelessWidget {
  const _NavHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x66CBD5E1), blurRadius: 14, offset: Offset(6, 6)),
                BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 14, offset: Offset(-6, -6)),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('←', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('我的成绩单', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF334155))),
              SizedBox(height: 4),
              Text('分享你的精彩时刻', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedIn extends StatelessWidget {
  const _AnimatedIn({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      opacity: enabled ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        offset: enabled ? Offset.zero : const Offset(0, 0.10),
        child: child,
      ),
    );
  }
}

class _PostcardFocusArea extends StatelessWidget {
  const _PostcardFocusArea({required this.score, required this.stars, required this.onEnlarge});

  final int score;
  final int stars;
  final VoidCallback onEnlarge;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: InkWell(
            onTap: onEnlarge,
            borderRadius: BorderRadius.circular(22),
            child: _Postcard(score: score, stars: stars),
          ),
        ),
        const SizedBox(height: 14),
        const Text('🎉 恭喜通关！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
        const SizedBox(height: 4),
        const Text(
          '你在脊椎健康挑战中表现优异',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Postcard extends StatelessWidget {
  const _Postcard({required this.score, required this.stars});

  final int score;
  final int stars;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        final desired = (width * 0.82).clamp(310.0, 600.0);
        final h = math.min(c.maxHeight, desired);

        return Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              right: -10,
              bottom: -10,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x33CBD5E1), Color(0x1F94A3B8)],
                  ),
                ),
              ),
            ),
            Container(
              height: h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(color: Color(0x66CBD5E1), blurRadius: 26, offset: Offset(14, 14)),
                  BoxShadow(color: Color(0xF2FFFFFF), blurRadius: 26, offset: Offset(-14, -14)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/user-postcard.png',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.80), width: 2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, required this.stars});

  final int score;
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x4DCBD5E1), blurRadius: 16, offset: Offset(6, 6)),
              BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 16, offset: Offset(-6, -6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFDC2626), height: 1),
              ),
              const SizedBox(width: 4),
              const Text('分', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x4DCBD5E1), blurRadius: 14, offset: Offset(5, 5)),
              BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 14, offset: Offset(-5, -5)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$stars', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
              const SizedBox(width: 6),
              const Text('⭐', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShareArea extends StatelessWidget {
  const _ShareArea({
    required this.onWeChat,
    required this.onQQ,
    required this.onSave,
    required this.onXiaotiancai,
    required this.onLater,
  });

  final VoidCallback onWeChat;
  final VoidCallback onQQ;
  final VoidCallback onSave;
  final VoidCallback onXiaotiancai;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '分享给朋友，一起挑战更高分数吧！',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
        Row(
          children: [
            Expanded(
              child: _ShareButton(iconAsset: 'assets/images/wechat.png', label: '微信好友', onTap: onWeChat),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ShareButton(iconAsset: 'assets/images/qq-chat.png', label: 'QQ空间', onTap: onQQ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ShareButton(
                iconAsset: 'assets/images/xiaotiancai.png',
                label: '小天才',
                iconSize: 67,
                circular: true,
                onTap: onXiaotiancai,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ShareButton(iconAsset: 'assets/images/local-save.png', label: '保存相册', onTap: onSave),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onLater,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66CBD5E1), blurRadius: 16, offset: Offset(8, 8)),
                      BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 16, offset: Offset(-8, -8)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('稍后分享', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: onSave,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.30), blurRadius: 18, offset: const Offset(8, 8)),
                      const BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 18, offset: Offset(-8, -8)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('保存相册', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.iconAsset,
    required this.label,
    required this.onTap,
    this.iconSize = 26,
    this.circular = false,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  final double iconSize;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      iconAsset,
      width: iconSize,
      height: iconSize,
      fit: circular ? BoxFit.cover : BoxFit.contain,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, __, ___) => SizedBox(width: iconSize, height: iconSize),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x66CBD5E1), blurRadius: 18, offset: Offset(10, 10)),
                BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 18, offset: Offset(-10, -10)),
              ],
            ),
            alignment: Alignment.center,
            child: circular ? ClipOval(child: image) : image,
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _ShareBackground extends StatelessWidget {
  const _ShareBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
          stops: [0, 0.30, 1],
        ),
      ),
      child: const Stack(
        children: [
          _FloatingCircle(left: 0.10, top: 0.15, size: 88, delay: 0),
          _FloatingCircle(right: 0.15, top: 0.25, size: 62, delay: 2),
          _FloatingCircle(left: 0.08, bottom: 0.30, size: 74, delay: 4),
          _FloatingStar(right: 0.25, top: 0.20, text: '✨', delay: 1),
          _FloatingStar(left: 0.20, top: 0.35, text: '⭐', delay: 3),
          _FloatingStar(right: 0.20, bottom: 0.25, text: '💫', delay: 5),
        ],
      ),
    );
  }
}

class _FloatingCircle extends StatelessWidget {
  const _FloatingCircle({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.size,
    required this.delay,
  });

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double size;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context);

    return Positioned(
      left: left == null ? null : s.width * left!,
      right: right == null ? null : s.width * right!,
      top: top == null ? null : s.height * top!,
      bottom: bottom == null ? null : s.height * bottom!,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(seconds: 6),
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          final p = (t + delay / 6) % 1.0;
          final dy = (p < 0.5 ? p : 1 - p) * 24;

          return Transform.translate(
            offset: Offset(0, -dy),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.60),
                    Colors.white.withValues(alpha: 0.20),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x4DCBD5E1), blurRadius: 18, offset: Offset(6, 6)),
                  BoxShadow(color: Color(0xB3FFFFFF), blurRadius: 18, offset: Offset(-6, -6)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatingStar extends StatelessWidget {
  const _FloatingStar({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.text,
    required this.delay,
  });

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final String text;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context);

    return Positioned(
      left: left == null ? null : s.width * left!,
      right: right == null ? null : s.width * right!,
      top: top == null ? null : s.height * top!,
      bottom: bottom == null ? null : s.height * bottom!,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(seconds: 3),
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          final p = (t + delay / 3) % 1.0;
          final scale = 1 + (p < 0.5 ? p : 1 - p) * 0.25;
          final opacity = 0.30 + (p < 0.5 ? p : 1 - p) * 0.70;

          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Text(text, style: const TextStyle(fontSize: 20)),
            ),
          );
        },
      ),
    );
  }
}
