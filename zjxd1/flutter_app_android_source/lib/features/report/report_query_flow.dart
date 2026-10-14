import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'report_theme.dart';
import 'spine_data_report_page.dart';

/// 检测报告查询 — 与首页底部「检测报告编码」入口一致的视觉与交互。
class ReportQueryFlow {
  ReportQueryFlow._();

  static const Color primary = ReportTheme.primary;
  static const Color primaryLight = ReportTheme.primaryLight;
  static const Color primaryBorder = ReportTheme.primaryBorder;
  static const Color textPrimary = ReportTheme.textPrimary;
  static const Color textSecondary = ReportTheme.textSecondary;
  static const Color textTertiary = ReportTheme.textTertiary;
  static const Color surfaceMuted = ReportTheme.surfaceMuted;

  static Future<void> open(BuildContext context) => showOptions(context);

  static Future<void> showOptions(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        final maxW = MediaQuery.sizeOf(dialogContext).width - 48;

        return Align(
          alignment: const Alignment(0, -0.18),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW.clamp(280.0, 360.0)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _sheetCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sheetHeader(
                        icon: Icons.description_rounded,
                        title: '检测报告查询',
                        subtitle: '选择方式获取您的脊柱健康报告',
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      _optionTile(
                        icon: Icons.edit_outlined,
                        title: '手动输入',
                        subtitle: '输入报告编码',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          showCodeInput(context);
                        },
                      ),
                      const Divider(height: 1, indent: 72, endIndent: 16, color: Color(0xFFF1F5F9)),
                      _optionTile(
                        icon: Icons.qr_code_scanner_rounded,
                        title: '扫码查询',
                        subtitle: '扫描报告上的二维码',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _openScanner(context);
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: textSecondary,
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> showCodeInput(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        final maxW = MediaQuery.sizeOf(dialogContext).width - 48;
        final viewInsets = MediaQuery.viewInsetsOf(dialogContext);

        return Align(
          alignment: const Alignment(0, -0.18),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.only(bottom: viewInsets.bottom * 0.35),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW.clamp(280.0, 360.0)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _ReportCodeInputSheet(
                    onSubmitted: (code) {
                      Navigator.of(dialogContext).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) _queryReport(context, code);
                      });
                    },
                    onCancel: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _openScanner(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ReportScannerPage(
          onScanned: (code) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) _queryReport(context, code);
            });
          },
        ),
      ),
    );
  }

  static Widget _sheetCard({required Widget child}) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(color: ReportTheme.primaryBorder.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: ReportTheme.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  static Widget _sheetHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: ReportTheme.iconGradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryBorder),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryBorder.withValues(alpha: 0.6)),
                ),
                child: Icon(icon, color: primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: textTertiary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _queryReport(BuildContext context, String code) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3, color: primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  '正在查询报告…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!context.mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!context.mounted) return;
    _showReportResult(context, code, success: true);
  }

  static void _showReportResult(BuildContext context, String code, {required bool success}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: success ? primaryLight : const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: success ? primary : const Color(0xFFF59E0B),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                success ? '查询成功' : '未找到报告',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                success ? '已找到对应报告，可查看详情。' : '请核对编码或联系检测机构。',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: textSecondary, height: 1.45),
              ),
              const SizedBox(height: 20),
              if (success)
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SpineDataReportPage()),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('查看报告', style: TextStyle(fontWeight: FontWeight.w700)),
                )
              else
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('知道了', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCodeInputSheet extends StatefulWidget {
  const _ReportCodeInputSheet({
    required this.onSubmitted,
    required this.onCancel,
  });

  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;

  @override
  State<_ReportCodeInputSheet> createState() => _ReportCodeInputSheetState();
}

class _ReportCodeInputSheetState extends State<_ReportCodeInputSheet> {
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSubmitted(_codeController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return ReportQueryFlow._sheetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportQueryFlow._sheetHeader(
            icon: Icons.pin_outlined,
            title: '输入报告编码',
            subtitle: '输入后查询您的检测报告',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '报告编码',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ReportQueryFlow.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeController,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: '请输入报告编码',
                    hintStyle: const TextStyle(color: ReportQueryFlow.textTertiary, fontSize: 14),
                    filled: true,
                    fillColor: ReportQueryFlow.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: ReportQueryFlow.primary, width: 1.5),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ReportQueryFlow.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                          ReportTheme.gradientButton(
                            onPressed: _submit,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_rounded, size: 20, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  '查询报告',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          TextButton(
            onPressed: widget.onCancel,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: ReportQueryFlow.textSecondary,
            ),
            child: const Text(
              '取消',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportScannerPage extends StatefulWidget {
  const _ReportScannerPage({required this.onScanned});

  final ValueChanged<String> onScanned;

  @override
  State<_ReportScannerPage> createState() => _ReportScannerPageState();
}

class _ReportScannerPageState extends State<_ReportScannerPage> with SingleTickerProviderStateMixin {
  late final AnimationController _lineController;
  Timer? _detectTimer;
  bool _detected = false;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

    _detectTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted || _detected) return;
      _detected = true;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      widget.onScanned('DEMO123456789ABC');
    });
  }

  @override
  void dispose() {
    _detectTimer?.cancel();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 相机区域占位（深色渐变，避免「白底+大图标」的演示感）
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                  Colors.black.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(260, 260),
                    painter: _ViewfinderPainter(),
                  ),
                  AnimatedBuilder(
                    animation: _lineController,
                    builder: (context, _) {
                      return Positioned(
                        top: 24 + (212 * _lineController.value),
                        left: 24,
                        right: 24,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: LinearGradient(
                              colors: [
                                ReportQueryFlow.primary.withValues(alpha: 0.0),
                                ReportQueryFlow.primary,
                                ReportQueryFlow.primary.withValues(alpha: 0.0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ReportQueryFlow.primary.withValues(alpha: 0.45),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    '扫一扫',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 48,
            child: const Text(
              '将二维码放入框内，即可自动识别',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const corner = 28.0;
    const stroke = 3.0;
    final paint = Paint()
      ..color = ReportQueryFlow.primary
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    void cornerPath(Offset start, Offset hEnd, Offset vEnd) {
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(hEnd.dx, hEnd.dy)
        ..moveTo(start.dx, start.dy)
        ..lineTo(vEnd.dx, vEnd.dy);
      canvas.drawPath(path, paint);
    }

    cornerPath(const Offset(0, 0), const Offset(corner, 0), const Offset(0, corner));
    cornerPath(Offset(w, 0), Offset(w - corner, 0), Offset(w, corner));
    cornerPath(Offset(0, h), Offset(corner, h), Offset(0, h - corner));
    cornerPath(Offset(w, h), Offset(w - corner, h), Offset(w, h - corner));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
