import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize({void Function(String? payload)? onSelect}) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    final init = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(init, onDidReceiveNotificationResponse: (resp) {
      onSelect?.call(resp.payload);
    });
  }

  static Future<void> show({required String title, required String body, String? payload}) async {
    const android = AndroidNotificationDetails('default', 'General');
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    await _plugin.show(0, title, body, details, payload: payload);
  }
}
