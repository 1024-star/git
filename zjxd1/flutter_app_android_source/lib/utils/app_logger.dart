import 'package:flutter/foundation.dart';

/// 全局日志工具：统一格式输出到控制台（IDE 运行控制台 / `flutter run` 输出 / adb logcat 均可见）。
///
/// 约定：任何 catch 到异常的地方都必须调用 [e] 输出，禁止静默吞掉；
/// tag 用模块名（如 '登录'、'AI助手'、'相机'），方便过滤定位。
class AppLogger {
  AppLogger._();

  /// 【错误日志】catch 到异常时调用；拿到堆栈时一并输出，便于定位出错位置
  static void e(String tag, Object error, [StackTrace? stackTrace]) {
    debugPrint('[$tag][ERROR] $error');
    if (stackTrace != null) {
      debugPrint('[$tag][STACK] $stackTrace');
    }
  }

  /// 【警告日志】失败但已兜底、不影响主流程的场景
  static void w(String tag, Object message) {
    debugPrint('[$tag][WARN] $message');
  }

  /// 【信息日志】关键流程节点（请求发起、状态切换等）
  static void i(String tag, Object message) {
    debugPrint('[$tag][INFO] $message');
  }
}
