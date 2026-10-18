import 'dart:io';
import 'dart:async';
import 'dart:math' as math;



import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:video_player/video_player.dart';

import '../../../config/app_config.dart';
import '../../../utils/app_logger.dart';



class HipBridgeTrainingResultPage extends StatefulWidget {

  const HipBridgeTrainingResultPage({

    super.key,

    required this.title,

    required this.actualCount,

    required this.targetCount,

    required this.actualTimeSeconds,

    required this.isCountMode,

    this.videoPath,

    this.resultData,

  });



  final String title;

  final int actualCount;

  final int targetCount;

  final int actualTimeSeconds;

  final bool isCountMode;
  final String? videoPath;

  final Map<String, dynamic>? resultData;

  @override

  State<HipBridgeTrainingResultPage> createState() => _HipBridgeTrainingResultPageState();

}



class _HipBridgeTrainingResultPageState extends State<HipBridgeTrainingResultPage> {

  bool _showGeneratingOverlay = true;

  /// 「正在生成训练结果」浮层的自动关闭定时器。
  /// 本页结果（星级/分数）全部在 initState 里本地算出，没有任何网络或 AI 请求，
  /// 因此浮层必须自动消失；之前漏了这一步，用户不点屏幕就会一直停在这里。
  Timer? _generatingTimer;

  // 【核心输出变量】结算星数与分数：达标后统一四星半 + 固定成绩 92 分
  late final double _stars;
  late final int _score;
  late final bool _goalDone;

  @override
  void initState() {
    super.initState();
    _goalDone = widget.targetCount > 0 && widget.actualCount >= widget.targetCount;
    if (_goalDone) {
      _stars = 4.5;
      _score = 92; // 达标成绩写死为 92
    } else {
      final s = _calcStars();
      _stars = s.toDouble();
      final completion = widget.targetCount > 0
          ? (widget.actualCount / widget.targetCount).clamp(0.0, 1.0)
          : 1.0;
      _score = ((s / 5) * 40 + completion * 60).round().clamp(0, 100);
    }

    // 结果已在本地算完（本页没有任何网络/AI 请求），浮层短暂展示后必须自动关闭。
    // 之前漏了这一步，用户不点屏幕就会一直停在「正在生成训练结果」。
    _generatingTimer?.cancel();
    _generatingTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _showGeneratingOverlay = false);
    });
  }

  @override
  void dispose() {
    _generatingTimer?.cancel();
    super.dispose();
  }

  void _dismissGeneratingOverlay() {
    if (!_showGeneratingOverlay) return;
    setState(() => _showGeneratingOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    final stars = _stars;
    final score = _score;
    final goalDone = _goalDone;
    final verdict = _verdict(stars);



    return Scaffold(

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

            stops: [0.0, 0.30, 0.60, 1.0],

          ),

        ),

        child: SafeArea(

          child: Stack(

            children: [

              const Positioned.fill(child: _BackgroundDecoration()),

              Padding(

                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Row(

                      children: [

                        _BackBubble(onTap: () => Navigator.of(context).maybePop()),

                        const SizedBox(width: 12),

                        Expanded(

                          child: Text(

                            '${widget.title} 结算',

                            style: const TextStyle(

                              fontSize: 18,

                              fontWeight: FontWeight.w900,

                              color: Color(0xFF4A5568),

                            ),

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 18),

                    Expanded(

                      // 改为可滚动：结算卡内含 440 高的 TabBarView，
                      // 横屏/小屏时整列必然超出可用高度，之前会 BOTTOM OVERFLOWED BY 279 PIXELS
                      child: SingleChildScrollView(

                        child: Center(

                        child: ConstrainedBox(

                          constraints: const BoxConstraints(maxWidth: 560),

                          child: Column(

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              _ResultCard(

                                stars: stars,

                                score: score,

                                goalDone: goalDone,

                                verdictTitle: verdict.title,

                                verdictDesc: verdict.desc,

                                isCountMode: widget.isCountMode,

                                actualCount: widget.actualCount,

                                targetCount: widget.targetCount,

                                actualTimeSeconds: widget.actualTimeSeconds,

                                videoPath: widget.videoPath,

                              ),

                              const SizedBox(height: 16),

                              _PrimaryButton(

                                text: '再来一次',

                                icon: '🚀',

                                onTap: () {
                                  // Clear the saved result and go back to training page
                                  SharedPreferences.getInstance().then((prefs) {
                                    prefs.remove('hip_bridge_has_result');
                                    prefs.remove('hip_bridge_result_data');
                                  });
                                  Navigator.of(context).pop();
                                },

                              ),

                              const SizedBox(height: 10),

                              _SecondaryButton(

                                text: '返回',

                                onTap: () => Navigator.of(context).pop(),

                              ),

                            ],

                          ),

                        ),

                      ),

                        ),

                    ),

                  ],

                ),

              ),

              if (_showGeneratingOverlay)

                Positioned.fill(

                  child: _TrainingResultGeneratingOverlay(

                    onDismiss: _dismissGeneratingOverlay,

                  ),

                ),

            ],

          ),

        ),

      ),

    );

  }



  int _calcStars() {
    if (widget.targetCount <= 0) {
      return widget.actualCount > 0 ? 4 : 0;
    }
    final ratio = widget.actualCount / widget.targetCount;
    if (ratio >= 0.8) return 4;
    if (ratio >= 0.6) return 3;
    if (ratio >= 0.4) return 2;
    if (ratio >= 0.2) return 1;
    return 0;
  }



  static _Verdict _verdict(double stars) {

    if (stars >= 4.5) {

      return const _Verdict(title: '🎉 超级棒！', desc: '动作稳定又标准，你就是小冠军～');

    }

    if (stars >= 3) {

      return const _Verdict(title: '💪 做得不错', desc: '再坚持一点点，下一次会更轻松～');

    }

    if (stars >= 1) {

      return const _Verdict(title: '✨ 继续加油', desc: '建议放慢速度，把动作做得更标准。');

    }

    return const _Verdict(title: '🌱 刚刚开始', desc: '没关系，从小目标开始，慢慢变强！');

  }

}



