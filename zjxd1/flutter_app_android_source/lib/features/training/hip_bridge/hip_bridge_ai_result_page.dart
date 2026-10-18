// ============================================================================
//  臀桥 AI 训练 · 结果页
//  展示：完成次数 + 四项评分 + 综合成绩 + 经验/徽章 + 是否解锁下一关
//  说明：评分为康复训练辅助的动作质量分析，非医学诊断。
// ============================================================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HipBridgeAiResultPage extends StatefulWidget {
  const HipBridgeAiResultPage({
    super.key,
    required this.levelName,
    required this.targetReps,
    required this.summary,
    required this.elapsedSeconds,
  });

  final String levelName;
  final int targetReps;
  final Map<String, dynamic> summary;
  final int elapsedSeconds;

  @override
  State<HipBridgeAiResultPage> createState() => _HipBridgeAiResultPageState();
}

class _HipBridgeAiResultPageState extends State<HipBridgeAiResultPage> {
  bool _saved = false;

  double _n(String k) => (widget.summary[k] as num?)?.toDouble() ?? 0;
  int get _reps => (widget.summary['reps'] as num?)?.toInt() ?? 0;
  double get _overall => _n('overall');

  /// 经验：综合分 + 完成次数共同决定
  int get _exp => (_overall * 1.5 + _reps * 5).round();

  /// 徽章：综合分达标
  String? get _badge {
    if (_overall >= 90) return '动作之星';
    if (_overall >= 80) return '稳定达人';
    if (_overall >= 70) return '坚持新星';
    return null;
  }

  /// 过关：次数达标 且 综合分达标
  bool get _passed => _reps >= widget.targetReps && _overall >= 70;

  String get _grade {
    if (_overall >= 90) return '优秀';
    if (_overall >= 80) return '良好';
    if (_overall >= 70) return '合格';
    if (_overall > 0) return '待加强';
    return '未完成';
  }

  @override
  void initState() {
    super.initState();
    _persist();
  }

  Future<void> _persist() async {
    if (_saved) return;
    _saved = true;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('hip_bridge_ai_last_exp', _exp);
      await p.setInt('hip_bridge_ai_last_overall', _overall.round());
      await p.setInt('hip_bridge_ai_last_reps', _reps);
      await p.setBool('hip_bridge_ai_last_passed', _passed);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D12),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _hero(),
                    const SizedBox(height: 14),
                    _scoreGrid(),
                    const SizedBox(height: 14),
                    _rewardCard(),
                    const SizedBox(height: 14),
                    _unlockCard(),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '本成绩为康复训练辅助的动作质量分析，不作为医学诊断依据',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('返回首页'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00E4A7),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_passed ? '完成，返回' : '再来一次'),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00E4A7), Color(0xFF0396FF)],
        ),
      ),
      child: Row(children: [
        SizedBox(
          width: 96, height: 96,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 96, height: 96,
              child: CircularProgressIndicator(
                value: (_overall / 100).clamp(0, 1),
                strokeWidth: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_overall.toStringAsFixed(0),
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, height: 1.0)),
              const Text('综合分', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ]),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.levelName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('评级：$_grade', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('完成 $_reps / ${widget.targetReps} 次 · 用时 ${widget.elapsedSeconds}s',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
              child: Text(_passed ? '✅ 已达成过关条件' : '⬜ 未达过关条件',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _scoreGrid() {
    final items = [
      ('动作完成度', _n('form'), Icons.check_circle_outline),
      ('左右对称性', _n('symmetry'), Icons.compare_arrows),
      ('轨迹/幅度', _n('trail'), Icons.show_chart),
      ('节奏', _n('tempo'), Icons.timer_outlined),
      ('稳定性', _n('stability'), Icons.auto_graph),
      ('完成次数', _reps.toDouble(), Icons.repeat),
    ];
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: items.map((it) {
        final isCount = it.$1 == '完成次数';
        return Container(
          width: (MediaQuery.of(context).size.width - 48) / 3,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF151A21),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(children: [
            Icon(it.$3, color: const Color(0xFF00E4A7), size: 20),
            const SizedBox(height: 8),
            Text(isCount ? '${it.$2.toInt()}' : it.$2.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(it.$1, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _rewardCard() {
    return _card(
      title: '本次奖励',
      child: Row(children: [
        _chip(Icons.star, '经验 +$_exp', const Color(0xFFFFC107)),
        const SizedBox(width: 10),
        _chip(Icons.emoji_events, _badge ?? '暂无徽章', _badge == null ? Colors.white38 : const Color(0xFF00E4A7)),
      ]),
    );
  }

  Widget _unlockCard() {
    return _card(
      title: '关卡进度',
      child: Row(children: [
        Icon(_passed ? Icons.lock_open : Icons.lock_outline,
            color: _passed ? const Color(0xFF00E4A7) : Colors.white38, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _passed ? '已解锁下一关，继续加油！' : '再练一次，达到 $_reps→${widget.targetReps} 次且综合分 ≥70 即可解锁',
            style: TextStyle(color: _passed ? Colors.white : Colors.white60, fontSize: 13),
          ),
        ),
      ]),
    );
  }

  Widget _card({required String title, required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151A21),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _chip(IconData icon, String text, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      );
}