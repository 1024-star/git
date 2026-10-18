import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

import 'camera_jump_challenge_page.dart';
import 'jump_challenge_page.dart';
import '../../utils/app_logger.dart';
import '../../utils/user_scope.dart';

class ChallengePreparePage extends StatefulWidget {
  const ChallengePreparePage({
    super.key,
    required this.pageTitle,
    required this.challengeLevel,
    required this.backgroundAsset,
    required this.levelName,
    required this.levelDescription,
    required this.levelColor,
  });

  final String pageTitle;
  final JumpChallengeLevel challengeLevel;
  final String backgroundAsset;

  final String levelName;
  final String levelDescription;
  final Color levelColor;

  @override
  State<ChallengePreparePage> createState() => _ChallengePreparePageState();
}

class _ChallengePreparePageState extends State<ChallengePreparePage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  static const int _requiredWatchSeconds = 5;
  static const String _gateVideoAssetJinggangshan ='assets/images/beiping-lugouqiao-digital-person.mov' ;
  static const String _gateVideoAssetBeiping = 'assets/images/jinggangshan-digital-person.mov';
  static const String _gateVideoAssetZunyiB = 'assets/images/zunyi-b-digital-person.mp4';

  late final VideoPlayerController _videoController;

  bool _videoReady = false;
  bool _videoInitFailed = false;
  bool _gateSatisfied = false;
  bool _gateDialogShown = false;
  bool _gateCounting = false;
  int _watchedSeconds = 0;

  final ValueNotifier<int> _watchedSecondsNotifier = ValueNotifier<int>(0);

  Timer? _videoInitTimeout;

  String _resolveGateVideoAsset() {
    final name = widget.levelName;
    // b 用户遵义关卡：使用指定的播报视频；a 用户保持原样
    if (UserScope.isDemo && UserScope.username == 'lzf' && name.contains('遵义')) {
      return _gateVideoAssetZunyiB;
    }
    if (name.contains('遵义')) {
      return _gateVideoAssetJinggangshan;
    }
    if (name.contains('井冈山')) {
      return _gateVideoAssetBeiping;
    }
    return _gateVideoAssetBeiping;
  }

  String _resolveStoryHintText() {
    final name = widget.levelName;
    if (name.contains('遵义')) {
      return '1935 年 1 月 15 日至 17 日，中共中央于红军长征途中抵达贵州遵义，针对第五次反 “围剿” 失利和长征初期的惨重损失，召开中央政治局扩大会议，会议集中纠正了博古、李德等人的 “左” 倾军事指挥错误，改组中央领导机构，增选毛泽东为中央政治局常委，确立了毛泽东在党中央和红军的领导地位。这一会议史称 “遵义会议”，它标志着中国共产党从幼年走向成熟，也揭开了中国革命转危为安、走向胜利的序幕';
    }
    return '1937年7月7日夜，日本侵略军借口一名士兵在军事演习中失踪，要求进入北平西南的宛平县城搜查，遭到中国守军严词拒绝后，日军随即向卢沟桥一带的中国军队发起攻击，并炮轰宛平城，中国守军第29军奋起抵抗。这一事件史称“七七事变”，它标志着日本帝国主义全面侵华战争的开始，也揭开了中华民族全民族抗战的序幕。';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _float = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _videoController = VideoPlayerController.asset(_resolveGateVideoAsset());
    _initGateMedia();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showGateDialogIfNeeded();
    });
  }

  Future<void> _initGateMedia() async {
    _videoInitTimeout?.cancel();
    _videoInitTimeout = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_videoController.value.isInitialized) return;
      setState(() {
        _videoInitFailed = true;
      });
    });

    try {
      await _videoController.initialize();
      await _videoController.setLooping(false);
      await _videoController.setVolume(1.0);
      _videoController.addListener(_onVideoTick);

      _videoInitTimeout?.cancel();
      _videoInitTimeout = null;

      if (!mounted) return;
      setState(() {
        _videoReady = true;
        _videoInitFailed = false;
      });
    } catch (e, st) {
      AppLogger.e('挑战准备', e, st);
      _videoInitTimeout?.cancel();
      _videoInitTimeout = null;

      if (!mounted) return;
      setState(() {
        _videoReady = false;
        _videoInitFailed = true;
      });
    }
  }

  Future<void> _retryVideoInit() async {
    try {
      await _videoController.initialize();
      await _videoController.setLooping(false);
      await _videoController.setVolume(1.0);
      if (!mounted) return;
      setState(() {
        _videoReady = true;
        _videoInitFailed = false;
      });
    } catch (e, st) {
      AppLogger.e('挑战准备', e, st);
      if (!mounted) return;
      setState(() {
        _videoReady = false;
        _videoInitFailed = true;
      });
    }
  }

  void _onVideoTick() {
    if (!_gateCounting) return;
    if (!_videoController.value.isInitialized) return;
    if (!_videoController.value.isPlaying) return;

    final seconds = _videoController.value.position.inSeconds;
    if (seconds <= _watchedSeconds) return;

    final nextWatched = seconds.clamp(0, _requiredWatchSeconds);
    if (nextWatched == _watchedSeconds) return;

    setState(() {
      _watchedSeconds = nextWatched;
      _watchedSecondsNotifier.value = _watchedSeconds;
      if (_watchedSeconds >= _requiredWatchSeconds) {
        _gateSatisfied = true;
        _gateCounting = false;
      }
    });
  }

  Future<void> _stopGateMedia() async {
    try {
      await _videoController.pause();
    } catch (e, st) {
      AppLogger.e('挑战准备', e, st);
    }
  }

  double get _watchProgress {
    return (_watchedSeconds / _requiredWatchSeconds).clamp(0.0, 1.0);
  }

  int get _watchRemaining {
    final left = _requiredWatchSeconds - _watchedSeconds;
    return left < 0 ? 0 : left;
  }

  Future<void> _toggleGatePlayback() async {
    if (!_videoController.value.isInitialized) return;
    if (_gateSatisfied) return;

    final isPlaying = _videoController.value.isPlaying;
    if (isPlaying) {
      try {
        await _videoController.pause();
      } catch (e, st) {
        AppLogger.e('挑战准备', e, st);
      }
      if (!mounted) return;
      setState(() {
        _gateCounting = false;
      });
      return;
    }

    try {
      await _videoController.setVolume(1.0);
      await _videoController.play();
    } catch (e, st) {
      AppLogger.e('挑战准备', e, st);
    }

    if (!mounted) return;
    setState(() {
      _gateCounting = true;
    });
  }

  Future<void> _showGateDialogIfNeeded() async {
    if (_gateDialogShown) return;
    if (_gateSatisfied) return;
    _gateDialogShown = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 53, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.levelColor.withValues(alpha: 0.10),
                          const Color(0xFFF8FAFC),
                          const Color(0xFFF8FAFC),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 520.0;
                          final dialogMaxHeight = maxH.clamp(670.0, 890.0);

                          // 根据账号和关卡动态调整难度
                          final baseTarget = widget.challengeLevel.targetCount;
                          final baseTimeLimit = widget.challengeLevel.timeLimitSeconds;
                          final target = (widget.levelName == '遵义')
                              ? (UserScope.isDemo && UserScope.username == 'lzf' ? 20 : 10)
                              : baseTarget;
                          final timeLimit = (widget.levelName == '遵义')
                              ? (UserScope.isDemo && UserScope.username == 'lzf' ? 45 : 80)
                              : baseTimeLimit;
                          final xpReward = widget.challengeLevel.id == 2
                              ? 120
                              : 120 + (target ~/ 2);
                          final coinReward = 30 + (widget.challengeLevel.id % 5) * 10;
                          final badgeText = '完成本关';

                          return ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: dialogMaxHeight),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.levelName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF0F172A),
                                              height: 1.0,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      widget.levelColor.withValues(alpha: 0.30),
                                                      const Color(0xFFFFFFFF),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(999),
                                                  border: Border.all(color: widget.levelColor.withValues(alpha: 0.35)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: widget.levelColor.withValues(alpha: 0.18),
                                                      blurRadius: 14,
                                                      offset: const Offset(0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 30,
                                                      height: 30,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                          colors: [
                                                            widget.levelColor.withValues(alpha: 0.98),
                                                            widget.levelColor.withValues(alpha: 0.55),
                                                          ],
                                                        ),
                                                        border: Border.all(color: Colors.white.withValues(alpha: 0.90), width: 1.4),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: widget.levelColor.withValues(alpha: 0.35),
                                                            blurRadius: 12,
                                                            offset: const Offset(0, 6),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          Positioned.fill(
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(2.0),
                                                              child: DecoratedBox(
                                                                decoration: BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.0),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            left: 4,
                                                            top: 3,
                                                            child: Container(
                                                              width: 14,
                                                              height: 9,
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(999),
                                                                gradient: LinearGradient(
                                                                  begin: Alignment.topLeft,
                                                                  end: Alignment.bottomRight,
                                                                  colors: [
                                                                    Colors.white.withValues(alpha: 0.75),
                                                                    Colors.white.withValues(alpha: 0.05),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const Center(
                                                            child: Icon(Icons.shield_rounded, size: 18, color: Colors.white),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      '关卡任务',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w900,
                                                        color: Color(0xFF0F172A),
                                                        height: 1.0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              ValueListenableBuilder<int>(
                                                valueListenable: _watchedSecondsNotifier,
                                                builder: (context, watched, _) {
                                                  final left = (_requiredWatchSeconds - watched).clamp(0, _requiredWatchSeconds);
                                                  final unlocked = watched >= _requiredWatchSeconds;
                                                  final badgeGradient = unlocked
                                                      ? const [Color(0xFF16A34A), Color(0xFF86EFAC)]
                                                      : const [Color(0xFF2563EB), Color(0xFF93C5FD)];
                                                  final glowColor = unlocked ? const Color(0xFF22C55E) : const Color(0xFF3B82F6);
                                                  return Container(
                                                    padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                          (unlocked ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF)).withValues(alpha: 0.95),
                                                          Colors.white,
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(999),
                                                      border: Border.all(
                                                        color: unlocked
                                                            ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                                                            : const Color(0xFF2563EB).withValues(alpha: 0.20),
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: glowColor.withValues(alpha: 0.16),
                                                          blurRadius: 14,
                                                          offset: const Offset(0, 8),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 30,
                                                          height: 30,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            gradient: LinearGradient(
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                              colors: badgeGradient,
                                                            ),
                                                            border: Border.all(color: Colors.white.withValues(alpha: 0.90), width: 1.4),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: glowColor.withValues(alpha: 0.30),
                                                                blurRadius: 12,
                                                                offset: const Offset(0, 6),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Stack(
                                                            children: [
                                                              Positioned.fill(
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(2.0),
                                                                  child: DecoratedBox(
                                                                    decoration: BoxDecoration(
                                                                      shape: BoxShape.circle,
                                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.0),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Positioned(
                                                                left: 4,
                                                                top: 3,
                                                                child: Container(
                                                                  width: 14,
                                                                  height: 9,
                                                                  decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.circular(999),
                                                                    gradient: LinearGradient(
                                                                      begin: Alignment.topLeft,
                                                                      end: Alignment.bottomRight,
                                                                      colors: [
                                                                        Colors.white.withValues(alpha: 0.75),
                                                                        Colors.white.withValues(alpha: 0.05),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Center(
                                                                child: Icon(
                                                                  unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                                                                  size: 18,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          unlocked ? '已解锁' : '观看 ${left}s 解锁',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w900,
                                                            color: unlocked ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                                            height: 1.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 关闭按钮始终可以点击
                                    InkWell(
                                      onTap: () => Navigator.of(context).pop(),
                                      borderRadius: BorderRadius.circular(999),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(Icons.close_rounded, size: 20, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Center(
                                          child: FractionallySizedBox(
                                            widthFactor: 0.7,
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.06),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 10),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: ValueListenableBuilder<VideoPlayerValue>(
                                                  valueListenable: _videoController,
                                                  builder: (context, value, _) {
                                                    final ready = value.isInitialized;
                                                    final hasError = value.hasError;
                                                    final showError = _videoInitFailed || hasError;
                                                    final errorText = value.errorDescription;
                                                    return AspectRatio(
                                                      aspectRatio: ready ? value.aspectRatio : (16 / 9),
                                                      child: ColoredBox(
                                                        color: Colors.black,
                                                        child: ready
                                                            ? VideoPlayer(_videoController)
                                                            : Center(
                                                                child: showError
                                                                    ? Padding(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                                                        child: Column(
                                                                          mainAxisSize: MainAxisSize.min,
                                                                          children: [
                                                                            const Text(
                                                                              '视频加载失败',
                                                                              textAlign: TextAlign.center,
                                                                              style: TextStyle(
                                                                                fontSize: 13,
                                                                                fontWeight: FontWeight.w900,
                                                                                color: Colors.white70,
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 6),
                                                                            Text(
                                                                              (errorText == null || errorText.isEmpty)
                                                                                  ? '请检查资源路径，或点击重试'
                                                                                  : errorText,
                                                                              textAlign: TextAlign.center,
                                                                              style: const TextStyle(
                                                                                fontSize: 12,
                                                                                fontWeight: FontWeight.w700,
                                                                                color: Colors.white60,
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 10),
                                                                            FilledButton.tonal(
                                                                              onPressed: () async {
                                                                                await _retryVideoInit();
                                                                                setInnerState(() {});
                                                                              },
                                                                              child: const Text('重试'),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      )
                                                                    : const SizedBox(
                                                                        width: 18,
                                                                        height: 18,
                                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                                      ),
                                                              ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ValueListenableBuilder<int>(
                                          valueListenable: _watchedSecondsNotifier,
                                          builder: (context, watched, _) {
                                            final progress = (watched / _requiredWatchSeconds).clamp(0.0, 1.0);
                                            final remaining = (_requiredWatchSeconds - watched).clamp(0, _requiredWatchSeconds);
                                            final done = watched >= _requiredWatchSeconds;
                                            return Row(
                                              children: [
                                                Expanded(
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(999),
                                                    child: SizedBox(
                                                      height: 10,
                                                      child: LinearProgressIndicator(
                                                        value: progress,
                                                        backgroundColor: const Color(0xFFE2E8F0),
                                                        valueColor: AlwaysStoppedAnimation<Color>(
                                                          done ? const Color(0xFF22C55E) : widget.levelColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  done ? '完成' : '${remaining}s',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    color: done ? const Color(0xFF16A34A) : const Color(0xFF334155),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                '剧情提示',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _resolveStoryHintText(),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF334155).withValues(alpha: 0.88),
                                                  height: 1.55,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                widget.levelColor.withValues(alpha: 0.14),
                                                const Color(0xFFF8FAFF),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: widget.levelColor.withValues(alpha: 0.16)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                                                blurRadius: 22,
                                                offset: const Offset(0, 12),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                          widget.levelColor.withValues(alpha: 0.90),
                                                          widget.levelColor.withValues(alpha: 0.40),
                                                        ],
                                                      ),
                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.90), width: 1.4),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: widget.levelColor.withValues(alpha: 0.18),
                                                          blurRadius: 12,
                                                          offset: const Offset(0, 8),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Stack(
                                                      children: [
                                                        Positioned.fill(
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(2.4),
                                                            child: DecoratedBox(
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.0),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          left: 6,
                                                          top: 5,
                                                          child: Container(
                                                            width: 18,
                                                            height: 11,
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(999),
                                                              gradient: LinearGradient(
                                                                begin: Alignment.topLeft,
                                                                end: Alignment.bottomRight,
                                                                colors: [
                                                                  Colors.white.withValues(alpha: 0.70),
                                                                  Colors.white.withValues(alpha: 0.05),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const Center(
                                                          child: Icon(Icons.assignment_turned_in_rounded, size: 22, color: Colors.white),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  const Expanded(
                                                    child: Text(
                                                      '挑战任务',
                                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.auto_awesome_rounded, size: 18, color: const Color(0xFFF59E0B).withValues(alpha: 0.92)),
                                                      const SizedBox(width: 2),
                                                      Icon(Icons.auto_awesome_rounded, size: 16, color: const Color(0xFFF59E0B).withValues(alpha: 0.65)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      widget.levelColor.withValues(alpha: 0.10),
                                                      Colors.white.withValues(alpha: 0.95),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(18),
                                                  border: Border.all(color: widget.levelColor.withValues(alpha: 0.12)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                                      blurRadius: 14,
                                                      offset: const Offset(0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 38,
                                                      height: 38,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                          colors: [
                                                            widget.levelColor.withValues(alpha: 0.90),
                                                            widget.levelColor.withValues(alpha: 0.50),
                                                          ],
                                                        ),
                                                        border: Border.all(color: Colors.white.withValues(alpha: 0.90), width: 1.4),
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          Positioned.fill(
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(2.4),
                                                              child: DecoratedBox(
                                                                decoration: BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.0),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            left: 6,
                                                            top: 5,
                                                            child: Container(
                                                              width: 18,
                                                              height: 11,
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(999),
                                                                gradient: LinearGradient(
                                                                  begin: Alignment.topLeft,
                                                                  end: Alignment.bottomRight,
                                                                  colors: [
                                                                    Colors.white.withValues(alpha: 0.70),
                                                                    Colors.white.withValues(alpha: 0.05),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const Center(
                                                            child: Icon(Icons.fitness_center_rounded, size: 22, color: Colors.white),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        // 为不同账户和关卡显示特定的任务描述
                                                        UserScope.isDemo && UserScope.username == 'lzf' && widget.levelName == '遵义'
                                                            ? '完成5组/每组20个的脊柱伸展运动'
                                                            : (widget.levelName == '遵义')
                                                                ? '完成 10 次腿部左右摆荡'
                                                                : '完成 $target 次标准动作',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w900,
                                                          color: Color(0xFF0F172A),
                                                          height: 1.1,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.85),
                                                        borderRadius: BorderRadius.circular(999),
                                                        border: Border.all(color: widget.levelColor.withValues(alpha: 0.18)),
                                                      ),
                                                      child: const Text(
                                                        '主目标',
                                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.0),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [Color(0xFFEAF3FF), Color(0xFFFFFFFF)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(18),
                                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                                      blurRadius: 14,
                                                      offset: const Offset(0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 38,
                                                      height: 38,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient: const LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                          colors: [Color(0xFF2563EB), Color(0xFF93C5FD)],
                                                        ),
                                                        border: Border.all(color: Colors.white.withValues(alpha: 0.90), width: 1.4),
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          Positioned.fill(
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(2.4),
                                                              child: DecoratedBox(
                                                                decoration: BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.0),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            left: 6,
                                                            top: 5,
                                                            child: Container(
                                                              width: 18,
                                                              height: 11,
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(999),
                                                                gradient: LinearGradient(
                                                                  begin: Alignment.topLeft,
                                                                  end: Alignment.bottomRight,
                                                                  colors: [
                                                                    Colors.white.withValues(alpha: 0.70),
                                                                    Colors.white.withValues(alpha: 0.05),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const Center(
                                                            child: Icon(Icons.timer_rounded, size: 22, color: Colors.white),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        (UserScope.isDemo && UserScope.username == 'lzf' && widget.levelName == '遵义')
                                                            ? '间隔休息1分钟'
                                                            : '限时 $timeLimit 秒',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w900,
                                                          color: Color(0xFF0F172A),
                                                          height: 1.1,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.85),
                                                        borderRadius: BorderRadius.circular(999),
                                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                                      ),
                                                      child: Text(
                                                        (UserScope.isDemo && UserScope.username == 'lzf' && widget.levelName == '遵义')
                                                            ? '间隔休息'
                                                            : '限时',
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8), height: 1.0),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [Color(0xFFF1F5F9), Color(0xFFFFFFFF)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(18),
                                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                                      blurRadius: 14,
                                                      offset: const Offset(0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 38,
                                                      height: 38,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                          colors: [
                                                            const Color(0xFF0F172A).withValues(alpha: 0.86),
                                                            const Color(0xFF334155).withValues(alpha: 0.70),
                                                          ],
                                                        ),
                                                        border: Border.all(color: Colors.white.withValues(alpha: 0.90), width: 1.4),
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          Positioned.fill(
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(2.4),
                                                              child: DecoratedBox(
                                                                decoration: BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.0),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            left: 6,
                                                            top: 5,
                                                            child: Container(
                                                              width: 18,
                                                              height: 11,
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(999),
                                                                gradient: LinearGradient(
                                                                  begin: Alignment.topLeft,
                                                                  end: Alignment.bottomRight,
                                                                  colors: [
                                                                    Colors.white.withValues(alpha: 0.55),
                                                                    Colors.white.withValues(alpha: 0.03),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const Center(
                                                            child: Icon(Icons.visibility_rounded, size: 22, color: Colors.white),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    const Expanded(
                                                      child: Text(
                                                        '保持动作节奏，尽量让每次动作都完整到位',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w800,
                                                          color: Color(0xFF334155),
                                                          height: 1.15,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.85),
                                                        borderRadius: BorderRadius.circular(999),
                                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                                      ),
                                                      child: const Text(
                                                        '技巧',
                                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569), height: 1.0),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                '完成奖励',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                              ),
                                              const SizedBox(height: 10),
                                              Wrap(
                                                spacing: 10,
                                                runSpacing: 10,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [Color(0xFFFFF7D6), Color(0xFFFFFFFF)],
                                                      ),
                                                      borderRadius: BorderRadius.circular(14),
                                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                                                          blurRadius: 14,
                                                          offset: const Offset(0, 8),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 32,
                                                          height: 32,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            gradient: const LinearGradient(
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                              colors: [Color(0xFFF59E0B), Color(0xFFFDE68A)],
                                                            ),
                                                            border: Border.all(color: Colors.white.withValues(alpha: 0.90), width: 1.4),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: const Color(0xFFF59E0B).withValues(alpha: 0.30),
                                                                blurRadius: 10,
                                                                offset: const Offset(0, 6),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Stack(
                                                            children: [
                                                              Positioned.fill(
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(2.2),
                                                                  child: DecoratedBox(
                                                                    decoration: BoxDecoration(
                                                                      shape: BoxShape.circle,
                                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.0),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Positioned(
                                                                left: 6,
                                                                top: 5,
                                                                child: Container(
                                                                  width: 16,
                                                                  height: 10,
                                                                  decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.circular(999),
                                                                    gradient: LinearGradient(
                                                                      begin: Alignment.topLeft,
                                                                      end: Alignment.bottomRight,
                                                                      colors: [
                                                                        Colors.white.withValues(alpha: 0.70),
                                                                        Colors.white.withValues(alpha: 0.05),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const Center(
                                                                child: Icon(Icons.bolt_rounded, size: 20, color: Colors.white),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          '+$xpReward 经验',
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w900,
                                                            color: Color(0xFF92400E),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [Color(0xFFEAF3FF), Color(0xFFFFFFFF)],
                                                      ),
                                                      borderRadius: BorderRadius.circular(14),
                                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(0xFF2563EB).withValues(alpha: 0.14),
                                                          blurRadius: 14,
                                                          offset: const Offset(0, 8),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 32,
                                                          height: 32,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            gradient: const LinearGradient(
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                              colors: [Color(0xFF2563EB), Color(0xFF93C5FD)],
                                                            ),
                                                            border: Border.all(color: Colors.white.withValues(alpha: 0.90), width: 1.4),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                                                                blurRadius: 10,
                                                                offset: const Offset(0, 6),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Stack(
                                                            children: [
                                                              Positioned.fill(
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(2.2),
                                                                  child: DecoratedBox(
                                                                    decoration: BoxDecoration(
                                                                      shape: BoxShape.circle,
                                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.0),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Positioned(
                                                                left: 6,
                                                                top: 5,
                                                                child: Container(
                                                                  width: 16,
                                                                  height: 10,
                                                                  decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.circular(999),
                                                                    gradient: LinearGradient(
                                                                      begin: Alignment.topLeft,
                                                                      end: Alignment.bottomRight,
                                                                      colors: [
                                                                        Colors.white.withValues(alpha: 0.70),
                                                                        Colors.white.withValues(alpha: 0.05),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const Center(
                                                                child: Icon(Icons.monetization_on_rounded, size: 20, color: Colors.white),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          '+$coinReward 金币',
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w900,
                                                            color: Color(0xFF1D4ED8),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                          widget.levelColor.withValues(alpha: 0.18),
                                                          Colors.white,
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(14),
                                                      border: Border.all(color: widget.levelColor.withValues(alpha: 0.26)),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: widget.levelColor.withValues(alpha: 0.14),
                                                          blurRadius: 14,
                                                          offset: const Offset(0, 8),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 32,
                                                          height: 32,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            gradient: LinearGradient(
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                              colors: [
                                                                widget.levelColor.withValues(alpha: 0.95),
                                                                widget.levelColor.withValues(alpha: 0.55),
                                                              ],
                                                            ),
                                                            border: Border.all(color: Colors.white.withValues(alpha: 0.90), width: 1.4),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: widget.levelColor.withValues(alpha: 0.28),
                                                                blurRadius: 10,
                                                                offset: const Offset(0, 6),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Stack(
                                                            children: [
                                                              Positioned.fill(
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(2.2),
                                                                  child: DecoratedBox(
                                                                    decoration: BoxDecoration(
                                                                      shape: BoxShape.circle,
                                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.0),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Positioned(
                                                                left: 6,
                                                                top: 5,
                                                                child: Container(
                                                                  width: 16,
                                                                  height: 10,
                                                                  decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.circular(999),
                                                                    gradient: LinearGradient(
                                                                      begin: Alignment.topLeft,
                                                                      end: Alignment.bottomRight,
                                                                      colors: [
                                                                        Colors.white.withValues(alpha: 0.70),
                                                                        Colors.white.withValues(alpha: 0.05),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const Center(
                                                                child: Icon(Icons.military_tech_rounded, size: 20, color: Colors.white),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          badgeText,
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w900,
                                                            color: Color(0xFF0F172A),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: _watchedSecondsNotifier,
                                        builder: (context, watched, _) {
                                          final canStart = watched >= _requiredWatchSeconds;
                                          return FilledButton(
                                            onPressed: canStart
                                                ? () async {
                                                    AppLogger.i('挑战准备', '[TIME] E0 点击开始游戏');
                                                    Navigator.of(context).pop();
                                                    await _stopGateMedia();
                                                    if (!mounted) return;
                                                    AppLogger.i('挑战准备', '[TIME] E1 即将 push 训练页');
                                                    _startChallenge();
                                                  }
                                                : null,
                                            style: FilledButton.styleFrom(
                                              backgroundColor: widget.levelColor,
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor: widget.levelColor.withValues(alpha: 0.25),
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                                            ),
                                            child: const Text('开始游戏'),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ValueListenableBuilder<VideoPlayerValue>(
                                        valueListenable: _videoController,
                                        builder: (context, value, _) {
                                          final videoInitialized = value.isInitialized;
                                          final isPlaying = videoInitialized && value.isPlaying;
                                          final actionText = isPlaying ? '暂停' : '播放';

                                          return FilledButton.tonal(
                                            onPressed: videoInitialized
                                                ? () async {
                                                    await _toggleGatePlayback();
                                                    setInnerState(() {});
                                                  }
                                                : null,
                                            style: FilledButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                                            ),
                                            child: Text(actionText),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await _stopGateMedia();

    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _videoInitTimeout?.cancel();
    _watchedSecondsNotifier.dispose();
    _videoController.removeListener(_onVideoTick);
    _videoController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startChallenge() {
    AppLogger.i('挑战准备', '[TIME] E2 _startChallenge 执行');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraJumpChallengePage(
          config: CameraJumpChallengeConfig(
            level: widget.challengeLevel,
            pageTitle: widget.pageTitle,
            wsUrl: null,
            forceLandscape: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final target = widget.challengeLevel.targetCount;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(0, 0),
              child: Image.asset(
                widget.backgroundAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.30),
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.32),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: _BackButton(onTap: () => Navigator.of(context).maybePop()),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _float,
                builder: (context, _) {
                  final dy = (0.5 - _float.value) * 18;
                  return Stack(
                    children: [
                      Positioned(
                        left: size.width * 0.18,
                        bottom: size.height * 0.42 + dy,
                        child: Transform.scale(
                          scale: 1.10,
                          child: Image.asset(
                            'assets/images/jiuse.png',
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.34,
            minChildSize: 0.14,
            maxChildSize: 0.78,
            builder: (context, scrollController) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.levelName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A202C),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.levelDescription,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _TimerRing(
                          seconds: widget.challengeLevel.timeLimitSeconds,
                          progress: 0,
                          color: widget.levelColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '目标：$target 个标准动作',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4A5568)),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 8,
                        child: LinearProgressIndicator(
                          value: 0,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(widget.levelColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _StartExerciseButton(
                      onTap: _startChallenge,
                      color: widget.levelColor,
                      enabled: _gateSatisfied,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _HelperButton(icon: '❓', text: '动作指导', onTap: () {}),
                        _HelperButton(icon: '⏸️', text: '暂停', onTap: () {}),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          child: const Center(
            child: Text('←', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF333333))),
          ),
        ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({required this.seconds, required this.progress, required this.color});

  final int seconds;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '$seconds',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2D3748)),
          ),
        ],
      ),
    );
  }
}

class _StartExerciseButton extends StatelessWidget {
  const _StartExerciseButton({required this.onTap, required this.color, required this.enabled});

  final VoidCallback onTap;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: enabled ? [color, const Color(0xFFF9D423)] : [const Color(0xFFCBD5E1), const Color(0xFF94A3B8)],
          ),
          boxShadow: [
            BoxShadow(
              color: (enabled ? color : const Color(0xFF64748B)).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/correction-exercise.png',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('开始闯关', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('点击开始脊柱健康训练', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              alignment: Alignment.center,
              child: const Text('→', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelperButton extends StatelessWidget {
  const _HelperButton({required this.icon, required this.text, required this.onTap});

  final String icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF718096))),
          ],
        ),
      ),
    );
  }
}
