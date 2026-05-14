# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Dart core
-keep class dart:** { *; }
-keep class com.dart.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keep class * extends java.util.ListResourceBundle { *; }

# Sentry
-keep class io.sentry.** { *; }
-keep class io.sentry.flutter.** { *; }
-keep class io.sentry.android.** { *; }

# GraphQL
-keep class com.apollographql.apollo.** { *; }
-dontwarn com.apollographql.apollo.**

# Secure storage
-keep class com.it_nomads_fluttersecurestorage.** { *; }
-dontwarn com.it_nomads_fluttersecurestorage.**

# Riverpod / lifecycle
-keep class * extends androidx.lifecycle.ViewModel { *; }
-keep class * extends androidx.lifecycle.AndroidViewModel { *; }
-keep class androidx.lifecycle.** { *; }
-keep class * implements androidx.lifecycle.LifecycleObserver { *; }

# YouTube player (WebView)
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }

# Play Core
-dontwarn com.google.android.play.core.**

# Method channels (all plugins use these reflectively)
-keep class **.Flutter** { *; }
-keep class **.MethodCallHandler { *; }
-keep class **.MethodChannel** { *; }

# Keep all native methods
-keepclasseswithmembernames class * { native <methods>; }

# General AndroidX
-keep class androidx.** { *; }
-keep class * extends androidx.** { *; }