class _Verdict {

  const _Verdict({required this.title, required this.desc});



  final String title;

  final String desc;

}



class _TrainingResultGeneratingOverlay extends StatefulWidget {

  const _TrainingResultGeneratingOverlay({required this.onDismiss});



  final VoidCallback onDismiss;



  @override

  State<_TrainingResultGeneratingOverlay> createState() => _TrainingResultGeneratingOverlayState();

}



class _TrainingResultGeneratingOverlayState extends State<_TrainingResultGeneratingOverlay> {

  void _handleTapAnywhere() {

    widget.onDismiss();

  }

  @override

  Widget build(BuildContext context) {

    return GestureDetector(

      behavior: HitTestBehavior.opaque,

      onTap: _handleTapAnywhere,

      child: Stack(

        children: [

          Positioned.fill(

            child: Container(

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

                  stops: [0.0, 0.30, 0.60, 1.0],

                ),

              ),

            ),

          ),

          const Positioned.fill(child: _BackgroundDecoration()),

          Center(

            child: ConstrainedBox(

              constraints: const BoxConstraints(maxWidth: 560),

              child: SizedBox(

                width: double.infinity,

                child: Container(

                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),

                  decoration: BoxDecoration(

                    color: Colors.white.withValues(alpha: 0.94),

                    borderRadius: BorderRadius.circular(22),

                    border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.5),

                    boxShadow: [

                      BoxShadow(

                        color: Colors.black.withValues(alpha: 0.10),

                        blurRadius: 26,

                        offset: const Offset(0, 16),

                      ),

                    ],

                  ),

                  child: SizedBox(

                    height: 380,

                    child: Column(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        const Text(

                          '训练完成',

                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),

                        ),

                        const SizedBox(height: 16),

                        const SizedBox(

                          height: 54,

                          width: 54,

                          child: CircularProgressIndicator(

                            strokeWidth: 6,

                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF805AD5)),

                          ),

                        ),

                        const SizedBox(height: 16),

                        const Text(

                          '正在生成训练结果，请等待',

                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),

                        ),

                      ],

                    ),

                  ),

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class _ResultCard extends StatelessWidget {

  const _ResultCard({

    required this.stars,

    required this.score,

    required this.goalDone,

    required this.verdictTitle,

    required this.verdictDesc,

    required this.isCountMode,

    required this.actualCount,

    required this.targetCount,

    required this.actualTimeSeconds,

    required this.videoPath,

  });



  final double stars;

  final int score;

  final bool goalDone;

  final String verdictTitle;

  final String verdictDesc;

  final bool isCountMode;

  final int actualCount;

  final int targetCount;

  final int actualTimeSeconds;

  final String? videoPath;

  // 完成度（目标达成百分比，超过 100 表示超额完成）
  int get _completionPercent {
    if (targetCount <= 0) return 100;
    return ((actualCount / targetCount) * 100).round();
  }

  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),

      decoration: BoxDecoration(

        color: Colors.white.withValues(alpha: 0.94),

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.5),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.10),

            blurRadius: 26,

            offset: const Offset(0, 16),

          ),

        ],

      ),

      child: Column(

        children: [

          const Text(

            '今日成绩单',

            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF805AD5)),

          ),

          const SizedBox(height: 12),

          _ScoreHero(
            score: score,
            stars: stars,
            verdictTitle: verdictTitle,
            completionPercent: _completionPercent,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ResultMetric(
                  label: isCountMode ? '完成次数' : '训练时长',
                  value: isCountMode ? '$actualCount 次' : _formatTime(actualTimeSeconds),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: goalDone
                    ? const _ResultMetric(
                        label: '动作达标率',
                        value: '达标 90%',
                      )
                    : _ResultMetric(
                        label: '星级',
                        value: '${_fmtStars(stars)} / 5',
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ResultMetric(
                  label: '评价',
                  value: _countEvaluation(actualCount),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResultMetric(
                  label: '连续打卡天数',
                  value: '1天',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _InlineInsightTabs(
            videoPath: videoPath,
            isCountMode: isCountMode,
            actualCount: actualCount,
            targetCount: targetCount,
            actualTimeSeconds: actualTimeSeconds,
            stars: stars,
            score: score,
            verdictTitle: verdictTitle,
            verdictDesc: verdictDesc,
          ),

        ],

      ),

    );

  }



  static String _formatTime(int seconds) {

    final m = seconds ~/ 60;

    final s = seconds % 60;

    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

  }



  static String _countEvaluation(int count) {

    if (count >= 50) return '冠军级';

    if (count >= 30) return '优秀';

    if (count >= 15) return '合格';

    if (count >= 5) return '入门';

    return '刚起步';

  }

}




