import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'webview_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final config = AppConfig.instance;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Navigate to WebView after delay
    Future.delayed(Duration(seconds: config.splashDelay), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WebViewScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;
    final bgColor = config.parseSplashBgColor();
    final isLightText = config.splashTextTheme == 'light';
    final textColor = isLightText ? Colors.white : Colors.black87;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: config.splashBgMode == 'color' ? bgColor : null,
          image: config.splashBgMode == 'image' &&
                  config.splashBackgroundImageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(config.splashBackgroundImageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  if (config.splashDisplayLogo &&
                      config.splashLogoImageUrl.isNotEmpty)
                    Container(
                      width: 150,
                      height: 150,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          config.splashLogoImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: config.parseThemeColor(),
                            child: Icon(
                              Icons.web,
                              size: 80,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (config.splashDisplayLogo)
                    Container(
                      width: 120,
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: config.parseThemeColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.web,
                        size: 60,
                        color: textColor,
                      ),
                    ),

                  // App Name
                  Text(
                    config.appName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Tagline
                  if (config.splashTagline.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        config.splashTagline,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Loading indicator
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        textColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
