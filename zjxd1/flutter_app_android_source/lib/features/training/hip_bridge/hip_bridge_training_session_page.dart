import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/app_logger.dart';
import '../../../utils/mirrored_camera_preview.dart';
import '../../../utils/user_scope.dart';
import '../../../config/app_config.dart';
import '../../mine/motion_api_client.dart';

import 'hip_bridge_training_result_page.dart';

class HipBridgeTrainingSessionPage extends StatefulWidget {
  const HipBridgeTrainingSessionPage({
    super.key,
    required this.pageTitle,
    required this.exerciseSeconds,
    required this.isCountMode,
    required this.targetCount,
  });

  final String pageTitle;
  final int exerciseSeconds;
  final bool isCountMode;
  final int targetCount;

  @override
  State<HipBridgeTrainingSessionPage> createState() => _HipBridgeTrainingSessionPageState();
}

class _HipBridgeTrainingSessionPageState extends State<HipBridgeTrainingSessionPage> with WidgetsBindingObserver {
  static const int _defaultProgressGoal = 10;

  CameraController? _cameraController;
  String? _cameraInitError;

  /// 【防重入标志】同一时刻只允许一个相机初始化/重取流程，
  /// 避免并发创建控制器抢占设备导致画面卡死
  bool _cameraInitializing = false;
  bool _cameraReacquiring = false;

  /// 相机操作超时：模拟器/主机切换摄像头桥接抖动时，枚举与初始化可能永久挂起
  static const Duration _cameraTimeout = Duration(seconds: 8);

  /// 【预览看门狗】模拟器上 ImageReader 预览纹理偶发停止更新（画面黑屏但相机设备仍打开），
  /// 通过帧流心跳检测冻结并在非录制时自动重取相机；录制中只记日志提示手动重试，避免误丢录像段。
  /// 若设为 false 可整体停用看门狗（仅保留手动重试按钮）。
  static const bool _kEnablePreviewWatchdog = false;
  static const Duration _previewStallThreshold = Duration(seconds: 5);
  Timer? _previewWatchdogTimer;
  DateTime? _lastCameraFrameAt;
  bool _frameStreamArmed = false;

  /// 连续自动恢复仍收不到帧的次数上限，防止对已损坏的虚拟相机无限循环重连
  int _watchdogAutoRecoveryStreak = 0;
  bool _loggedRecordingStall = false;

  String? _recordedVideoPath;
  bool _videoRecordingStarted = false;

  bool _showCountdown = false;
  String _countdownText = '';
  Timer? _countdownTimer;

  bool _showTimer = false;
  Timer? _timer;
  int _secondsLeft = 0;

  bool _isRecording = false;
  int _messageCount = 0;

  bool _showPlusOne = false;
  bool _showFirework = false;
  bool _showBarrage = false;
  bool _showAwesome = false;

  Timer? _plusOneTimer;
  Timer? _fireworkTimer;
  Timer? _barrageTimer;
  Timer? _awesomeTimer;

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _goodSfxPlayer = AudioPlayer();

  final SoLoud _soLoud = SoLoud.instance;
  AudioSource? _plusOneSource;
  AudioSource? _goodSource;
  bool _soLoudReady = false;

  static const double _bgmVolume = 0.55;
  static const double _sfxVolume = 1.00;

  static const String _bgmAsset = 'images/exercise-background-music.wav';
  static const String _plusOneSfxAsset = 'images/plusone.mp3';
  static const String _goodSfxAsset = 'images/good.wav';
  static const String _countdown3Asset = 'images/3.mp3';
  static const String _countdown2Asset = 'images/2.mp3';
  static const String _countdown1Asset = 'images/1.mp3';
  static const String _countdownGoAsset = 'images/gogo.mp3';

  String? _coachVideoError;

  int get _progressGoal {
    if (widget.isCountMode && widget.targetCount > 0) return widget.targetCount;
    return widget.pageTitle.contains('关卡') ? 50 : _defaultProgressGoal;
  }

