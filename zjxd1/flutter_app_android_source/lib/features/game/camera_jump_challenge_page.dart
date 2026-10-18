import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'dart:io';

import 'dart:math' as math;



import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import '../../config/app_config.dart';

import 'package:flutter/services.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'challenge_result_page.dart';

import 'jump_challenge_page.dart';

import '../../utils/app_logger.dart';

import '../../utils/mirrored_camera_preview.dart';



class CameraJumpChallengeConfig {

  const CameraJumpChallengeConfig({

    required this.level,

    this.pageTitle,

    this.wsUrl,

    this.forceLandscape = false,

  });



  final JumpChallengeLevel level;

  final String? pageTitle;

  final Uri? wsUrl;

  final bool forceLandscape;

}



class CameraJumpChallengePage extends StatefulWidget {

  const CameraJumpChallengePage({

    super.key,

    required this.config,

  });



  final CameraJumpChallengeConfig config;



  @override

  State<CameraJumpChallengePage> createState() => _CameraJumpChallengePageState();

}



class _CameraJumpChallengePageState extends State<CameraJumpChallengePage> with WidgetsBindingObserver {

  static const double _bgmVolume = 0.55;

  static const String _bgmAsset = 'images/exercise-background-music.wav';



  CameraController? _controller;
  final Stopwatch _sw = Stopwatch();


  Future<void>? _initFuture;

  /// 防重入：横屏切换会触发 resumed 生命周期，若不拦截相机会被初始化两次
  bool _cameraInitializing = false;

  String? _initErrorText;

  /// 相机操作超时：模拟器/主机切换摄像头桥接抖动时，枚举与初始化可能永久挂起
  static const Duration _cameraTimeout = Duration(seconds: 8);

  /// 记住已选摄像头：生命周期恢复重初始化时不再弹选择框
  CameraDescription? _lastSelectedCamera;



  final AudioPlayer _bgmPlayer = AudioPlayer();

  final AudioPlayer _countdownPlayer = AudioPlayer();



  final SoLoud _soLoud = SoLoud.instance;

  AudioSource? _tapSfxSource;

  bool _soLoudReady = false;



  Timer? _countdownTimer;

  Timer? _exerciseTimer;



  int _countdown = 3;

  bool showCountdown = false;

  bool showTimer = false;



  int remainingSeconds = 60;

  int messageCount = 0;



  WebSocket? _ws;

  StreamSubscription? _wsSub;

  bool wsConnected = false;



  bool isRecording = false;

  bool isStarting = false;



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _sw.start();
AppLogger.i('跳跃挑战', '[TIME] T0 页面 initState 开始');


    remainingSeconds = widget.config.level.timeLimitSeconds;

    unawaited(_initBgm());

    unawaited(_initSfxEngine());

