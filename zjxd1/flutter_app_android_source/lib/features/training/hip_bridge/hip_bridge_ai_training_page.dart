// ============================================================================
//  臀桥 · AI 动作分析训练页
//  ---------------------------------------------------------------------------
//  链路：摄像头 -> 抽帧(10~15fps) -> PC 识别服务(WebSocket) -> 关键点+评分
//        -> 骨骼叠加 -> HUD -> 结束取 summary -> 结果页
//
//  本页为「康复训练辅助」，做动作质量分析，不做任何医学诊断。
// ============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/app_config.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/mirrored_camera_preview.dart';
import 'hip_bridge_ai_result_page.dart';

const List<List<int>> kPoseConnections = [
  [0, 1], [1, 2], [2, 3], [3, 7], [0, 4], [4, 5], [5, 6], [6, 8], [9, 10],
  [11, 12], [11, 13], [13, 15], [15, 17], [15, 19], [15, 21], [17, 19],
  [12, 14], [14, 16], [16, 18], [16, 20], [16, 22], [18, 20],
  [11, 23], [12, 24], [23, 24], [23, 25], [25, 27], [27, 29], [27, 31], [29, 31],
  [24, 26], [26, 28], [28, 30], [28, 32], [30, 32],
];

/// 校准键：按设备保存，第一次选对后以后自动使用
const String _kCalibKey = 'hip_bridge_calib_mode';

class HipBridgeAiTrainingPage extends StatefulWidget {
  const HipBridgeAiTrainingPage({
    super.key,
    required this.targetReps,
    this.levelName = '臀桥训练',
    this.targetSeconds = 0,
  });

  final int targetReps;
  final String levelName;
  final int targetSeconds;

  @override
  State<HipBridgeAiTrainingPage> createState() => _HipBridgeAiTrainingPageState();
}