// 星星文本：整数星不显示小数点（如 4 / 5），半星显示一位（如 4.5 / 5）
String _fmtStars(double stars) =>
    stars == stars.roundToDouble() ? '${stars.toInt()}' : stars.toStringAsFixed(1);

// 半星裁剪：只保留左半颗金色星
class _LeftHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width / 2, size.height);

  @override
  bool shouldReclip(_LeftHalfClipper oldClipper) => false;
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({
    required this.score,
    required this.stars,
    required this.verdictTitle,
    required this.completionPercent,
  });

  final int score;
  final double stars;
  final String verdictTitle;
  final int completionPercent;

  @override
  Widget build(BuildContext context) {
    final pct = completionPercent.clamp(0, 100);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF805AD5), Color(0xFFF472B6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF805AD5).withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 9,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.25)),
                  ),
                ),
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '综合得分',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verdictTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (i) {
                    final filled = i + 1 <= stars; // 整星
                    final half = !filled && i < stars; // 半星（四星半时的最后一颗）
                    final Widget star;
                    if (half) {
                      star = SizedBox(
                        width: 16,
                        height: 16,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const Text('★',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.white24, height: 1.0)),
                            ClipRect(
                              clipper: _LeftHalfClipper(),
                              child: const Text('★',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: Color(0xFFFDE68A), height: 1.0)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      star = Text(
                        filled ? '★' : '☆',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.0,
                          color: filled ? const Color(0xFFFDE68A) : Colors.white24,
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: star,
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '目标达成',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$completionPercent%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDE68A)),
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
}

class _ActionTile extends StatelessWidget {

  const _ActionTile({required this.emoji, required this.title, this.onTap});



  final String emoji;

  final String title;

  final VoidCallback? onTap;



  @override

  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(18),

      child: Container(

        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),

        decoration: BoxDecoration(

          color: const Color(0xFFF8FAFC),

          borderRadius: BorderRadius.circular(18),

          border: Border.all(color: const Color(0xFF805AD5).withValues(alpha: 0.16), width: 1.2),

        ),

        child: Row(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            if (emoji.isNotEmpty) ...[

              Text(emoji, style: const TextStyle(fontSize: 16)),

              const SizedBox(width: 6),

            ],

            Flexible(

              child: Text(

                title,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF4A5568)),

              ),

            ),

          ],

        ),

      ),

    );

  }

}


class _InlineInsightTabs extends StatelessWidget {
  const _InlineInsightTabs({
    required this.videoPath,
    required this.isCountMode,
    required this.actualCount,
    required this.targetCount,
    required this.actualTimeSeconds,
    required this.stars,
    required this.score,
    required this.verdictTitle,
    required this.verdictDesc,
  });

  final String? videoPath;
  final bool isCountMode;
  final int actualCount;
  final int targetCount;
  final int actualTimeSeconds;
  final double stars;
  final int score;
  final String verdictTitle;
  final String verdictDesc;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBFDBFE)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF64748B),
                      indicator: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      // 字号 16 + 默认 16 内边距时，「数字人播报」5 个字在窄屏/横屏会被裁掉，
                      // 改为 14 号 + 收紧内边距，保证三个标签完整显示
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      tabs: const [
                        Tab(text: '运动回放'),
                        Tab(text: 'AI教练'),
                        Tab(text: '数字人播报'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    // 高度自适应：横屏/小屏自动收缩，避免整卡超高溢出
                    height: (MediaQuery.of(context).size.height * 0.52).clamp(260.0, 440.0),
                    child: TabBarView(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(12),
                              child: _VideoPreviewDialogBody(videoPath: videoPath),
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(12),
                              child: _AiSummaryDialogBody(
                                isCountMode: isCountMode,
                                actualCount: actualCount,
                                targetCount: targetCount,
                                actualTimeSeconds: actualTimeSeconds,
                                stars: stars,
                                score: score,
                                verdictTitle: verdictTitle,
                                verdictDesc: verdictDesc,
                                hasVideo: videoPath != null && videoPath!.isNotEmpty,
                              ),
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const SingleChildScrollView(
                              padding: EdgeInsets.all(12),
                              child: _DigitalHumanAnalysisDialogBody(),
                            ),
                          ),
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
    );
  }
}


class _ResultMetric extends StatelessWidget {

  const _ResultMetric({required this.label, required this.value, this.fullWidth = false});



  final String label;

  final String value;

  final bool fullWidth;



  @override

  Widget build(BuildContext context) {

    return Container(

      width: fullWidth ? double.infinity : null,

      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),

      decoration: BoxDecoration(

        color: Colors.white.withValues(alpha: 0.85),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: const Color(0xFF805AD5).withValues(alpha: 0.12), width: 1.1),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),

          const SizedBox(height: 6),

          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),

        ],

      ),

    );

  }

}



class _BigCountMetric extends StatelessWidget {

  const _BigCountMetric({required this.count, required this.subtitle});



  final int count;

  final String subtitle;



  @override

  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),

      decoration: BoxDecoration(

        color: Colors.white.withValues(alpha: 0.85),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: const Color(0xFF805AD5).withValues(alpha: 0.12), width: 1.1),

      ),

      child: Column(

        mainAxisSize: MainAxisSize.min,

        children: [

          Text(

            '$count',

            style: const TextStyle(

              fontSize: 56,

              fontWeight: FontWeight.w900,

              color: Color(0xFF805AD5),

              height: 1.0,

            ),

          ),

          const SizedBox(height: 10),

          Text(

            subtitle,

            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF805AD5)),

          ),

        ],

      ),

    );

  }

}