    _initFuture = _lockLandscapeAndInitCamera();

  }

  Future<void> _lockLandscapeAndInitCamera() async {
    // 横屏切换与相机枚举互不依赖：并行发起，避免串行累加（实测 155ms + 735ms）
    final orientationFuture = SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
    ]);
    if (!mounted) return;
    await _initCamera(orientationFuture);
    AppLogger.i('跳跃挑战', '[TIME] T5 摄像头全流程完成 +${_sw.elapsedMilliseconds}ms');
  }

  Future<void> _initBgm() async {

    try {

      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);

      await _bgmPlayer.setVolume(_bgmVolume);

      await _bgmPlayer.setAudioContext(

        AudioContext(

          android: AudioContextAndroid(

            isSpeakerphoneOn: false,

            stayAwake: false,

            contentType: AndroidContentType.music,

            usageType: AndroidUsageType.game,

            audioFocus: AndroidAudioFocus.none,

          ),

          iOS: AudioContextIOS(

            category: AVAudioSessionCategory.playback,

            options: const {

              AVAudioSessionOptions.mixWithOthers,

            },

          ),

        ),

      );

    } catch (e, st) {

      AppLogger.e('跳跃挑战', e, st);

    }

  }



  Future<void> _startBgmIfNeeded() async {

    try {

      await _bgmPlayer.stop();

      await _bgmPlayer.play(AssetSource(_bgmAsset));

    } catch (e, st) {

      AppLogger.e('跳跃挑战', e, st);

    }

  }



  Future<void> _stopBgm() async {

    try {

      await _bgmPlayer.stop();

    } catch (e, st) {

      AppLogger.e('跳跃挑战', e, st);

    }

  }



  Future<void> _initSfxEngine() async {

    try {

      await _soLoud.init();

      final src = await _soLoud.loadAsset('assets/images/plusone.mp3');

      if (!mounted) {

        await _soLoud.disposeSource(src);

        return;

      }

      _tapSfxSource = src;

      _soLoudReady = true;

    } catch (e, st) {

      AppLogger.e('跳跃挑战', e, st);

    }



    // Initialize countdown player

    try {

      await _countdownPlayer.setReleaseMode(ReleaseMode.stop);

      await _countdownPlayer.setVolume(1.0);

    } catch (e, st) {

      AppLogger.e('跳跃挑战', e, st);

    }

  }



  @override

  void dispose() {

    WidgetsBinding.instance.removeObserver(this);

    _countdownTimer?.cancel();

    _exerciseTimer?.cancel();

    _disconnectWebSocket();

    _controller?.dispose();

    unawaited(_stopBgm());

    unawaited(_bgmPlayer.dispose());

    unawaited(_countdownPlayer.dispose());
    // 同上：释放 SoLoud 引擎，避免占住音频会话导致其它播放器无声
    try {
      _soLoud.deinit();
    } catch (_) {}


    final src = _tapSfxSource;

    if (src != null) {

      unawaited(_soLoud.disposeSource(src));

    }

    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    super.dispose();

  }



  Future<void> _playTapSfx() async {

    if (!_soLoudReady) return;

    final src = _tapSfxSource;

    if (src == null) return;

    try {

      await _soLoud.play(src);

    } catch (e, st) {

      AppLogger.e('跳跃挑战', e, st);

    }

  }



  Future<void> _playCountdownSound(int number) async {

    try {

      if (number == 0) {

        return;

      } else {

        // For numbers 3, 2, 1 - use system click sound

        // Play multiple clicks for different numbers to create variation

        for (int i = 0; i <= number; i++) {

          await Future.delayed(const Duration(milliseconds: 100));

          await SystemSound.play(SystemSoundType.click);

        }

      }

    } catch (e, st) {

      AppLogger.e('跳跃挑战', e, st);

      // Fallback to single system sound if anything fails

      try {

        await SystemSound.play(SystemSoundType.click);

      } catch (err, stackTrace) {

        AppLogger.e('跳跃挑战', err, stackTrace);

      }

    }

  }



  String get pageTitle => widget.config.pageTitle ?? widget.config.level.name;



  double get progressPercent {

    final target = widget.config.level.targetCount;

    if (target <= 0) return 0;

    return (messageCount / target * 100).clamp(0, 100);

  }



  int _computeScore() {

    final target = widget.config.level.targetCount;

    if (target <= 0) {

      return (messageCount * 10).clamp(0, 100);

    }

    final ratio = (messageCount / target).clamp(0.0, 1.0);

    return (ratio * 100).round().clamp(0, 100);

  }



  int _computeStars() {

    final p = progressPercent;

    if (p >= 100) return 5;

    if (p >= 80) return 4;

    if (p >= 60) return 3;

    if (p >= 40) return 2;

    if (p > 0) return 1;

    return 0;

  }



  String _formatTime(int seconds) {

    final mins = seconds ~/ 60;

    final secs = seconds % 60;

    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

  }



  Future<void> _initCamera([Future<void>? orientationFuture]) async {
    if (_cameraInitializing) return;
    _cameraInitializing = true;
    try {
      // 立即发起枚举但不阻塞弹窗：弹窗先出现并显示"正在搜索摄像头…"
      AppLogger.i('跳跃挑战', '[TIME] T1a 开始枚举相机 +${_sw.elapsedMilliseconds}ms');
      final camerasFuture = availableCameras().timeout(_cameraTimeout);

      CameraDescription? selectedCamera = _lastSelectedCamera;
      if (selectedCamera == null) {
        if (!mounted) return;
        // 必须等首帧渲染完成后再弹窗：initState 尚未结束时 showDialog 取不到 Localizations
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        AppLogger.i('跳跃挑战', '[TIME] T2a 立即弹出摄像头选择框 +${_sw.elapsedMilliseconds}ms');
        selectedCamera = await _showCameraSelectionDialog(camerasFuture);
        AppLogger.i('跳跃挑战', '[TIME] T3 用户已选定摄像头 +${_sw.elapsedMilliseconds}ms');
        _lastSelectedCamera = selectedCamera;
      }

      final cameras = await camerasFuture;
      AppLogger.i('跳跃挑战', '[TIME] T2 相机枚举完成(共${cameras.length}个) +${_sw.elapsedMilliseconds}ms');

      if (cameras.isEmpty) {
        throw StateError('未检测到可用相机。若使用模拟器，请开启虚拟相机或使用真机测试。');
      }

      for (var i = 0; i < cameras.length; i++) {
        AppLogger.i('跳跃挑战',
            '相机[$i] name=${cameras[i].name} lens=${cameras[i].lensDirection} sensorOrientation=${cameras[i].sensorOrientation}');
      }

      final cameraToUse = selectedCamera ??
          cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          );

      // 横屏方向必须早于控制器创建完成，否则模拟器预览会横置
      if (orientationFuture != null) {
        await orientationFuture;
        AppLogger.i('跳跃挑战', '[TIME] T1 横屏切换完成 +${_sw.elapsedMilliseconds}ms');
      }

      final controller = CameraController(
        cameraToUse,
        // medium：模拟器虚拟相机 use case 有限，high 会导致相机起不来
        ResolutionPreset.medium,
        enableAudio: false,
      );

      AppLogger.i('跳跃挑战', '[TIME] T3a 开始 controller.initialize() +${_sw.elapsedMilliseconds}ms');
      await controller.initialize().timeout(_cameraTimeout);
      AppLogger.i('跳跃挑战', '[TIME] T4 initialize 完成 +${_sw.elapsedMilliseconds}ms');

      // 图像流：供「自动动作计数」使用
      try {
        await controller.startImageStream(_onPoseFrame);
      } catch (e, st) {
        AppLogger.e('跳跃挑战', e, st);
      }

      // 朝向 / 闪光灯并行；缩放放后台，避免串行等待拖慢首帧
      await Future.wait([
        _safeCall(() => controller.lockCaptureOrientation(DeviceOrientation.landscapeLeft)),
        _safeCall(() => controller.setFlashMode(FlashMode.off)),
      ]);
      unawaited(_safeCall(() => controller.setZoomLevel(1.0)));

      if (!mounted) {
        await controller.dispose();
        return;
      }

      AppLogger.i('跳跃挑战', '[TIME] T4b 图像流/朝向/闪光灯处理完成 +${_sw.elapsedMilliseconds}ms');
      setState(() {
        _controller = controller;
        _initErrorText = null;
      });
    } catch (e, st) {
      AppLogger.e('跳跃挑战', e, st);
      if (!mounted) return;
      setState(() {
        _initErrorText = e.toString();
      });
      rethrow;
    } finally {
      _cameraInitializing = false;
    }
  }

  /// 容错包装：单项失败不影响整体初始化（如设备不支持闪光灯/缩放）
  Future<void> _safeCall(Future<void> Function() action) async {
    try {
      await action();
    } catch (e, st) {
      AppLogger.e('跳跃挑战', e, st);
    }
  }

  Future<CameraDescription?> _showCameraSelectionDialog(
      Future<List<CameraDescription>> camerasFuture) async {
    var autoPicked = false;
    return await showDialog<CameraDescription>(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<List<CameraDescription>>(
          future: camerasFuture,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState != ConnectionState.done;
            final failed = snapshot.hasError;
            final cameras = snapshot.data ?? const <CameraDescription>[];

            // 只有一个摄像头时无需用户选择：自动选中并关闭（保持原有行为）
            if (!loading && !failed && cameras.length == 1 && !autoPicked) {
              autoPicked = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop(cameras.first);
                }
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: MediaQuery.of(context).size.height - 24,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF667EEA).withValues(alpha: 0.15),
                        const Color(0xFF764BA2).withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 10),
                              Text(
                                '选择摄像头',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (loading) ...[
                          const SizedBox(height: 6),
                          const CircularProgressIndicator(color: Color(0xFF667EEA)),
                          const SizedBox(height: 12),
                          const Text('正在搜索摄像头…',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4B5563))),
                          const SizedBox(height: 6),
                        ] else if (failed) ...[
                          const SizedBox(height: 6),
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 32),
                          const SizedBox(height: 8),
                          const Text('摄像头搜索失败',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1F2937))),
                          const SizedBox(height: 4),
                          Text('${snapshot.error}',
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                          const SizedBox(height: 6),
                        ] else if (cameras.isEmpty) ...[
                          const SizedBox(height: 6),
                          const Icon(Icons.videocam_off_rounded, color: Color(0xFFEF4444), size: 32),
                          const SizedBox(height: 8),
                          const Text('未检测到可用摄像头',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1F2937))),
                          const SizedBox(height: 6),
                        ] else
                          Flexible(
                            child: SizedBox(
                              width: 320,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: cameras.length,
                                itemBuilder: (context, index) {
                                  final camera = cameras[index];
                                  final lensDirection = camera.lensDirection == CameraLensDirection.front
                                      ? '前置摄像头（本机/USB 摄像头）'
                                      : camera.lensDirection == CameraLensDirection.back
                                          ? '后置摄像头（模拟场景）'
                                          : '外接摄像头';
                                  final icon = camera.lensDirection == CameraLensDirection.front
                                      ? Icons.camera_front
                                      : camera.lensDirection == CameraLensDirection.back
                                          ? Icons.camera_rear
                                          : Icons.videocam;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF667EEA).withValues(alpha: 0.08),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () => Navigator.of(context).pop(camera),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          leading: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF667EEA).withValues(alpha: 0.15),
                                                  const Color(0xFF764BA2).withValues(alpha: 0.08),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Icon(icon, color: const Color(0xFF667EEA), size: 22),
                                          ),
                                          title: Text(
                                            '摄像头 ${index + 1}  ${camera.name}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          subtitle: Text(
                                            lensDirection,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.check_circle_outline,
                                              color: Color(0xFF667EEA),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                                width: 2,
                              ),
                              foregroundColor: const Color(0xFF667EEA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.white.withValues(alpha: 0.5),
                            ),
                            child: const Text(
                              '取消',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
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
      },
    );
  }

  Future<void> _switchCamera() async {

    // 录制中切换会销毁正在录制的控制器，直接中断录像，禁止
    if (isRecording) return;

    final controller = _controller;

    if (controller == null) return;



    try {

      final cameras = await availableCameras().timeout(_cameraTimeout);

      if (cameras.isEmpty) return;



      final current = controller.description;

      final nextLens = current.lensDirection == CameraLensDirection.front

          ? CameraLensDirection.back

          : CameraLensDirection.front;



      final next = cameras.firstWhere(

        (c) => c.lensDirection == nextLens,

        orElse: () => cameras.first,

      );



      // 第一步：先释放旧控制器并移出界面（预览区自动进入 loading 态）
      if (mounted) {
        setState(() {
          _controller = null;
          _initErrorText = null;
        });
      }
      await controller.dispose();



      if (!mounted) return;



      // 第二步：再初始化新控制器
      final nextController = CameraController(

        next,

        ResolutionPreset.high,

        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,

      );



      try {
        await nextController.initialize().timeout(_cameraTimeout);
        await nextController.lockCaptureOrientation(DeviceOrientation.landscapeLeft);
        await nextController.setFlashMode(FlashMode.off);
      } catch (e, st) {
        AppLogger.e('跳跃挑战', e, st);
        // 初始化失败：释放半成品控制器并把错误上屏，避免预览指向失效对象造成冻屏
        await nextController.dispose();
        if (!mounted) return;
        setState(() {
          _initErrorText = e.toString();
        });
        return;
      }



      if (!mounted) {

        await nextController.dispose();

        return;

      }



      setState(() {

        _controller = nextController;

      });

    } catch (e, st) {

      AppLogger.e('跳跃挑战', e, st);

      if (!mounted) return;

      setState(() {

        _initErrorText = e.toString();

      });

    }

  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      // 主机切换摄像头/窗口失焦时虚拟相机设备可能断开重连，插件不会自动恢复，
      // 必须主动释放，等 resumed 后重建，否则预览会永久冻结
      _releaseCameraForLifecycle();
    } else if (state == AppLifecycleState.resumed) {
      if (mounted && _controller == null && _initErrorText == null && !_cameraInitializing) {
        // 复用横屏锁定+初始化流程；已记住上次选择的摄像头，不会重新弹框
        setState(() {
          _initFuture = _lockLandscapeAndInitCamera();
        });
      }
    }
  }

  void _releaseCameraForLifecycle() {
    final controller = _controller;
    if (controller == null) return;
    _controller = null;
    if (controller.value.isRecordingVideo) {
      // 后台导致的录制中断：放弃该段录像，等待 resumed 后重建相机
      try {
        unawaited(controller.stopVideoRecording());
      } catch (e, st) {
        AppLogger.e('跳跃挑战', e, st);
      }
    }
    unawaited(controller.dispose());
    if (mounted) {
      setState(() {});
    }
  }

  /// 相机初始化/切换失败后的手动重试入口
  void _retryCameraInit() {
    if (isRecording) return;
    if (_cameraInitializing) return;
    setState(() {
      _initErrorText = null;
      _initFuture = _lockLandscapeAndInitCamera();
    });
  }



  // ==================== 自动动作计数：向识别服务发帧 ====================

  /// 背压：上一帧还没回包就不发下一帧，避免积压
  bool _poseSending = false;
  DateTime _poseLastSent = DateTime.fromMillisecondsSinceEpoch(0);
  /// 发送间隔（毫秒）：约 12fps
  static const int _poseIntervalMs = 80;

  /// 相机帧回调：抽帧发给 PC 端识别服务，由服务判定「是否完成一次跳跃」
  void _onPoseFrame(CameraImage img) {
    if (!mounted) return;
    if (!isRecording) return;
    if (_poseSending) return;
    final now = DateTime.now();
    if (now.difference(_poseLastSent).inMilliseconds < _poseIntervalMs) return;
    final ws = _ws;
    if (ws == null || !wsConnected) return;
    _poseSending = true;
    _poseLastSent = now;
    try {
      ws.add(_packYPlane(img));
    } catch (_) {
      _poseSending = false;
    }
  }

  /// 打包 Y 平面灰度帧（App 侧零编码开销）
  /// 格式：[Y1][w:u16][h:u16][stride:u16] + Y 字节
  Uint8List _packYPlane(CameraImage img) {
    final p = img.planes[0];
    final hdr = ByteData(8);
    hdr.setUint8(0, 0x59);
    hdr.setUint8(1, 0x31);
    hdr.setUint16(2, img.width & 0xFFFF, Endian.little);
    hdr.setUint16(4, img.height & 0xFFFF, Endian.little);
    hdr.setUint16(6, p.bytesPerRow & 0xFFFF, Endian.little);
    final out = Uint8List(8 + p.bytes.length);
    out.setRange(0, 8, hdr.buffer.asUint8List());
    out.setRange(8, out.length, p.bytes);
    return out;
  }

  Future<void> _connectWebSocketIfNeeded() async {

    // 优先用配置里的 wsUrl；没有则连本机视觉识别服务（jump 模式，自动计数）
    final url = widget.config.wsUrl ?? Uri.parse(kPoseWsUrl);



    await _disconnectWebSocket();



    try {

      final ws = await WebSocket.connect(url.toString());

      _ws = ws;

      wsConnected = true;

      // 切到跳跃计数模式并复位
      ws.add(jsonEncode({'cmd': 'mode', 'value': 'jump'}));
      ws.add(jsonEncode({'cmd': 'reset'}));



      _wsSub = ws.listen(

        (event) {

          if (!mounted) return;

          if (!isRecording) return;

          // 识别服务每帧都会回包，只有 event == 'jump' 才算一次有效动作
          bool isJump = false;
          try {
            final m = jsonDecode(event as String) as Map<String, dynamic>;
            isJump = m['event'] == 'jump';
            _poseSending = false;   // 背压：收到回包才允许发下一帧
          } catch (_) {
            _poseSending = false;
            return;
          }
          if (!isJump) return;

          setState(() {

            messageCount += 1;

          });



          if (widget.config.level.targetCount > 0 && messageCount >= widget.config.level.targetCount) {

            _endRecording();

          }

        },

        onError: (_) {

          wsConnected = false;

        },

        onDone: () {

          wsConnected = false;

        },

      );

    } catch (e, st) {

      AppLogger.e('跳跃挑战', e, st);

      wsConnected = false;

    }

  }



  Future<void> _disconnectWebSocket() async {

    try {

      await _wsSub?.cancel();

    } catch (e, st) {

      AppLogger.e('跳跃挑战', e, st);

    }

    _wsSub = null;



    try {

      await _ws?.close();

    } catch (e, st) {

      AppLogger.e('跳跃挑战', e, st);

    }

    _ws = null;

    wsConnected = false;

  }



  void _startCountdown() {

    if (isStarting || showCountdown) return;



    setState(() {

      isStarting = true;

      showCountdown = true;

      showTimer = false;

      _countdown = 3;

    });



    // Play sound for initial countdown number

    unawaited(_playCountdownSound(3));



    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {

      if (!mounted) return;



      if (_countdown > 1) {

        setState(() {

          _countdown -= 1;

        });

        // Play sound for each countdown number

        unawaited(_playCountdownSound(_countdown));

        return;

      }



      if (_countdown == 1) {

        setState(() {

          _countdown = 0;

        });

        // Play GO sound

        unawaited(_playCountdownSound(0));

        return;

      }



      t.cancel();

      _countdownTimer = null;



      if (!mounted) return;

      setState(() {

        showCountdown = false;

      });



      _startTimerAndRecording();

    });

  }



  void _startTimerAndRecording() {

    _exerciseTimer?.cancel();



    setState(() {

      remainingSeconds = widget.config.level.timeLimitSeconds;

      messageCount = 0;

      showTimer = true;

      isRecording = true;

      isStarting = false;

    });



    unawaited(_startBgmIfNeeded());



    _connectWebSocketIfNeeded();



    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (t) {

      if (!mounted) return;

      if (!isRecording) return;



      if (remainingSeconds <= 0) {

        _endRecording();

        return;

      }



      setState(() {

        remainingSeconds -= 1;

      });



      if (widget.config.level.targetCount > 0 && messageCount >= widget.config.level.targetCount) {

        _endRecording();

      }

    });

  }



  Future<void> _endRecording() async {

    if (!isRecording && !showTimer) return;



    _exerciseTimer?.cancel();

    _exerciseTimer = null;



    await _stopBgm();



    await _disconnectWebSocket();



    if (!mounted) return;

    setState(() {

      isRecording = false;

      showTimer = false;

      isStarting = false;

      showCountdown = false;

    });



    if (!mounted) return;

    final score = _computeScore();

    final stars = _computeStars();

    final timeUsedSeconds = (widget.config.level.timeLimitSeconds - remainingSeconds).clamp(0, widget.config.level.timeLimitSeconds);



    Navigator.of(context).pushReplacement(

      MaterialPageRoute(

        builder: (_) => ChallengeResultPage(

          level: widget.config.level,

          completedCount: messageCount,

          timeUsedSeconds: timeUsedSeconds,

          playerScore: score,

          earnedStars: stars,

          title: widget.config.level.name,

        ),

      ),

    );

  }



  Future<void> _confirmExit() async {

    final ok = await showDialog<bool>(

      context: context,

      builder: (context) {

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 280,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF5F5),
                  Color(0xFFFFE5E5),
                  Color(0xFFFFD5D5),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '确认退出训练？',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isRecording ? '运动正在进行中，退出将丢失当前进度' : '确定要退出吗？',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            foregroundColor: const Color(0xFF6B7280),
                          ),
                          child: const Text(
                            '继续训练',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            '确认退出',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
        );

      },

    );



    if (ok == true && mounted) {

      Navigator.of(context).pop();

    }

  }



  void _debugPlusOne() {

    if (!isRecording || isStarting) return;



    setState(() {

      messageCount += 1;

    });



    unawaited(_playTapSfx());



    if (widget.config.level.targetCount > 0 && messageCount >= widget.config.level.targetCount) {

      _endRecording();

    }

  }



  @override

  Widget build(BuildContext context) {

    return WillPopScope(

      onWillPop: () async {

        if (isRecording) {

          await _confirmExit();

          return false;

        }

        return true;

      },

      child: Scaffold(

        backgroundColor: Colors.black,

        body: Stack(

          children: [

            Positioned.fill(

              child: FutureBuilder<void>(

                future: _initFuture,

                builder: (context, snapshot) {

                  if (snapshot.hasError) {

                    return Center(

                      child: Padding(

                        padding: const EdgeInsets.symmetric(horizontal: 24),

                        child: Column(

                          mainAxisSize: MainAxisSize.min,

                          children: [

                            Text(

                              _initErrorText ?? '相机初始化失败',

                              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),

                              textAlign: TextAlign.center,

                            ),

                            const SizedBox(height: 12),

                            TextButton.icon(

                              onPressed: _retryCameraInit,

                              icon: const Icon(Icons.refresh_rounded, size: 18),

                              label: const Text('重试'),

                              style: TextButton.styleFrom(foregroundColor: Colors.white),

                            ),

                          ],

                        ),

                      ),

                    );

                  }



                  if (snapshot.connectionState != ConnectionState.done || _controller == null) {

                    return const Center(child: CircularProgressIndicator(color: Colors.white));

                  }



                  final controller = _controller!;

                  return _CameraBackground(controller: controller, errorText: _initErrorText);

                },

              ),

            ),

            // ===== 测试模式：点击画面任意位置 = 计数 +1 =====
            // 刻意放在 Stack 靠前的位置：空白处/画面区域点击计数，
            // 后面的导航栏、GO、翻转摄像头等按钮仍优先响应，互不干扰。
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !isRecording || isStarting,
                child: GestureDetector(
                  onTap: _debugPlusOne,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Positioned(

              left: 0,

              right: 0,

              top: 0,

              child: SafeArea(

                bottom: false,

                child: _CustomNavbar(title: pageTitle),

              ),

            ),

            if (showCountdown)

              Positioned.fill(

                child: _CountdownOverlay(text: _countdown == 0 ? 'GO!' : '$_countdown'),

              ),

            if (showTimer) ...[

              Positioned(

                left: 18,

                top: 110,

                child: _OverlayPill(text: _formatTime(remainingSeconds)),

              ),

              Positioned(

                right: 18,

                top: 110,

                child: _OverlayCounter(text: '$messageCount'),

              ),

              Positioned(

                left: 18,

                top: 140,

                right: 18,

                child: _CuteProgressOverlay(

                  progress: (progressPercent / 100).clamp(0.0, 1.0),

                  text: '${math.min(messageCount, widget.config.level.targetCount)}/${widget.config.level.targetCount}',

                ),

              ),

            ],

            Positioned(

              left: 0,

              right: 0,

              bottom: 0,

              child: SafeArea(

                top: false,

                child: _BottomMenu(

                  isRecording: isRecording,

                  onBack: _confirmExit,

                  onSnapshot: () {

                    if (isStarting || showCountdown) return;

                    if (isRecording) {

                      showDialog<bool>(

                        context: context,

                        builder: (context) {

                          return AlertDialog(

                            title: const Text('提示'),

                            content: const Text('是否提前结束运动？'),

                            actions: [

                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),

                              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('确定')),

                            ],

                          );

                        },

                      ).then((ok) {

                        if (ok == true) {

                          _endRecording();

                        }

                      });

                    } else {

                      unawaited(_countdownPlayer.play(AssetSource('images/gogo.mp3')));

                      _startCountdown();

                    }

                  },

                  onFlip: _switchCamera,

                ),

              ),

            ),


          ],

        ),

      ),

    );

  }

}



