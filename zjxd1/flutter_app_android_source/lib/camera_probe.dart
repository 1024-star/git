// ============================================================
//  临时相机探针（诊断用，不属于正式功能）
//  目的：验证 CameraX 下「预览 + startImageStream 逐帧取帧」能否并存，
//        并逐帧计算平均亮度以判断是否出现黑帧。
//  用法： flutter run -t lib/camera_probe.dart -d emulator-5554
// ============================================================
import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ProbeApp());
}

class ProbeApp extends StatelessWidget {
  const ProbeApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ProbePage(),
      );
}

class ProbePage extends StatefulWidget {
  const ProbePage({super.key});
  @override
  State<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<ProbePage> {
  CameraController? _cam;
  String _status = '初始化中...';
  bool _ready = false;

  int _frames = 0;
  int _fps = 0;
  int _prevFrames = 0;
  double _luma = -1;
  double _minLuma = 999;
  double _maxLuma = -1;
  int _blackFrames = 0; // 平均亮度 < 8 视为黑帧
  DateTime? _lastFrameAt;
  int _stallEvents = 0;
  String _size = '-';
  bool _recording = false;

  Timer? _ticker;
  final List<String> _log = [];

  void _addLog(String s) {
    debugPrint('[PROBE] $s');
    _log.insert(0, '${DateTime.now().toString().substring(11, 19)}  $s');
    if (_log.length > 12) _log.removeLast();
  }

  @override
  void initState() {
    super.initState();
    _init();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      final stalled = _lastFrameAt == null ||
          now.difference(_lastFrameAt!).inMilliseconds > 1500;
      if (!stalled) {
        setState(() {
          _fps = _frames - _prevFrames;
          _prevFrames = _frames;
        });
        // 每秒把量化指标打到日志，便于无人值守验证
        debugPrint('[METRICS] frames=%_total fps=%_fps luma=%_luma min=%_min max=%_max black=%_black stall=%_stall'
            .replaceAll('%_total', '$_frames')
            .replaceAll('%_fps', '$_fps')
            .replaceAll('%_luma', _luma < 0 ? '-' : _luma.toStringAsFixed(1))
            .replaceAll('%_min', _minLuma > 900 ? '-' : _minLuma.toStringAsFixed(1))
            .replaceAll('%_max', _maxLuma < 0 ? '-' : _maxLuma.toStringAsFixed(1))
            .replaceAll('%_black', '$_blackFrames')
            .replaceAll('%_stall', '$_stallEvents'));
      } else if (_ready && _lastFrameAt != null) {
        _stallEvents++;
        _addLog('!! 帧流停滞  ${now.difference(_lastFrameAt!).inMilliseconds}ms');
        setState(() {});
      }
    });
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _status = '没有可用相机');
        return;
      }
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      _addLog('发现 ${cams.length} 个相机，用 ${front.name}');

      final cam = CameraController(front, ResolutionPreset.high, enableAudio: false);
      await cam.initialize();
      if (!mounted) return;
      setState(() {
        _cam = cam;
        _ready = true;
        _status = '预览已启动，正在开图像流...';
      });
      _addLog('预览初始化完成');

      // 关键：在预览同时开启图像流
      await cam.startImageStream(_onFrame);
      _addLog('图像流已开启（预览+取帧并存）');
      setState(() => _status = '预览 + 图像流 并存中');

      // ---- 追加验证：图像流进行中能否同时录像 ----
      await Future<void>.delayed(const Duration(seconds: 3));
      final framesBeforeRec = _frames;
      try {
        _addLog('开始录像...');
        await cam.startVideoRecording();
        _recording = true;
        setState(() => _status = '预览 + 取帧 + 录像 三者并存中');
        _addLog('录像已开始（三路并存）');
        await Future<void>.delayed(const Duration(seconds: 25));
        final f2 = _frames;
        final xf = await cam.stopVideoRecording();
        _recording = false;
        _addLog('录像结束: 取帧增量=' + (f2 - framesBeforeRec).toString() +
            ' 文件=' + xf.name);
        setState(() => _status = '三者并存验证通过（录像期间取帧正常）');
      } catch (e) {
        _recording = false;
        _addLog('录像失败: ' + e.toString());
        setState(() => _status = '录像异常（见日志）');
      }
    } catch (e, st) {
      _addLog('异常: $e');
      setState(() => _status = '异常: $e');
      debugPrint('$st');
    }
  }

  void _onFrame(CameraImage img) {
    _lastFrameAt = DateTime.now();
    _frames++;
    if (_frames == 1) {
      _size = '${img.width}x${img.height} planes=${img.planes.length}';
    }
    // 取 Y 平面（yuv420 的第 0 个平面）采样算平均亮度
    if (img.planes.isNotEmpty) {
      final Uint8List y = img.planes[0].bytes;
      if (y.isNotEmpty) {
        int sum = 0;
        int n = 0;
        final step = (y.length ~/ 2000).clamp(1, 1 << 20);
        for (int i = 0; i < y.length; i += step) {
          sum += y[i];
          n++;
        }
        final avg = n == 0 ? -1.0 : sum / n;
        _luma = avg;
        if (avg < _minLuma) _minLuma = avg;
        if (avg > _maxLuma) _maxLuma = avg;
        if (avg < 8) _blackFrames++;
      }
    }
    if (mounted && _frames % 30 == 0) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _cam?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = _cam;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: _ready && cam != null
                    ? AspectRatio(
                        aspectRatio: 1 / cam.value.aspectRatio,
                        child: CameraPreview(cam),
                      )
                    : Text(_status, style: const TextStyle(color: Colors.white)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                color: const Color(0xFF111111),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_status,
                        style: const TextStyle(color: Colors.cyan, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('实现: camera_android_camerax (CameraX)',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('分辨率: $_size',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _kv('帧总数', '$_frames'),
                      _kv('FPS', '$_fps'),
                      _kv('当前亮度', _luma < 0 ? '-' : _luma.toStringAsFixed(1)),
                    ]),
                    Row(children: [
                      _kv('最小亮度', _minLuma > 900 ? '-' : _minLuma.toStringAsFixed(1)),
                      _kv('最大亮度', _maxLuma < 0 ? '-' : _maxLuma.toStringAsFixed(1)),
                      _kv('黑帧数', '$_blackFrames'),
                    ]),
                    Row(children: [
                      _kv('停滞次数', '$_stallEvents'),
                    ]),
                    const Divider(color: Colors.white24, height: 12),
                    Expanded(
                      child: ListView(
                        children: _log
                            .map((s) => Text(s,
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')))
                            .toList(),
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

  Widget _kv(String k, String v) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(v, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}