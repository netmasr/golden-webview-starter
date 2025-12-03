import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  final config = AppConfig.instance;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentUrl = '';
  double _loadingProgress = 0;
  int _currentNavIndex = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _checkConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasOffline = _isOffline;
      _isOffline = results.isEmpty || results.contains(ConnectivityResult.none);

      if (wasOffline && !_isOffline && _hasError) {
        // Connection restored, reload
        _reload();
      }

      if (mounted) setState(() {});
    });
  }

  void _initWebView() {
    final siteUrl = config.siteUrl.isNotEmpty
        ? config.siteUrl
        : 'https://example.com';

    _currentUrl = siteUrl;

    _controller = WebViewController()
      ..setJavaScriptMode(config.enableJavaScript
          ? JavaScriptMode.unrestricted
          : JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
                _currentUrl = url;
                _loadingProgress = 0;
              });
            }
          },
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100;
              });
            }
          },
          onPageFinished: (url) async {
            if (mounted) {
              final canGoBack = await _controller.canGoBack();
              final canGoForward = await _controller.canGoForward();
              setState(() {
                _isLoading = false;
                _currentUrl = url;
                _canGoBack = canGoBack;
                _canGoForward = canGoForward;
              });
            }
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description} (${error.errorCode})');
            
            // Ignore minor errors that don't affect page loading
            if (error.errorCode == -1 || error.errorCode == -6) {
              // -1: Generic error, -6: Connection refused
              // These might be for sub-resources, not the main page
              return;
            }

            if (mounted) {
              setState(() {
                _hasError = true;
                _isLoading = false;
                _errorMessage = _getErrorMessage(error.errorCode, error.description);
              });
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            
            // Handle external links
            if (_shouldOpenExternally(url)) {
              _launchExternalUrl(url);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
          onHttpError: (error) {
            debugPrint('HTTP error: ${error.response?.statusCode}');
            // Don't show error for HTTP errors, let the page handle it
          },
        ),
      );

    // Set user agent if specified
    if (config.userAgent.isNotEmpty) {
      _controller.setUserAgent(config.userAgent);
    } else {
      // Use a modern mobile user agent
      _controller.setUserAgent(
        Platform.isIOS
            ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
            : 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      );
    }

    // Clear cache if configured
    if (config.clearCacheOnStart) {
      _clearCache();
    }

    // Load the URL
    _loadUrl(siteUrl);
  }

  Future<void> _clearCache() async {
    try {
      await _controller.clearCache();
      await _controller.clearLocalStorage();
      debugPrint('Cache cleared successfully');
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  Future<void> _loadUrl(String url) async {
    try {
      // Add timestamp to prevent caching issues
      final uri = Uri.parse(url);
      final newUri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      
      await _controller.loadRequest(newUri);
    } catch (e) {
      debugPrint('Failed to load URL: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'فشل في تحميل الصفحة: $e';
        });
      }
    }
  }

  bool _shouldOpenExternally(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Open external links in browser
    final siteHost = Uri.tryParse(config.siteUrl)?.host ?? '';
    if (uri.host.isNotEmpty && uri.host != siteHost) {
      // Check if it's a common external link
      final externalSchemes = ['tel', 'mailto', 'sms', 'whatsapp'];
      if (externalSchemes.contains(uri.scheme)) {
        return true;
      }
      
      // Check for common external domains
      final externalDomains = [
        'play.google.com',
        'apps.apple.com',
        'facebook.com',
        'twitter.com',
        'instagram.com',
        'youtube.com',
        'wa.me',
      ];
      if (externalDomains.any((d) => uri.host.contains(d))) {
        return true;
      }
    }

    // Handle special schemes
    if (!['http', 'https'].contains(uri.scheme)) {
      return true;
    }

    return false;
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to launch URL: $e');
    }
  }

  String _getErrorMessage(int errorCode, String description) {
    switch (errorCode) {
      case -2:
        return 'لا يوجد اتصال بالإنترنت';
      case -6:
        return 'تعذر الاتصال بالخادم';
      case -8:
        return 'انتهت مهلة الاتصال';
      case -11:
        return 'الصفحة غير موجودة';
      default:
        return description.isNotEmpty ? description : 'حدث خطأ غير متوقع';
    }
  }

  Future<void> _reload() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _errorMessage = '';
    });
    
    // Clear cache before reload to fix caching issues
    await _clearCache();
    
    // Reload with fresh URL
    await _loadUrl(_currentUrl.isNotEmpty ? _currentUrl : config.siteUrl);
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  Future<void> _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
    }
  }

  void _navigateToNavItem(int index) {
    if (index < config.navItems.length) {
      final item = config.navItems[index];
      setState(() {
        _currentNavIndex = index;
      });
      _loadUrl(item.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _canGoBack) {
          await _goBack();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNav(),
        drawer: config.navType == 'drawer' ? _buildDrawer() : null,
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    // Hide app bar for classic navigation without title
    if (config.navType == 'classic') {
      return null;
    }

    return AppBar(
      title: Text(config.appName),
      actions: [
        if (_canGoBack)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
        if (_canGoForward)
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _goForward,
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _reload,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isOffline && _hasError) {
      return ErrorView(
        message: 'لا يوجد اتصال بالإنترنت',
        icon: Icons.wifi_off,
        onRetry: _reload,
      );
    }

    if (_hasError) {
      return ErrorView(
        message: _errorMessage,
        onRetry: _reload,
      );
    }

    return Stack(
      children: [
        // WebView
        config.pullToRefresh
            ? RefreshIndicator(
                onRefresh: _reload,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height -
                        (config.navType == 'bottom-tabs' ? 80 : 0) -
                        MediaQuery.of(context).padding.top,
                    child: WebViewWidget(controller: _controller),
                  ),
                ),
              )
            : WebViewWidget(controller: _controller),

        // Loading indicator
        if (_isLoading)
          LoadingView(progress: _loadingProgress),
      ],
    );
  }

  Widget? _buildBottomNav() {
    if (config.navType != 'bottom-tabs' || config.navItems.isEmpty) {
      return null;
    }

    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      selectedItemColor: config.parseThemeColor(),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: _navigateToNavItem,
      items: config.navItems.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.iconData),
          label: item.title,
        );
      }).toList(),
    );
  }

  Widget? _buildDrawer() {
    if (config.navType != 'drawer' || config.navItems.isEmpty) {
      return null;
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: config.parseThemeColor(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (config.splashLogoImageUrl.isNotEmpty)
                  Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        config.splashLogoImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.web),
                      ),
                    ),
                  ),
                Text(
                  config.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...config.navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return ListTile(
              leading: Icon(item.iconData),
              title: Text(item.title),
              selected: index == _currentNavIndex,
              selectedColor: config.parseThemeColor(),
              onTap: () {
                Navigator.pop(context);
                _navigateToNavItem(index);
              },
            );
          }),
        ],
      ),
    );
  }
}