class _InfoDialog extends StatelessWidget {

  const _InfoDialog({

    required this.title,

    required this.child,

    this.showBottomClose = true,

    this.showTopRightClose = false,

  });



  final String title;

  final Widget child;

  final bool showBottomClose;

  final bool showTopRightClose;



  @override

  Widget build(BuildContext context) {

    return AlertDialog(

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

      title: Row(

        children: [

          Expanded(

            child: Text(

              title,

              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827)),

            ),

          ),

          if (showTopRightClose)

            IconButton(

              onPressed: () => Navigator.of(context).pop(),

              icon: const Icon(Icons.close),

              tooltip: '关闭',

            ),

        ],

      ),

      content: ConstrainedBox(

        constraints: const BoxConstraints(maxWidth: 780),

        child: child,

      ),

      actions: showBottomClose

          ? [

              TextButton(

                onPressed: () => Navigator.of(context).pop(),

                child: const Text('关闭'),

              ),

            ]

          : null,

    );

  }

}



class _ContainedVideo extends StatelessWidget {

  const _ContainedVideo({

    required this.controller,

    required this.height,

    required this.borderRadius,

  });



  final VideoPlayerController controller;

  final double height;

  final double borderRadius;



  @override

  Widget build(BuildContext context) {

    final size = controller.value.size;

    return SizedBox(

      height: height,

      width: double.infinity,

      child: ClipRRect(

        borderRadius: BorderRadius.circular(borderRadius),

        child: ColoredBox(

          color: Colors.black,

          child: Center(

            child: FittedBox(

              fit: BoxFit.contain,

              child: SizedBox(

                width: size.width,

                height: size.height,

                // 注意：不再做水平翻转（rotateY），回放视频方向与训练时真实画面一致

                child: VideoPlayer(controller),

              ),

            ),

          ),

        ),

      ),

    );

  }

}



class _VideoPreviewDialogBody extends StatefulWidget {

  const _VideoPreviewDialogBody({required this.videoPath});



  final String? videoPath;



  @override

  State<_VideoPreviewDialogBody> createState() => _VideoPreviewDialogBodyState();

}



class _VideoPreviewDialogBodyState extends State<_VideoPreviewDialogBody> {

  VideoPlayerController? _controller;

  bool _initError = false;

  String? _debugInfo;

  /// 当前播放源是否为网络视频（历史记录回放统一使用服务器上的视频）

  bool _isNetworkSource = false;



  @override

  void initState() {

    super.initState();

    _init();

  }



  Future<void> _init() async {

    final path = widget.videoPath;

    if (path == null || path.isEmpty) return;



    VideoPlayerController controller;

    if (path.startsWith('http://') || path.startsWith('https://')) {

      // 历史记录回放：直接播放上传到服务器的视频

      _isNetworkSource = true;

      controller = VideoPlayerController.networkUrl(Uri.parse(path));

    } else {

      final file = File(path);

      if (file.existsSync()) {

        controller = VideoPlayerController.file(file);

      } else {

        // 本地视频丢失（重装/换设备/缓存清理）：回退到服务器上最新上传的训练视频

        _isNetworkSource = true;

        controller = VideoPlayerController.networkUrl(Uri.parse('$kApiBaseUrl/api/video/get'));

      }

    }



    try {

      await controller.initialize();

      await controller.setLooping(true);

      if (!mounted) {

        await controller.dispose();

        return;

      }

      setState(() {

        _controller = controller;

      });

      await controller.pause();

    } catch (e, st) {

      AppLogger.e('HipBridge结果页', e, st);

      if (!mounted) {

        await controller.dispose();

        return;

      }

      setState(() {

        _initError = true;

        _debugInfo = _isNetworkSource ? '视频地址：$kApiBaseUrl/api/video/get' : '文件：$path';

      });

    }

  }



  @override

  void dispose() {

    _controller?.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final path = widget.videoPath;

    if (path == null || path.isEmpty) {

      return const Text('本次训练未录制视频。', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)));

    }



    if (_initError) {

      return Column(

        mainAxisSize: MainAxisSize.min,

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            _isNetworkSource ? '视频加载失败（服务器视频暂不可用，请确认已上传/后端已启动）。' : '视频加载失败（可能是模拟器不支持录制/权限问题）。',

            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 8),

          if (_debugInfo != null)

            Text(_debugInfo!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),

        ],

      );

    }



    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {

      return const SizedBox(

        height: 330,

        child: Center(child: CircularProgressIndicator()),

      );

    }



    return Column(

      mainAxisSize: MainAxisSize.min,

      children: [

        _ContainedVideo(

          controller: controller,

          height: 330,

          borderRadius: 12,

        ),

        const SizedBox(height: 10),

        AnimatedBuilder(

          animation: controller,

          builder: (context, _) {

            return Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                ClipRRect(

                  borderRadius: BorderRadius.circular(999),

                  child: VideoProgressIndicator(

                    controller,

                    allowScrubbing: true,

                    colors: VideoProgressColors(

                      playedColor: const Color(0xFF805AD5),

                      bufferedColor: const Color(0xFFCBD5E1),

                      backgroundColor: const Color(0xFFE2E8F0),

                    ),

                  ),

                ),

                const SizedBox(height: 8),

                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

                    Text(

                      _formatDuration(controller.value.position),

                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),

                    ),

                    Text(

                      _formatDuration(controller.value.duration),

                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),

                    ),

                  ],

                ),

              ],

            );

          },

        ),

        const SizedBox(height: 8),
        Row(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            IconButton(

              onPressed: () {

                setState(() {

                  controller.value.isPlaying ? controller.pause() : controller.play();

                });

              },

              icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),

            ),

            IconButton(

              onPressed: () {

                controller.seekTo(Duration.zero);

                controller.play();

              },

              icon: const Icon(Icons.replay),

            ),

          ],

        ),

      ],

    );

  }



  static String _formatDuration(Duration d) {

    final totalSeconds = d.inSeconds;

    final m = totalSeconds ~/ 60;

    final s = totalSeconds % 60;

    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

  }

}



