import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';



import 'features/auth/login_page.dart';

import 'utils/app_logger.dart';

import 'utils/app_route_observer.dart';

export 'utils/app_route_observer.dart';



void main() {

  WidgetsFlutterBinding.ensureInitialized();

  // 【全局异常兜底】让未捕获的报错在控制台可见（含 flutter run 控制台 / adb logcat），
  // 避免异常被框架默认处理后无上下文或被静默丢失
  FlutterError.onError = (details) {
    AppLogger.e('Flutter框架', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('未捕获异常', error, stack);
    return true;
  };

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(

    const SystemUiOverlayStyle(

      statusBarColor: Colors.transparent,

      statusBarIconBrightness: Brightness.dark,

      statusBarBrightness: Brightness.light,

      systemNavigationBarColor: Colors.white,

      systemNavigationBarIconBrightness: Brightness.dark,

    ),

  );

  runApp(const MyApp());

}



class MyApp extends StatelessWidget {

  const MyApp({super.key});



  // This widget is the root of your application.

  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'Flutter Demo',

      builder: (context, child) {

        return _NoSnackBarScaffoldMessenger(

          child: child ?? const SizedBox.shrink(),

        );

      },

      theme: ThemeData(

        // This is the theme of your application.

        //

        // TRY THIS: Try running your application with "flutter run". You'll see

        // the application has a purple toolbar. Then, without quitting the app,

        // try changing the seedColor in the colorScheme below to Colors.green

        // and then invoke "hot reload" (save your changes or press the "hot

        // reload" button in a Flutter-supported IDE, or press "r" if you used

        // the command line to start the app).

        //

        // Notice that the counter didn't reset back to zero; the application

        // state is not lost during the reload. To reset the state, use hot

        // restart instead.

        //

        // This works for code too, not just values: Most code changes can be

        // tested with just a hot reload.

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),

      ),

      home: const LoginPage(),

      navigatorObservers: [appRouteObserver],

    );

  }

}



class _NoSnackBarScaffoldMessenger extends ScaffoldMessenger {

  const _NoSnackBarScaffoldMessenger({required super.child});



  @override

  ScaffoldMessengerState createState() => _NoSnackBarScaffoldMessengerState();

}



class _NoSnackBarScaffoldMessengerState extends ScaffoldMessengerState {

  @override

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    SnackBar snackBar, {
    AnimationStyle? snackBarAnimationStyle,
  }) {

    return super.showSnackBar(

      const SnackBar(

        content: SizedBox.shrink(),

        duration: Duration(milliseconds: 1),

        backgroundColor: Colors.transparent,

        elevation: 0,

        behavior: SnackBarBehavior.floating,

        margin: EdgeInsets.zero,

        padding: EdgeInsets.zero,

      ),

      snackBarAnimationStyle: snackBarAnimationStyle,
    );

  }

}

