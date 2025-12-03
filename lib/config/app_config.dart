import 'dart:convert';
import 'package:flutter/services.dart';

/// Application configuration loaded from assets or dart-define
class AppConfig {
  static final AppConfig instance = AppConfig._();
  AppConfig._();

  // Core settings
  String appName = 'Golden WebView App';
  String siteUrl = '';
  String appId = 'com.example.goldenwebview';
  String userAgent = '';
  String themeColor = '#2196F3';
  String orientation = 'system'; // portrait, landscape, system

  // Splash settings
  String splashBgMode = 'color'; // color, image
  String splashBgColor = '#2196F3';
  String splashTagline = '';
  String splashTextTheme = 'light'; // light, dark
  int splashDelay = 3;
  bool splashDisplayLogo = true;
  String splashBackgroundImageUrl = '';
  String splashLogoImageUrl = '';

  // Navigation settings
  String navType = 'classic'; // classic, bottom-tabs, drawer
  List<NavItem> navItems = [];

  // Permissions
  bool permGeolocation = false;
  bool permCamera = false;
  bool permMicrophone = false;

  // Features
  bool pullToRefresh = true;
  bool enableJavaScript = true;
  bool enableZoom = false;
  bool clearCacheOnStart = false;

  /// Load configuration from assets/config/app_config.json
  /// Falls back to dart-define values if file not found
  Future<void> load() async {
    // First, try to load from dart-define (Codemagic build)
    _loadFromDartDefine();

    // Then try to load from JSON file (local development)
    try {
      final jsonString = await rootBundle.loadString('assets/config/app_config.json');
      final Map<String, dynamic> json = jsonDecode(jsonString);
      _loadFromJson(json);
    } catch (e) {
      // File not found or invalid, use dart-define values
      debugPrint('Config file not found, using dart-define values: $e');
    }
  }

