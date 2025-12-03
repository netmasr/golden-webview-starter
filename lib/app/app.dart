import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../screens/splash_screen.dart';
import '../screens/webview_screen.dart';

class GoldenWebViewApp extends StatelessWidget {
  const GoldenWebViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;
    final themeColor = config.parseThemeColor();

    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeColor),
        useMaterial3: true,
        primaryColor: themeColor,
        appBarTheme: AppBarTheme(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: config.splashDelay > 0
          ? const SplashScreen()
          : const WebViewScreen(),
    );
  }
}