class _HipBridgeAiTrainingPageState extends State<HipBridgeAiTrainingPage>
    with WidgetsBindingObserver {
  // ---------------- 相机 ----------------
  CameraController? _camera;
  bool _cameraReady = false;
  String? _cameraError;
  static const Duration _cameraTimeout = Duration(seconds: 10);

  // ---------------- 识别服务 ----------------
  WebSocket? _ws;
  bool _wsConnected = false;
  bool _sending = false;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  final int _sendIntervalMs = 80;
  int _framesSent = 0;
  int _framesRecv = 0;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  /// AI 不可用 -> 降级基础训练模式（手动计数）
  bool get _degraded => !_wsConnected;
  int _manualReps = 0;

  // ---------------- 识别结果 ----------------
  List<List<double>>? _lm;
  double? _hipAngle;
  int _reps = 0;
  String _tip = '准备开始';
  Map<String, dynamic> _live = const {};
  String _view = 'unknown';
  bool _angleApplicable = true;
  bool _symApplicable = true;

  // ---------------- 流程 ----------------
  bool _showBrief = true;          // 开始前的机位提示
  bool _finished = false;
  Timer? _ticker;
  int _elapsed = 0;

  // 校准：0原样 1左右翻转 2上下翻转 3旋转180
  int _calib = 1;
  static const List<String> _calibNames = ['原样', '左右翻转', '上下翻转', '旋转180°'];

  /// summary 请求用（避免对同一 Stream 二次 listen）
  Completer<Map<String, dynamic>?>? _summaryCompleter;

  int get _displayReps => _degraded ? _manualReps : _reps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));
    unawaited(_loadCalib());
  }

  Future<void> _loadCalib() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getInt(_kCalibKey);
      if (v != null && mounted) setState(() => _calib = v % 4);
    } catch (_) {}
  }

  Future<void> _saveCalib(int v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kCalibKey, v);
    } catch (_) {}
  }

  Future<void> _start() async {
    setState(() => _showBrief = false);
    await _initCamera();
    await _connectWs();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finished) return;
      setState(() => _elapsed++);
    });
  }

  // ================= 相机 =================
  Future<void> _initCamera() async {
    if (_finished) return;
    try {
      final cams = await availableCameras().timeout(_cameraTimeout);
      if (cams.isEmpty) throw StateError('未检测到可用相机');
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      // 不要显式指定 imageFormatGroup：模拟器虚拟相机最多 3 路 surface
      final c = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await c.initialize().timeout(_cameraTimeout);
      if (!mounted || _finished) {
        await c.dispose();
        return;
      }
      await c.startImageStream(_onFrame);
      setState(() {
        _camera = c;
        _cameraReady = true;
        _cameraError = null;
      });
      AppLogger.i('臀桥AI训练', '相机就绪 ${c.value.previewSize}');
    } catch (e, st) {
      AppLogger.e('臀桥AI训练', e, st);
      if (mounted) setState(() => _cameraError = '$e');
    }
  }

  // ================= WebSocket =================
  Future<void> _connectWs() async {
    if (_finished) return;
    try {
      await _ws?.close();
    } catch (_) {}
    _ws = null;
    try {
      final ws = await WebSocket.connect(kPoseWsUrl).timeout(const Duration(seconds: 6));
      ws.listen(_onWsMessage, onError: (e) => _onWsDown('$e'), onDone: () => _onWsDown('closed'));
      _ws = ws;
      ws.add(jsonEncode({'cmd': 'mode', 'value': 'glute_bridge'}));
      ws.add(jsonEncode({'cmd': 'reset'}));
      _reconnectAttempts = 0;
      if (mounted) setState(() => _wsConnected = true);
      AppLogger.i('臀桥AI训练', '识别服务已连接 $kPoseWsUrl');
    } catch (e) {
      AppLogger.w('臀桥AI训练', '识别服务连接失败，进入基础训练模式: $e');
      if (mounted) setState(() => _wsConnected = false);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_finished) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delay = Duration(seconds: (2 * _reconnectAttempts).clamp(2, 15));
    _reconnectTimer = Timer(delay, () { if (!_finished && !_wsConnected) unawaited(_connectWs()); });
  }

  void _onWsDown(String reason) {
    AppLogger.w('臀桥AI训练', '识别服务断开: $reason');
    if (!mounted) return;
    setState(() => _wsConnected = false);
    _scheduleReconnect();
  }

  void _onWsMessage(dynamic raw) {
    _sending = false;
    _framesRecv++;
    if (!mounted || _finished) return;
    if (raw is! String) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      // summary 响应优先交给等待者
      final c = _summaryCompleter;
      if (c != null && !c.isCompleted && m['reps'] != null && m['hip_angle'] == null) {
        c.complete(m);
        return;
      }
      // 模式/重置 ACK
      if (m['hip_angle'] == null && m['reps'] == null) return;

      if (m['ok'] != true) {
        setState(() => _tip = (m['tip'] as String?) ?? '请进入画面');
        return;
      }
      final lmRaw = m['lm'];
      setState(() {
        if (lmRaw is List) {
          _lm = lmRaw.whereType<List>()
              .map((e) => e.map((v) => (v as num).toDouble()).toList()).toList();
        }
        _hipAngle = (m['hip_angle'] as num?)?.toDouble();
        _reps = (m['reps'] as num?)?.toInt() ?? _reps;
        _tip = (m['tip'] as String?) ?? _tip;
        _view = (m['view'] as String?) ?? _view;
        _angleApplicable = (m['angle_applicable'] as bool?) ?? true;
        _symApplicable = (m['sym_applicable'] as bool?) ?? true;
        final lv = m['live'];
        if (lv is Map) _live = lv.cast<String, dynamic>();
      });
      if (widget.targetReps > 0 && _reps >= widget.targetReps) unawaited(_finish());
    } catch (e, st) {
      AppLogger.e('臀桥AI训练', e, st);
    }
  }

  // ================= 抽帧 =================
  void _onFrame(CameraImage img) {
    if (!mounted || _finished || _showBrief) return;
    if (_sending) return;
    final now = DateTime.now();
    if (now.difference(_lastSent).inMilliseconds < _sendIntervalMs) return;
    final ws = _ws;
    if (ws == null || !_wsConnected) return;
    _sending = true;
    _lastSent = now;
    try {
      ws.add(_packY(img));
      _framesSent++;
    } catch (_) {
      _sending = false;
    }
  }

  Uint8List _packY(CameraImage img) {
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

  // ================= 结束 =================
  Future<void> _finish() async {
    if (_finished) return;
    setState(() => _finished = true);
    _ticker?.cancel();
    _reconnectTimer?.cancel();
    try { await _camera?.stopImageStream(); } catch (_) {}

    Map<String, dynamic> summary = {
      'reps': _displayReps,
      'form': 0, 'symmetry': null, 'sym_applicable': false,
      'stability': 0, 'tempo': 0, 'trail': 0, 'overall': 0,
      'degraded': _degraded,
      'view': _view,
    };
    if (!_degraded) {
      try {
        final ws = _ws;
        if (ws != null) {
          final c = Completer<Map<String, dynamic>?>();
          _summaryCompleter = c;
          ws.add(jsonEncode({'cmd': 'summary'}));
          final m = await c.future.timeout(const Duration(seconds: 4));
          if (m != null && m['ok'] == true) summary = m;
        }
      } catch (e, st) {
        AppLogger.e('臀桥AI训练', e, st);
      } finally {
        _summaryCompleter = null;
      }
    }
    // 释放资源，避免残留占用
    await _teardown();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => HipBridgeAiResultPage(
        levelName: widget.levelName,
        targetReps: widget.targetReps,
        summary: summary,
        elapsedSeconds: _elapsed,
      ),
    ));
  }

  /// 统一释放相机与 WebSocket
  Future<void> _teardown() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    try { await _ws?.close(); } catch (_) {}
    _ws = null;
    _wsConnected = false;
    try { await _camera?.dispose(); } catch (_) {}
    _camera = null;
    _cameraReady = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      // 切后台：释放相机，避免与其它 App 抢摄像头
      if (_camera != null) {
        unawaited(_teardownCameraOnly());
      }
    } else if (state == AppLifecycleState.resumed && !_finished && !_showBrief && _camera == null) {
      unawaited(_initCamera());
    }
  }

  Future<void> _teardownCameraOnly() async {
    final c = _camera;
    _camera = null;
    _cameraReady = false;
    if (mounted) setState(() {});
    try { await c?.dispose(); } catch (_) {}
  }

  @override
  void dispose() {
    _finished = true;
    _ticker?.cancel();
    _reconnectTimer?.cancel();
    try { _ws?.close(); } catch (_) {}
    try { _camera?.dispose(); } catch (_) {}
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave();
        if (!leave || !mounted) return;
        await _teardown();
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: _showBrief ? _buildBrief() : _buildBody()),
      ),
    );
  }

  Future<bool> _confirmLeave() async {
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('结束训练？'),
        content: const Text('当前进度不会保存。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('继续训练')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('退出')),
        ],
      ),
    );
    return r ?? false;
  }

  /// 开始前的机位提示（第七项要求）
  Widget _buildBrief() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF12161C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF00E4A7).withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.videocam, color: Color(0xFF00E4A7)),
              const SizedBox(width: 8),
              Text(widget.levelName,
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 14),
            const Text('请把手机放在身体侧面（侧位拍摄），并确保全身进入画面。',
                style: TextStyle(color: Color(0xFFFFC107), fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            const Text('为什么要侧位？\n· 髋角（肩-髋-膝）只有在侧位才成立\n· 正面拍摄会被透视压缩，角度不准',
                style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.7)),
            const SizedBox(height: 12),
            Row(children: [
              _briefChip('目标 ${widget.targetReps} 次'),
              const SizedBox(width: 8),
              _briefChip('AI 动作分析'),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: _start,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00E4A7),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('已放好，开始训练'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _briefChip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF00E4A7).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(t, style: const TextStyle(color: Color(0xFF00E4A7), fontSize: 12)),
      );

  Widget _buildBody() {
    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 56),
            const SizedBox(height: 14),
            Text('相机不可用\n$_cameraError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () { setState(() => _cameraError = null); unawaited(_initCamera()); },
              child: const Text('重试'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _finish, child: const Text('跳过，直接结束')),
          ]),
        ),
      );
    }
    final cam = _camera;
    if (!_cameraReady || cam == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return Row(children: [
      Expanded(
        flex: 7,
        child: Center(
          child: AspectRatio(
            aspectRatio: cam.value.aspectRatio,
            child: Stack(fit: StackFit.expand, children: [
              MirroredCameraPreview(controller: cam, mirror: _calib == 1 || _calib == 3),
              CustomPaint(painter: _SkeletonPainter(_lm, calib: _calib)),
              if (!_degraded && !_angleApplicable)
                Positioned(
                  left: 0, right: 0, top: 0,
                  child: Container(
                    color: const Color(0xCCFF6B6B),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    child: const Text('当前机位不适合臀桥髋角分析，请把手机移到身体侧面',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              Positioned(
                top: 6, right: 6,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: Text('骨骼校准：${_calibNames[_calib]}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ),
                  IconButton(
                    tooltip: '切换骨骼叠加方向',
                    icon: const Icon(Icons.flip, color: Colors.white70, size: 20),
                    onPressed: () {
                      final v = (_calib + 1) % 4;
                      setState(() => _calib = v);
                      unawaited(_saveCalib(v));
                    },
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
      Expanded(flex: 3, child: _buildHud()),
    ]);
  }

  Widget _buildHud() {
    String f(Object? v) => v == null ? '不适用' : (v as num).toStringAsFixed(0);
    final viewName = {'side': '侧位', 'front': '正面', 'oblique': '斜位'}[_view] ?? '识别中';
    return Container(
      color: const Color(0xFF0E1116),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: _degraded ? Colors.orangeAccent : const Color(0xFF00E4A7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(_degraded ? 'AI分析不可用 · 基础训练模式' : 'AI动作分析 · 已连接',
                style: TextStyle(color: _degraded ? Colors.orangeAccent : const Color(0xFF00E4A7), fontSize: 12)),
          ),
          Text('机位 $viewName', style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _big('髋角', _degraded ? '--' : (_hipAngle == null ? '--' : '${_hipAngle!.toStringAsFixed(0)}°')),
          _big('次数', '$_displayReps/${widget.targetReps}'),
        ]),
        const SizedBox(height: 10),
        _score('动作完成度', _degraded ? '--' : f(_live['form'])),
        _score('左右对称性', _degraded ? '--' : (_symApplicable ? f(_live['symmetry']) : '不适用')),
        _score('轨迹/幅度', _degraded ? '--' : f(_live['trail'])),
        _score('节奏', _degraded ? '--' : f(_live['tempo'])),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF17202A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00E4A7).withValues(alpha: 0.35)),
          ),
          child: Text('提示：${_degraded ? "请按标准动作完成，完成后点右侧计数" : _tip}',
              style: const TextStyle(color: Color(0xFF00E4A7), fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        // 降级模式才显示手动计数
        if (_degraded)
          Row(children: [
            Expanded(
              child: FilledButton(
                onPressed: () => setState(() => _manualReps++),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0396FF)),
                child: const Text('完成一次 +1'),
              ),
            ),
          ]),
        if (_degraded) const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: _finish, child: const Text('结束训练'))),
        ]),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('已训练 ${_elapsed}s · 发$_framesSent帧/收$_framesRecv帧 · 仅供参考，非医学诊断',
              style: const TextStyle(color: Colors.white24, fontSize: 10)),
        ),
      ]),
    );
  }

  Widget _big(String k, String v) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _score(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(k, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const Spacer(),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
      );
}