class _CameraBackground extends StatelessWidget {
  const _CameraBackground({required this.controller, required this.errorText});

  final CameraController? controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final text = (errorText ?? '').trim();
    if (text.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    if (c == null || !c.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }

    final previewSize = c.value.previewSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: previewSize?.width ?? constraints.maxWidth,
                height: previewSize?.height ?? constraints.maxHeight,
                child: MirroredCameraPreview(controller: c),
              ),
            ),
          ),
        );
      },
    );
  }
}



class _CustomNavbar extends StatelessWidget {

  const _CustomNavbar({required this.title});



  final String title;



  @override

  Widget build(BuildContext context) {

    return Container(

      height: 50,

      alignment: Alignment.center,

      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.30)),

      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),

    );

  }

}



class _CountdownOverlay extends StatelessWidget {

  const _CountdownOverlay({required this.text});



  final String text;



  @override

  Widget build(BuildContext context) {

    return Container(

      color: Colors.black.withValues(alpha: 0.20),

      alignment: Alignment.center,

      child: Text(

        text,

        style: const TextStyle(

          fontSize: 120,

          fontWeight: FontWeight.w900,

          color: Colors.white,

        ),

      ),

    );

  }

}



class _OverlayPill extends StatelessWidget {

  const _OverlayPill({required this.text});



  final String text;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

      decoration: BoxDecoration(

        color: const Color(0xFF2E2C2F),

        borderRadius: BorderRadius.circular(30),

      ),

      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),

    );

  }

}



class _OverlayCounter extends StatelessWidget {

  const _OverlayCounter({required this.text});



  final String text;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

      decoration: BoxDecoration(

        color: const Color(0xFF2E2C2F),

        borderRadius: BorderRadius.circular(30),

      ),

      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),

    );

  }

}



class _CuteProgressOverlay extends StatelessWidget {

  const _CuteProgressOverlay({required this.progress, required this.text});



  final double progress;

  final String text;



  @override

  Widget build(BuildContext context) {

    final clamped = progress.clamp(0.0, 1.0);



    return LayoutBuilder(

      builder: (context, constraints) {

        final w = constraints.maxWidth;

        final trackWidth = w * 0.45;

        const trackHeight = 14.0;

        final fillWidth = (trackWidth * clamped).clamp(0.0, trackWidth);

        final visibleFill = math.max(trackHeight * 0.60, fillWidth);



        final trackRadius = trackHeight * 1.2;

        final knobSize = trackHeight * 2.1;

        final knobLeft = (fillWidth - (knobSize * 0.5)).clamp(-(knobSize * 0.5), trackWidth - (knobSize * 0.5));



        return SizedBox(

          height: 56,

          child: Center(

            child: SizedBox(

              width: trackWidth,

              height: 56,

              child: Stack(

                clipBehavior: Clip.none,

                children: [

                  Positioned(

                    top: 4,

                    left: -6,

                    child: Container(

                      width: trackWidth + 12,

                      height: 44,

                      decoration: BoxDecoration(

                        borderRadius: BorderRadius.circular(trackRadius * 1.6),

                        gradient: const LinearGradient(

                          begin: Alignment.topLeft,

                          end: Alignment.bottomRight,

                          colors: [Color(0xFFFFD7E8), Color(0xFFE6E3FF), Color(0xFFD7F3FF)],

                        ),

                        boxShadow: [

                          BoxShadow(

                            color: Colors.black.withValues(alpha: 0.18),

                            blurRadius: 16,

                            offset: const Offset(0, 10),

                          ),

                        ],

                        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 2),

                      ),

                    ),

                  ),

                  Positioned(

                    top: 22,

                    left: 0,

                    child: Container(

                      width: trackWidth,

                      height: trackHeight,

                      decoration: BoxDecoration(

                        borderRadius: BorderRadius.circular(trackRadius),

                        gradient: LinearGradient(

                          begin: Alignment.topLeft,

                          end: Alignment.bottomRight,

                          colors: [

                            Colors.white.withValues(alpha: 0.55),

                            Colors.white.withValues(alpha: 0.18),

                          ],

                        ),

                        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),

                      ),

                    ),

                  ),

                  Positioned(

                    top: 22,

                    left: 0,

                    child: ClipRRect(

                      borderRadius: BorderRadius.circular(trackRadius),

                      child: Container(

                        width: visibleFill,

                        height: trackHeight,

                        decoration: const BoxDecoration(

                          gradient: LinearGradient(

                            begin: Alignment.centerLeft,

                            end: Alignment.centerRight,

                            colors: [Color(0xFFFF63B6), Color(0xFFB388FF), Color(0xFF57D6FF)],

                          ),

                        ),

                      ),

                    ),

                  ),

                  Positioned(

                    top: 20,

                    left: 0,

                    child: Container(

                      width: visibleFill,

                      height: trackHeight + 6,

                      decoration: BoxDecoration(

                        borderRadius: BorderRadius.circular(trackRadius),

                        color: Colors.white.withValues(alpha: 0.16),

                      ),

                    ),

                  ),

                  Positioned(

                    top: 24,

                    left: visibleFill - 2,

                    child: Container(

                      width: 4,

                      height: trackHeight * 0.80,

                      decoration: BoxDecoration(

                        color: Colors.white.withValues(alpha: 0.92),

                        borderRadius: BorderRadius.circular(3),

                        boxShadow: [

                          BoxShadow(

                            color: Colors.white.withValues(alpha: 0.6),

                            blurRadius: 10,

                          )

                        ],

                      ),

                    ),

                  ),

                  Positioned(

                    top: 14,

                    left: knobLeft,

                    child: Container(

                      width: knobSize,

                      height: knobSize,

                      decoration: BoxDecoration(

                        shape: BoxShape.circle,

                        color: Colors.white.withValues(alpha: 0.96),

                        boxShadow: [

                          BoxShadow(

                            color: const Color(0xFFFF63B6).withValues(alpha: 0.35),

                            blurRadius: 18,

                            offset: const Offset(0, 6),

                          ),

                        ],

                        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),

                      ),

                      child: const Center(

                        child: Icon(

                          Icons.favorite,

                          size: 18,

                          color: Color(0xFFFF4FA8),

                        ),

                      ),

                    ),

                  ),

                  Positioned.fill(

                    top: 4,

                    child: Align(

                      alignment: Alignment.topCenter,

                      child: Text(

                        text,

                        style: const TextStyle(

                          fontSize: 14,

                          fontWeight: FontWeight.w900,

                          color: Colors.white,

                          shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],

                        ),

                      ),

                    ),

                  ),

                ],

              ),

            ),

          ),

        );

      },

    );

  }

}



