import 'dart:async';

import 'package:flutter/material.dart';

import '../../utils/user_scope.dart';
import 'motion_api_client.dart';

class MotionRecordsPage extends StatefulWidget {
  const MotionRecordsPage({
    super.key,
    this.initialDarkMode = false,
  });

  final bool initialDarkMode;

  @override
  State<MotionRecordsPage> createState() => _MotionRecordsPageState();
}

class _MotionRecordsPageState extends State<MotionRecordsPage> {
  late bool _darkMode;

  final ScrollController _scrollController = ScrollController();

  bool loading = false;
  bool refreshing = false;
  bool hasMore = true;
  int currentPage = 1;
  final int pageSize = 10;

  final List<_MotionRecord> motionList = [];

  @override
  void initState() {
    super.initState();
    _darkMode = widget.initialDarkMode;

    _scrollController.addListener(_onScroll);

    scheduleMicrotask(() {
      if (!mounted) return;
      _refresh();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (loading || !hasMore) return;

    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 120) {
      _loadMore();
    }
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

  void _toggleTheme() {
    setState(() {
      _darkMode = !_darkMode;
    });
  }

  Future<void> _refresh() async {
    if (loading) return;
    setState(() {
      refreshing = true;
      currentPage = 1;
      hasMore = true;
    });

    try {
      final data = await _fetchPage(1);
      if (!mounted) return;
      setState(() {
        motionList
          ..clear()
          ..addAll(data);
        hasMore = data.length >= pageSize;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        refreshing = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (loading || refreshing || !hasMore) return;
    setState(() {
      loading = true;
      currentPage += 1;
    });

    try {
      final data = await _fetchPage(currentPage);
      if (!mounted) return;
      setState(() {
        motionList.addAll(data);
        hasMore = data.length >= pageSize;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<List<_MotionRecord>> _fetchPage(int page) async {
    // 从后端读取该用户的真实运动记录，前端按 pageSize 分页展示
    final list = await MotionApiClient().listRecords(username: (UserScope.username ?? '').trim());

    final startIndex = (page - 1) * pageSize;
    if (startIndex >= list.length) return const [];

    final endIndex = (startIndex + pageSize) > list.length ? list.length : startIndex + pageSize;
    final slice = list.sublist(startIndex, endIndex);

    return slice.map((r) {
      return _MotionRecord(
        id: 'm_${r.createdAtMs}',
        motionName: r.motionName.isEmpty ? '运动训练' : r.motionName,
        createTime: DateTime.fromMillisecondsSinceEpoch(r.createdAtMs),
      );
    }).toList(growable: false);
  }

  bool _isRecentRecord(DateTime createTime) {
    final now = DateTime.now();
    return now.difference(createTime).inHours <= 24;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _back() {
    Navigator.of(context).pop(_darkMode);
  }

  void _toDetail(_MotionRecord item) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('查看详情'),
          content: Text('运动：${item.motionName}\n时间：${_formatDate(item.createTime)}'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('确定')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgTertiary = _darkMode ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB);
    final cardBg = _darkMode ? const Color(0xFF111827) : Colors.white;
    final textPrimary = _darkMode ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = _darkMode ? Colors.white70 : const Color(0xFF374151);
    final textTertiary = _darkMode ? Colors.white60 : const Color(0xFF6B7280);

    return WillPopScope(
      onWillPop: () async {
        _back();
        return false;
      },
      child: Scaffold(
        backgroundColor: bgTertiary,
        body: Column(
          children: [
            _Navbar(
              onBack: _back,
              onToggleTheme: _toggleTheme,
              darkMode: _darkMode,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '运动记录',
                      style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('筛选（占位）')));
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text('全部', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Text('▼', style: TextStyle(color: textTertiary, fontSize: 10, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: motionList.isEmpty && !loading && !refreshing
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          _EmptyState(cardBg: cardBg, textSecondary: textSecondary, textTertiary: textTertiary),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: motionList.length + 1,
                        itemBuilder: (context, index) {
                          if (index == motionList.length) {
                            return _LoadMoreIndicator(
                              loading: loading,
                              hasMore: hasMore,
                              textTertiary: textTertiary,
                            );
                          }

                          final item = motionList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _MotionCard(
                              item: item,
                              cardBg: cardBg,
                              textPrimary: textPrimary,
                              textTertiary: textTertiary,
                              scheme: _scheme,
                              isRecent: _isRecentRecord(item.createTime),
                              dateText: _formatDate(item.createTime),
                              onTapDetail: () => _toDetail(item),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Navbar extends StatelessWidget {
  const _Navbar({
    required this.onBack,
    required this.onToggleTheme,
    required this.darkMode,
  });

  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    final foreground = darkMode ? Colors.white : Colors.black87;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back_rounded, color: foreground),
              label: Text('返回', style: TextStyle(color: foreground)),
            ),
            const Expanded(
              child: Center(
                child: Text('运动记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
            IconButton(
              onPressed: onToggleTheme,
              icon: Icon(darkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded, color: foreground),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.cardBg,
    required this.textSecondary,
    required this.textTertiary,
  });

  final Color cardBg;
  final Color textSecondary;
  final Color textTertiary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Text('📝', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text('暂无运动记录', style: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('开始您的第一次运动吧！', style: TextStyle(color: textTertiary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MotionCard extends StatelessWidget {
  const _MotionCard({
    required this.item,
    required this.cardBg,
    required this.textPrimary,
    required this.textTertiary,
    required this.scheme,
    required this.isRecent,
    required this.dateText,
    required this.onTapDetail,
  });

  final _MotionRecord item;
  final Color cardBg;
  final Color textPrimary;
  final Color textTertiary;
  final ColorScheme scheme;
  final bool isRecent;
  final String dateText;
  final VoidCallback onTapDetail;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                  gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(dateText, style: TextStyle(color: textTertiary, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const Spacer(),
                      if (isRecent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                          ),
                          child: const Text('新', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _GradientText(
                          item.motionName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _OutlinePillButton(
                        text: '查看详情',
                        color: scheme.primary,
                        onTap: onTapDetail,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinePillButton extends StatelessWidget {
  const _OutlinePillButton({required this.text, required this.color, required this.onTap});

  final String text;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.2),
          borderRadius: BorderRadius.circular(999),
          color: Colors.transparent,
        ),
        child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect);
      },
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator({
    required this.loading,
    required this.hasMore,
    required this.textTertiary,
  });

  final bool loading;
  final bool hasMore;
  final Color textTertiary;

  @override
  Widget build(BuildContext context) {
    if (!loading && !hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: Text('没有更多数据了', style: TextStyle(color: textTertiary, fontSize: 12)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: textTertiary.withValues(alpha: 0.6)),
            ),
          if (loading) const SizedBox(width: 10),
          Text(
            loading ? '加载中...' : '上拉加载更多',
            style: TextStyle(color: textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MotionRecord {
  const _MotionRecord({
    required this.id,
    required this.motionName,
    required this.createTime,
  });

  final String id;
  final String motionName;
  final DateTime createTime;
}