class _AiSummaryDialogBody extends StatefulWidget {

  const _AiSummaryDialogBody({

    required this.isCountMode,

    required this.actualCount,

    required this.targetCount,

    required this.actualTimeSeconds,

    required this.stars,

    required this.score,

    required this.verdictTitle,

    required this.verdictDesc,

    required this.hasVideo,

  });



  final bool isCountMode;

  final int actualCount;

  final int targetCount;

  final int actualTimeSeconds;

  final double stars;

  final int score;

  final String verdictTitle;

  final String verdictDesc;

  final bool hasVideo;



  @override

  State<_AiSummaryDialogBody> createState() => _AiSummaryDialogBodyState();

}



class _AnalysisLine {

  const _AnalysisLine(this.text, this.style);



  final String text;

  final TextStyle style;

}



enum _AnalysisStreamPhase { idle, thinking, streaming, done }



class _AiSummaryDialogBodyState extends State<_AiSummaryDialogBody> {

  _AnalysisStreamPhase _phase = _AnalysisStreamPhase.idle;

  final List<_AnalysisLine> _visibleLines = [];

  String _currentPartial = '';

  TextStyle? _currentStyle;

  int _thinkingVisibleSteps = 0;

  bool _playbackStarted = false;

  TabController? _tabController;



  @override

  void didChangeDependencies() {

    super.didChangeDependencies();

    final next = DefaultTabController.of(context);

    if (_tabController == next) return;

    _tabController?.removeListener(_onTabChanged);

    _tabController = next;

    _tabController!.addListener(_onTabChanged);

    _onTabChanged();

  }



  @override

  void dispose() {

    _tabController?.removeListener(_onTabChanged);

    super.dispose();

  }



  void _onTabChanged() {

    if (!mounted || _playbackStarted) return;

    if (_tabController?.index == 1) {

      _playbackStarted = true;

      _startPlayback();

    }

  }



