import 'package:flutter/material.dart';

import 'report_query_flow.dart';
import 'report_theme.dart';

/// 底部导航「检测报告编码」对应的主界面，点击「查询报告」后弹出查询方式对话框。
class ReportCodeEntryPage extends StatelessWidget {
  const ReportCodeEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: ReportTheme.pageGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text(
                  '检测报告编码',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ReportTheme.textPrimary),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: ReportTheme.iconGradient,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: ReportTheme.primaryBorder),
                          boxShadow: [
                            BoxShadow(
                              color: ReportTheme.primary.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.description_rounded, size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '查询脊柱健康检测报告',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: ReportTheme.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '可通过报告编码或二维码获取您的检测数据',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ReportTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),
                      ReportTheme.gradientButton(
                        onPressed: () => ReportQueryFlow.showOptions(context),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
