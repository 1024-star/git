import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../utils/app_logger.dart';
import '../../utils/user_scope.dart';

class MotionApiException implements Exception {
  MotionApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MotionRecord {
  const MotionRecord({
    required this.motionName,
    required this.actualCount,
    required this.targetCount,
    required this.actualTimeSeconds,
    required this.isCountMode,
    required this.createdAtMs,
  });

  final String motionName;
  final int actualCount;
  final int targetCount;
  final int actualTimeSeconds;
  final bool isCountMode;
  final int createdAtMs;

  factory MotionRecord.fromJson(Map<String, dynamic> json) {
    return MotionRecord(
      motionName: (json['motionName'] as String?) ?? '',
      actualCount: ((json['actualCount'] as num?) ?? 0).toInt(),
      targetCount: ((json['targetCount'] as num?) ?? 0).toInt(),
      actualTimeSeconds: ((json['actualTimeSeconds'] as num?) ?? 0).toInt(),
      isCountMode: (json['isCountMode'] ?? false) as bool,
      createdAtMs: ((json['createdAtMs'] as num?) ?? 0).toInt(),
    );
  }
}

class MotionApiClient {
  MotionApiClient({
    http.Client? client,
    this.baseUrl = kApiBaseUrl,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// 训练完成上报一条运动记录（失败静默，不影响本地展示）
  Future<bool> saveRecord({
    required MotionRecord record,
    String? username,
  }) async {
    final finalUser = (username ?? UserScope.username ?? 'anonymous').trim();
    final uri = Uri.parse('$baseUrl/api/motion/save').replace(
      queryParameters: {'username': finalUser},
    );
    final resp = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'motionName': record.motionName,
        'actualCount': record.actualCount,
        'targetCount': record.targetCount,
        'actualTimeSeconds': record.actualTimeSeconds,
        'isCountMode': record.isCountMode,
        'createdAtMs': record.createdAtMs,
      }),
    );

    return resp.statusCode == 201;
  }

  /// 查询用户运动记录（最新在前）
  Future<List<MotionRecord>> listRecords({String? username}) async {
    final uri = Uri.parse('$baseUrl/api/motion/list').replace(
      queryParameters: {
        if (username != null && username.trim().isNotEmpty) 'username': username.trim(),
      },
    );

    final resp = await _client.get(uri);
    final decoded = _tryDecodeJson(resp);

    if (resp.statusCode != 200) {
      final message = _extractMessage(decoded) ?? '请求失败(${resp.statusCode})';
      throw MotionApiException(message);
    }

    if (decoded is! List) {
      throw MotionApiException('响应格式错误');
    }

    return decoded
        .whereType<Map>()
        .map((e) => MotionRecord.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static Object? _tryDecodeJson(http.Response resp) {
    try {
      final text = utf8.decode(resp.bodyBytes);
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    } catch (e, st) {
      AppLogger.e('运动记录API', e, st);
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