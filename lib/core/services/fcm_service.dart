import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

/// FCMService — Firebase Cloud Messaging + Local Notifications for Debity
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'debity_high_importance',
    'Debity Notifications',
    description: 'Installment due date alerts',
    importance: Importance.high,
  );

  static const _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'debity_high_importance',
      'Debity Notifications',
      channelDescription: 'Installment due date alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
  );

  /// Call once in main() after Firebase.initializeApp()
  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS / Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Init local notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initSettings);

    // Show foreground FCM messages as local notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground: ${message.notification?.title}');
      final n = message.notification;
      if (n != null) {
        _localNotifications.show(
          n.hashCode,
          n.title,
          n.body,
          _notifDetails,
        );
      }
    });

    // Save token to Supabase
    final token = await getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await saveFcmTokenToSupabase(token);
    }
  }

  /// Returns the current device FCM token
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('FCM getToken error: $e');
      return null;
    }
  }

  /// Save/upsert the FCM token to the user_fcm_tokens Supabase table
  static Future<void> saveFcmTokenToSupabase(String token) async {
    try {
      final platform = Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Unknown';
      await Supabase.instance.client.from('user_fcm_tokens').upsert(
        {
          'token': token,
          'platform': platform,
          'device_name': 'Unknown',
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'token',
      );
      debugPrint('FCM token saved to Supabase');
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Send an immediate local test notification (no Firebase needed)
  static Future<void> showTestNotification({
    String title = 'إشعار تجريبي - ديبتي',
    String body = 'الإشعارات تعمل بشكل صحيح ✓',
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _notifDetails,
    );
  }

  /// Show a local notification for a due installment
  static Future<void> showDueNotification({
    required String customerName,
    required String amount,
    required String dueDate,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'قسط مستحق قريباً',
      'العميل $customerName: $amount - تاريخ الاستحقاق $dueDate',
      _notifDetails,
    );
  }

  /// Check if the app has notification permission granted
  static Future<bool> hasPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Request notification permission — returns true if granted
  static Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Deactivate this device's FCM token on logout
  static Future<void> deactivateToken() async {
    try {
      final token = await getToken();
      if (token != null) {
        await Supabase.instance.client
            .from('user_fcm_tokens')
            .update({'is_active': false})
            .eq('token', token);
      }
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM deactivateToken error: $e');
    }
  }
}