class _BottomMenu extends StatelessWidget {

  const _BottomMenu({

    required this.isRecording,

    required this.onBack,

    required this.onSnapshot,

    required this.onFlip,

  });



  final bool isRecording;

  final VoidCallback onBack;

  final VoidCallback onSnapshot;

  final VoidCallback onFlip;



  @override

  Widget build(BuildContext context) {

    return SizedBox(

      height: 120,

      child: Center(

        child: Row(

          mainAxisSize: MainAxisSize.min,

          children: [

            _CircleButton(

              icon: Icons.arrow_back,

              onTap: onBack,

            ),

            const SizedBox(width: 16),

            _GoButton(isRecording: isRecording, onTap: onSnapshot),

            const SizedBox(width: 16),

            _CircleButton(

              icon: Icons.flip_camera_android,

              onTap: onFlip,

            ),

          ],

        ),

      ),

    );

  }

}



class _CircleButton extends StatelessWidget {

  const _CircleButton({required this.icon, required this.onTap});



  final IconData icon;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(99),

      child: Container(

        width: 56,

        height: 56,

        decoration: BoxDecoration(

          color: Colors.black.withValues(alpha: 0.35),

          shape: BoxShape.circle,

          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),

        ),

        child: Icon(icon, color: Colors.white, size: 26),

      ),

    );

  }

}



class _GoButton extends StatelessWidget {

  const _GoButton({required this.isRecording, required this.onTap});



  final bool isRecording;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(60),

      child: Container(

        width: isRecording ? 160 : 140,

        height: 56,

        decoration: BoxDecoration(

          gradient: const LinearGradient(colors: [Color(0xFFFC3307), Color(0xFFFF4F76)]),

          borderRadius: BorderRadius.circular(60),

          boxShadow: [

            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 10)),

          ],

        ),

        alignment: Alignment.center,

        child: Text(

          isRecording ? '结束' : 'GO!',

          style: TextStyle(

            color: Colors.white,

            fontWeight: FontWeight.w900,

            fontSize: isRecording ? 22 : 24,

            fontStyle: isRecording ? FontStyle.normal : FontStyle.italic,

          ),

        ),

      ),

    );

  }

}

