import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/message_model.dart';
import '../../features/emergency/models/help_request.dart';

/// Unified notification service for the entire app
/// Handles chat messages, alerts, appointments, and emergencies
/// with user-type specific behaviors and accessibility features
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  final FlutterTts _tts = FlutterTts();
  
  String? _currentUserType;
  bool _isAppInForeground = true;
  bool _isSchoolHours = false;
  
  // Notification ID counters for different priorities
  int _emergencyNotificationId = 1000;
  int _urgentNotificationId = 2000;
  int _importantNotificationId = 3000;
  int _normalNotificationId = 4000;
  int _alertNotificationId = 5000;
  int _appointmentNotificationId = 6000;
  
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  /// Initialize the notification service
  /// [userType] should be 'elder', 'caregiver', or 'youth'
  Future<void> initialize({String? userType}) async {
    _currentUserType = userType;
    
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
    
    await _createNotificationChannels();
    await _setupTTS();
    await _requestPermissions();
    _setupSchoolHoursCheck();
  }

  /// Create notification channels for different priorities and types
  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      final channels = [
        const AndroidNotificationChannel(
          'emergency_channel',
          'Emergency Alerts',
          description: 'Critical emergency alerts that bypass all settings',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color.fromARGB(255, 255, 0, 0),
        ),
        const AndroidNotificationChannel(
          'urgent_channel', 
          'Urgent Messages',
          description: 'Important messages requiring immediate attention',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        const AndroidNotificationChannel(
          'important_channel',
          'Important Messages', 
          description: 'Important family communications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        const AndroidNotificationChannel(
          'normal_channel',
          'Family Chat',
          description: 'Regular family chat messages',
          importance: Importance.low,
          priority: Priority.low,
        ),
        const AndroidNotificationChannel(
          'alerts_channel',
          'Care Alerts',
          description: 'Family care and health alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        const AndroidNotificationChannel(
          'appointment_reminders_channel',
          'Appointment Reminders',
          description: 'Appointment and medication reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ];

      for (final channel in channels) {
        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
    }
  }

  /// Setup text-to-speech for elder users
  Future<void> _setupTTS() async {
    if (_currentUserType == 'elder') {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.8);
      await _tts.setVolume(1.0);
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
    
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Setup school hours detection for youth users
  void _setupSchoolHoursCheck() {
    if (_currentUserType == 'youth') {
      // Check school hours every hour
      Stream.periodic(const Duration(hours: 1)).listen((_) {
        _checkSchoolHours();
      });
      _checkSchoolHours(); // Check immediately
    }
  }

  void _checkSchoolHours() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final hour = now.hour;
    
    // Monday to Friday, 8 AM to 3 PM
    _isSchoolHours = weekday >= 1 && weekday <= 5 && hour >= 8 && hour < 15;
  }

  // MARK: - Chat Message Notifications

  /// Show notification for new message with proper handling for user types
  Future<void> showMessageNotification(
    String senderName,
    String content,
    MessagePriority priority, {
    String? familyId,
    String? messageId,
  }) async {
    if (_isAppInForeground && priority != MessagePriority.emergency) return;
    
    // School hours filtering (except emergencies)
    if (_currentUserType == 'youth' && _isSchoolHours) {
      if (priority != MessagePriority.emergency) {
        return;
      }
    }
    
    final notificationId = _getNotificationId(priority);
    final title = senderName;
    final body = content;
    
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(priority),
      _getChannelName(priority),
      channelDescription: _getChannelDescription(priority),
      icon: '@mipmap/ic_launcher',
      playSound: true,
      sound: priority == MessagePriority.emergency 
          ? const RawResourceAndroidNotificationSound('emergency_alert')
          : const RawResourceAndroidNotificationSound('notification'),
      priority: _getAndroidPriority(priority),
      importance: _getAndroidImportance(priority),
      ledColor: priority == MessagePriority.emergency 
          ? const Color.fromARGB(255, 255, 0, 0) 
          : null,
      enableVibration: true,
      vibrationPattern: priority == MessagePriority.emergency
          ? Int64List.fromList([0, 1000, 500, 1000])
          : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      title,
      body,
      details,
      payload: 'message:$familyId:$messageId',
    );
    
    // TTS announcement for elder users
    await _announceMessage(senderName, content, priority);
  }

  // MARK: - Alert Notifications

  /// Send alert notification for caregivers
  Future<void> sendCareAlert({
    required String title,
    required String message,
    required String alertType,
    String? familyMemberId,
  }) async {
    if (_currentUserType != 'caregiver') return;

    final notificationId = _alertNotificationId++;
    
    const androidDetails = AndroidNotificationDetails(
      'alerts_channel',
      'Care Alerts',
      channelDescription: 'Family care and health alerts',
      icon: '@mipmap/ic_launcher',
      priority: Priority.high,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      ledColor: Color.fromARGB(255, 255, 165, 0), // Orange
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      title,
      message,
      details,
      payload: 'alert:$alertType:$familyMemberId',
    );
  }

  /// Send appointment reminder
  Future<void> scheduleAppointmentReminder({
    required String title,
    required String message,
    required DateTime scheduledTime,
    String? appointmentId,
  }) async {
    final notificationId = _appointmentNotificationId++;
    
    const androidDetails = AndroidNotificationDetails(
      'appointment_reminders_channel',
      'Appointment Reminders',
      channelDescription: 'Appointment and medication reminders',
      icon: '@mipmap/ic_launcher',
      priority: Priority.high,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      ledColor: Color.fromARGB(255, 0, 255, 0), // Green
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      title,
      message,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      payload: 'appointment:$appointmentId',
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Send emergency notification to all family members
  Future<void> sendEmergencyNotification({
    required String title,
    required String message,
    required HelpRequestType helpType,
    String? location,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'Critical emergency alerts',
      icon: '@mipmap/ic_launcher',
      priority: Priority.max,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('emergency_alert'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      ledColor: Color.fromARGB(255, 255, 0, 0),
      fullScreenIntent: true,
      ongoing: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'emergency_alert.wav',
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    final notificationId = _emergencyNotificationId++;

    await _notifications.show(
      notificationId,
      title,
      message,
      details,
      payload: 'emergency:${helpType.name}:$location',
    );
    
    // TTS announcement for elder users
    if (_currentUserType == 'elder') {
      await _tts.speak('Emergency alert: $title. $message');
    }
  }

  /// Cancel all emergency notifications
  Future<void> cancelEmergencyNotifications() async {
    // Cancel emergency notifications (IDs 1000-1999)
    for (int i = 1000; i < _emergencyNotificationId; i++) {
      await _notifications.cancel(i);
    }
  }

  // MARK: - Utility Methods
  
  /// Announce message using TTS for elder users
  Future<void> _announceMessage(String senderName, String content, MessagePriority priority) async {
    if (_currentUserType != 'elder') return;
    String announcement = '';
    
    switch (priority) {
      case MessagePriority.emergency:
        announcement = 'Emergency message from $senderName: $content';
        break;
      case MessagePriority.urgent:
        announcement = 'Urgent message from $senderName: $content';
        break;
      case MessagePriority.important:
        announcement = 'Important message from $senderName: $content';
        break;
      case MessagePriority.normal:
        announcement = 'Message from $senderName: $content';
        break;
    }
    
    await _tts.speak(announcement);
  }

  /// Get notification ID based on priority
  int _getNotificationId(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return _emergencyNotificationId++;
      case MessagePriority.urgent:
        return _urgentNotificationId++;
      case MessagePriority.important:
        return _importantNotificationId++;
      case MessagePriority.normal:
        return _normalNotificationId++;
    }
  }

  /// Get channel ID based on priority
  String _getChannelId(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return 'emergency_channel';
      case MessagePriority.urgent:
        return 'urgent_channel';
      case MessagePriority.important:
        return 'important_channel';
      case MessagePriority.normal:
        return 'normal_channel';
    }
  }

  /// Get channel name based on priority
  String _getChannelName(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return 'Emergency Alerts';
      case MessagePriority.urgent:
        return 'Urgent Messages';
      case MessagePriority.important:
        return 'Important Messages';
      case MessagePriority.normal:
        return 'Family Chat';
    }
  }

  /// Get channel description based on priority
  String _getChannelDescription(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return 'Critical emergency alerts that bypass all settings';
      case MessagePriority.urgent:
        return 'Important messages requiring immediate attention';
      case MessagePriority.important:
        return 'Important family communications';
      case MessagePriority.normal:
        return 'Regular family chat messages';
    }
  }

  /// Get Android priority based on message priority
  Priority _getAndroidPriority(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return Priority.max;
      case MessagePriority.urgent:
        return Priority.high;
      case MessagePriority.important:
        return Priority.defaultPriority;
      case MessagePriority.normal:
        return Priority.low;
    }
  }

  /// Get Android importance based on message priority
  Importance _getAndroidImportance(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return Importance.max;
      case MessagePriority.urgent:
        return Importance.high;
      case MessagePriority.important:
        return Importance.defaultImportance;
      case MessagePriority.normal:
        return Importance.low;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
    
    final payload = response.payload;
    if (payload != null) {
      final parts = payload.split(':');
      if (parts.isNotEmpty) {
        final type = parts[0];
        switch (type) {
          case 'message':
            // Navigate to chat screen
            if (parts.length >= 2) {
              final familyId = parts[1];
              // TODO: Navigate to chat with familyId
            }
            break;
          case 'alert':
            // Navigate to appropriate alert screen
            if (parts.length >= 2) {
              final alertType = parts[1];
              // TODO: Navigate based on alert type
            }
            break;
          case 'appointment':
            // Navigate to appointment details
            if (parts.length >= 2) {
              final appointmentId = parts[1];
              // TODO: Navigate to appointment details
            }
            break;
          case 'emergency':
            // Navigate to emergency screen
            if (parts.length >= 2) {
              final helpType = parts[1];
              // TODO: Navigate to emergency response
            }
            break;
        }
      }
    }
  }

  /// Update app foreground state
  void setAppInForeground(bool inForeground) {
    _isAppInForeground = inForeground;
  }

  /// Update user type
  void setUserType(String userType) {
    _currentUserType = userType;
    if (userType == 'elder') {
      _setupTTS();
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}