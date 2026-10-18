import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../utils/app_logger.dart';

class AiApiException implements Exception {
  AiApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiScript {
  const AiScript({required this.id, required this.generatedAtMs, required this.blocks});

  final String id;
  final int generatedAtMs;
  final List<AiBlock> blocks;

  factory AiScript.fromJson(Map<String, dynamic> json) {
    final blocksRaw = json['blocks'];
    final blocks = <AiBlock>[];
    if (blocksRaw is List) {
      for (final e in blocksRaw) {
        if (e is Map) {
          blocks.add(AiBlock.fromJson(e.cast<String, dynamic>()));
        }
      }
    }
    return AiScript(
      id: (json['id'] as String?) ?? '',
      generatedAtMs: ((json['generatedAtMs'] as num?) ?? 0).toInt(),
      blocks: blocks,
    );
  }
}

class AiBlock {
  const AiBlock({required this.type, required this.delayMs, required this.data});

  final String type;
  final int delayMs;
  final Map<String, dynamic> data;

  factory AiBlock.fromJson(Map<String, dynamic> json) {
    final d = json['data'];
    return AiBlock(
      type: (json['type'] as String?) ?? '',
      delayMs: ((json['delayMs'] as num?) ?? 0).toInt(),
      data: (d is Map ? d.cast<String, dynamic>() : const <String, dynamic>{}),
    );
  }
}

class AiApiClient {
  AiApiClient({
    http.Client? client,
    this.baseUrl = kApiBaseUrl,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<AiScript> fetchScript() async {
    final uri = Uri.parse('$baseUrl/api/ai/script');
    final resp = await _client.get(uri);

    final decoded = _tryDecodeJson(resp);
    if (resp.statusCode != 200) {
      final message = _extractMessage(decoded) ?? '请求失败(${resp.statusCode})';
      throw AiApiException(message);
    }

    if (decoded is! Map<String, dynamic>) {
      throw AiApiException('响应格式错误');
    }

    return AiScript.fromJson(decoded);
  }

  /// 小灵问答：把用户问题发给后端（本地规则引擎），返回回答文本。
  /// 带 12 秒超时，失败抛 AiApiException，避免页面无限等待。
  Future<String> ask(String question) async {
    final uri = Uri.parse('$baseUrl/api/ai/chat/ask');
    final resp = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({'question': question}),
        )
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () {
            AppLogger.e('AI助手API', '问答请求超时（12s）');
            throw AiApiException('小灵响应超时，请重试');
          },
        );
    final decoded = _tryDecodeJson(resp);
    if (resp.statusCode != 200) {
      throw AiApiException(_extractMessage(decoded) ?? '请求失败(${resp.statusCode})');
    }
    if (decoded is! Map<String, dynamic>) throw AiApiException('响应格式错误');
    if (decoded['ok'] != true) {
      throw AiApiException((decoded['answer'] as String?) ?? '小灵暂时无法回答');
    }
    return ((decoded['answer'] as String?) ?? '').trim();
  }

  static Object? _tryDecodeJson(http.Response resp) {
    try {
      final text = utf8.decode(resp.bodyBytes);
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    } catch (e, st) {
      AppLogger.e('AI助手API', e, st);
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
