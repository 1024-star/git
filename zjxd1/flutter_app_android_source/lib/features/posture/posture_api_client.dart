import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../utils/app_logger.dart';

class PostureApiException implements Exception {
  PostureApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PostureReport {
  const PostureReport({
    required this.score,
    required this.severity,
    required this.curveShape,
    required this.shoulderTilt,
    required this.pelvicTilt,
    required this.trunkShiftPercent,
    required this.cobbAngle,
    required this.summary,
    required this.riskFindings,
    required this.advice,
    required this.generatedAtMs,
    this.stepIndex,
    this.stepName,
    this.frontImagePath,
    this.sideImagePath,
  });

  final int score;
  final String severity;
  final String curveShape;
  final double shoulderTilt;
  final double pelvicTilt;
  final double trunkShiftPercent;
  final double cobbAngle;
  final String summary;
  final List<String> riskFindings;
  final List<String> advice;
  final int generatedAtMs;

  /// 存储记录专用字段（/api/posture/list 返回）
  final int? stepIndex;
  final String? stepName;
  final String? frontImagePath;
  final String? sideImagePath;

  factory PostureReport.fromJson(Map<String, dynamic> json) {
    List<String> _asStringList(Object? v) {
      if (v is List) {
        return v.whereType<Object?>().map((e) => e?.toString() ?? '').where((s) => s.trim().isNotEmpty).toList();
      }
      return const [];
    }

    return PostureReport(
      score: ((json['score'] as num?) ?? 0).toInt(),
      severity: (json['severity'] as String?) ?? '',
      curveShape: (json['curveShape'] as String?) ?? '',
      shoulderTilt: ((json['shoulderTilt'] as num?) ?? 0).toDouble(),
      pelvicTilt: ((json['pelvicTilt'] as num?) ?? 0).toDouble(),
      trunkShiftPercent: ((json['trunkShiftPercent'] as num?) ?? 0).toDouble(),
      cobbAngle: ((json['cobbAngle'] as num?) ?? 0).toDouble(),
      summary: (json['summary'] as String?) ?? '',
      riskFindings: _asStringList(json['riskFindings']),
      advice: _asStringList(json['advice']),
      generatedAtMs: ((json['generatedAtMs'] as num?) ?? 0).toInt(),
      stepIndex: (json['stepIndex'] as num?)?.toInt(),
      stepName: json['stepName'] as String?,
      frontImagePath: json['frontImagePath'] as String?,
      sideImagePath: json['sideImagePath'] as String?,
    );
  }
}

class PostureApiClient {
  PostureApiClient({
    http.Client? client,
    this.baseUrl = kApiBaseUrl,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<PostureReport> fetchReport({required int stepIndex, required String stepName}) async {
    final uri = Uri.parse('$baseUrl/api/posture/report').replace(
      queryParameters: {
        'stepIndex': stepIndex.toString(),
        'stepName': stepName,
      },
    );

    final resp = await _client.get(uri);
    final decoded = _tryDecodeJson(resp);

    if (resp.statusCode != 200) {
      final message = _extractMessage(decoded) ?? '请求失败(${resp.statusCode})';
      throw PostureApiException(message);
    }

    if (decoded is! Map<String, dynamic>) {
      throw PostureApiException('响应格式错误');
    }
    return PostureReport.fromJson(decoded);
  }

  /// 检测完成后把报告上报到后端存储（失败静默，不影响本地展示）
  Future<bool> saveReport({
    required String username,
    required int stepIndex,
    required String stepName,
    required PostureReport report,
    String? frontImagePath,
    String? sideImagePath,
  }) async {
    final uri = Uri.parse('$baseUrl/api/posture/save');
    final resp = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'username': username,
        'stepIndex': stepIndex,
        'stepName': stepName,
        'score': report.score,
        'severity': report.severity,
        'curveShape': report.curveShape,
        'shoulderTilt': report.shoulderTilt,
        'pelvicTilt': report.pelvicTilt,
        'trunkShiftPercent': report.trunkShiftPercent,
        'cobbAngle': report.cobbAngle,
        'summary': report.summary,
        'frontImagePath': frontImagePath ?? '',
        'sideImagePath': sideImagePath ?? '',
        'generatedAtMs': report.generatedAtMs,
      }),
    );

    return resp.statusCode == 201;
  }

  /// 报告中心：查询已存储的检测记录（最新在前）
  Future<List<PostureReport>> listReports({String? username}) async {
    final uri = Uri.parse('$baseUrl/api/posture/list').replace(
      queryParameters: {
        if (username != null && username.trim().isNotEmpty) 'username': username.trim(),
      },
    );

    final resp = await _client.get(uri);
    final decoded = _tryDecodeJson(resp);

    if (resp.statusCode != 200) {
      final message = _extractMessage(decoded) ?? '请求失败(${resp.statusCode})';
      throw PostureApiException(message);
    }

    if (decoded is! List) {
      throw PostureApiException('响应格式错误');
    }

    return decoded
        .whereType<Map>()
        .map((e) => PostureReport.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// 脊柱筛查两张图片上传到后端（后端再 SFTP 转存到远程服务器，
  /// 固定文件名 back/Backbend 覆盖旧图，扩展名按图片实际保存格式 .jpg）。
  Future<bool> uploadImages({
    required String backImagePath,
    required String backbendImagePath,
  }) async {
    final uri = Uri.parse('$baseUrl/api/spine/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('back', backImagePath))
      ..files.add(await http.MultipartFile.fromPath('backbend', backbendImagePath));

    final resp = await request.send().timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        AppLogger.e('体态API', '脊柱筛查图片上传超时');
        throw TimeoutException('图片上传超时');
      },
    );

    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  static Object? _tryDecodeJson(http.Response resp) {
    try {
      final text = utf8.decode(resp.bodyBytes);
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    } catch (e, st) {
      AppLogger.e('体态API', e, st);
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
