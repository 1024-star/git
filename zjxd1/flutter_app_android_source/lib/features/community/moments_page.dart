import 'package:flutter/material.dart';

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  State<MomentsPage> createState() => _MomentsPageState();

  static void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _MomentsPageState extends State<MomentsPage> {
  late final List<_Moment> _moments = List<_Moment>.from(_sampleMoments);

  static const _bgGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  );

  static const _cardRadius = BorderRadius.all(Radius.circular(18));

  static const _me = _UserProfile(
    name: '小恐龙',
    motto: '每天都要健康运动哦！',
    avatarAsset: 'assets/images/user-avatar-1.jpg',
  );

  static const _pickerAssets = <String>[
    'assets/images/yundongdakazhaopan/p2.png',
    'assets/images/yundongdakazhaopan/a2.png',
    'assets/images/yundongdakazhaopan/a1.png',
    'assets/images/yundongdakazhaopan/d2.png',
  ];

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _moments.shuffle();
    });
  }

  Future<void> _openCreateSheet() async {
    final created = await showModalBottomSheet<_Moment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateMomentSheet(
        me: _me,
        pickerAssets: _pickerAssets,
      ),
    );

    if (!mounted) return;
    if (created == null) return;

    setState(() {
      _moments.insert(0, created);
    });
  }

  @override
  Widget build(BuildContext context) {
    final moments = _moments;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: _bgGradient),
        child: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refresh,
                color: const Color(0xFF4FACFE),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: _TopHeader(
                          onCamera: () => MomentsPage._toast(context, '相机功能开发中'),
                          onCreate: _openCreateSheet,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _PersonalStatsCard(
                          user: _me,
                          mascotAsset: 'assets/images/jump-rope-girl-illustration.png',
                          stats: const _TodayStats(steps: '8,652', calories: '326', exercises: '3'),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _PostEntryCard(
                          me: _me,
                          onTap: _openCreateSheet,
                        ),
                      ),
                    ),
                    if (moments.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 18, 16, 120),
                          child: _EmptyMomentsHint(),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                        sliver: SliverList.separated(
                          itemCount: moments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _MomentCard(moment: moments[index]);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (Navigator.of(context).canPop())
                Positioned(
                  top: 12,
                  left: 12,
                  child: _CircleIconButton(
                    onTap: () {
                      final nav = Navigator.of(context);
                      if (nav.canPop()) nav.pop();
                    },
                    child: const Text(
                      '←',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)), // 从14改为22
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4FACFE),
        elevation: 10,
        onPressed: _openCreateSheet,
        child: const Text('✏️', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _PostEntryCard extends StatelessWidget {
  const _PostEntryCard({required this.me, required this.onTap});

  final _UserProfile me;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.22), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4FACFE).withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.55), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  me.avatarAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '今天运动了吗？发一条动态吧～',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF666666)), // 从13改为17
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '发布',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900), // 从12改为16
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMomentsHint extends StatelessWidget {
  const _EmptyMomentsHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 2),
      ),
      child: const Row(
        children: [
          Text('🫧', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '还没有动态哦，发布第一条吧～',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF)), // 从13改为17
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateMomentSheet extends StatefulWidget {
  const _CreateMomentSheet({
    required this.me,
    required this.pickerAssets,
  });

  final _UserProfile me;
  final List<String> pickerAssets;

  @override
  State<_CreateMomentSheet> createState() => _CreateMomentSheetState();
}

class _CreateMomentSheetState extends State<_CreateMomentSheet> {
  final _controller = TextEditingController();
  final Set<String> _selected = <String>{};
  bool _featured = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      MomentsPage._toast(context, '写点内容再发布吧');
      return;
    }

    final m = _Moment(
      user: widget.me,
      content: text,
      timeAgo: '刚刚',
      featured: _featured,
      exercise: null,
      images: _selected.toList(growable: false),
      likes: 0,
      comments: 0,
      isLiked: false,
      likeUsers: const [],
    );

    Navigator.of(context).pop(m);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFEFF6FF)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, -10),
              )
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.55), width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            widget.me.avatarAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '发布动态',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: const BorderRadius.all(Radius.circular(18)),
                      border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.18), width: 2),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: TextField(
                      controller: _controller,
                      maxLines: 5,
                      minLines: 3,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '分享一下今天的训练、心情或者小成就～',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700),
                      ),
                      style: const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ToggleChip(
                        active: _featured,
                        icon: '✨',
                        text: '精选',
                        onTap: () => setState(() => _featured = !_featured),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '选择图片（占位）',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)), // 从12改为16
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.pickerAssets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final asset = widget.pickerAssets[index];
                        final selected = _selected.contains(asset);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selected.remove(asset);
                              } else {
                                _selected.add(asset);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.9),
                                width: selected ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                asset,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FACFE),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 10,
                      ),
                      child: const Text(
                        '发布动态',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white), // 从15改为19
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.active, required this.icon, required this.text, required this.onTap});

  final bool active;
  final String icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFF93C5FD) : const Color(0xFFF8F9FA);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? const Color(0xFF3B82F6) : Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)), // 从14改为18
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF666666)), // 从12改为16
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.onCamera, required this.onCreate});

  final VoidCallback onCamera;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FACFE).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.20), width: 2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4FACFE), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4FACFE).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/dragon-background-1.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF4FACFE)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '健康朋友圈',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)), // 从18改为22
                ),
              ),
              _GradientCircleAction(icon: '📷', onTap: onCamera),
              const SizedBox(width: 10),
              _GradientCircleAction(icon: '➕', onTap: onCreate),
            ],
          ),
          const Positioned(
            right: 56,
            top: 6,
            child: Text('', style: TextStyle(fontSize: 22, color: Color(0xFF1E40AF))), // 从18改为22,
          ),
          const Positioned(
            right: 16,
            bottom: 2,
            child: Text('', style: TextStyle(fontSize: 20, color: Color(0xFF1E40AF))), // 从16改为20,
          ),
        ],
      ),
    );
  }
}

