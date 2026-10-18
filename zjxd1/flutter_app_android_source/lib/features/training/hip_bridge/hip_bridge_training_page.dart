import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/app_config.dart';
import '../../../utils/app_logger.dart';
import '../../mine/motion_api_client.dart';
import '../../../utils/user_scope.dart';
import 'hip_bridge_training_session_page.dart';
import 'hip_bridge_ai_training_page.dart';
import 'hip_bridge_training_result_page.dart';

class HipBridgeTrainingPage extends StatefulWidget {
  const HipBridgeTrainingPage({super.key});

  @override
  State<HipBridgeTrainingPage> createState() => _HipBridgeTrainingPageState();
}

class _HipBridgeTrainingPageState extends State<HipBridgeTrainingPage> with SingleTickerProviderStateMixin {
  static const String _hasResultKey = 'hip_bridge_has_result';
  static const String _resultDataKey = 'hip_bridge_result_data';

  int todaySkips = 3;
  int weekSkips = 12;
  int totalSkips = 48;

  int currentMode = 0;

  String selectedTime = '01:00';
  final List<String> timeOptions = const ['30s', '45s', '01:00', '01:30', '02:00', '03:00'];

  int selectedCount = 100;
  final List<int> countOptions = const [50, 100, 150, 200, 300, 500];

  late final AnimationController _controller;

  // Training result state
  bool _hasSavedResult = false;
  Map<String, dynamic>? _savedResultData;

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  final List<_LeaderboardUser> leaderboard = const [
    _LeaderboardUser(name: '小丽', skips: 185, avatarAsset: 'assets/images/user-avatar-1.jpg', isMe: false),
    _LeaderboardUser(name: '小明', skips: 172, avatarAsset: 'assets/images/user-avatar-2.jpg', isMe: false),
    _LeaderboardUser(name: '小美', skips: 168, avatarAsset: 'assets/images/user-avatar-3.png', isMe: false),
    _LeaderboardUser(name: '我', skips: 156, avatarAsset: 'assets/images/user-avatar-4.jpg', isMe: true),
    _LeaderboardUser(name: '小强', skips: 142, avatarAsset: 'assets/images/user-avatar-5.jpg', isMe: false),
    _LeaderboardUser(name: '小红', skips: 138, avatarAsset: 'assets/images/user-avatar-1.jpg', isMe: false),
    _LeaderboardUser(name: '小华', skips: 125, avatarAsset: 'assets/images/user-avatar-2.jpg', isMe: false),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    _loadState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchMode(int index) {
    if (index == currentMode) return;
    setState(() {
      currentMode = index;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('切换到${index == 0 ? '定时' : '定数'}模式')),
    );
  }

  void _startTraining() async {
    final targetText = currentMode == 0 ? selectedTime : '${selectedCount}次';
    final seconds = currentMode == 0 ? _parseTimeToSeconds(selectedTime) : 30 * 60;

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => HipBridgeTrainingSessionPage(
          pageTitle: '臀桥训练',
          exerciseSeconds: seconds,
          isCountMode: currentMode == 1,
          targetCount: currentMode == 1 ? selectedCount : 0,
        ),
      ),
    );

    if (result != null && mounted) {
      // Save the training result
      await _saveState(result);
      setState(() {
        _hasSavedResult = true;
        _savedResultData = result;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('准备开始训练！目标: $targetText')),
    );
  }

