import 'package:flutter/material.dart';

import 'community_api_client.dart';
import '../../config/app_config.dart';
import '../../utils/app_logger.dart';
import '../../utils/user_scope.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();

  static void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ErrorHint extends StatelessWidget {
  const _ErrorHint({required this.text, required this.onRetry});

  final String text;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '加载失败',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666)),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FACFE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 10,
              ),
              child: const Text(
                '重试',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityPageState extends State<CommunityPage> {
  static const _defaultBaseUrl = kApiBaseUrl;

  late final CommunityApiClient _api = CommunityApiClient(baseUrl: _defaultBaseUrl);

  List<_Post> _posts = const [];
  bool _loading = true;
  String? _errorText;

  static const _bgGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  );

  static const _defaultAvatar = 'assets/images/user-avatar-1.jpg';

  /// 当前登录用户（演示/未登录回退为小恐龙）。
  _UserProfile get _me {
    final isReal = !UserScope.isDemo && (UserScope.username?.trim().isNotEmpty ?? false);
    return _UserProfile(
      name: isReal ? UserScope.username! : '小恐龙',
      motto: '每天都要健康运动哦！',
      avatarAsset: isReal && (UserScope.avatar?.trim().isNotEmpty ?? false)
          ? UserScope.avatar!
          : _defaultAvatar,
    );
  }

  static const _pickerAssets = <String>[
    'assets/images/hip-bridge-1.png',
    'assets/images/side-plank-support.png',
    'assets/images/balance-training.png',
    'assets/images/jinggangshan.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final remote = await _api.listPosts(userName: _me.name);
      if (!mounted) return;
      setState(() {
        _posts = remote.map(_Post.fromRemote).toList(growable: false);
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.e('社区', e, st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = '加载失败：$e';
      });
    }
  }

  Future<void> _refresh() async {
    await _loadPosts();
  }

  Future<void> _openCreateSheet() async {
    final created = await showModalBottomSheet<_CreatePostResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostSheet(
        me: _me,
        pickerAssets: _pickerAssets,
      ),
    );

    if (!mounted) return;
    if (created == null) return;

    try {
      final remote = await _api.createPost(
        content: created.content,
        featured: created.featured,
        images: created.images,
        userName: _me.name,
        userAvatar: _me.avatarAsset,
      );
      if (!mounted) return;
      setState(() {
        _posts = <_Post>[_Post.fromRemote(remote), ..._posts];
      });
    } catch (e, st) {
      AppLogger.e('社区', e, st);
      if (!mounted) return;
      CommunityPage._toast(context, '发布失败：$e');
    }
  }

  Future<_Post> _toggleLike(int postId) async {
    final remote = await _api.toggleLike(id: postId, userName: _me.name);
    return _Post.fromRemote(remote);
  }

  @override
  Widget build(BuildContext context) {
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
                          onCamera: () => CommunityPage._toast(context, '相机功能开发中'),
                          onCreate: _openCreateSheet,
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
                    if (_loading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 30, 16, 120),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            ),
                          ),
                        ),
                      )
                    else if (_errorText != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                          child: _ErrorHint(
                            text: _errorText!,
                            onRetry: _loadPosts,
                          ),
                        ),
                      )
                    else if (_posts.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 18, 16, 120),
                          child: _EmptyHint(),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                        sliver: SliverList.separated(
                          itemCount: _posts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _PostCard(
                            post: _posts[index],
                            onToggleLike: _toggleLike,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)),
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

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.onCamera, required this.onCreate});

  final VoidCallback onCamera;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '社区',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
          ),
        ),
        _CircleIconButton(
          onTap: onCamera,
          child: const Text('📷', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 10),
        _CircleIconButton(
          onTap: onCreate,
          child: const Text('➕', style: TextStyle(fontSize: 18)),
        ),
      ],
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF666666)),
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
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({
    required this.me,
    required this.pickerAssets,
  });

  final _UserProfile me;
  final List<String> pickerAssets;

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
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
      CommunityPage._toast(context, '写点内容再发布吧');
      return;
    }

    Navigator.of(context).pop(
      _CreatePostResult(
        content: text,
        featured: _featured,
        images: _selected.toList(growable: false),
      ),
    );
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
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF666666)),
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
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
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
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post, required this.onToggleLike});

  final _Post post;
  final Future<_Post> Function(int postId) onToggleLike;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late bool _liked = widget.post.isLiked;
  late int _likeCount = widget.post.likes;

  Future<void> _toggleLike() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final updated = await widget.onToggleLike(widget.post.id);
      if (!mounted) return;
      setState(() {
        _liked = updated.isLiked;
        _likeCount = updated.likes;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(_liked ? '已点赞' : '已取消点赞')),
      );
    } catch (e, st) {
      AppLogger.e('社区', e, st);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('点赞失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.18), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(asset: p.user.avatarAsset),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.user.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (p.featured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFA726)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '精选',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.timeAgo,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.content,
            style: const TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          if (p.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ImagesGrid(images: p.images),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionChip(
                icon: _liked ? '❤️' : '🤍',
                text: '赞 $_likeCount',
                active: _liked,
                onTap: _toggleLike,
              ),
              const SizedBox(width: 10),
              _ActionChip(
                icon: '💬',
                text: '评论 ${p.comments}',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('评论功能开发中'))),
              ),
              const SizedBox(width: 10),
              _ActionChip(
                icon: '📤',
                text: '分享',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分享成功'))),
              ),
            ],
          ),
          if (p.likeUsers.isNotEmpty) ...[
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
                      _likeText(p.likeUsers),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4FACFE).withValues(alpha: 0.45), width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
        ),
      ),
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
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF666666)),
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

class _Post {
  const _Post({
    required this.id,
    required this.user,
    required this.content,
    required this.timeAgo,
    required this.featured,
    required this.images,
    required this.likes,
    required this.comments,
    required this.isLiked,
    required this.likeUsers,
  });

  final int id;
  final _UserProfile user;
  final String content;
  final String timeAgo;
  final bool featured;
  final List<String> images;
  final int likes;
  final int comments;
  final bool isLiked;
  final List<String> likeUsers;

  factory _Post.fromRemote(CommunityPost r) {
    return _Post(
      id: r.id,
      user: _UserProfile(name: r.userName, motto: '', avatarAsset: r.userAvatar),
      content: r.content,
      timeAgo: r.timeAgo,
      featured: r.featured,
      images: r.images,
      likes: r.likes,
      comments: r.comments,
      isLiked: r.liked,
      likeUsers: r.likeUsers,
    );
  }
}

class _CreatePostResult {
  const _CreatePostResult({
    required this.content,
    required this.featured,
    required this.images,
  });

  final String content;
  final bool featured;
  final List<String> images;
}
