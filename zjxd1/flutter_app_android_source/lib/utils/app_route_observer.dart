import 'package:flutter/widgets.dart';

/// 全局路由观察者：供首页等页面感知"被其他页面遮挡/恢复"，
/// 用于在不可见时暂停常驻无限动画，降低 UI 线程与 GPU 空转。
/// 在 main.dart 的 MaterialApp.navigatorObservers 中注册。
final RouteObserver<ModalRoute<void>> appRouteObserver = RouteObserver<ModalRoute<void>>();