class _GradientCircleAction extends StatelessWidget {
  const _GradientCircleAction({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4FACFE).withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(icon, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _PersonalStatsCard extends StatelessWidget {
  const _PersonalStatsCard({
    required this.user,
    required this.stats,
    required this.mascotAsset,
  });

  final _UserProfile user;
  final _TodayStats stats;
  final String mascotAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FACFE).withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
        border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.25), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4FACFE), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4FACFE).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    user.avatarAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF333333)), // 从16改为20
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.motto,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF666666)), // 从12改为16
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 58,
                height: 58,
                child: Image.asset(
                  mascotAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatItem(number: stats.steps, label: '今日步数', icon: '🚶‍♀️'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatItem(number: stats.calories, label: '消耗卡路里', icon: '🔥'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatItem(number: stats.exercises, label: '完成训练', icon: '💪'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.number, required this.label, required this.icon});

  final String number;
  final String label;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        gradient: const LinearGradient(colors: [Color(0xFFF0F8FF), Color(0xFFE6E6FA)]),
        border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.12), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)), // 从18改为22
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 6),
          Text(icon, style: const TextStyle(fontSize: 18)), // 从14改为18
        ],
      ),
    );
  }
}

class _MomentCard extends StatefulWidget {
  const _MomentCard({required this.moment});

  final _Moment moment;

  @override
  State<_MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<_MomentCard> {
  late bool _liked = widget.moment.isLiked;
  late int _likeCount = widget.moment.likes;

  @override
  Widget build(BuildContext context) {
    final m = widget.moment;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: (m.featured ? const Color(0xFF4FACFE) : const Color(0xFF4FACFE).withValues(alpha: 0.18)),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
                  border: Border.all(color: const Color(0xFF60A5FA), width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    m.user.avatarAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.user.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF333333)), // 从14改为18
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.timeAgo,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333)), // 从11改为15
                    ),
                  ],
                ),
              ),
              if (m.featured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4FACFE).withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: const Text(
                    '精选',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white), // 从10改为14
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            m.content,
            style: TextStyle(fontSize: 18, height: 1.55, fontWeight: FontWeight.w600, color: Color(0xFF333333)), // 从14改为18
          ),
          if (m.exercise != null) ...[
            const SizedBox(height: 12),
            _ExerciseDataCard(exercise: m.exercise!),
          ],
          if (m.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ImagesGrid(images: m.images),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionChip(
                active: _liked,
                icon: _liked ? '❤️' : '🤍',
                text: '$_likeCount',
                onTap: () {
                  setState(() {
                    _liked = !_liked;
                    _likeCount += _liked ? 1 : -1;
                  });
                },
              ),
              const SizedBox(width: 12),
              _ActionChip(
                icon: '💬',
                text: '${m.comments}',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('评论功能开发中'))),
              ),
              const SizedBox(width: 12),
              _ActionChip(
                icon: '📤',
                text: '分享',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分享成功'))),
              ),
            ],
          ),
          if (m.likeUsers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border(left: BorderSide(color: Color(0xFF4FACFE), width: 3)),
              ),
              child: Row(
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _likeText(m.likeUsers),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF666666)), // 从12改为16
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _likeText(List<String> users) {
    if (users.length <= 3) return '${users.join('、')} 觉得很赞';
    return '${users.take(3).join('、')} 等${users.length}人觉得很赞';
  }
}

class _ExerciseDataCard extends StatelessWidget {
  const _ExerciseDataCard({required this.exercise});

  final _ExerciseData exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.18), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  exercise.iconAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)), // 从13改为17
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(value: exercise.durationMinutes, unit: '分钟'),
              _MiniStat(value: exercise.calories, unit: '千卡'),
              _MiniStat(value: exercise.count, unit: '次'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF666666)), // 从10改为14
        ),
      ],
    );
  }
}