  void _loadFromDartDefine() {
    appName = const String.fromEnvironment('GWA_APP_NAME', defaultValue: 'Golden WebView App');
    siteUrl = const String.fromEnvironment('GWA_SITE_URL', defaultValue: '');
    appId = const String.fromEnvironment('GWA_APP_ID', defaultValue: 'com.example.goldenwebview');
    userAgent = const String.fromEnvironment('GWA_USER_AGENT', defaultValue: '');
    themeColor = const String.fromEnvironment('GWA_THEME_COLOR', defaultValue: '#2196F3');
    orientation = const String.fromEnvironment('GWA_PLATFORM_ORIENTATION', defaultValue: 'system');

    // Splash
    splashBgMode = const String.fromEnvironment('GWA_SPLASH_BG_MODE', defaultValue: 'color');
    splashBgColor = const String.fromEnvironment('GWA_SPLASH_BG_COLOR', defaultValue: '#2196F3');
    splashTagline = const String.fromEnvironment('GWA_SPLASH_TAGLINE', defaultValue: '');
    splashTextTheme = const String.fromEnvironment('GWA_SPLASH_TEXT_THEME', defaultValue: 'light');
    splashDelay = int.tryParse(const String.fromEnvironment('GWA_SPLASH_DELAY', defaultValue: '3')) ?? 3;
    splashDisplayLogo = const String.fromEnvironment('GWA_SPLASH_DISPLAY_LOGO', defaultValue: '1') == '1';
    splashBackgroundImageUrl = const String.fromEnvironment('GWA_SPLASH_BACKGROUND_IMAGE_URL', defaultValue: '');
    splashLogoImageUrl = const String.fromEnvironment('GWA_SPLASH_LOGO_IMAGE_URL', defaultValue: '');

    // Navigation
    navType = const String.fromEnvironment('GWA_NAV_TYPE', defaultValue: 'classic');
    final navItemsB64 = const String.fromEnvironment('GWA_NAV_ITEMS_B64', defaultValue: '');
    if (navItemsB64.isNotEmpty) {
      try {
        final decoded = utf8.decode(base64Decode(navItemsB64));
        final List<dynamic> items = jsonDecode(decoded);
        navItems = items.map((e) => NavItem.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Failed to parse nav items: $e');
      }
    }
  }

  void _loadFromJson(Map<String, dynamic> json) {
    appName = json['app_name'] ?? json['name'] ?? appName;
    siteUrl = json['site_url'] ?? siteUrl;
    appId = json['app_id'] ?? appId;
    userAgent = json['user_agent'] ?? userAgent;
    themeColor = json['theme_color'] ?? themeColor;
    orientation = json['orientation'] ?? orientation;

    // Splash
    splashBgMode = json['splash_bg_mode'] ?? json['splash_background_mode'] ?? splashBgMode;
    splashBgColor = json['splash_bg_color'] ?? splashBgColor;
    splashTagline = json['splash_tagline'] ?? splashTagline;
    splashTextTheme = json['splash_text_theme'] ?? splashTextTheme;
    splashDelay = json['splash_delay'] ?? splashDelay;
    splashDisplayLogo = json['splash_display_logo'] ?? splashDisplayLogo;
    splashBackgroundImageUrl = json['splash_background_image'] ?? splashBackgroundImageUrl;
    splashLogoImageUrl = json['splash_logo_image'] ?? splashLogoImageUrl;

    // Navigation
    navType = json['nav_type'] ?? navType;
    if (json['nav_items'] != null) {
      if (json['nav_items'] is String) {
        try {
          final List<dynamic> items = jsonDecode(json['nav_items']);
          navItems = items.map((e) => NavItem.fromJson(e)).toList();
        } catch (e) {
          debugPrint('Failed to parse nav items from string: $e');
        }
      } else if (json['nav_items'] is List) {
        navItems = (json['nav_items'] as List).map((e) => NavItem.fromJson(e)).toList();
      }
    }

    // Permissions
    final perms = json['permissions'];
    if (perms is Map) {
      permGeolocation = perms['geolocation'] ?? permGeolocation;
      permCamera = perms['camera'] ?? permCamera;
      permMicrophone = perms['microphone'] ?? permMicrophone;
    }

    // Features
    pullToRefresh = json['pull_to_refresh'] ?? pullToRefresh;
    enableJavaScript = json['enable_javascript'] ?? enableJavaScript;
    enableZoom = json['enable_zoom'] ?? enableZoom;
    clearCacheOnStart = json['clear_cache_on_start'] ?? clearCacheOnStart;
  }

  /// Parse hex color string to Color
  Color parseThemeColor() {
    try {
      String hex = themeColor.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return const Color(0xFF2196F3);
    }
  }

  Color parseSplashBgColor() {
    try {
      String hex = splashBgColor.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return parseThemeColor();
    }
  }
}

/// Navigation item model
class NavItem {
  final String title;
  final String url;
  final String icon;

  NavItem({required this.title, required this.url, this.icon = 'home'});

  factory NavItem.fromJson(Map<String, dynamic> json) {
    return NavItem(
      title: json['title'] ?? json['label'] ?? 'Item',
      url: json['url'] ?? json['href'] ?? '',
      icon: json['icon'] ?? 'home',
    );
  }

  IconData get iconData {
    switch (icon.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'search':
        return Icons.search;
      case 'favorite':
      case 'favorites':
        return Icons.favorite;
      case 'person':
      case 'profile':
      case 'account':
        return Icons.person;
      case 'settings':
        return Icons.settings;
      case 'shopping_cart':
      case 'cart':
        return Icons.shopping_cart;
      case 'category':
      case 'categories':
        return Icons.category;
      case 'info':
        return Icons.info;
      case 'contact':
      case 'phone':
        return Icons.phone;
      case 'email':
      case 'mail':
        return Icons.email;
      case 'menu':
        return Icons.menu;
      case 'list':
        return Icons.list;
      case 'grid':
        return Icons.grid_view;
      case 'notifications':
        return Icons.notifications;
      default:
        return Icons.circle;
    }
  }
}

void logDebug(String message) {
  // ignore: avoid_print
  print('[GoldenWebView] $message');
}
