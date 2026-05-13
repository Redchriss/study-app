# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# GraphQL
-keep class com.apollographql.apollo.** { *; }
-dontwarn com.apollographql.apollo.**

# Riverpod
-keep class ** extends androidx.lifecycle.ViewModel
-keep class ** extends androidx.lifecycle.AndroidViewModel

# Secure storage
-keep class com.it_nomads_fluttersecurestorage.** { *; }
-dontwarn com.it_nomads_fluttersecurestorage.**

# Firebase
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.firebase.**

# Sentry
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