  /// 启动「AI 动作分析训练」：摄像头 + 实时骨骼识别 + 规则评分
  void _startAiTraining() {
    final targetReps = currentMode == 1 ? selectedCount : 10;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HipBridgeAiTrainingPage(
          targetReps: targetReps,
          levelName: '臀桥训练',
        ),
      ),
    );
  }

  int _parseTimeToSeconds(String val) {
    final s = val.trim();
    if (s.isEmpty) return 60;

    if (s.contains(':')) {
      final parts = s.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final sec = int.tryParse(parts[1]) ?? 0;
        return (m * 60) + sec;
      }
    }

    final digits = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));
    return digits ?? 60;
  }

  Future<void> _loadState() async {
    // 历史记录已持久化存储到数据库（motion_records 表，每次训练完成都会上报一条）。
    // 页面只显示最新的一次：优先从数据库拉取最新记录，数据库不可用时回退本地 SharedPreferences。
    Map<String, dynamic>? localData;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasResult = prefs.getBool(_hasResultKey) ?? false;
      final resultJson = prefs.getString(_resultDataKey);
      if (hasResult && resultJson != null && resultJson.isNotEmpty) {
        localData = _parseResultData(resultJson);
      }
    } catch (e, st) {
      AppLogger.e('HipBridge入口', e, st);
    }

    try {
      final records = await MotionApiClient()
          .listRecords(username: UserScope.username)
          .timeout(const Duration(seconds: 5));
      MotionRecord? latest;
      for (final r in records) {
        if (r.motionName == '臀桥训练') {
          latest = r;
          break; // 后端按时间倒序返回，第一条即最新一次
        }
      }

      if (latest != null && mounted) {
        setState(() {
          _hasSavedResult = true;
          _savedResultData = {
            'title': latest!.motionName,
            'actualCount': latest.actualCount,
            'targetCount': latest.targetCount,
            'actualTimeSeconds': latest.actualTimeSeconds,
            'isCountMode': latest.isCountMode,
            // 历史回放统一回显上传到服务器上的最新训练视频（后端 /api/video/get 经 SFTP 拉取远程视频）
            'videoPath': '$kApiBaseUrl/api/video/get',
          };
        });
        print('Hip Bridge Training: Loaded latest record from database');
        return;
      }
    } catch (e) {
      print('Hip Bridge Training: Load latest record from database failed - $e');
    }

    // 数据库无记录或不可用时，回退到本地 SharedPreferences
    if (localData != null && mounted) {
      setState(() {
        _hasSavedResult = true;
        _savedResultData = localData;
      });
      print('Hip Bridge Training: Loaded saved result from local');
    } else if (mounted) {
      setState(() {
        _hasSavedResult = false;
        _savedResultData = null;
      });
      print('Hip Bridge Training: No saved result found');
    }
  }

  Future<void> _saveState(Map<String, dynamic> resultData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasResultKey, true);
      await prefs.setString(_resultDataKey, _serializeResultData(resultData));
      print('Hip Bridge Training: Result saved successfully');
    } catch (e) {
      print('Hip Bridge Training: Error saving state - $e');
    }
  }

  Future<void> _clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasResultKey);
      await prefs.remove(_resultDataKey);
      print('Hip Bridge Training: State cleared');
    } catch (e) {
      print('Hip Bridge Training: Error clearing state - $e');
    }
  }

  String _serializeResultData(Map<String, dynamic> data) {
    return '''
{
  "title": "${data['title']}",
  "actualCount": ${data['actualCount']},
  "targetCount": ${data['targetCount']},
  "actualTimeSeconds": ${data['actualTimeSeconds']},
  "isCountMode": ${data['isCountMode']},
  "videoPath": "${data['videoPath'] ?? ''}"
}''';
  }

  Map<String, dynamic>? _parseResultData(String json) {
    try {
      // Simple JSON parsing for our specific structure
      final titleMatch = RegExp(r'"title":\s*"([^"]+)"').firstMatch(json);
      final actualCountMatch = RegExp(r'"actualCount":\s*(\d+)').firstMatch(json);
      final targetCountMatch = RegExp(r'"targetCount":\s*(\d+)').firstMatch(json);
      final actualTimeMatch = RegExp(r'"actualTimeSeconds":\s*(\d+)').firstMatch(json);
      final isCountModeMatch = RegExp(r'"isCountMode":\s*(true|false)').firstMatch(json);
      final videoPathMatch = RegExp(r'"videoPath":\s*"([^"]*)"').firstMatch(json);

      if (titleMatch != null && actualCountMatch != null) {
        return {
          'title': titleMatch.group(1) ?? '臀桥训练',
          'actualCount': int.tryParse(actualCountMatch.group(1) ?? '0') ?? 0,
          'targetCount': int.tryParse(targetCountMatch?.group(1) ?? '0') ?? 0,
          'actualTimeSeconds': int.tryParse(actualTimeMatch?.group(1) ?? '0') ?? 0,
          'isCountMode': isCountModeMatch?.group(1) == 'true',
          'videoPath': videoPathMatch?.group(1),
        };
      }
    } catch (e) {
      print('Hip Bridge Training: Error parsing result data - $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _TopSection(controller: _controller, today: todaySkips, week: weekSkips, total: totalSkips),
                    const SizedBox(height: 16),
                    _HistorySection(
                      hasResult: _hasSavedResult,
                      resultData: _savedResultData,
                      onViewResult: () => _viewLastResult(),
                      onClear: _clearState,
                    ),
                    const SizedBox(height: 16),
                    _ControlSection(
                      currentMode: currentMode,
                      onSwitchMode: _switchMode,
                      selectedTime: selectedTime,
                      timeOptions: timeOptions,
                      onSelectTime: (v) => setState(() => selectedTime = v),
                      selectedCount: selectedCount,
                      countOptions: countOptions,
                      onSelectCount: (v) => setState(() => selectedCount = v),
                      onStart: _startTraining,
                      onClearResult: _clearAndStartNew,
                    ),
                    const SizedBox(height: 12),
                    _StartButton(
                      onTap: _startAiTraining,
                      label: 'AI 动作分析训练',
                    ),
                    const SizedBox(height: 16),
                    _LeaderboardSection(leaderboard: leaderboard),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _BackFab(onTap: () => Navigator.of(context).pop()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewLastResult() {
    if (_savedResultData == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HipBridgeTrainingResultPage(
          title: _savedResultData!['title'] ?? '臀桥训练',
          actualCount: _savedResultData!['actualCount'] ?? 0,
          targetCount: _savedResultData!['targetCount'] ?? 0,
          actualTimeSeconds: _savedResultData!['actualTimeSeconds'] ?? 0,
          isCountMode: _savedResultData!['isCountMode'] ?? false,
          videoPath: _savedResultData!['videoPath'],
        ),
      ),
    );
  }

  Future<void> _clearAndStartNew() async {
    await _clearState();
    setState(() {
      _hasSavedResult = false;
      _savedResultData = null;
    });
    _startTraining();
  }
}

class _TopSection extends StatelessWidget {
  const _TopSection({
    required this.controller,
    required this.today,
    required this.week,
    required this.total,
  });

  final Animation<double> controller;
  final int today;
  final int week;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          _CharacterArea(controller: controller),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard(number: '$today', label: '今日训练')),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(number: '$week', label: '本周训练')),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(number: '$total', label: '累计训练')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CharacterArea extends StatelessWidget {
  const _CharacterArea({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final side = math.min(size.width - 64, 240.0);

    return Center(
      child: SizedBox(
        width: side * 2, 
        height: side * 2, 
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final t = controller.value;
            final bounce = 1.0 + (math.sin(t * math.pi * 2) * 0.035);

            return Stack(
              children: [
                Center(
                  child: Transform.scale(
                    scale: bounce,
                    child: Image.asset(
                      'assets/images/hip-bridge-girl-illustration.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, size: 120, color: Colors.white), // 从96放大到120 (25%增长)
                    ),
                  ),
                ),
                _Star(
                  controller: controller,
                  emoji: '⭐',
                  base: const Offset(0.12, 0.22),
                  delay: 0.0,
                  area: side * 2,
                ),
                _Star(
                  controller: controller,
                  emoji: '✨',
                  base: const Offset(0.78, 0.28),
                  delay: 0.33,
                  area: side * 2,
                ),
                _Star(
                  controller: controller,
                  emoji: '💫',
                  base: const Offset(0.20, 0.78),
                  delay: 0.66,
                  area: side * 2,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.controller,
    required this.emoji,
    required this.base,
    required this.delay,
    required this.area,
  });

  final Animation<double> controller;
  final String emoji;
  final Offset base;
  final double delay;
  final double area;

  @override
  Widget build(BuildContext context) {
    // 注意：Positioned 与外层 Stack 之间不允许夹 RenderObjectWidget（如 LayoutBuilder），
    // 否则会抛 "Incorrect use of ParentDataWidget"。这里改为由父级直接传入区域尺寸 area。
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = (controller.value + delay) % 1.0;
        final dy = math.sin(t * math.pi * 2) * -10;
        final opacity = 0.6 + (math.sin(t * math.pi * 2) * 0.35);
        final angle = t * math.pi;
        return Positioned(
          left: area * base.dx,
          top: area * base.dy,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(
                angle: angle,
                child: Text(emoji, style: const TextStyle(fontSize: 25)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFB6C1).withValues(alpha: 0.30), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9A9E).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFFE91E63)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }
}

class _ControlSection extends StatelessWidget {
  const _ControlSection({
    required this.currentMode,
    required this.onSwitchMode,
    required this.selectedTime,
    required this.timeOptions,
    required this.onSelectTime,
    required this.selectedCount,
    required this.countOptions,
    required this.onSelectCount,
    required this.onStart,
    this.onClearResult,
  });

  final int currentMode;
  final ValueChanged<int> onSwitchMode;

  final String selectedTime;
  final List<String> timeOptions;
  final ValueChanged<String> onSelectTime;

  final int selectedCount;
  final List<int> countOptions;
  final ValueChanged<int> onSelectCount;

  final VoidCallback onStart;
  final VoidCallback? onClearResult;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFB6C1).withValues(alpha: 0.30), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9A9E).withValues(alpha: 0.20),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              _ModeTabs(current: currentMode, onChanged: onSwitchMode),
              const SizedBox(height: 16),
              Text(
                currentMode == 0 ? '选择时长' : '目标次数',
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFF4A5568)),
              ),
              const SizedBox(height: 14),
              _OptionGrid(
                items: currentMode == 0 ? timeOptions : countOptions.map((e) => e.toString()).toList(growable: false),
                selected: currentMode == 0 ? selectedTime : selectedCount.toString(),
                onSelected: (v) {
                  if (currentMode == 0) {
                    onSelectTime(v);
                  } else {
                    onSelectCount(int.tryParse(v) ?? selectedCount);
                  }
                },
              ),
              const SizedBox(height: 16),
              _StartButton(onTap: onStart),
              if (onClearResult != null) ...[
                const SizedBox(height: 12),
                _ClearButton(onTap: onClearResult!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.current, required this.onChanged});

  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              text: '定时',
              active: current == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeTab(
              text: '定数',
              active: current == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({required this.text, required this.active, required this.onTap});

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: active
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4)],
              )
            : null,
        color: active ? null : Colors.transparent,
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFFFF9A9E).withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 21,
              fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              color: active ? Colors.white : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({required this.items, required this.selected, required this.onSelected});

  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final v = items[index];
        final isSelected = v == selected;
        return InkWell(
          onTap: () => onSelected(v),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected ? null : const Color(0xFFF8F9FA),
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
                    )
                  : null,
              border: Border.all(
                color: isSelected ? const Color(0xFF4FC3F7) : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4FC3F7).withValues(alpha: 0.30),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      )
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              v,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF4A5568)),
            ),
          ),
        );
      },
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap, this.label});
  final String? label;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF9A9E), Color(0xFFF093FB)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9A9E).withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label ?? '开始训练',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Image.asset(
              'assets/images/spine.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(width: 26, height: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.refresh, size: 18, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            const Text(
              '清除记录，重新开始',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.hasResult,
    required this.resultData,
    required this.onViewResult,
    required this.onClear,
  });

  final bool hasResult;
  final Map<String, dynamic>? resultData;
  final VoidCallback onViewResult;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (!hasResult || resultData == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 32, color: Color(0xFFCBD5E1)),
                SizedBox(height: 8),
                Text(
                  '暂无训练记录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
                SizedBox(height: 4),
                Text(
                  '完成训练后将显示历史记录',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final actualCount = resultData!['actualCount'] ?? 0;
    final targetCount = resultData!['targetCount'] ?? 0;
    final actualTimeSeconds = resultData!['actualTimeSeconds'] ?? 0;
    final isCountMode = resultData!['isCountMode'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF805AD5), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF805AD5).withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF805AD5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                  '上次训练结果',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                ),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Text(
                      '清除',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
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
                  child: _ResultMetric(
                    label: '目标达成',
                    value: '${((actualCount / targetCount) * 100).toInt()}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onViewResult,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF805AD5), Color(0xFF9F7AEA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '查看详细结果',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}

class _ViewLastResultButton extends StatelessWidget {
  const _ViewLastResultButton({
    required this.actualCount,
    required this.targetCount,
    required this.actualTimeSeconds,
    required this.isCountMode,
    required this.videoPath,
    required this.onTap,
  });

  final int actualCount;
  final int targetCount;
  final int actualTimeSeconds;
  final bool isCountMode;
  final String? videoPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFF805AD5), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF805AD5).withValues(alpha: 0.20),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history, size: 20, color: Color(0xFF805AD5)),
              const SizedBox(width: 10),
              const Text(
                '查看上次训练结果',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF805AD5)),
              ),
              const SizedBox(width: 8),
              Text(
                isCountMode ? '$actualCount次' : '${actualTimeSeconds ~/ 60}:${(actualTimeSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardSection extends StatelessWidget {
  const _LeaderboardSection({required this.leaderboard});

  final List<_LeaderboardUser> leaderboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFB6C1).withValues(alpha: 0.30), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9A9E).withValues(alpha: 0.20),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('🏆 臀桥周榜', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFF4A5568))),
              const SizedBox(height: 6),
              const Text('本周排行榜', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: Color(0xFF718096))),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: leaderboard.length,
                  itemBuilder: (context, index) {
                    final user = leaderboard[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LeaderboardItem(rank: index + 1, user: user),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  const _LeaderboardItem({required this.rank, required this.user});

  final int rank;
  final _LeaderboardUser user;

  String? get _medalAsset {
    if (rank == 1) return 'assets/images/gold-trophy.png';
    if (rank == 2) return 'assets/images/silver-trophy.png';
    if (rank == 3) return 'assets/images/bronze-trophy.png';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final highlight = user.isMe;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight ? const Color(0xFFFDcb6E) : Colors.transparent, width: 1.5),
        gradient: highlight
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFEAA7), Color(0xFFFAB1A0)],
              )
            : null,
        color: highlight ? null : const Color(0xFFF8F9FA),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text('$rank', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF4A5568))),
                if (_medalAsset != null)
                  Positioned(
                    right: -2,
                    top: -4,
                    child: Image.asset(
                      _medalAsset!,
                      width: 26,
                      height: 26,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              user.avatarAsset,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB), child: SizedBox(width: 40, height: 40)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF4A5568))),
                const SizedBox(height: 2),
                Text('${user.skips} 次', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: Color(0xFF718096))),
              ],
            ),
          ),
          if (highlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4)]),
              ),
              child: const Text('我', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

class _BackFab extends StatelessWidget {
  const _BackFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.92),
            border: Border.all(color: const Color(0xFFFFB6C1).withValues(alpha: 0.30), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          alignment: Alignment.center,
          child: const Text('←', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFF4A5568))),
        ),
      ),
    );
  }
}

class _LeaderboardUser {
  const _LeaderboardUser({required this.name, required this.skips, required this.avatarAsset, required this.isMe});

  final String name;
  final int skips;
  final String avatarAsset;
  final bool isMe;
}