// ======================= 骨骼绘制 =======================
class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter(this.lm, {required this.calib});
  final List<List<double>>? lm;
  final int calib;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = lm;
    if (pts == null || pts.length < 33) return;
    Offset at(int i) {
      final p = pts[i];
      double x = p[0], y = p[1];
      switch (calib) {
        case 1: x = 1.0 - x; break;
        case 2: y = 1.0 - y; break;
        case 3: x = 1.0 - x; y = 1.0 - y; break;
      }
      return Offset(x * size.width, y * size.height);
    }

    final line = Paint()
      ..color = const Color(0xFF00E4A7).withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = Colors.white;

    for (final c in kPoseConnections) {
      final a = pts[c[0]], b = pts[c[1]];
      if (a.length < 3 || b.length < 3) continue;
      if (a[2] < 0.3 || b[2] < 0.3) continue;
      canvas.drawLine(at(c[0]), at(c[1]), line);
    }
    for (int i = 0; i < 33; i++) {
      if (pts[i].length < 3 || pts[i][2] < 0.3) continue;
      canvas.drawCircle(at(i), 3.5, dot);
    }
    // 髋部参考点（臀桥关键点）
    for (final i in [23, 24]) {
      if (pts[i][2] < 0.3) continue;
      canvas.drawCircle(at(i), 7, Paint()..color = const Color(0xFFFFC107));
    }
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter old) => old.lm != lm || old.calib != calib;
}