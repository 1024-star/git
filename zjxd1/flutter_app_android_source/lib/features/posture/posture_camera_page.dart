import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../utils/app_logger.dart';
import '../../utils/mirrored_camera_preview.dart';

class PostureCameraPage extends StatefulWidget {
  const PostureCameraPage({
    super.key,
    required this.stepName,
    required this.tip,
    required this.overlayImageAsset,
    required this.audioAsset,
  });

  final String stepName;
  final String tip;
  final String overlayImageAsset;
  final String audioAsset;

  @override
  State<PostureCameraPage> createState() => _PostureCameraPageState();
}

class _PostureCameraPageState extends State<PostureCameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _initErrorText;

  /// 记住已选摄像头：生命周期恢复重初始化时不再弹选择框
  CameraDescription? _lastSelectedCamera;

  /// 防止模拟器等环境下 availableCameras()/initialize() 永久挂起导致页面无限转圈
  static const Duration _initTimeout = Duration(seconds: 15);

  final AudioPlayer _player = AudioPlayer();

  XFile? _captured;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFuture = _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      // 主机切换摄像头/窗口失焦时虚拟相机设备可能断开重连，插件不会自动恢复，
      // 必须主动释放，等 resumed 后重建，否则预览会永久冻结
      final controller = _controller;
      if (controller == null) return;
      _controller = null;
      unawaited(controller.dispose());
      if (mounted) {
        setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      // 拍照预览态无需恢复相机，仅在取景态重建
      if (mounted && _controller == null && _captured == null) {
        _retryInit();
      }
    }
  }

  Future<void> _playStepAudio() async {
    if (widget.audioAsset.trim().isEmpty) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(_assetSourcePath(widget.audioAsset)));
    } catch (e, st) {
      AppLogger.e('体态相机', e, st);
    }
  }

  String _assetSourcePath(String asset) {
    var a = asset.trim();
    if (a.startsWith('assets/')) {
      a = a.substring('assets/'.length);
    }
    return a;
  }

  String _formatInitError(Object error) {
    if (error is MissingPluginException) {
      return '当前运行平台/构建未集成相机插件。\n请使用 Android/iOS 真机或模拟器运行，并执行一次完整重启（非热重载）。';
    }
    if (error is CameraException) {
      final desc = (error.description ?? '').trim();
      if (desc.isEmpty) {
        return '错误码：${error.code}';
      }
      return '错误码：${error.code}\n$desc';
    }
    return error.toString();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras().timeout(_initTimeout);
      if (cameras.isEmpty) {
        throw StateError('未检测到可用相机。若使用模拟器，请开启虚拟相机或使用真机测试。');
      }

      CameraDescription? selectedCamera;
      if (cameras.length > 1) {
        // 生命周期恢复重初始化时复用上次选择，避免再次弹框打断
        selectedCamera = _lastSelectedCamera;
        if (selectedCamera == null) {
          if (!mounted) return;
          selectedCamera = await _showCameraSelectionDialog(cameras);
          _lastSelectedCamera = selectedCamera;
        }
      }

      final cameraToUse = selectedCamera ?? cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // 摄像头选择完成后，再播报动作姿势提示
      _playStepAudio();

      final controller = CameraController(
        cameraToUse,
        ResolutionPreset.high, // 1280×720，仅拍照无录像，不会触发录像相关卡死问题
        enableAudio: false,
      );

      await controller.initialize().timeout(_initTimeout);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initErrorText = null;
      });
    } catch (e) {
      final text = _formatInitError(e);
      debugPrint('PostureCameraPage init failed: $text');
      if (mounted) {
        setState(() {
          _initErrorText = text;
        });
      }
      rethrow;
    }
  }

  Future<CameraDescription?> _showCameraSelectionDialog(List<CameraDescription> cameras) async {
    return await showDialog<CameraDescription>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 14),
                        Text(
                          '选择摄像头',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 240,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: cameras.length,
                      itemBuilder: (context, index) {
                        final camera = cameras[index];
                        final lensDirection = camera.lensDirection == CameraLensDirection.front
                            ? ''
                            : camera.lensDirection == CameraLensDirection.back
                                ? ''
                                : '';
                        final icon = camera.lensDirection == CameraLensDirection.front
                            ? Icons.camera_front
                            : camera.lensDirection == CameraLensDirection.back
                                ? Icons.camera_rear
                                : Icons.videocam;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                leading: Container(
                                  width: 52,
                                  height: 52,
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
                                  child: Icon(icon, color: const Color(0xFF667EEA), size: 30),
                                ),
                                title: Text(
                                  '摄像头 ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                subtitle: Text(
                                  lensDirection,
                                  style: const TextStyle(
                                    fontSize: 14,
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await _player.stop();
    } catch (e, st) {
      AppLogger.e('体态相机', e, st);
    }

    try {
      final file = await controller.takePicture().timeout(const Duration(seconds: 10));
      // 【核心处理】把 EXIF 旋转标记直接烤进像素：
      // 相机落盘的 JPG 像素是"横"的，靠 EXIF 标记转正；App 内 Image 组件认 EXIF 显示正常，
      // 但服务器端（OpenCV/YOLO）读图不认 EXIF，上传后会变成横图。
      // 烤进像素后，本地确认图/报告图与服务器上的图方向完全一致。
      final fixedFile = await _bakeOrientation(file);
      if (!mounted) return;
      setState(() {
        _captured = fixedFile;
      });
    } catch (e, st) {
      AppLogger.e('体态相机', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('拍照失败，请重试')),
      );
    }
  }

  /// 把 EXIF Orientation 旋转烤进像素并覆盖原文件（失败时退回原图，不影响拍照流程）
  Future<XFile> _bakeOrientation(XFile src) async {
    try {
      final bytes = await src.readAsBytes();
      final decoded = img.decodeJpg(bytes);
      if (decoded == null) return src;
      if (!decoded.exif.imageIfd.hasOrientation || decoded.exif.imageIfd.orientation == 1) {
        return src; // 无旋转标记，无需处理
      }
      final baked = img.bakeOrientation(decoded);
      await File(src.path).writeAsBytes(img.encodeJpg(baked, quality: 95), flush: true);
      return src;
    } catch (e, st) {
      AppLogger.e('体态相机', e, st);
      return src;
    }
  }

  void _retake() {
    setState(() {
      _captured = null;
    });
    _playStepAudio();
  }

  void _confirm() {
    final file = _captured;
    if (file == null) return;
    Navigator.of(context).pop(file.path);
  }

  void _retryInit() {
    setState(() {
      _initErrorText = null;
      _initFuture = _initCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: FutureBuilder<void>(
                future: _initFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    final details = _initErrorText;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('相机初始化失败', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                            if (details != null && details.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                details,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: _retryInit,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('重试'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState != ConnectionState.done || _controller == null) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  if (_captured != null) {
                    // 不再做水平镜像，拍后确认图方向与保存原图/报告页一致
                    return Image.file(File(_captured!.path), fit: BoxFit.cover);
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final controller = _controller!;
                      final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
                      final previewRatio = isPortrait ? (1 / controller.value.aspectRatio) : controller.value.aspectRatio;

                      // 标准等比铺满：预览宽度撑满屏幕，高度按比例计算并居中裁切，不做任何非等比缩放
                      final previewWidth = constraints.maxWidth;
                      final previewHeight = previewWidth / previewRatio;

                      return Center(
                        child: SizedBox(
                          width: previewWidth,
                          height: previewHeight,
                          child: ClipRect(
                            // 预览保持镜像（照镜子式取景，用户已确认要镜像）
                            child: MirroredCameraPreview(controller: controller),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_captured == null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.55,
                    child: Image.asset(
                      widget.overlayImageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          widget.stepName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                    ),
                    child: Text(
                      widget.tip,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _captured == null
                    ? Row(
                        children: [
                          const Spacer(),
                          GestureDetector(
                            onTap: _takePicture,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  )
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _retake,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.75), width: 1.5),
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                ),
                                child: const Text('重拍', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: _confirm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                  ),
                                  child: const Text('确认', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
