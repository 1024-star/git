import 'package:flutter/material.dart';

/// 游戏风 3D 盾牌勋章（成就收藏用）
class GameMedalBadge extends StatelessWidget {
  const GameMedalBadge({
    super.key,
    required this.theme,
    required this.emblem,
    required this.ribbonText,
    required this.unlocked,
    this.size = 76,
  });

  final GameMedalTheme theme;
  final IconData emblem;
  final String ribbonText;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final h = size * 1.12;

    Widget medal = SizedBox(
      width: size,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: size * 0.08,
            child: Container(
              width: size * 0.88,
              height: size * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.glow.withValues(alpha: unlocked ? 0.55 : 0.18),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _ShieldMedalBody(
              width: size,
              height: size * 0.92,
              theme: theme,
              emblem: emblem,
              unlocked: unlocked,
            ),
          ),
          Positioned(
            bottom: 0,
            child: _MedalRibbon(
              text: ribbonText,
              width: size * 0.92,
              colors: theme.ribbonGradient,
              unlocked: unlocked,
            ),
          ),
          if (unlocked) ..._sparkles(size, h),
          if (!unlocked)
            Positioned(
              top: size * 0.22,
              child: Container(
                width: size * 0.52,
                height: size * 0.52,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
              ),
            ),
        ],
      ),
    );

    if (!unlocked) {
      medal = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.45, 0.12, 0.12, 0, 40,
          0.12, 0.45, 0.12, 0, 40,
          0.12, 0.12, 0.45, 0, 40,
          0, 0, 0, 0.72, 0,
        ]),
        child: medal,
      );
    }

    return medal;
  }

  List<Widget> _sparkles(double size, double h) {
    return [
      Positioned(left: size * 0.08, top: h * 0.18, child: _Sparkle(size: 6)),
      Positioned(right: size * 0.1, top: h * 0.28, child: _Sparkle(size: 5)),
      Positioned(right: size * 0.22, top: h * 0.12, child: _Sparkle(size: 4)),
    ];
  }
}

class GameMedalTheme {
  const GameMedalTheme({
    required this.fill,
    required this.fillDark,
    required this.border,
    required this.borderLight,
    required this.glow,
    required this.ribbonGradient,
    required this.emblemColor,
  });

  final Color fill;
  final Color fillDark;
  final Color border;
  final Color borderLight;
  final Color glow;
  final List<Color> ribbonGradient;
  final Color emblemColor;
}

class GameMedalThemes {
  static const trophy = GameMedalTheme(
    fill: Color(0xFFE53935),
    fillDark: Color(0xFFB71C1C),
    border: Color(0xFFFFD54F),
    borderLight: Color(0xFFFFF59D),
    glow: Color(0xFFFF5252),
    ribbonGradient: [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFFF8F00)],
    emblemColor: Colors.white,
  );

  static const fire = GameMedalTheme(
    fill: Color(0xFFFF5722),
    fillDark: Color(0xFFD84315),
    border: Color(0xFFFFCC80),
    borderLight: Color(0xFFFFE0B2),
    glow: Color(0xFFFF7043),
    ribbonGradient: [Color(0xFFFFCC80), Color(0xFFFF9800), Color(0xFFF57C00)],
    emblemColor: Colors.white,
  );

  static const star = GameMedalTheme(
    fill: Color(0xFF1E88E5),
    fillDark: Color(0xFF1565C0),
    border: Color(0xFF90CAF9),
    borderLight: Color(0xFFE3F2FD),
    glow: Color(0xFF42A5F5),
    ribbonGradient: [Color(0xFF81D4FA), Color(0xFF29B6F6), Color(0xFF0288D1)],
    emblemColor: Colors.white,
  );

  static const diamond = GameMedalTheme(
    fill: Color(0xFF8E24AA),
    fillDark: Color(0xFF6A1B9A),
    border: Color(0xFFCE93D8),
    borderLight: Color(0xFFF3E5F5),
    glow: Color(0xFFAB47BC),
    ribbonGradient: [Color(0xFFE1BEE7), Color(0xFFBA68C8), Color(0xFF8E24AA)],
    emblemColor: Colors.white,
  );

  static const crown = GameMedalTheme(
    fill: Color(0xFFFF8F00),
    fillDark: Color(0xFFE65100),
    border: Color(0xFFFFE082),
    borderLight: Color(0xFFFFF9C4),
    glow: Color(0xFFFFB300),
    ribbonGradient: [Color(0xFFFFE082), Color(0xFFFFCA28), Color(0xFFFF8F00)],
    emblemColor: Colors.white,
  );

  static const rocket = GameMedalTheme(
    fill: Color(0xFF00897B),
    fillDark: Color(0xFF00695C),
    border: Color(0xFF80CBC4),
    borderLight: Color(0xFFB2DFDB),
    glow: Color(0xFF26A69A),
    ribbonGradient: [Color(0xFFA7FFEB), Color(0xFF4DB6AC), Color(0xFF00897B)],
    emblemColor: Colors.white,
  );
}

