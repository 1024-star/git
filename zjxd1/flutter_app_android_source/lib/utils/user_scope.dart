import 'dart:core';

class UserScope {
  static String? _username;
  static String? _nickname;
  static String? _avatar;
  static String? _token;
  static int? _expiresAtMs;
  static bool _isDemo = false;

  static String? get username => _username;
  static String? get nickname => _nickname;
  static String? get avatar => _avatar;
  static String? get token => _token;
  static int? get expiresAtMs => _expiresAtMs;
  static bool get isDemo => _isDemo;
  static bool get isLoggedIn => !_isDemo && (_token != null && _token!.isNotEmpty);

  static void setUser({
    required String username,
    String? nickname,
    String? avatar,
    String? token,
    int? expiresAtMs,
    bool isDemo = false,
  }) {
    _username = username;
    _nickname = nickname;
    _avatar = avatar;
    _token = token;
    _expiresAtMs = expiresAtMs;
    _isDemo = isDemo;
  }

  static void clear() {
    _username = null;
    _nickname = null;
    _avatar = null;
    _token = null;
    _expiresAtMs = null;
    _isDemo = false;
  }

  static String get exportVideoDir {
    final u = (_username ?? 'anonymous').trim();
    return '/sdcard/Movies/flutter_app_video/${_sanitize(u)}';
  }

  static String _sanitize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'anonymous';

    final buf = StringBuffer();
    for (final codeUnit in trimmed.codeUnits) {
      final ch = String.fromCharCode(codeUnit);
      final isAZ = codeUnit >= 65 && codeUnit <= 90;
      final isaz = codeUnit >= 97 && codeUnit <= 122;
      final is09 = codeUnit >= 48 && codeUnit <= 57;
      if (isAZ || isaz || is09 || ch == '_' || ch == '-') {
        buf.write(ch);
      } else {
        buf.write('_');
      }
    }
    return buf.toString();
  }
}
