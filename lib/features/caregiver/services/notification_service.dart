import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/alert.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  NotificationService._internal();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // Navigate to relevant screen based on payload
    }
  }

  Future<void> showNotification(Alert alert) async {
    const androidDetails = AndroidNotificationDetails(
      'alerts_channel',
      'Alerts',
      channelDescription: 'Family care alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      alert.id.hashCode,
      alert.title,
      alert.description,
      details,
      payload: alert.id,
    );
  }

  Future<void> showCriticalAlert(Alert alert) async {
    const androidDetails = AndroidNotificationDetails(
      'critical_alerts_channel',
      'Critical Alerts',
      channelDescription: 'Critical family care alerts',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      playSound: true,
      ongoing: true,
      autoCancel: false,
    );
    
    const iosDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.critical,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      alert.id.hashCode,
      '🚨 CRITICAL: ${alert.title}',
      alert.description,
      details,
      payload: alert.id,
    );
  }

  Future<void> showHighPriorityAlert(Alert alert) async {
    const androidDetails = AndroidNotificationDetails(
      'high_priority_alerts_channel',
      'High Priority Alerts',
      channelDescription: 'High priority family care alerts',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      alert.id.hashCode,
      '⚠️ ${alert.title}',
      alert.description,
      details,
      payload: alert.id,
    );
  }

  Future<void> scheduleAppointmentReminder(
    String id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'appointment_reminders_channel',
      'Appointment Reminders',
      channelDescription: 'Appointment reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.zonedSchedule(
      id.hashCode,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: id,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
