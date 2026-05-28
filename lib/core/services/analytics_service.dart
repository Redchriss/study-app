import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class AnalyticsService {
  static FirebaseAnalytics? _instance;
  static bool get _isEnabled => AppConfig.firebaseEnabled;

  static FirebaseAnalytics get instance {
    if (_instance == null && _isEnabled) {
      throw Exception(
          'Firebase Analytics not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  static Future<void> initialize() async {
    if (!_isEnabled) return;

    try {
      await Firebase.initializeApp().timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw TimeoutException('Firebase.initializeApp'),
      );
      _instance = FirebaseAnalytics.instance;
      await _instance?.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      debugPrint('Failed to initialize Firebase Analytics: $e');
    }
  }

  static Future<void> logEvent(String name,
      {Map<String, Object>? parameters}) async {
    if (!_isEnabled || _instance == null) return;
    try {
      await _instance!.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Failed to log event: $e');
    }
  }

  static Future<void> logScreenView(String screenName) async {
    if (!_isEnabled || _instance == null) return;
    try {
      await _instance!.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('Failed to log screen view: $e');
    }
  }

  static Future<void> logLogin(String loginMethod) async {
    if (!_isEnabled || _instance == null) return;
    try {
      await _instance!.logLogin(loginMethod: loginMethod);
    } catch (e) {
      debugPrint('Failed to log login: $e');
    }
  }

  static Future<void> logSignUp(String signUpMethod) async {
    if (!_isEnabled || _instance == null) return;
    try {
      await _instance!.logSignUp(signUpMethod: signUpMethod);
    } catch (e) {
      debugPrint('Failed to log sign up: $e');
    }
  }

  static Future<void> setUserId(String userId) async {
    if (!_isEnabled || _instance == null) return;
    try {
      await _instance!.setUserId(id: userId);
    } catch (e) {
      debugPrint('Failed to set user id: $e');
    }
  }

  static Future<void> setUserProperty(String name, String? value) async {
    if (!_isEnabled || _instance == null) return;
    try {
      await _instance!.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Failed to set user property: $e');
    }
  }
}