class _ImagesGrid extends StatelessWidget {
  const _ImagesGrid({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final count = images.length;

    final crossAxisCount = count == 1
        ? 1
        : (count == 2)
            ? 2
            : 3;

    final aspectRatio = count == 1 ? 1.8 : (count == 2 ? 1.1 : 1.0);

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: aspectRatio,
        ),
        itemCount: count,
        itemBuilder: (context, index) {
          final asset = images[index];
          return InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
                  ),
                ),
              ),
            ),
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
            ),
          );
        },
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.text,
    required this.onTap,
    this.active = false,
  });

  final String icon;
  final String text;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFF93C5FD) : const Color(0xFFF8F9FA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? const Color(0xFF3B82F6) : Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)), // 从14改为18
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF666666)), // 从12改为16
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.95),
          border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.35), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4FACFE).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _UserProfile {
  const _UserProfile({required this.name, required this.motto, required this.avatarAsset});

  final String name;
  final String motto;
  final String avatarAsset;
}

class _TodayStats {
  const _TodayStats({required this.steps, required this.calories, required this.exercises});

  final String steps;
  final String calories;
  final String exercises;
}

class _Moment {
  const _Moment({
    required this.user,
    required this.content,
    required this.timeAgo,
    required this.featured,
    required this.exercise,
    required this.images,
    required this.likes,
    required this.comments,
    required this.isLiked,
    required this.likeUsers,
  });

  final _UserProfile user;
  final String content;
  final String timeAgo;
  final bool featured;
  final _ExerciseData? exercise;
  final List<String> images;
  final int likes;
  final int comments;
  final bool isLiked;
  final List<String> likeUsers;
}

class _ExerciseData {
  const _ExerciseData({
    required this.iconAsset,
    required this.title,
    required this.durationMinutes,
    required this.calories,
    required this.count,
  });

  final String iconAsset;
  final String title;
  final String durationMinutes;
  final String calories;
  final String count;
}

const _sampleMoments = <_Moment>[
  _Moment(
    user: _UserProfile(name: '健身小达人', motto: '', avatarAsset: 'assets/images/user-avatar-2.jpg'),
    content: '今天完成了30分钟的臀桥训练，感觉核心力量提升了很多！大家也要坚持运动哦~ 💪',
    timeAgo: '5分钟前',
    featured: true,
    exercise: _ExerciseData(
      iconAsset: 'assets/images/yundongdakazhaopan/p2.png',
      title: '臀桥训练',
      durationMinutes: '30',
      calories: '128',
      count: '50',
    ),
    images: ['assets/images/yundongdakazhaopan/p2.png'],
    likes: 24,
    comments: 8,
    isLiked: true,
    likeUsers: ['小恐龙', '运动女孩', '健康生活'],
  ),
  _Moment(
    user: _UserProfile(name: '瑜伽小仙女', motto: '', avatarAsset: 'assets/images/user-avatar-3.png'),
    content: '晨练瑜伽结束！今天的拉伸让身体特别舒服，推荐给大家这组动作~ ✨',
    timeAgo: '1小时前',
    featured: false,
    exercise: _ExerciseData(
      iconAsset: 'assets/images/cartoon-girl-cat-stretch.png',
      title: '晨练瑜伽',
      durationMinutes: '45',
      calories: '95',
      count: '12',
    ),
    images: ['assets/images/yundongdakazhaopan/a1.png', 'assets/images/yundongdakazhaopan/a2.png'],
    likes: 18,
    comments: 5,
    isLiked: false,
    likeUsers: ['运动达人', '健康女孩'],
  ),
  _Moment(
    user: _UserProfile(name: '跑步爱好者', motto: '', avatarAsset: 'assets/images/user-avatar-4.jpg'),
    content: '完成今天的5公里跑步！天气很好，心情也很棒~ 🌞',
    timeAgo: '2小时前',
    featured: false,
    exercise: null,
    images: [
      'assets/images/yundongdakazhaopan/d3.png',
      'assets/images/yundongdakazhaopan/d1.png',
      'assets/images/yundongdakazhaopan/d2.png',
    ],
    likes: 32,
    comments: 12,
    isLiked: true,
    likeUsers: ['小恐龙', '健身小达人', '运动女孩', '跑步小子'],
  ),
  _Moment(
    user: _UserProfile(name: '力量训练家', motto: '', avatarAsset: 'assets/images/user-avatar-5.jpg'),
    content: '新的一周开始！今天进行了全身力量训练，感觉满满的能量~ 💥',
    timeAgo: '3小时前',
    featured: false,
    exercise: _ExerciseData(
      iconAsset: 'assets/images/yundongdakazhaopan/p2.png',
      title: '力量训练',
      durationMinutes: '60',
      calories: '245',
      count: '25',
    ),
    images: const [],
    likes: 15,
    comments: 3,
    isLiked: false,
    likeUsers: ['健身小达人', '运动达人'],
  ),
];