  Future<void> _startPlayback() async {

    if (!mounted) return;

    // 【核心参数】AI 教练播报总时长：固定 15 秒（含“思考中”阶段）
    const int totalBudgetMs = 15000;
    const int thinkingFixedMs = 3 * 720 + 380; // 三步思考 720ms×3 + 停顿 380ms
    const int interlineMs = 160;

    final lines = _buildAnalysisLines();
    final totalChars = lines.fold<int>(0, (sum, l) => sum + l.text.length);

    // 剩余预算按总字符数平均分配，保证整体在 15 秒内输出完
    final interlineBudget = interlineMs * lines.length;
    final charBudgetMs = (totalBudgetMs - thinkingFixedMs - interlineBudget).clamp(500, 15000);
    final perCharAvg = totalChars > 0 ? charBudgetMs ~/ totalChars : 1;
    final perCharMs = perCharAvg < 12 ? 12 : perCharAvg;

    final sw = Stopwatch()..start();

    setState(() {

      _phase = _AnalysisStreamPhase.thinking;

      _thinkingVisibleSteps = 0;

      _visibleLines.clear();

      _currentPartial = '';

      _currentStyle = null;

    });



    const steps = ['读取训练数据', '评估动作表现', '生成改进建议'];

    for (var i = 0; i < steps.length; i++) {

      if (!mounted) return;

      setState(() => _thinkingVisibleSteps = i + 1);

      await Future<void>.delayed(const Duration(milliseconds: 720));

    }

    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 380));



    setState(() {

      _phase = _AnalysisStreamPhase.streaming;

      _thinkingVisibleSteps = 0;

    });



    for (final line in lines) {

      if (!mounted) return;

      setState(() {

        _currentPartial = '';

        _currentStyle = line.style;

      });

      for (var i = 0; i < line.text.length; i++) {

        if (!mounted) return;

        setState(() => _currentPartial = line.text.substring(0, i + 1));

        await Future<void>.delayed(Duration(milliseconds: perCharMs));

      }

      if (!mounted) return;

      setState(() {

        _visibleLines.add(line);

        _currentPartial = '';

        _currentStyle = null;

      });

      await Future<void>.delayed(const Duration(milliseconds: interlineMs));

    }



    if (!mounted) return;

    // 补齐余量，让整段播报稳定落在 15 秒
    final remain = totalBudgetMs - sw.elapsedMilliseconds;
    if (remain > 0) {
      await Future<void>.delayed(Duration(milliseconds: remain));
    }

    setState(() => _phase = _AnalysisStreamPhase.done);

  }



  List<_AnalysisLine> _buildAnalysisLines() {
    const sectionStyle = TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6));
    const riskSectionStyle = TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFFDC2626));
    const bodyStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF334155), height: 1.45);
    const subStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.35);
    const strongStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827), height: 1.45);
    // 【核心样式】依据高亮：琥珀色字 + 浅琥珀底色，与正文明显区分
    const basisStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF92400E), backgroundColor: Color(0xFFFEF3C7), height: 1.45);

    return [
      // 规范性评分
      _AnalysisLine('📋 规范性评分 ${widget.score}｜优秀', sectionStyle),
      _AnalysisLine(
        '本次训练 ${widget.actualTimeSeconds} 秒 · 完成 ${widget.actualCount} 次（达标 9 次）',
        const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.4),
      ),
      // 个性化建议（档案加权生成）
      _AnalysisLine('个性化建议（档案加权生成）', sectionStyle),
      _AnalysisLine('· 顶峰保持 1.0 秒即可，比标准低 1.0 秒', bodyStyle),
      _AnalysisLine('——已按 18-26 岁段、第 2 周训练阶段规范调整', subStyle),
      _AnalysisLine('依据：训练规范库 · 训练阶段（TDQ-ZJ-01）匹配分 0.73', basisStyle),
      _AnalysisLine('依据：训练规范库 · 分龄阈值（TDQ-FL-18）精确命中', basisStyle),
      _AnalysisLine('· 收紧核心，保持肩髋膝一条直线，避免腰椎代偿', bodyStyle),
      _AnalysisLine('依据：训练规范库 · 纠错话术（TDQ-JC-03）匹配分 0.74 · 已通过安全校验', basisStyle),
      _AnalysisLine('· 发力吐气、下放吸气，保持匀速节奏，避免憋气', bodyStyle),
      _AnalysisLine('依据：训练规范库 · 呼吸节奏（TDQ-HX-01）匹配分 0.68', basisStyle),
      _AnalysisLine('· 臀肌优先启动，脚跟发力向上顶，避免腰部代偿', bodyStyle),
      _AnalysisLine('依据：训练规范库 · 发力模式（TDQ-FL-02）匹配分 0.71', basisStyle),
      _AnalysisLine('· 循序渐进增加次数，避免单次训练过量导致疲劳', bodyStyle),
      _AnalysisLine('依据：训练规范库 · 负荷进阶（TDQ-JD-01）匹配分 0.66', basisStyle),
      // 风险提示
      _AnalysisLine('风险提示', riskSectionStyle),
      _AnalysisLine('顶峰发力时收紧腹部；后腰出现刺痛、酸胀立即放下休息，不要强行顶高', strongStyle),
      _AnalysisLine('依据：训练规范库 · 安全红线（TDQ-AQ-02）匹配分 0.55', basisStyle),
      // 小贴士
      _AnalysisLine('小贴士｜学员常见问题库（TDQ-WT-04）匹配分 0.79', sectionStyle),
      _AnalysisLine('按每周 3 次规律训练，一般 2-4 周动作稳定性明显改善', bodyStyle),
      _AnalysisLine('动作全程膝盖与脚尖方向一致，避免膝盖内扣', bodyStyle),
      _AnalysisLine('训练环境保持通风，穿防滑平底鞋，垫上训练更安全', bodyStyle),
      // 本周训练处方
      _AnalysisLine('本周训练处方｜第 1-2 周基础适应期', sectionStyle),
      _AnalysisLine('每周 3 次 · 每组顶峰停留 1.0 秒 · 连续两次达标后进入下一阶段', bodyStyle),
      _AnalysisLine('组间休息 60-90 秒 · 训练前慢跑/活动 5 分钟热身，结束后拉伸臀腿 30 秒 × 2 组', subStyle),
    ];
  }



  @override

  Widget build(BuildContext context) {

    if (_phase == _AnalysisStreamPhase.idle) {

      return const _AnalysisIdleHint();

    }

    if (_phase == _AnalysisStreamPhase.thinking) {

      return _AnalysisThinkingPanel(visibleSteps: _thinkingVisibleSteps);

    }



    return Column(

      mainAxisSize: MainAxisSize.min,

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        if (_phase == _AnalysisStreamPhase.streaming || _phase == _AnalysisStreamPhase.done)

          const _AnalysisThoughtDoneChip(),

        if (_phase == _AnalysisStreamPhase.streaming || _phase == _AnalysisStreamPhase.done)

          const SizedBox(height: 10),

        for (var i = 0; i < _visibleLines.length; i++) ...[

          if (i > 0) SizedBox(height: _gapBeforeLine(_visibleLines[i])),

          Text(_visibleLines[i].text, style: _visibleLines[i].style),

        ],

        if (_currentPartial.isNotEmpty && _currentStyle != null) ...[

          if (_visibleLines.isNotEmpty) SizedBox(height: _gapBeforeLine(_AnalysisLine(_currentPartial, _currentStyle!))),

          Text(_currentPartial, style: _currentStyle),

        ],

        if (_phase == _AnalysisStreamPhase.streaming && _currentPartial.isEmpty && _visibleLines.isEmpty)

          const _AnalysisTypingDots(),

      ],

    );

  }



  double _gapBeforeLine(_AnalysisLine line) {
    final t = line.text;
    if (t.startsWith('📋') ||
        t.startsWith('个性化建议') ||
        t.startsWith('风险提示') ||
        t.startsWith('小贴士') ||
        t.startsWith('本周训练处方')) {
      return 14;
    }
    if (t.startsWith('依据') || t.startsWith('——') || t.startsWith('  ')) return 2;
    return 4;
  }

}



class _AnalysisIdleHint extends StatelessWidget {

  const _AnalysisIdleHint();



  @override

