// 临时探针：单独用 video_player 播放数字人视频，打印播放器真实状态
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: DhProbe()));

class DhProbe extends StatefulWidget {
  const DhProbe({super.key});
  @override
  State<DhProbe> createState() => _DhProbeState();
}

class _DhProbeState extends State<DhProbe> {
  VideoPlayerController? _c;
  String _info = '初始化中...';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.asset(
        'assets/images/digital-human-coachr.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await c.initialize();
      await c.setVolume(1.0);
      await c.setLooping(true);
      await c.play();
      if (!mounted) return;
      setState(() => _c = c);
      final v = c.value;
      final s = 'isInit=${v.isInitialized}\n'
          'size=${v.size}\n'
          'duration=${v.duration}\n'
          'volume=${v.volume}\n'
          'isPlaying=${v.isPlaying}\n'
          'aspect=${v.aspectRatio}\n'
          'error=${v.errorDescription}';
      debugPrint('[DHPROBE] $s');
      setState(() => _info = s);
      // 每秒打一次，看播放进度是否推进（推进=在播）
      for (var i = 0; i < 8; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        final vv = c.value;
        debugPrint('[DHPROBE] t=$i pos=${vv.position} playing=${vv.isPlaying} vol=${vv.volume}');
      }
    } catch (e, st) {
      debugPrint('[DHPROBE] 异常: $e\n$st');
      if (mounted) setState(() => _info = '异常: $e');
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: Center(
              child: c == null
                  ? Text(_info, style: const TextStyle(color: Colors.white))
                  : AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFF111111),
            padding: const EdgeInsets.all(12),
            child: Text(_info, style: const TextStyle(color: Colors.cyan, fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}