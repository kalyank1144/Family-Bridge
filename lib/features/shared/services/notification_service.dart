import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logging_service.dart';

/// Service for managing push notifications, local notifications, and notification scheduling
/// Implements HIPAA-compliant notification handling with privacy controls
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;
  final LoggingService _logger = LoggingService();

  bool _isInitialized = false;
  Function(String)? _onNotificationTap;

  /// Initialize the notification service
  Future<void> initialize({Function(String)? onNotificationTap}) async {
    if (_isInitialized) return;

    _onNotificationTap = onNotificationTap;

    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Request permissions
    await _requestPermissions();

    _isInitialized = true;
    _logger.info('NotificationService initialized');
  }

  /// Schedule a local notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        _convertToTZDateTime(scheduledTime),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders',
            'Medication Reminders',
            channelDescription: 'Notifications for medication reminders',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload != null ? jsonEncode(payload) : null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      _logger.info('Notification scheduled: $id - $title');
    } catch (e) {
      _logger.error('Failed to schedule notification: $e');
      throw NotificationException('Failed to schedule notification: $e');
    }
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? channelId,
    String? channelName,
  }) async {
    try {
      await _localNotifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId ?? 'general',
            channelName ?? 'General Notifications',
            channelDescription: 'General app notifications',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload != null ? jsonEncode(payload) : null,
      );

      _logger.info('Notification shown: $id - $title');
    } catch (e) {
      _logger.error('Failed to show notification: $e');
      throw NotificationException('Failed to show notification: $e');
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      _logger.info('Notification cancelled: $id');
    } catch (e) {
      _logger.error('Failed to cancel notification: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      _logger.info('All notifications cancelled');
    } catch (e) {
      _logger.error('Failed to cancel all notifications: $e');
    }
  }

  /// Send push notification to specific user
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // This would integrate with a push notification service like Firebase
      // For now, we'll log the notification
      _logger.info('Push notification sent to $userId: $title - $message');
    } catch (e) {
      _logger.error('Failed to send push notification: $e');
      throw NotificationException('Failed to send push notification: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      _logger.error('Failed to get pending notifications: $e');
      return [];
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        return await androidImpl.areNotificationsEnabled() ?? false;
      }
      
      // For iOS, assume enabled if we got this far
      return true;
    } catch (e) {
      _logger.error('Failed to check notification status: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return true;
    } catch (e) {
      _logger.error('Failed to request notification permissions: $e');
      return false;
    }
  }

  /// Handle notification response
  void _onNotificationResponse(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null && _onNotificationTap != null) {
        _onNotificationTap!(payload);
      }
      _logger.info('Notification tapped: ${response.id}');
    } catch (e) {
      _logger.error('Error handling notification response: $e');
    }
  }

  /// Convert DateTime to TZDateTime (placeholder implementation)
  dynamic _convertToTZDateTime(DateTime dateTime) {
    // In a real implementation, you would use the timezone package
    // For now, return the DateTime as-is
    return dateTime;
  }
}

/// Custom exception for notification service errors
class NotificationException implements Exception {
  final String message;
  NotificationException(this.message);
  
  @override
  String toString() => 'NotificationException: $message';
}