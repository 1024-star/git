import 'package:flutter/material.dart';

import 'motion_api_client.dart';
import 'motion_records_page.dart';
import 'user_profile_page.dart';
import 'widgets/game_medal_badge.dart';
import '../auth/login_page.dart';
import '../report/report_history_page.dart';
import '../../utils/app_logger.dart';
import '../../utils/user_scope.dart';

/// 青少年向「我的」页字号与圆角
abstract final class _MineTeenStyle {
  static const double radiusLg = 22;
  static const double radiusMd = 18;

  static const double navTitle = 22;
  static const double userName = 26;
  static const double userMeta = 16;
  static const double userLevel = 15;
  static const double edit = 15;
  static const double statValue = 22;
  static const double statLabel = 13;
  static const double statTrend = 12;
  static const double sectionTitle = 20;
  static const double sectionIcon = 24;
  static const double body = 17;
  static const double bodySm = 15;
  static const double caption = 13;
  static const double badgeName = 15;

  static const headerGradient = [
    Color(0xFFFF8FB1),
    Color(0xFFB794F6),
    Color(0xFF60A5FA),
  ];

  static const pageBg = Color(0xFFF3F0FF);
  static const cardBorder = Color(0xFFE9D5FF);
}

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _ReportPreview extends StatelessWidget {
  const _ReportPreview({
    required this.scheme,
    required this.textPrimary,
    required this.textTertiary,
    required this.darkMode,
  });

  final ColorScheme scheme;
  final Color textPrimary;
  final Color textTertiary;
  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    final card = darkMode ? const Color(0xFF0B1220) : const Color(0xFFF0F9FF);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary.withValues(alpha: 0.2), const Color(0xFF93C5FD).withValues(alpha: 0.15)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.insights_rounded, color: scheme.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 最近一次检测报告',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textPrimary, fontSize: _MineTeenStyle.body, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  '看看哪里要加油、得分多少～',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textTertiary, fontSize: _MineTeenStyle.bodySm, fontWeight: FontWeight.w600, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '去看看',
              style: TextStyle(color: scheme.primary, fontSize: _MineTeenStyle.bodySm, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

/// 个性化档案预览卡（点击进入档案页）
class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({
    required this.scheme,
    required this.textPrimary,
    required this.textTertiary,
  });

  final ColorScheme scheme;
  final Color textPrimary;
  final Color textTertiary;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF7C6BF0);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.person_search_rounded, color: accent, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 智能分析 · 脊柱/体能/画像',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textPrimary, fontSize: _MineTeenStyle.body, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  '查看你的个性化康复档案与用户画像',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textTertiary, fontSize: _MineTeenStyle.bodySm, fontWeight: FontWeight.w600, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '去查看',
              style: TextStyle(color: accent, fontSize: _MineTeenStyle.bodySm, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinePageState extends State<MinePage> {
  bool _darkMode = false;

  String? name;
  String? avatar;

  @override
  void initState() {
    super.initState();
    // 为演示账号lzf生成固定的随机9位数用户名
    if (UserScope.isDemo && UserScope.username == 'lzf') {
      // 使用固定的种子生成随机数，确保每次都是相同的9位数
      final randomSeed = 'user_b_fixed_seed_2024';
      final hash = randomSeed.hashCode.abs();
      final random9Digits = (hash % 900000000 + 100000000).toString(); // 确保9位数
      name = '用户$random9Digits';
    } else if (UserScope.username == 'a') {
      // 为账号a生成固定的随机9位数用户名（参考 lzf 的生成方式）
      final randomSeed = 'user_a_fixed_seed_2024';
      final hash = randomSeed.hashCode.abs();
      final random9Digits = (hash % 900000000 + 100000000).toString(); // 确保9位数
      name = '用户$random9Digits';
    } else {
      name = '小明';
    }
    _loadRecentMotions();
  }

  Future<void> _loadRecentMotions() async {
    try {
      final username = (UserScope.username ?? '').trim();
      final list = await MotionApiClient().listRecords(username: username);
      if (!mounted) return;
      setState(() {
        _recentMotions = list.take(3).map((r) {
          final dt = DateTime.fromMillisecondsSinceEpoch(r.createdAtMs);
          final timeText = _motionTimeText(dt);
          final minutes = (r.actualTimeSeconds / 60).ceil();
          return _MotionItem(
            name: r.motionName.isEmpty ? '运动训练' : r.motionName,
            time: timeText,
            durationMinutes: minutes,
            type: _motionTypeOf(r.motionName),
          );
        }).toList(growable: false);
      });
    } catch (e, st) {
      AppLogger.e('个人中心', e, st);
    }
  }

  static String _motionTimeText(DateTime dt) {
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    String two(int v) => v.toString().padLeft(2, '0');
    if (sameDay) {
      return '今天 ${two(dt.hour)}:${two(dt.minute)}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
    if (isYesterday) {
      return '昨天 ${two(dt.hour)}:${two(dt.minute)}';
    }
    return '${dt.month}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  static _MotionType _motionTypeOf(String name) {
    final n = name;
    if (n.contains('臀桥') || n.contains('仰卧')) return _MotionType.jump;
    if (n.contains('俯卧')) return _MotionType.situp;
    return _MotionType.pullup;
  }

  int consecutiveDays = 1;
  int totalCheckInDays = 525;
  int userLevel = 3;
  double levelProgress = 65;

  final _challengeProgress = const _ChallengeProgress(completed: 2, total: 5, recent: 1);
  final int badgeCount = 3;
  final int totalBadges = 20;
  final int recentBadges = 1;

  final int totalWorkouts = 28;

  List<_MotionItem> _recentMotions = const [];

  final List<_BadgeItem> badges = const [
    _BadgeItem(name: '首战告捷', type: _BadgeType.trophy, unlocked: true),
    _BadgeItem(name: '七日连击', type: _BadgeType.fire, unlocked: true),
    _BadgeItem(name: '运动达人', type: _BadgeType.star, unlocked: true),
    _BadgeItem(name: '坚持不懈', type: _BadgeType.diamond, unlocked: false),
    _BadgeItem(name: '完美主义', type: _BadgeType.crown, unlocked: false),
    _BadgeItem(name: '超越极限', type: _BadgeType.rocket, unlocked: false),
  ];

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _toggleTheme() {
    setState(() {
      _darkMode = !_darkMode;
    });
  }

  Future<void> _openMotionRecords() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MotionRecordsPage(initialDarkMode: _darkMode),
      ),
    );

    if (!mounted) return;
    if (result is bool) {
      setState(() {
        _darkMode = result;
      });
    }
  }

  Future<void> _openDataReport() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const ReportHistoryPage(),
      ),
    );
  }

  /// 打开用户个性化档案页
  Future<void> _openUserProfile() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const UserProfilePage(),
      ),
    );
  }

  /// 退出登录：二次确认 → 清空本地登录态 → 回到登录页
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出当前账号吗？下次登录需要重新输入账号信息。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
              child: const Text('退出登录'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    UserScope.clear();
    // 清空导航栈并回到登录页（main.dart 中 home 为 LoginPage）
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  ColorScheme get _scheme {
    if (_darkMode) {
      return const ColorScheme.dark(
        primary: Color(0xFF667EEA),
        surface: Color(0xFF1C1C1E),
      );
    }
    return const ColorScheme.light(
      primary: Color(0xFF667EEA),
      surface: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bgTertiary = _darkMode ? const Color(0xFF0F172A) : _MineTeenStyle.pageBg;
    final cardBg = _darkMode ? const Color(0xFF111827) : Colors.white;
    final textPrimary = _darkMode ? Colors.white : const Color(0xFF1F2937);
    final textTertiary = _darkMode ? Colors.white70 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgTertiary,
      body: SizedBox(
        height: size.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _HeaderSection(
                      scheme: _scheme,
                      darkMode: _darkMode,
                      name: name,
                      avatar: avatar,
                      consecutiveDays: consecutiveDays,
                      totalCheckInDays: totalCheckInDays,
                      userLevel: userLevel,
                      levelProgress: levelProgress,
                      onToggleTheme: _toggleTheme,
                      onTapChat: () => _toast('聊天（占位）'),
                      onTapAvatar: () => _toast('头像（占位）'),
                      onTapLogin: () => _toast('去登录（占位）'),
                      onTapEdit: () => _toast('编辑资料（占位）'),
                      textPrimary: textPrimary,
                      textTertiary: textTertiary,
                    ),
                    Transform.translate(
                      offset: const Offset(0, -48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _StatsCardsRow(
                              scheme: _scheme,
                              cardBg: cardBg,
                              textPrimary: textPrimary,
                              textTertiary: textTertiary,
                              challengeProgress: _challengeProgress,
                              badgeCount: badgeCount,
                              recentBadges: recentBadges,
                              totalWorkouts: totalWorkouts,
                              onTapChallenge: () => _toast('闯关记录（占位）'),
                              onTapBadges: () => _toast('徽章（占位）'),
                              onTapMotions: _openMotionRecords,
                            ),
                            const SizedBox(height: 16),
                            _SectionBlock(
                              cardBg: cardBg,
                              title: '🏃 运动记录',
                              titleIcon: Icons.directions_run_rounded,
                              accentColor: const Color(0xFFFF8A65),
                              textPrimary: textPrimary,
                              textTertiary: textTertiary,
                              trailing: _MoreLink(onTap: _openMotionRecords, textTertiary: textTertiary, scheme: _scheme),
                              onTap: _openMotionRecords,
                              child: _MotionList(
                                items: _recentMotions,
                                scheme: _scheme,
                                textPrimary: textPrimary,
                                textTertiary: textTertiary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionBlock(
                              cardBg: cardBg,
                              title: '📈 数据报告',
                              titleIcon: Icons.insights_rounded,
                              accentColor: const Color(0xFF60A5FA),
                              textPrimary: textPrimary,
                              textTertiary: textTertiary,
                              trailing: _MoreLink(onTap: _openDataReport, textTertiary: textTertiary, scheme: _scheme),
                              onTap: _openDataReport,
                              child: _ReportPreview(
                                scheme: _scheme,
                                textPrimary: textPrimary,
                                textTertiary: textTertiary,
                                darkMode: _darkMode,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionBlock(
                              cardBg: cardBg,
                              title: '用户个性化档案',
                              titleIcon: Icons.person_search_rounded,
                              accentColor: const Color(0xFF7C6BF0),
                              textPrimary: textPrimary,
                              textTertiary: textTertiary,
                              trailing: _MoreLink(onTap: _openUserProfile, textTertiary: textTertiary, scheme: _scheme),
                              onTap: _openUserProfile,
                              child: _ProfilePreview(
                                scheme: _scheme,
                                textPrimary: textPrimary,
                                textTertiary: textTertiary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionBlock(
                              cardBg: cardBg,
                              title: '🏆 成就收藏',
                              titleIcon: Icons.emoji_events_rounded,
                              accentColor: const Color(0xFFFBBF24),
                              textPrimary: textPrimary,
                              textTertiary: textTertiary,
                              trailing: _BadgeCountPill(
                                text: '$badgeCount/$totalBadges',
                                cardBg: _darkMode ? const Color(0xFF0B1220) : const Color(0xFFF0F2F7),
                                textTertiary: textTertiary,
                              ),
                              child: _BadgesGrid(
                                items: badges,
                                scheme: _scheme,
                                textPrimary: textPrimary,
                                textTertiary: textTertiary,
                                onTap: (badge) {
                                  if (badge.unlocked) {
                                    showDialog<void>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(badge.name),
                                          content: const Text('恭喜你获得了这个徽章！'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('确定')),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    showDialog<void>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('徽章未解锁'),
                                          content: const Text('继续努力运动，解锁更多徽章吧！'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('确定')),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SectionBlock(
                              cardBg: cardBg,
                              title: '⚙️ 应用设置',
                              titleIcon: Icons.settings_rounded,
                              accentColor: const Color(0xFFA78BFA),
                              textPrimary: textPrimary,
                              textTertiary: textTertiary,
                              onTap: () => _toast('进入设置（占位）'),
                              child: _SettingsMenuItem(
                                scheme: _scheme,
                                textPrimary: textPrimary,
                                textTertiary: textTertiary,
                                onTap: () => _toast('进入设置（占位）'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _LogoutButton(
                              cardBg: cardBg,
                              textDanger: const Color(0xFFEF4444),
                              onTap: _confirmLogout,
                            ),
                            const SizedBox(height: 24),
                          ],
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

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.scheme,
    required this.darkMode,
    required this.name,
    required this.avatar,
    required this.consecutiveDays,
    required this.totalCheckInDays,
    required this.userLevel,
    required this.levelProgress,
    required this.onToggleTheme,
    required this.onTapChat,
    required this.onTapAvatar,
    required this.onTapLogin,
    required this.onTapEdit,
    required this.textPrimary,
    required this.textTertiary,
  });

  final ColorScheme scheme;
  final bool darkMode;
  final String? name;
  final String? avatar;
  final int consecutiveDays;
  final int totalCheckInDays;
  final int userLevel;
  final double levelProgress;

  final VoidCallback onToggleTheme;
  final VoidCallback onTapChat;
  final VoidCallback onTapAvatar;
  final VoidCallback onTapLogin;
  final VoidCallback onTapEdit;

  final Color textPrimary;
  final Color textTertiary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 12, 16, 96),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _MineTeenStyle.headerGradient,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(right: -50, top: -80, child: _HeaderBubble(size: 180)),
          const Positioned(left: -60, bottom: -60, child: _HeaderBubble(size: 140)),
          const Positioned(left: 140, top: 70, child: _HeaderBubble(size: 110)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MineNavbar(
                onToggleTheme: onToggleTheme,
                onTapChat: onTapChat,
                darkMode: darkMode,
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(
                    avatar: avatar,
                    onTap: onTapAvatar,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: name == null || name!.trim().isEmpty
                        ? _LoginPrompt(onTap: onTapLogin)
                        : _UserInfo(
                            name: name!.trim(),
                            consecutiveDays: consecutiveDays,
                            totalCheckInDays: totalCheckInDays,
                            userLevel: userLevel,
                            levelProgress: levelProgress,
                          ),
                  ),
                  const SizedBox(width: 10),
                  _EditButton(onTap: onTapEdit),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MineNavbar extends StatelessWidget {
  const _MineNavbar({
    required this.onToggleTheme,
    required this.onTapChat,
    required this.darkMode,
  });

  final VoidCallback onToggleTheme;
  final VoidCallback onTapChat;
  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Center(
            child: Text(
              '我的 ✨',
              style: TextStyle(color: Colors.white, fontSize: _MineTeenStyle.navTitle, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        IconButton(
          onPressed: onToggleTheme,
          icon: Icon(darkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded, color: Colors.white),
        ),
        IconButton(
          onPressed: onTapChat,
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _HeaderBubble extends StatelessWidget {
  const _HeaderBubble({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.18,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatar, required this.onTap});

  final String? avatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.22),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF63B6).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: avatar == null || avatar!.trim().isEmpty
              ? const Center(child: Icon(Icons.face_rounded, color: Colors.white, size: 44))
              : Image.network(
                  avatar!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => const Center(child: Icon(Icons.person_rounded, color: Colors.white, size: 38)),
                ),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('点击登录', style: TextStyle(color: Colors.white, fontSize: _MineTeenStyle.userName, fontWeight: FontWeight.w900)),
            SizedBox(height: 6),
            Text('一起动起来，超酷的！', style: TextStyle(color: Colors.white70, fontSize: _MineTeenStyle.userMeta)),
          ],
        ),
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  const _UserInfo({
    required this.name,
    required this.consecutiveDays,
    required this.totalCheckInDays,
    required this.userLevel,
    required this.levelProgress,
  });

  final String name;
  final int consecutiveDays;
  final int totalCheckInDays;
  final int userLevel;
  final double levelProgress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: _MineTeenStyle.userName, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '连续打卡 ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: _MineTeenStyle.userMeta,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '$consecutiveDays',
                        style: const TextStyle(
                          color: Color(0xFFFFF176),
                          fontSize: _MineTeenStyle.userMeta,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: ' 天 · 总打卡 ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: _MineTeenStyle.userMeta,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '$totalCheckInDays',
                        style: const TextStyle(
                          color: Color(0xFFFFF176),
                          fontSize: _MineTeenStyle.userMeta,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: ' 天',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: _MineTeenStyle.userMeta,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('✨ 运动达人 Lv.$userLevel', style: const TextStyle(color: Colors.white, fontSize: _MineTeenStyle.userLevel, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 10,
              color: Colors.white.withValues(alpha: 0.22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (levelProgress / 100).clamp(0.0, 1.0),
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text('编辑', style: TextStyle(color: Colors.white, fontSize: _MineTeenStyle.edit, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _StatsCardsRow extends StatelessWidget {
  const _StatsCardsRow({
    required this.scheme,
    required this.cardBg,
    required this.textPrimary,
    required this.textTertiary,
    required this.challengeProgress,
    required this.badgeCount,
    required this.recentBadges,
    required this.totalWorkouts,
    required this.onTapChallenge,
    required this.onTapBadges,
    required this.onTapMotions,
  });

  final ColorScheme scheme;
  final Color cardBg;
  final Color textPrimary;
  final Color textTertiary;

  final _ChallengeProgress challengeProgress;
  final int badgeCount;
  final int recentBadges;
  final int totalWorkouts;

  final VoidCallback onTapChallenge;
  final VoidCallback onTapBadges;
  final VoidCallback onTapMotions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatsCard(
            icon: Icons.flag_rounded,
            iconBg: const Color(0xFFFFE0B2),
            iconColor: const Color(0xFFFF9800),
            label: '闯关',
            value: '${challengeProgress.completed}/${challengeProgress.total}',
            trendText: '+${challengeProgress.recent}',
            trendColor: const Color(0xFF22C55E),
            onTap: onTapChallenge,
            cardBg: cardBg,
            textPrimary: textPrimary,
            textTertiary: textTertiary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatsCard(
            icon: Icons.workspace_premium_rounded,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFFA855F7),
            label: '徽章',
            value: '$badgeCount',
            trendText: '+$recentBadges',
            trendColor: const Color(0xFF22C55E),
            onTap: onTapBadges,
            cardBg: cardBg,
            textPrimary: textPrimary,
            textTertiary: textTertiary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatsCard(
            icon: Icons.favorite_rounded,
            iconBg: const Color(0xFFFFE4EC),
            iconColor: const Color(0xFFFF4081),
            label: '运动天',
            value: '$totalWorkouts',
            trendText: null,
            trendColor: scheme.primary,
            onTap: onTapMotions,
            cardBg: cardBg,
            textPrimary: textPrimary,
            textTertiary: textTertiary,
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.trendText,
    required this.trendColor,
    required this.onTap,
    required this.cardBg,
    required this.textPrimary,
    required this.textTertiary,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String? trendText;
  final Color trendColor;
  final VoidCallback onTap;

  final Color cardBg;
  final Color textPrimary;
  final Color textTertiary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_MineTeenStyle.radiusMd),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(_MineTeenStyle.radiusMd),
          border: Border.all(color: _MineTeenStyle.cardBorder.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(color: iconColor.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: iconColor.withValues(alpha: 0.2)),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const Spacer(),
                if (trendText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(trendText!, style: TextStyle(color: trendColor, fontSize: _MineTeenStyle.statTrend, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(color: textPrimary, fontSize: _MineTeenStyle.statValue, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: textTertiary, fontSize: _MineTeenStyle.statLabel, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.cardBg,
    required this.title,
    required this.titleIcon,
    required this.textPrimary,
    required this.textTertiary,
    required this.child,
    this.accentColor = const Color(0xFF667EEA),
    this.trailing,
    this.onTap,
  });

  final Color cardBg;
  final String title;
  final IconData titleIcon;
  final Color accentColor;
  final Color textPrimary;
  final Color textTertiary;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_MineTeenStyle.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(_MineTeenStyle.radiusLg),
          border: Border.all(color: accentColor.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(color: accentColor.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(titleIcon, color: accentColor, size: _MineTeenStyle.sectionIcon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: TextStyle(color: textPrimary, fontSize: _MineTeenStyle.sectionTitle, fontWeight: FontWeight.w900)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _MoreLink extends StatelessWidget {
  const _MoreLink({required this.onTap, required this.textTertiary, required this.scheme});

  final VoidCallback onTap;
  final Color textTertiary;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Text('查看全部', style: TextStyle(color: scheme.primary, fontSize: _MineTeenStyle.bodySm, fontWeight: FontWeight.w900)),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, color: textTertiary, size: 18),
        ],
      ),
    );
  }
}

class _BadgeCountPill extends StatelessWidget {
  const _BadgeCountPill({required this.text, required this.cardBg, required this.textTertiary});

  final String text;
  final Color cardBg;
  final Color textTertiary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: TextStyle(color: textTertiary, fontSize: _MineTeenStyle.bodySm, fontWeight: FontWeight.w900)),
    );
  }
}

class _MotionList extends StatelessWidget {
  const _MotionList({
    required this.items,
    required this.scheme,
    required this.textPrimary,
    required this.textTertiary,
  });

  final List<_MotionItem> items;
  final ColorScheme scheme;
  final Color textPrimary;
  final Color textTertiary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _MotionRow(item: items[i], textPrimary: textPrimary, textTertiary: textTertiary, scheme: scheme),
          if (i != items.length - 1)
            Divider(height: 18, thickness: 1, color: textTertiary.withValues(alpha: 0.18)),
        ]
      ],
    );
  }
}

class _MotionRow extends StatelessWidget {
  const _MotionRow({required this.item, required this.textPrimary, required this.textTertiary, required this.scheme});

  final _MotionItem item;
  final Color textPrimary;
  final Color textTertiary;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final color = item.type.color;

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Icon(item.type.icon, color: color, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: TextStyle(color: textPrimary, fontSize: _MineTeenStyle.body, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(item.time, style: TextStyle(color: textTertiary, fontSize: _MineTeenStyle.bodySm, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${item.durationMinutes}', style: TextStyle(color: scheme.primary, fontSize: _MineTeenStyle.body, fontWeight: FontWeight.w900)),
            Text('分钟', style: TextStyle(color: textTertiary, fontSize: _MineTeenStyle.caption, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _BadgesGrid extends StatelessWidget {
  const _BadgesGrid({
    required this.items,
    required this.scheme,
    required this.textPrimary,
    required this.textTertiary,
    required this.onTap,
  });

  final List<_BadgeItem> items;
  final ColorScheme scheme;
  final Color textPrimary;
  final Color textTertiary;
  final void Function(_BadgeItem badge) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _BadgeTile(
          item: item,
          scheme: scheme,
          textPrimary: textPrimary,
          textTertiary: textTertiary,
          onTap: () => onTap(item),
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.item,
    required this.scheme,
    required this.textPrimary,
    required this.textTertiary,
    required this.onTap,
  });

  final _BadgeItem item;
  final ColorScheme scheme;
  final Color textPrimary;
  final Color textTertiary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          GameMedalBadge(
            theme: item.type.medalTheme,
            emblem: item.type.icon,
            ribbonText: gameMedalRibbonLabel(item.name),
            unlocked: item.unlocked,
            size: 76,
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: TextStyle(
              color: item.unlocked ? textPrimary : textTertiary,
              fontSize: _MineTeenStyle.badgeName,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  const _SettingsMenuItem({
    required this.scheme,
    required this.textPrimary,
    required this.textTertiary,
    required this.onTap,
  });

  final ColorScheme scheme;
  final Color textPrimary;
  final Color textTertiary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
              ),
              child: const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('应用设置', style: TextStyle(color: textPrimary, fontSize: _MineTeenStyle.body, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('通知、隐私、更新等', style: TextStyle(color: textTertiary, fontSize: _MineTeenStyle.bodySm, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

enum _MotionType {
  jump,
  situp,
  pullup,
}

extension on _MotionType {
  IconData get icon {
    switch (this) {
      case _MotionType.jump:
        return Icons.directions_run_rounded;
      case _MotionType.situp:
        return Icons.self_improvement_rounded;
      case _MotionType.pullup:
        return Icons.fitness_center_rounded;
    }
  }

  Color get color {
    switch (this) {
      case _MotionType.jump:
        return const Color(0xFFFFC107);
      case _MotionType.situp:
        return const Color(0xFF9C27B0);
      case _MotionType.pullup:
        return const Color(0xFF2196F3);
    }
  }
}

class _MotionItem {
  const _MotionItem({
    required this.name,
    required this.time,
    required this.durationMinutes,
    required this.type,
  });

  final String name;
  final String time;
  final int durationMinutes;
  final _MotionType type;
}

enum _BadgeType {
  trophy,
  fire,
  star,
  diamond,
  crown,
  rocket,
}

extension on _BadgeType {
  IconData get icon {
    switch (this) {
      case _BadgeType.trophy:
        return Icons.emoji_events_rounded;
      case _BadgeType.fire:
        return Icons.local_fire_department_rounded;
      case _BadgeType.star:
        return Icons.star_rounded;
      case _BadgeType.diamond:
        return Icons.diamond_rounded;
      case _BadgeType.crown:
        return Icons.workspace_premium_rounded;
      case _BadgeType.rocket:
        return Icons.rocket_launch_rounded;
    }
  }

  Color get color {
    switch (this) {
      case _BadgeType.trophy:
        return const Color(0xFFFFC107);
      case _BadgeType.fire:
        return const Color(0xFFF44336);
      case _BadgeType.star:
        return const Color(0xFF2196F3);
      case _BadgeType.diamond:
        return const Color(0xFF9C27B0);
      case _BadgeType.crown:
        return const Color(0xFFFF9800);
      case _BadgeType.rocket:
        return const Color(0xFF4CAF50);
    }
  }

  GameMedalTheme get medalTheme {
    switch (this) {
      case _BadgeType.trophy:
        return GameMedalThemes.trophy;
      case _BadgeType.fire:
        return GameMedalThemes.fire;
      case _BadgeType.star:
        return GameMedalThemes.star;
      case _BadgeType.diamond:
        return GameMedalThemes.diamond;
      case _BadgeType.crown:
        return GameMedalThemes.crown;
      case _BadgeType.rocket:
        return GameMedalThemes.rocket;
    }
  }
}

class _BadgeItem {
  const _BadgeItem({
    required this.name,
    required this.type,
    required this.unlocked,
  });

  final String name;
  final _BadgeType type;
  final bool unlocked;
}

class _ChallengeProgress {
  const _ChallengeProgress({required this.completed, required this.total, required this.recent});

  final int completed;
  final int total;
  final int recent;
}

/// 退出登录按钮
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({
    required this.cardBg,
    required this.textDanger,
    required this.onTap,
  });

  final Color cardBg;
  final Color textDanger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_MineTeenStyle.radiusLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(_MineTeenStyle.radiusLg),
          border: Border.all(color: textDanger.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: textDanger, size: 22),
            const SizedBox(width: 8),
            Text(
              '退出登录',
              style: TextStyle(
                color: textDanger,
                fontSize: _MineTeenStyle.body,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