class _ShieldMedalBody extends StatelessWidget {
  const _ShieldMedalBody({
    required this.width,
    required this.height,
    required this.theme,
    required this.emblem,
    required this.unlocked,
  });

  final double width;
  final double height;
  final GameMedalTheme theme;
  final IconData emblem;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _ShieldMedalPainter(theme: theme, unlocked: unlocked),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: height * 0.06,
              left: width * 0.18,
              child: Container(
                width: width * 0.28,
                height: height * 0.14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: unlocked ? 0.55 : 0.22),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: height * 0.26,
              child: Icon(
                emblem,
                size: width * 0.36,
                color: theme.emblemColor.withValues(alpha: unlocked ? 1 : 0.65),
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
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

class _ShieldMedalPainter extends CustomPainter {
  _ShieldMedalPainter({required this.theme, required this.unlocked});

  final GameMedalTheme theme;
  final bool unlocked;

  Path _shieldPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.5, h * 0.02);
    path.lineTo(w * 0.9, h * 0.2);
    path.lineTo(w * 0.78, h * 0.68);
    path.quadraticBezierTo(w * 0.5, h * 0.98, w * 0.22, h * 0.68);
    path.lineTo(w * 0.1, h * 0.2);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shieldPath(size);
    final alpha = unlocked ? 1.0 : 0.75;

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.fill.withValues(alpha: alpha),
            theme.fillDark.withValues(alpha: alpha),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.07
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.borderLight.withValues(alpha: alpha),
            theme.border.withValues(alpha: alpha),
            theme.borderLight.withValues(alpha: alpha * 0.8),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.025
        ..color = Colors.white.withValues(alpha: unlocked ? 0.35 : 0.15),
    );
  }

  @override
  bool shouldRepaint(covariant _ShieldMedalPainter oldDelegate) {
    return oldDelegate.theme != theme || oldDelegate.unlocked != unlocked;
  }
}

class _MedalRibbon extends StatelessWidget {
  const _MedalRibbon({
    required this.text,
    required this.width,
    required this.colors,
    required this.unlocked,
  });

  final String text;
  final double width;
  final List<Color> colors;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: colors.map((c) => c.withValues(alpha: unlocked ? 1 : 0.55)).toList(),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: unlocked ? 0.65 : 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: unlocked ? 0.35 : 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: unlocked ? 1 : 0.85),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1.1,
          shadows: const [
            Shadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome, size: size, color: Colors.white.withValues(alpha: 0.9));
  }
}

/// 将成就名称压成绶带上的短文案
String gameMedalRibbonLabel(String name) {
  final t = name.trim();
  if (t.isEmpty) return '成就';
  if (t.length <= 4) return t;
  return t.substring(0, 4);
}
