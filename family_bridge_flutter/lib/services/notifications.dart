import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (resp) async {
        // Hook for deep linking with payload.
      },
    );
  }

  static Future<void> showNow({required String id, required String title, required String body, String? payload}) async {
    const androidDetails = AndroidNotificationDetails('familybridge_default', 'General', importance: Importance.defaultImportance);
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(id.hashCode, title, body, const NotificationDetails(android: androidDetails, iOS: iosDetails), payload: payload);
  }
}
