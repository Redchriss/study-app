import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static String? _fcmToken;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _requestPermission();
      await _getToken();
      _configureHandlers();
    } catch (e, st) {
      debugPrint('PushNotificationService init failed: $e');
      debugPrint('$st');
    }
  }

  static Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');
  }

  static Future<void> _getToken() async {
    _fcmToken = await _fcm.getToken();
    debugPrint('FCM token: $_fcmToken');
    _fcm.onTokenRefresh.listen((token) {
      _fcmToken = token;
    });
  }

  static void _configureHandlers() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'yaza_push',
          'Yaza Push Notifications',
          channelDescription: 'Push notifications from Yaza',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  static void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('FCM notification opened: ${message.messageId}');
  }

  static String? get token => _fcmToken;
  static bool get isInitialized => _initialized;
}