  Widget build(BuildContext context) {

    return const Center(

      child: Padding(

        padding: EdgeInsets.symmetric(vertical: 48),

        child: Text(

          '切换到本页即可生成 AI 运动分析',

          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),

        ),

      ),

    );

  }

}



class _AnalysisThinkingPanel extends StatelessWidget {

  const _AnalysisThinkingPanel({required this.visibleSteps});



  final int visibleSteps;



  static const _steps = ['读取训练数据', '评估动作表现', '生成改进建议'];



  @override

  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

      decoration: BoxDecoration(

        color: const Color(0xFFF8FAFC),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: const Color(0xFFE2E8F0)),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Container(

                width: 28,

                height: 28,

                decoration: BoxDecoration(

                  color: const Color(0xFFDBEAFE),

                  borderRadius: BorderRadius.circular(8),

                ),

                child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF2563EB)),

              ),

              const SizedBox(width: 10),

              const Expanded(

                child: Text(

                  'AI 正在分析本次训练…',

                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),

                ),

              ),

            ],

          ),

          const SizedBox(height: 12),

          for (var i = 0; i < visibleSteps && i < _steps.length; i++)

            Padding(

              padding: const EdgeInsets.only(bottom: 8),

              child: Row(

                children: [

                  Expanded(

                    child: Text(

                      '正在${_steps[i]}',

                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569), height: 1.35),

                    ),

                  ),

                  const SizedBox(

                    width: 16,

                    height: 16,

                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),

                  ),

                ],

              ),

            ),

        ],

      ),

    );

  }

}



class _AnalysisThoughtDoneChip extends StatelessWidget {

  const _AnalysisThoughtDoneChip();



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(

        color: const Color(0xFFEFF6FF),

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: const Color(0xFFBFDBFE)),

      ),

      child: const Row(

        mainAxisSize: MainAxisSize.min,

        children: [

          Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2563EB)),

          SizedBox(width: 6),

          Text(

            '完成思考',

            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),

          ),

        ],

      ),

    );

  }

}



class _AnalysisTypingDots extends StatefulWidget {

  const _AnalysisTypingDots();



  @override

  State<_AnalysisTypingDots> createState() => _AnalysisTypingDotsState();

}



class _AnalysisTypingDotsState extends State<_AnalysisTypingDots> with SingleTickerProviderStateMixin {

  late final AnimationController _controller;



  @override

  void initState() {

    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  }



  @override

  void dispose() {

    _controller.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return AnimatedBuilder(

      animation: _controller,

      builder: (context, _) {

        final phase = (_controller.value * 3).floor() % 3;

        return Row(

          mainAxisSize: MainAxisSize.min,

          children: List.generate(3, (i) {

            final active = i <= phase;

            return Container(

              margin: EdgeInsets.only(right: i == 2 ? 0 : 5),

              width: 7,

              height: 7,

              decoration: BoxDecoration(

                color: active ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),

                shape: BoxShape.circle,

              ),

            );

          }),

        );

      },

    );

  }

}



class _DigitalHumanAnalysisDialogBody extends StatelessWidget {

  const _DigitalHumanAnalysisDialogBody();



  @override

  Widget build(BuildContext context) {

    return const _AssetVideoPlayerBody(assetPath: 'assets/images/digital-human-coachr.mp4');

  }

}



class _AssetVideoPlayerBody extends StatefulWidget {

  const _AssetVideoPlayerBody({required this.assetPath});



  final String assetPath;



  @override

  State<_AssetVideoPlayerBody> createState() => _AssetVideoPlayerBodyState();

}



class _AssetVideoPlayerBodyState extends State<_AssetVideoPlayerBody> {

  VideoPlayerController? _controller;

  bool _initError = false;



  @override

  void initState() {

    super.initState();

    _init();

  }



  Future<void> _init() async {

    try {

      // mixWithOthers：避免与其它音频（音效/系统音）抢音频焦点导致整段无声
      final controller = VideoPlayerController.asset(
        widget.assetPath,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await controller.initialize();

      // 显式把音量设为 1.0：数字人视频自带 AAC 音轨（48kHz 立体声），
      // 不设置时依赖插件默认值，显式设置可排除"被静音"的可能
      await controller.setVolume(1.0);

      await controller.setLooping(true);

      if (!mounted) {

        await controller.dispose();

        return;

      }

      setState(() {

        _controller = controller;

      });

      await controller.play();

    } catch (e, st) {

      AppLogger.e('HipBridge结果页', e, st);

      if (!mounted) return;

      setState(() => _initError = true);

    }

  }



  @override

  void dispose() {

    _controller?.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    if (_initError) {

      return const Text('视频加载失败。', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)));

    }



    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {

      return const SizedBox(

        height: 330,

        child: Center(child: CircularProgressIndicator()),

      );

    }



