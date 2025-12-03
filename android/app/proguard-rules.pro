# Flutter WebView ProGuard Rules

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep WebView classes
-keep class android.webkit.** { *; }
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
    public void *(android.webkit.WebView, java.lang.String);
}

# Keep JavaScript interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep Gson (if used)
-keepattributes Signature
-keepattributes *Annotation*

# Keep connectivity_plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Keep permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }
