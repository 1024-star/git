import 'dart:convert';

import 'package:http/http.dart' as http;

class CommunityApiClient {
  CommunityApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<List<CommunityPost>> listPosts({
    String userName = '小恐龙',
  }) async {
    final uri = Uri.parse('$baseUrl/api/community/posts');
    final resp = await _client.get(uri);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException(resp.statusCode, resp.body);
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! List) {
      throw const FormatException('Unexpected response: not a list');
    }

    return decoded.map((e) => CommunityPost.fromJson(e as Map<String, dynamic>)).toList(growable: false);
  }

  Future<CommunityPost> createPost({
    required String content,
    bool featured = false,
    List<String> images = const [],
    String userName = '小恐龙',
    String userAvatar = 'assets/images/user-avatar-1.jpg',
  }) async {
    final uri = Uri.parse('$baseUrl/api/community/posts');
    final resp = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        if (userName.isNotEmpty) 'X-User-Name': userName,
        if (userAvatar.isNotEmpty) 'X-User-Avatar': userAvatar,
      },
      body: jsonEncode({
        'content': content,
        'featured': featured,
        'images': images,
      }),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException(resp.statusCode, resp.body);
    }

    return CommunityPost.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<CommunityPost> toggleLike({
    required int id,
    String userName = '小恐龙',
  }) async {
    final uri = Uri.parse('$baseUrl/api/community/posts/$id/like');
    final resp = await _client.post(
      uri,
      headers: {
        if (userName.isNotEmpty) 'X-User-Name': userName,
      },
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException(resp.statusCode, resp.body);
    }

    return CommunityPost.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }
}

class HttpException implements Exception {
  const HttpException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'HttpException($statusCode): $body';
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.timeAgo,
    required this.featured,
    required this.images,
    required this.likes,
    required this.comments,
    required this.liked,
    required this.likeUsers,
  });

  final int id;
  final String userName;
  final String userAvatar;
  final String content;
  final String timeAgo;
  final bool featured;
  final List<String> images;
  final int likes;
  final int comments;
  final bool liked;
  final List<String> likeUsers;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'];
    final likeUsersRaw = json['likeUsers'];

    return CommunityPost(
      id: (json['id'] as num).toInt(),
      userName: (json['userName'] ?? '') as String,
      userAvatar: (json['userAvatar'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      timeAgo: (json['timeAgo'] ?? '') as String,
      featured: (json['featured'] ?? false) as bool,
      images: imagesRaw is List ? imagesRaw.map((e) => e.toString()).toList(growable: false) : const [],
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      liked: (json['liked'] ?? false) as bool,
      likeUsers: likeUsersRaw is List ? likeUsersRaw.map((e) => e.toString()).toList(growable: false) : const [],
    );
  }
}