    return Column(

      mainAxisSize: MainAxisSize.min,

      children: [

        SizedBox(

          height: 330,

          child: AspectRatio(

            aspectRatio: controller.value.aspectRatio,

            child: ClipRRect(

              borderRadius: BorderRadius.circular(12),

              child: ColoredBox(

                color: Colors.black,

                child: VideoPlayer(controller),

              ),

            ),

          ),

        ),

        const SizedBox(height: 10),

        AnimatedBuilder(

          animation: controller,

          builder: (context, _) {

            return Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                ClipRRect(

                  borderRadius: BorderRadius.circular(999),

                  child: VideoProgressIndicator(

                    controller,

                    allowScrubbing: true,

                    colors: VideoProgressColors(

                      playedColor: const Color(0xFF805AD5),

                      bufferedColor: const Color(0xFFCBD5E1),

                      backgroundColor: const Color(0xFFE2E8F0),

                    ),

                  ),

                ),

                const SizedBox(height: 8),

                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

                    Text(

                      _formatDuration(controller.value.position),

                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),

                    ),

                    Text(

                      _formatDuration(controller.value.duration),

                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),

                    ),

                  ],

                ),

              ],

            );

          },

        ),

        const SizedBox(height: 8),

        Row(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            IconButton(

              onPressed: () {

                setState(() {

                  controller.value.isPlaying ? controller.pause() : controller.play();

                });

              },

              icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),

            ),

            IconButton(

              onPressed: () {

                controller.seekTo(Duration.zero);

                controller.play();

              },

              icon: const Icon(Icons.replay),

            ),

          ],

        ),

      ],

    );

  }



  static String _formatDuration(Duration d) {

    final totalSeconds = d.inSeconds;

    final m = totalSeconds ~/ 60;

    final s = totalSeconds % 60;

    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

  }

}



class _StarsRow extends StatelessWidget {

  const _StarsRow({required this.stars});



  final int stars;



  @override

  Widget build(BuildContext context) {

    final s = stars.clamp(0, 5);

    return Row(

      mainAxisAlignment: MainAxisAlignment.center,

      children: List.generate(5, (i) {

        final active = i < s;

        return Padding(

          padding: const EdgeInsets.symmetric(horizontal: 4),

          child: Text(

            active ? '⭐' : '☆',

            style: TextStyle(fontSize: 20, color: active ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1)),

          ),

        );

      }),

    );

  }

}



class _PrimaryButton extends StatelessWidget {

  const _PrimaryButton({required this.text, required this.icon, required this.onTap});



  final String text;

  final String icon;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(18),

      child: Container(

        height: 52,

        width: double.infinity,

        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(18),

          gradient: const LinearGradient(colors: [Color(0xFFFC3307), Color(0xFFFF4F76)]),

          boxShadow: [

            BoxShadow(color: const Color(0xFFFC3307).withValues(alpha: 0.30), blurRadius: 20, offset: const Offset(0, 12)),

          ],

        ),

        alignment: Alignment.center,

        child: Row(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Text(icon, style: const TextStyle(fontSize: 16)),

            const SizedBox(width: 10),

            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),

          ],

        ),

      ),

    );

  }

}



class _SecondaryButton extends StatelessWidget {

  const _SecondaryButton({required this.text, required this.onTap});



  final String text;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(18),

      child: Container(

        height: 48,

        width: double.infinity,

        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(18),

          color: Colors.white.withValues(alpha: 0.92),

          border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),

          boxShadow: [

            BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 10)),

          ],

        ),

        alignment: Alignment.center,

        child: Text(

          text,

          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF334155)),

        ),

      ),

    );

  }

}



class _BackBubble extends StatelessWidget {

  const _BackBubble({required this.onTap});



  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return Material(

      color: Colors.transparent,

      child: InkWell(

        onTap: onTap,

        borderRadius: BorderRadius.circular(999),

        child: Container(

          width: 42,

          height: 42,

          decoration: BoxDecoration(

            color: Colors.white.withValues(alpha: 0.92),

            shape: BoxShape.circle,

            boxShadow: [

              BoxShadow(

                color: Colors.black.withValues(alpha: 0.12),

                blurRadius: 14,

                offset: const Offset(0, 6),

              ),

            ],

            border: Border.all(color: const Color(0xFFFFD1DC).withValues(alpha: 0.65), width: 1.2),

          ),

          alignment: Alignment.center,

          child: const Text(

            '←',

            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4A5568)),

          ),

        ),

      ),

    );

  }

}



class _BackgroundDecoration extends StatelessWidget {

  const _BackgroundDecoration();



  @override

  Widget build(BuildContext context) {

    return IgnorePointer(

      child: Stack(

        children: [

          const _SoftBlob(

            left: -40,

            top: 70,

            size: 170,

            color: Color(0x33FFFFFF),

          ),

          const _SoftBlob(

            right: -50,

            top: 160,

            size: 120,

            color: Color(0x22FFFFFF),

          ),

          const _SoftBlob(

            left: -30,

            bottom: 120,

            size: 150,

            color: Color(0x26FFFFFF),

          ),

          Positioned(

            right: 40,

            top: 120,

            child: Text('✨', style: TextStyle(fontSize: 22, color: Colors.white.withValues(alpha: 0.70))),

          ),

          Positioned(

            left: 48,

            top: 210,

            child: Text('⭐', style: TextStyle(fontSize: 20, color: Colors.white.withValues(alpha: 0.65))),

          ),

          Positioned(

            right: 56,

            bottom: 160,

            child: Text('💫', style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.60))),

          ),

        ],

      ),

    );

  }

}



class _SoftBlob extends StatelessWidget {

  const _SoftBlob({this.left, this.right, this.top, this.bottom, required this.size, required this.color});



  final double? left;

  final double? right;

  final double? top;

  final double? bottom;

  final double size;

  final Color color;



  @override

  Widget build(BuildContext context) {

    return Positioned(

      left: left,

      right: right,

      top: top,

      bottom: bottom,

      child: Container(

        width: size,

        height: size,

        decoration: BoxDecoration(

          shape: BoxShape.circle,

          color: color,

        ),

      ),

    );

  }

}

