import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_share_page.dart';
import 'jump_challenge_page.dart';
import '../../utils/app_logger.dart';
import '../../utils/user_scope.dart';

class ChallengeResultPage extends StatefulWidget {
  const ChallengeResultPage({
    super.key,
    required this.level,
    required this.completedCount,
    required this.timeUsedSeconds,
    required this.playerScore,
    required this.earnedStars,
    this.title = '闯关结果',
  });

  final JumpChallengeLevel level;
  final int completedCount;
  final int timeUsedSeconds;
  final int playerScore;
  final int earnedStars;
  final String title;

  @override
  State<ChallengeResultPage> createState() => _ChallengeResultPageState();
}

class _ChallengeResultPageState extends State<ChallengeResultPage> {
  bool _isGeneratingResult = true;

  // 【核心输出变量】通关奖励金币：整场只发放一次，累加到闯关页右上角
  bool _coinGranted = false;

  String get _coinKey {
    final user = (UserScope.username ?? '').trim();
    return 'game_coins_${user.isEmpty ? 'guest' : user}';
  }

  /// 将本次奖励金币累计到本地存储（闯关页右上角读数）
  Future<void> _grantCoins(int coin) async {
    if (coin <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_coinKey) ?? 0;
      await prefs.setInt(_coinKey, current + coin);
    } catch (e, st) {
      AppLogger.e('挑战结果', e, st);
    }
  }

  @override
  void initState() {
    super.initState();
    _autoFinishGenerating();
  }

  Future<void> _autoFinishGenerating() async {
    final ms = 2000 + math.Random().nextInt(1001);
    await Future.delayed(Duration(milliseconds: ms));
    if (!mounted) return;
    setState(() => _isGeneratingResult = false);
  }

  void _finishGenerating() {
    if (!_isGeneratingResult) return;
    setState(() => _isGeneratingResult = false);
  }

  @override
  Widget build(BuildContext context) {
    // 【遵义关卡 - 写死展示值】遵义关卡结束后，本次得分固定 94，星星数固定 4，任务完成度固定 97%
    final isZunyiLevel = widget.level.name.contains('遵义');
    final score = isZunyiLevel ? 94 : widget.playerScore.clamp(0, 100);
    final stars = isZunyiLevel ? 4 : widget.earnedStars.clamp(0, 5);
    final completion = isZunyiLevel
        ? '97%'
        : _completionSummary(level: widget.level, completedCount: widget.completedCount);
    final verdict = _verdict(
      level: widget.level,
      completedCount: widget.completedCount,
      timeUsedSeconds: widget.timeUsedSeconds,
      score: score,
      stars: stars,
    );
    final rewards = _rewards(level: widget.level, completedCount: widget.completedCount, timeUsedSeconds: widget.timeUsedSeconds, stars: stars);

    // 通关后把本次奖励金币发放一次（写入本地，供闯关页右上角累加显示）
    if (!_coinGranted && widget.completedCount >= widget.level.targetCount && rewards.coin > 0) {
      _coinGranted = true;
      final grantedCoin = rewards.coin;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _grantCoins(grantedCoin);
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
          ),
        ),
        child: SafeArea(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Stack(
              children: [
                const Positioned.fill(child: _BackgroundDecoration()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _GlassBackButton(onTap: () => Navigator.of(context).maybePop()),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 320),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: _isGeneratingResult
                                      ? _ResultCardGeneratingPanel(
                                          key: const ValueKey('generating'),
                                          onTap: _finishGenerating,
                                        )
                                      : _ResultCard(
                                          key: const ValueKey('result'),
                                          score: score,
                                          stars: stars,
                                          completion: completion,
                                          verdictTitle: verdict.title,
                                          verdictDesc: verdict.desc,
                                          xp: rewards.xp,
                                          coin: rewards.coin,
                                          badge: rewards.badge,
                                        ),
                                ),
                                const SizedBox(height: 18),
                                IgnorePointer(
                                  ignoring: _isGeneratingResult,
                                  child: AnimatedOpacity(
                                  opacity: _isGeneratingResult ? 0.45 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Column(
                                      children: [
                                        _PrimaryButton(
                                          text: '分享成绩',
                                          icon: Icons.ios_share_rounded,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => GameSharePage(playerScore: score, earnedStars: stars),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _SecondaryButton(
                                                text: '再来一次',
                                                onTap: () => Navigator.of(context).maybePop(),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _SecondaryButton(
                                                text: '返回闯关',
                                                onTap: () => Navigator.of(context).maybePop(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }

  static String _completionSummary({required JumpChallengeLevel level, required int completedCount}) {
    final target = level.targetCount <= 0 ? 1 : level.targetCount;
    final done = completedCount.clamp(0, target);
    final p = (done / target * 100).round();
    return '$done/$target（$p%）';
  }

  static _Verdict _verdict({
    required JumpChallengeLevel level,
    required int completedCount,
    required int timeUsedSeconds,
    required int score,
    required int stars,
  }) {
    final target = level.targetCount <= 0 ? 1 : level.targetCount;
    final done = completedCount.clamp(0, target);
    final ratio = (done / target).clamp(0.0, 1.0);
    final timeLimit = level.timeLimitSeconds <= 0 ? 60 : level.timeLimitSeconds;
    final inTime = timeUsedSeconds <= timeLimit;
    final passed = done >= target && inTime;

    if (passed && (stars >= 4 || score >= 90) && timeUsedSeconds <= (timeLimit * 0.75).round()) {
      return const _Verdict(title: '🚀 超级通关！', desc: '目标完成得又快又稳，动作很标准～');
    }
    if (passed) {
      return const _Verdict(title: '🎉 顺利通关！', desc: '你完成了本关目标，继续保持节奏～');
    }
    if (!inTime && ratio >= 0.8) {
      return const _Verdict(title: '⏳ 差一点点！', desc: '完成度很高了，再快一点点就能通关～');
    }
    if (ratio >= 0.6) {
      return const _Verdict(title: '💪 做得不错', desc: '你已经接近目标了，下一次更稳更快～');
    }
    return const _Verdict(title: '✨ 继续加油', desc: '先把动作做标准，再慢慢把次数加上来。');
  }
  static _Rewards _rewards({
    required JumpChallengeLevel level,
    required int completedCount,
    required int timeUsedSeconds,
    required int stars,
  }) {
    final target = level.targetCount <= 0 ? 1 : level.targetCount;
    final done = completedCount.clamp(0, target);
    final ratio = (done / target).clamp(0.0, 1.0);
    final timeLimit = level.timeLimitSeconds <= 0 ? 60 : level.timeLimitSeconds;

    final baseXp = level.id == 2 ? 120 : 120 + (target ~/ 2);
    final baseCoin = 30 + (level.id % 5) * 10;

    final inTime = timeUsedSeconds <= timeLimit;
    final passed = done >= target && inTime;

    if (!passed) {
      final xp = (baseXp * ratio).round().clamp(0, baseXp);
      final coin = (baseCoin * ratio).round().clamp(0, baseCoin);
      final badge = ratio >= 0.8 ? '勇敢挑战' : '继续努力';
      return _Rewards(xp: xp, coin: coin, badge: badge);
    }

    final speedBonus = timeUsedSeconds <= (timeLimit * 0.75).round() ? 20 : 0;
    final starBonusXp = stars * 10;
    final starBonusCoin = stars >= 4 ? 20 : (stars >= 2 ? 10 : 0);

    final xp = level.id == 2 ? 120 : baseXp + speedBonus + starBonusXp;
    final coin = math.min(50, baseCoin + speedBonus + starBonusCoin);
    const badge = '完成本关';
    return _Rewards(xp: xp, coin: coin, badge: badge);
  }
}

class _Rewards {
  const _Rewards({required this.xp, required this.coin, required this.badge});

  final int xp;
  final int coin;
  final String badge;
}

class _Verdict {
  const _Verdict({required this.title, required this.desc});

  final String title;
  final String desc;
}

class _ResultIconBadge extends StatelessWidget {
  const _ResultIconBadge({
    required this.icon,
    required this.gradient,
    required this.iconColor,
    this.size = 36,
    this.iconSize = 20,
  });

  final IconData icon;
  final List<Color> gradient;
  final Color iconColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }
}

class _ResultCardFrame extends StatelessWidget {
  const _ResultCardFrame({required this.child});

  final Widget child;

  static BoxDecoration decoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 26,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: decoration(),
      child: child,
    );
  }
}

class _ResultCardGeneratingPanel extends StatelessWidget {
  const _ResultCardGeneratingPanel({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _ResultCardFrame(
        child: const SizedBox(
          height: 380,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '闯关完成',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 54,
                width: 54,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '正在生成通关成绩单，请等待',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    super.key,
    required this.score,
    required this.stars,
    required this.completion,
    required this.verdictTitle,
    required this.verdictDesc,
    required this.xp,
    required this.coin,
    required this.badge,
  });

  final int score;
  final int stars;
  final String completion;
  final String verdictTitle;
  final String verdictDesc;
  final int xp;
  final int coin;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return _ResultCardFrame(
      child: Column(
        children: [
          const Text(
            '通关成绩单',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ScoreTile(
                  title: '本次得分',
                  value: score.toString(),
                  suffix: '分',
                  accent: const Color(0xFFDC2626),
                  icon: Icons.emoji_events_rounded,
                  iconGradient: const [Color(0xFFFFB347), Color(0xFFFF6B35)],
                  iconColor: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScoreTile(
                  title: '获得星星',
                  value: stars.toString(),
                  suffix: '⭐',
                  accent: const Color(0xFFF59E0B),
                  icon: Icons.star_rounded,
                  iconGradient: const [Color(0xFFFDE68A), Color(0xFFFBBF24)],
                  iconColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ScoreTile(
            title: '任务完成度',
            value: completion,
            suffix: '',
            accent: const Color(0xFF2563EB),
            icon: Icons.verified_rounded,
            iconGradient: const [Color(0xFF60A5FA), Color(0xFF2563EB)],
            iconColor: Colors.white,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.18), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ResultIconBadge(
                  icon: Icons.rocket_launch_rounded,
                  gradient: [Color(0xFF7DD3FC), Color(0xFF2563EB)],
                  iconColor: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(verdictTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(
                        verdictDesc,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.16), width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _RewardPill(
                    text: '+$xp 经验',
                    tint: const Color(0xFFFFF7ED),
                    border: const Color(0xFFF59E0B),
                    icon: Icons.bolt_rounded,
                    iconGradient: const [Color(0xFFFBBF24), Color(0xFFF97316)],
                    iconColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RewardPill(
                    text: '+$coin 金币',
                    tint: const Color(0xFFEFF6FF),
                    border: const Color(0xFF60A5FA),
                    icon: Icons.paid_rounded,
                    iconGradient: const [Color(0xFFFDE68A), Color(0xFFEAB308)],
                    iconColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RewardPill(
                    text: badge,
                    tint: const Color(0xFFF0FDF4),
                    border: const Color(0xFF34D399),
                    icon: Icons.military_tech_rounded,
                    iconGradient: const [Color(0xFF6EE7B7), Color(0xFF10B981)],
                    iconColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StarsRow(stars: stars),
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({
    required this.icon,
    required this.text,
    required this.tint,
    required this.border,
    required this.iconGradient,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color tint;
  final Color border;
  final List<Color> iconGradient;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ResultIconBadge(
            icon: icon,
            gradient: iconGradient,
            iconColor: iconColor,
            size: 28,
            iconSize: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.title,
    required this.value,
    required this.suffix,
    required this.accent,
    required this.icon,
    required this.iconGradient,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String suffix;
  final Color accent;
  final IconData icon;
  final List<Color> iconGradient;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.16), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ResultIconBadge(
                icon: icon,
                gradient: iconGradient,
                iconColor: iconColor,
                size: 34,
                iconSize: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: accent, height: 1),
              ),
              const SizedBox(width: 6),
              Text(
                suffix,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final active = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            active ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 26,
            color: active ? const Color(0xFFFBBF24) : const Color(0xFFCBD5E1),
            shadows: active
                ? [
                    Shadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.text, required this.icon, required this.onTap});

  final String text;
  final IconData icon;
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
          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
          boxShadow: [
            BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 12)),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
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

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 10),
            )
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white),
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
