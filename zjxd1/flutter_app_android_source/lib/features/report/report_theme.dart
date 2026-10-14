import 'package:flutter/material.dart';

/// 检测报告模块 — 清新青春风配色（青蓝渐变，与首页暖色互补）。
abstract final class ReportTheme {
  static const Color primary = Color(0xFF06B6D4);
  static const Color primaryEnd = Color(0xFF38BDF8);
  static const Color primaryLight = Color(0xFFE0F7FE);
  static const Color primarySoft = Color(0xFFF0F9FF);
  static const Color primaryBorder = Color(0xFFBAE6FD);
  static const Color accent = Color(0xFF818CF8);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color surfaceMuted = Color(0xFFF8FAFC);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryEnd],
  );

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF0F9FF), Color(0xFFFAF5FF), Color(0xFFFFFFFF)],
  );

  static const LinearGradient iconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF67E8F9), Color(0xFF7DD3FC)],
  );

  static ButtonStyle filledButtonStyle() {
    return FilledButton.styleFrom(
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    );
  }

  static Widget gradientButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 48),
            child: child,
          ),
        ),
      ),
    );
  }
}