  double get _progress {
    if (_progressGoal <= 0) return 0;
    return (_messageCount / _progressGoal).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsLeft = widget.exerciseSeconds;
    _preloadAudio();
    unawaited(_initSfxEngine());
    _initCoachVideo();
    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));
    unawaited(_initCamera());
  }

  Future<void> _initSfxEngine() async {
    try {
      await _soLoud.init();
      final src = await _soLoud.loadAsset('assets/images/plusone.mp3');
      final good = await _soLoud.loadAsset('assets/images/good.wav');
      if (!mounted) {
        await _soLoud.disposeSource(src);
        await _soLoud.disposeSource(good);
        return;
      }
      _plusOneSource = src;
      _goodSource = good;
      _soLoudReady = true;
    } catch (e, st) {
      AppLogger.e('HipBridge训练', e, st);
    }
  }

  Future<void> _playCountdownGoSfx() async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource(_countdownGoAsset));
    } catch (e, st) {
      AppLogger.e('HipBridge训练', e, st);
    }
  }

  Future<void> _initCoachVideo() async {
    try {
      _coachVideoError = null;
      if (mounted) setState(() {});
    } catch (e, st) {
      AppLogger.e('HipBridge训练', e, st);
      if (!mounted) return;
      setState(() {
        _coachVideoError = 'GIF初始化失败';
      });
    }
  }

  Future<void> _initCamera() async {
    if (_cameraInitializing) return;
    _cameraInitializing = true;
    try {
      try {
        final cameras = await availableCameras().timeout(_cameraTimeout);
        if (cameras.isEmpty) {
          throw StateError('未检测到可用相机。若使用模拟器，请开启虚拟相机或使用真机测试。');
        }

        final front = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        final controller = CameraController(
          front,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await controller.initialize().timeout(_cameraTimeout);

        if (!mounted) {
          await controller.dispose();
          return;
        }

        setState(() {
          _cameraController = controller;
          _cameraInitError = null;
        });
        unawaited(_armPreviewWatchdog(controller));
      } catch (e, st) {
        AppLogger.e('HipBridge训练', e, st);
        if (!mounted) return;
        setState(() {
          _cameraInitError = e.toString();
        });
      }
    } finally {
      _cameraInitializing = false;
    }
  }

  /// 串行切换相机：必须先释放旧控制器再初始化新的。
  /// 模拟器/Windows 摄像头桥接下设备是独占的，"先开后关"会因抢占冲突导致画面永久卡住。
  Future<void> _switchCamera() async {
    // 录制中切换会销毁正在录制的控制器，直接中断录像，禁止
    if (_isRecording) return;

    final current = _cameraController;
    if (current == null || !current.value.isInitialized) return;

    try {
      final cameras = await availableCameras().timeout(_cameraTimeout);
      if (cameras.isEmpty) return;

      final currentDesc = current.description;
      final nextLens = currentDesc.lensDirection == CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;

      final next = cameras.firstWhere(
        (c) => c.lensDirection == nextLens,
        orElse: () => cameras.first,
      );

      // 第一步：先释放旧控制器并移出界面（预览区自动进入 loading 态）
      if (mounted) {
        setState(() {
          _cameraController = null;
          _cameraInitError = null;
        });
      }
      await current.dispose();

      if (!mounted) return;

      // 第二步：再初始化新控制器
      final nextController = CameraController(
        next,
        ResolutionPreset.high,
        enableAudio: false,
      );

      try {
        await nextController.initialize().timeout(_cameraTimeout);
      } catch (e, st) {
        AppLogger.e('HipBridge训练', e, st);
        // 初始化失败：释放半成品控制器并把错误上屏，避免预览指向失效对象造成冻屏
        await nextController.dispose();
        if (!mounted) return;
        setState(() {
          _cameraInitError = e.toString();
        });
        return;
      }

      if (!mounted) {
        await nextController.dispose();
        return;
      }

      setState(() {
        _cameraController = nextController;
      });
      unawaited(_armPreviewWatchdog(nextController));
    } catch (e, st) {
      AppLogger.e('HipBridge训练', e, st);
      if (!mounted) return;
      setState(() {
        _cameraInitError = e.toString();
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
      if (mounted &&
          !_cameraReacquiring &&
          !_cameraInitializing &&
          _cameraController == null &&
          _cameraInitError == null) {
        unawaited(_initCamera());
      }
    }
  }

  void _releaseCameraForLifecycle() {
    final camera = _cameraController;
    if (camera == null) return;
    _cameraController = null;
    if (camera.value.isRecordingVideo) {
      // 后台导致的录制中断：放弃该段录像，等待 resumed 后重建相机
      try {
        unawaited(camera.stopVideoRecording());
      } catch (e, st) {
        AppLogger.e('HipBridge训练', e, st);
      }
      _videoRecordingStarted = false;
    }
    unawaited(camera.dispose());
    if (mounted) {
      setState(() {});
    }
  }

  /// 相机初始化/切换失败后的手动重试入口（错误提示上的重试按钮）
  void _retryCameraInit() {
    unawaited(_forceReacquireCamera());
  }

  /// 【核心重试入口】训练中预览冻结（卡死）时强制重新获取摄像头：
  /// 释放旧控制器 → 重新初始化。全程可点（含录制中）。
  /// 若正在录制，冻结画面的录像已不可用，直接放弃该段录制以保证画面恢复。
  /// 释放操作带超时保护，防止对已冻结设备的调用永久挂起导致重试无法开始。
  Future<void> _forceReacquireCamera() async {
    if (_cameraReacquiring) return;
    _cameraReacquiring = true;
    try {
      final current = _cameraController;
      if (current != null && current.value.isRecordingVideo) {
        // 放弃当前录制段，避免 _endRecording 再访问已释放的控制器
        _videoRecordingStarted = false;
        _recordedVideoPath = null;
      }

      // 先把旧控制器移出界面，预览区立即进入 loading 态
      if (mounted && (current != null || _cameraInitError != null)) {
        setState(() {
          _cameraController = null;
          _cameraInitError = null;
        });
      }

      if (current != null) {
        try {
          await current.dispose().timeout(_cameraTimeout);
        } catch (e, st) {
          AppLogger.e('HipBridge训练', e, st);
        }
      }

      await _initCamera();
    } finally {
      _cameraReacquiring = false;
    }
  }

  /// 【预览看门狗】为当前控制器开启帧流心跳：仅用帧回调的时间戳检测预览是否冻结，
  /// 不消费图像数据。个别设备/模拟器 HAL 不支持帧流时自动停用看门狗，仅保留手动重试。
  Future<void> _armPreviewWatchdog(CameraController controller) async {
    if (!_kEnablePreviewWatchdog) return;
    _lastCameraFrameAt = null;
    _frameStreamArmed = false;
    _loggedRecordingStall = false;
    try {
      await controller.startImageStream((CameraImage _) {
        _lastCameraFrameAt = DateTime.now();
      });
      if (identical(_cameraController, controller) && mounted) {
        _frameStreamArmed = true;
        // 开启成功即视为收到心跳，为第一帧留出停顿宽限
        _lastCameraFrameAt = DateTime.now();
      }
    } catch (e, st) {
      AppLogger.e('HipBridge训练', e, st);
    }
    _previewWatchdogTimer ??= Timer.periodic(const Duration(seconds: 2), (_) {
      _checkPreviewWatchdog();
    });
  }

  /// 【预览看门狗】周期检查：帧心跳超过阈值视为预览冻结，
  /// 非录制时自动重取相机（复用手动重试逻辑），录制中只记日志避免误丢录像段
  void _checkPreviewWatchdog() {
    if (!mounted || !_kEnablePreviewWatchdog) return;
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (!_frameStreamArmed || _cameraReacquiring || _cameraInitializing) return;

    final last = _lastCameraFrameAt;
    final stalled = last != null && DateTime.now().difference(last) > _previewStallThreshold;
    if (!stalled) {
      _watchdogAutoRecoveryStreak = 0;
      _loggedRecordingStall = false;
      return;
    }

    if (controller.value.isRecordingVideo) {
      if (!_loggedRecordingStall) {
        _loggedRecordingStall = true;
        AppLogger.w('HipBridge训练', '预览帧流停滞（录制中）：如画面黑屏请点重试按钮恢复');
      }
      return;
    }

    if (_watchdogAutoRecoveryStreak >= 3) {
      return;
    }
    _watchdogAutoRecoveryStreak++;
    AppLogger.w('HipBridge训练', '检测到预览冻结（第$_watchdogAutoRecoveryStreak次），自动重取相机');
    unawaited(_forceReacquireCamera());
  }

  Future<void> _preloadAudio() async {
    try {
      await _bgmPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _goodSfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    } catch (e, st) {
      AppLogger.e('HipBridge训练', e, st);
    }

    try {
      await _bgmPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.media,
            contentType: AndroidContentType.music,
            audioFocus: AndroidAudioFocus.none,
            stayAwake: false,
            isSpeakerphoneOn: true,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: <AVAudioSessionOptions>{AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await _sfxPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.media,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.none,
            stayAwake: false,
            isSpeakerphoneOn: true,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: <AVAudioSessionOptions>{AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await _goodSfxPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.media,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.none,
            stayAwake: false,
            isSpeakerphoneOn: true,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: <AVAudioSessionOptions>{AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.e('HipBridge训练', e, st);
    }

    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _goodSfxPlayer.setReleaseMode(ReleaseMode.stop);

    try {
      await _bgmPlayer.setVolume(_bgmVolume);
      await _sfxPlayer.setVolume(_sfxVolume);
      await _goodSfxPlayer.setVolume(_sfxVolume);
    } catch (e, st) {
      AppLogger.e('HipBridge训练', e, st);
    }

    // Preload by setting sources once.
    try {
      await _bgmPlayer.setSource(AssetSource(_bgmAsset));
      await _sfxPlayer.setSource(AssetSource(_plusOneSfxAsset));
      await _goodSfxPlayer.setSource(AssetSource(_goodSfxAsset));
    } catch (e, st) {
      AppLogger.e('HipBridge训练', e, st);
    }
  }

  @override
  void dispose() {
    _clearAllTimers();
    _cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    final src = _plusOneSource;
    if (src != null) {
      unawaited(_soLoud.disposeSource(src));
    }
    final good = _goodSource;
    if (good != null) {
      unawaited(_soLoud.disposeSource(good));
    }
    unawaited(_bgmPlayer.stop());
    unawaited(_bgmPlayer.dispose());
    unawaited(_sfxPlayer.stop());
    unawaited(_sfxPlayer.dispose());
    unawaited(_goodSfxPlayer.stop());
    unawaited(_goodSfxPlayer.dispose());

    // 【关键】释放 SoLoud 音频引擎：之前只 dispose 了音源、没有 deinit，
    // 引擎会一直占着 Android 音频会话，导致后续「数字人播报」的 video_player 无声。
    if (_soLoudReady) {
      _soLoud.deinit();
      _soLoudReady = false;
    }
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    super.dispose();
  }

  void _clearAllTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    _timer?.cancel();
    _timer = null;

    _plusOneTimer?.cancel();
    _plusOneTimer = null;

    _fireworkTimer?.cancel();
    _fireworkTimer = null;

    _barrageTimer?.cancel();
    _barrageTimer = null;

    _awesomeTimer?.cancel();
    _awesomeTimer = null;

    _previewWatchdogTimer?.cancel();
    _previewWatchdogTimer = null;
  }

  Future<void> _playPlusOneSfx() async {
    if (_soLoudReady) {
      final src = _plusOneSource;
      if (src != null) {
        try {
          await _soLoud.play(src);
          return;
        } catch (e, st) {
          AppLogger.e('HipBridge训练', e, st);
        }
      }
    }

    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource(_plusOneSfxAsset));
    } catch (e, st) {
      AppLogger.e('HipBridge训练', e, st);
    }
  }

  Future<void> _playGoodSfx() async {
    if (_soLoudReady) {
      final src = _goodSource;
      if (src != null) {
        try {
          await _soLoud.play(src);
          return;
        } catch (e, st) {
          AppLogger.e('HipBridge训练', e, st);
        }
      }
    }

    try {
      await _goodSfxPlayer.stop();
      await _goodSfxPlayer.setVolume(_sfxVolume);
      await _goodSfxPlayer.play(AssetSource(_goodSfxAsset));
    } catch (e, st) {
      AppLogger.e('HipBridge训练', e, st);
    }
  }

  Future<void> _startCountdown() async {
    if (_isRecording) return;

    setState(() {
      _showCountdown = true;
      _showTimer = false;
      _countdownText = '3';
    });

    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);

    var count = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      count -= 1;
      if (!mounted) return;

      if (count > 0) {
        setState(() {
          _countdownText = '$count';
        });

        HapticFeedback.selectionClick();
        SystemSound.play(SystemSoundType.click);
        return;
      }

      if (count == 0) {
        setState(() {
          _countdownText = 'GO!';
        });

        HapticFeedback.mediumImpact();
        return;
      }

      t.cancel();
      _countdownTimer = null;
      if (!mounted) return;
      setState(() {
        _showCountdown = false;
      });
      _startTimer();
    });
  }

  Future<void> _startTimer() async {
    setState(() {
      _showTimer = true;
      _isRecording = true;
      _secondsLeft = widget.exerciseSeconds;
    });

    _recordedVideoPath = null;

    CameraController? camera = _cameraController;
    if (camera == null || !camera.value.isInitialized) {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        camera = _cameraController;
        if (camera != null && camera.value.isInitialized) break;
      }
    }

    if (camera != null && camera.value.isInitialized) {
      try {
        if (!camera.value.isRecordingVideo) {
          try {
            await camera.startVideoRecording();
          } catch (e, st) {
            AppLogger.e('HipBridge训练', e, st);
            // 个别模拟器 HAL 开着帧流时无法同时录制：先停帧流（看门狗随之停用）再重试录制一次
            if (_frameStreamArmed && identical(camera, _cameraController)) {
              try {
                await camera.stopImageStream();
              } catch (_) {}
              _frameStreamArmed = false;
              _lastCameraFrameAt = null;
              await camera.startVideoRecording();
            } else {
              rethrow;
            }
          }
        }
        _videoRecordingStarted = true;
      } catch (e, st) {
        AppLogger.e('HipBridge训练', e, st);
        _videoRecordingStarted = false;
      }
    }

    try {
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.play(AssetSource(_bgmAsset));
    } catch (e, st) {
      AppLogger.e('HipBridge训练', e, st);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (!widget.isCountMode) {
        setState(() {
          _secondsLeft -= 1;
        });
        if (_secondsLeft <= 0) {
          _endRecording();
        }
      }
    });
  }

  Future<void> _endRecording() async {
    _timer?.cancel();
    _timer = null;

    final camera = _cameraController;
    if (camera != null && camera.value.isInitialized) {
      try {
        if (camera.value.isRecordingVideo) {
          final file = await camera.stopVideoRecording();
          _recordedVideoPath = file.path;
          final copied = await _copyVideoToExportDir(_recordedVideoPath);
          if (copied != null) {
            _recordedVideoPath = copied;
            // 后台异步上传到后端，不阻塞结果页展示
            _uploadVideoInBackground(copied);
          }
        }
      } catch (e, st) {
        AppLogger.e('HipBridge训练', e, st);
      }
      _videoRecordingStarted = false;
    }

    await _bgmPlayer.stop();

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _showTimer = false;
      _showCountdown = false;
    });

    if (!mounted) return;

    final actualTime = widget.isCountMode ? 0 : (widget.exerciseSeconds - _secondsLeft).clamp(0, widget.exerciseSeconds);
    final actualCount = _messageCount;
    final targetCount = widget.isCountMode ? widget.targetCount : _progressGoal;

    final resultData = {
      'title': widget.pageTitle,
      'actualCount': actualCount,
      'targetCount': targetCount,
      'actualTimeSeconds': actualTime,
      'isCountMode': widget.isCountMode,
      'videoPath': _recordedVideoPath,
    };

    // Save directly to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hip_bridge_has_result', true);
      await prefs.setString('hip_bridge_result_data', '''
{
  "title": "${resultData['title']}",
  "actualCount": ${resultData['actualCount']},
  "targetCount": ${resultData['targetCount']},
  "actualTimeSeconds": ${resultData['actualTimeSeconds']},
  "isCountMode": ${resultData['isCountMode']},
  "videoPath": "${resultData['videoPath'] ?? ''}"
}''');
      print('Hip Bridge Training: Result saved from session page');
    } catch (e) {
      print('Hip Bridge Training: Error saving result - $e');
    }

    // 上报真实运动记录到后端（失败静默，不影响结果页）
    _saveMotionRecord(actualCount, targetCount, actualTime);

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HipBridgeTrainingResultPage(
          title: widget.pageTitle,
          actualCount: actualCount,
          targetCount: targetCount,
          actualTimeSeconds: actualTime,
          isCountMode: widget.isCountMode,
          videoPath: _recordedVideoPath,
        ),
      ),
    );
  }

  Future<String?> _copyVideoToExportDir(String? sourcePath) async {
    final src = (sourcePath ?? '').trim();
    if (src.isEmpty) return null;

    try {
      final srcFile = File(src);
      if (!srcFile.existsSync()) return null;

      final dirPath = UserScope.exportVideoDir;
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final extIndex = src.lastIndexOf('.');
      final ext = extIndex >= 0 ? src.substring(extIndex) : '.mp4';
      // 用动作名+时间戳生成唯一文件名，避免所有视频都叫 test 且相互覆盖
      final stamp = DateTime.now().millisecondsSinceEpoch.toString();
      final destPath = '${dir.path}/hip_bridge_$stamp$ext';

      await srcFile.copy(destPath);
      return destPath;
    } catch (e) {
      debugPrint('Copy video to ${UserScope.exportVideoDir} failed: $e');
      return null;
    }
  }

  /// 后台把训练视频上传到后端（后端再 SFTP 转存到远程服务器）。
  /// 只做日志，不弹 UI，也不阻塞结果页；失败静默（下次训练会重新上传）。
  void _uploadVideoInBackground(String localPath) {
    // 与其他 API 客户端保持一致的默认后端地址
    const baseUrl = kApiBaseUrl;

    unawaited(() async {
      try {
        final uri = Uri.parse('$baseUrl/api/video/upload');
        final request = http.MultipartRequest('POST', uri)
          ..fields['username'] = (UserScope.username ?? 'anonymous').trim()
          ..files.add(await http.MultipartFile.fromPath('file', localPath));

        final resp = await request.send().timeout(
          const Duration(minutes: 10),
          onTimeout: () {
            debugPrint('Video upload timeout: $localPath');
            throw TimeoutException('视频上传超时');
          },
        );

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final body = await resp.stream.bytesToString();
          debugPrint('Video uploaded: $localPath -> $body');
        } else {
          final body = await resp.stream.bytesToString();
          debugPrint('Video upload failed (${resp.statusCode}): $body');
        }
      } catch (e) {
        debugPrint('Video upload error: $e');
      }
    }());
  }

  /// 训练完成后上报真实运动记录到后端（失败静默，不影响结果页）
  void _saveMotionRecord(int actualCount, int targetCount, int actualTime) {
    unawaited(() async {
      try {
        final record = MotionRecord(
          motionName: widget.pageTitle,
          actualCount: actualCount,
          targetCount: targetCount,
          actualTimeSeconds: actualTime,
          isCountMode: widget.isCountMode,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        );
        final ok = await MotionApiClient().saveRecord(record: record);
        debugPrint(ok ? 'Motion record saved: ${widget.pageTitle}' : 'Motion record save failed');
      } catch (e) {
        debugPrint('Motion record save error: $e');
      }
    }());
  }

  Future<void> _onBack() async {
    if (!_isRecording) {
      Navigator.of(context).pop();
      return;
    }

    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFFFF69B4).withOpacity(0.3), width: 2),
          ),
          elevation: 12,
          shadowColor: const Color(0xFFFF69B4).withOpacity(0.15),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF69B4).withOpacity(0.1),
                  const Color(0xFFFFB6C1).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              '提示',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD1477A),
              ),
            ),
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: const Text(
              '是否放弃运动？',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF555555),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF69B4).withOpacity(0.4)),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF69B4).withOpacity(0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: const Color(0xFFD1477A),
                ),
                child: const Text(
                  '取消',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF69B4).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  '确定',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldQuit == true && mounted) {
      await _bgmPlayer.stop();
      Navigator.of(context).pop();
    }
  }

  Future<void> _onSnapshot() async {
    if (_isRecording) {
      final shouldEnd = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: const Color(0xFFFF69B4).withOpacity(0.3), width: 2),
            ),
            elevation: 12,
            shadowColor: const Color(0xFFFF69B4).withOpacity(0.15),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFF69B4).withOpacity(0.1),
                    const Color(0xFFFFB6C1).withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Text(
                '提示',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD1477A),
                ),
              ),
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: const Text(
                '是否提前结束运动？',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF555555),
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF69B4).withOpacity(0.4)),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF69B4).withOpacity(0.05),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    foregroundColor: const Color(0xFFD1477A),
                  ),
                  child: const Text(
                    '取消',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF69B4).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    '确定',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldEnd == true) {
        await _endRecording();
      }
      return;
    }

    unawaited(_playCountdownGoSfx());
    await _startCountdown();
  }

  void _plusOne() {
    if (!_isRecording) return;

    setState(() {
      _messageCount += 1;
      _showPlusOne = true;
    });

    unawaited(_playPlusOneSfx());

    _plusOneTimer?.cancel();
    _plusOneTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _showPlusOne = false;
      });
    });

    _triggerEffects();

    if (widget.isCountMode && widget.targetCount > 0 && _messageCount >= widget.targetCount) {
      Timer(const Duration(seconds: 1), () {
        if (mounted) {
          unawaited(_endRecording());
        }
      });
    }
  }

  void _triggerEffects() {
    // 礼花：每10次
    if (_messageCount > 0 && _messageCount % 10 == 0) {
      setState(() {
        _showFirework = true;
      });
      _fireworkTimer?.cancel();
      _fireworkTimer = Timer(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() {
          _showFirework = false;
        });
      });
    }

    // 弹幕：每3次
    if (_messageCount > 0 && _messageCount % 3 == 0) {
      unawaited(_playGoodSfx()); // 先播放音效
      setState(() {
        _showBarrage = true;
      });
      _barrageTimer?.cancel();
      _barrageTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _showBarrage = false;
        });
      });
    }

    // 厉害：4,14,24...
    if (_messageCount >= 4 && (_messageCount - 4) % 10 == 0) {
      setState(() {
        _showAwesome = true;
      });
      unawaited(_playGoodSfx());
      _awesomeTimer?.cancel();
      _awesomeTimer = Timer(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        setState(() {
          _showAwesome = false;
        });
      });
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final camera = _cameraController;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _CameraBackground(
              controller: camera,
              errorText: _cameraInitError,
              onRetry: _retryCameraInit,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ),

          // Tap anywhere (camera area) to simulate +1 count (behind UI, so it won't block buttons)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isRecording,
              child: GestureDetector(
                onTap: _plusOne,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Custom navbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 52,
                color: Colors.black.withValues(alpha: 0.30),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    _CircleIconButton(
                      onTap: _onBack,
                      icon: Icons.close_rounded,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.pageTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 54),
                  ],
                ),
              ),
            ),
          ),

          // Countdown overlay
          if (_showCountdown)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.25),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.80, end: 1.0).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Stack(
                      key: ValueKey<String>(_countdownText),
                      alignment: Alignment.center,
                      children: [
                        Text(
                          _countdownText,
                          style: TextStyle(
                            fontSize: isLandscape ? 220 : 180,
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 12
                              ..color = Colors.black.withValues(alpha: 0.35),
                          ),
                        ),
                        Text(
                          _countdownText,
                          style: TextStyle(
                            fontSize: isLandscape ? 220 : 180,
                            fontWeight: FontWeight.w900,
                            color: _countdownText == 'GO!' ? const Color(0xFFD2FA55) : Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 26, offset: Offset(0, 8)),
                              Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (_showTimer)
            Positioned(
              top: isLandscape ? 20 : 92,
              left: isLandscape ? 18 : 18,
              child: _DarkPill(
                child: Text(
                  _formatTime(widget.isCountMode ? widget.exerciseSeconds : _secondsLeft),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),

          if (_showTimer)
            Positioned(
              top: isLandscape ? 20 : 92,
              right: 18,
              child: _DarkPill(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _showPlusOne ? const Color(0xFFD2FA55) : Colors.white,
                  ),
                  child: Text('${_messageCount}'),
                ),
              ),
            ),

          if (_showTimer)
            Positioned(
              top: isLandscape ? 12 : 60,
              left: 0,
              right: 0,
              child: Center(
                child: Transform.scale(
                  scale: isLandscape ? 0.60 : 1,
                  child: _ProgressBar(
                    progress: _progress,
                    // 进度条上不再显示达成次数文案，次数统一看右上角
                    text: '',
                  ),
                ),
              ),
            ),

          if (_showTimer)
            Positioned(
              top: isLandscape ? 88 : 180,
              left: 14,
              child: _CoachVideoCard(
                errorText: _coachVideoError,
                width: isLandscape ? 170 : 140,
              ),
            ),

          // +1 bubble
          if (_showPlusOne && widget.pageTitle.contains('关卡'))
            Positioned(
              top: size.height * 0.40,
              left: size.width * 0.5 - 90,
              child: _PlusOneBadge(),
            ),

          if (_showFirework)
            Positioned(
              top: size.height * 0.45,
              left: isLandscape ? size.width * 0.70 : size.width * 0.72,
              child: Transform.scale(
                scale: isLandscape ? 0.6 : 1,
                child: Image.asset(
                  'assets/images/firework-effect.gif',
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                  // 限制解码尺寸：GIF 逐帧走 CPU 软解码，按显示尺寸解码可大幅降低每帧开销
                  cacheWidth: 320,
                  errorBuilder: (context, _, __) => const SizedBox.shrink(),
                ),
              ),
            ),

          if (_showBarrage)
            Positioned.fill(
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 1.00,
                  heightFactor: 1.00,
                  child: Image.asset(
                    'assets/images/chat-barrage-effect.gif',
                    fit: BoxFit.contain,
                    // 限制解码尺寸：GIF 逐帧走 CPU 软解码，按显示尺寸解码可大幅降低每帧开销
                    cacheWidth: 720,
                    errorBuilder: (context, _, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          if (_showAwesome)
            Positioned(
              top: isLandscape ? size.height * 0.08 : size.height * 0.28,
              left: size.width * 0.5 - 120,
              child: Transform.scale(
                scale: isLandscape ? 0.6 : 1,
                child: Image.asset(
                  'assets/images/awesome-effect.gif',
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                  // 限制解码尺寸：GIF 逐帧走 CPU 软解码，按显示尺寸解码可大幅降低每帧开销
                  cacheWidth: 480,
                  errorBuilder: (context, _, __) => const SizedBox.shrink(),
                ),
              ),
            ),

          // Bottom menu
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // 居中布局
                  children: [
                    _CircleIconButton(
                      onTap: _onBack,
                      icon: Icons.arrow_back_rounded,
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: isLandscape ? 210 : 240,
                      child: _GoButton(
                        isRecording: _isRecording,
                        onTap: _onSnapshot,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 【重试按钮】摄像头卡死时手动重新获取：随时可点（含录制中），
                    // 释放当前控制器并重新初始化，预览区会先显示 loading
                    _CircleIconButton(
                      onTap: _forceReacquireCamera,
                      icon: Icons.restart_alt_rounded,
                    ),
                    const SizedBox(width: 16),
                    _CircleIconButton(
                      onTap: _switchCamera,
                      icon: Icons.cameraswitch_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraBackground extends StatelessWidget {
  const _CameraBackground({
    required this.controller,
    required this.errorText,
    this.onRetry,
  });

  final CameraController? controller;
  final String? errorText;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errorText!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重试'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                ),
              ],
            ],
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

class _CoachVideoCard extends StatelessWidget {
  const _CoachVideoCard({
    required this.errorText,
    required this.width,
  });

  final String? errorText;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (errorText != null) {
      return SizedBox(
        width: width,
        child: Text(
          errorText!,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return SizedBox(
      width: width,
      child: Transform.scale(
        scale: 1.5,
        child: Image.asset(
          'assets/images/tunqiao2.gif',
          fit: BoxFit.contain,
          // 限制解码尺寸：常驻教学 GIF 逐帧走 CPU 软解码，按显示尺寸解码可大幅降低每帧开销
          cacheWidth: 480,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: width,
              child: Text(
                'GIF加载失败',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2C2F),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: child,
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.text});

  final double progress;
  final String text;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: 1020,
      height: 180,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          final trackLeft = w * 0.20;
          final trackTop = h * 0.52;
          final trackWidth = w * 0.62;
          final trackHeight = h * 0.15;
          final fillWidth = (trackWidth * clamped).clamp(0.0, trackWidth);
          final visibleFill = math.max(trackHeight * 0.60, fillWidth);

          final trackRadius = trackHeight * 1.2;
          final knobSize = trackHeight * 2.1;
          final knobLeft = (trackLeft + fillWidth - (knobSize * 0.5)).clamp(trackLeft - (knobSize * 0.5), trackLeft + trackWidth - (knobSize * 0.5));

          return Stack(
            children: [
              Positioned(
                top: trackTop - (trackHeight * 0.90),
                left: trackLeft - (trackHeight * 0.60),
                child: Container(
                  width: trackWidth + (trackHeight * 1.2),
                  height: trackHeight * 2.8,
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
                top: trackTop,
                left: trackLeft,
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
                top: trackTop,
                left: trackLeft,
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
                top: trackTop - (trackHeight * 0.18),
                left: trackLeft,
                child: Container(
                  width: visibleFill,
                  height: trackHeight + (trackHeight * 0.28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(trackRadius),
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Positioned(
                top: trackTop + (trackHeight * 0.10),
                left: trackLeft + visibleFill - 2,
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
                top: trackTop - (knobSize * 0.52) + 12, // 高度下移12px (累计下移12px)
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
              Positioned(
                top: h * 0.37,
                left: 0,
                right: 0,
                child: Center(
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
          );
        },
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.onTap, required this.icon});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Icon(icon, color: Colors.white),
        ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFC3307), Color(0xFFFF4F76)],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFC3307).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            isRecording ? '结束' : 'GO!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 26,
              fontStyle: isRecording ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlusOneBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: const Text(
        '+1',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFD2FA55)),
      ),
    );
  }
}
