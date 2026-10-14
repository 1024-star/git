import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../utils/app_logger.dart';

class AuthApiException implements Exception {
  AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
    this.lastLoginAtMs,
  });

  final int id;
  final String username;
  final String nickname;
  final String avatar;
  final int? lastLoginAtMs;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      username: (json['username'] as String?) ?? '',
      nickname: (json['nickname'] as String?) ?? '',
      avatar: (json['avatar'] as String?) ?? '',
      lastLoginAtMs: (json['lastLoginAtMs'] as num?)?.toInt(),
    );
  }
}

class AuthResponse {
  const AuthResponse({
    required this.user,
    required this.token,
    this.expiresAtMs,
  });

  final AuthUser user;
  final String token;
  final int? expiresAtMs;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: AuthUser.fromJson((json['user'] as Map).cast<String, dynamic>()),
      token: (json['token'] as String?) ?? '',
      expiresAtMs: (json['expiresAtMs'] as num?)?.toInt(),
    );
  }
}

class AuthApiClient {
  AuthApiClient({
    http.Client? client,
    this.baseUrl = kApiBaseUrl,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<AuthResponse> login({required String username, required String password}) {
    return _post(
      path: '/api/auth/login',
      body: {
        'username': username,
        'password': password,
      },
      expectedStatusCodes: const {200},
    );
  }

  Future<AuthResponse> register({required String username, required String password}) {
    return _post(
      path: '/api/auth/register',
      body: {
        'username': username,
        'password': password,
      },
      expectedStatusCodes: const {201},
    );
  }

  Future<AuthResponse> _post({
    required String path,
    required Map<String, dynamic> body,
    required Set<int> expectedStatusCodes,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final resp = await _client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode(body),
    );

    final decoded = _tryDecodeJson(resp);
    if (!expectedStatusCodes.contains(resp.statusCode)) {
      final message = _extractMessage(decoded) ?? '请求失败(${resp.statusCode})';
      throw AuthApiException(message);
    }

    if (decoded is! Map<String, dynamic>) {
      throw AuthApiException('响应格式错误');
    }
    return AuthResponse.fromJson(decoded);
  }

  static Object? _tryDecodeJson(http.Response resp) {
    try {
      final text = utf8.decode(resp.bodyBytes);
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    } catch (e, st) {
      AppLogger.e('认证API', e, st);
      return null;
    }
  }

  static String? _extractMessage(Object? decoded) {
    if (decoded is Map) {
      final m = decoded['message'];
      if (m is String && m.trim().isNotEmpty) return m;
    }
    return null;
  }
}
