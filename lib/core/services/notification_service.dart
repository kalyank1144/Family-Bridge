import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

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
        await _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
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

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        await androidImplementation.requestPermission();
      }
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
    }
  }

  /// Setup school hours filtering for youth users
  void _setupSchoolHoursCheck() {
    if (_currentUserType == 'youth') {
      final now = DateTime.now();
      final hour = now.hour;
      final weekday = now.weekday;
      
      _isSchoolHours = weekday >= 1 && weekday <= 5 && hour >= 8 && hour < 15;
    }
  }

  // MARK: - Chat Message Notifications

  /// Show notification for chat messages
  Future<void> showMessageNotification({
    required String id,
    required String senderName,
    required String content,
    required MessagePriority priority,
    required MessageType type,
  }) async {
    if (_isAppInForeground && priority != MessagePriority.emergency) return;
    
    // School hours filtering (except emergencies)
    if (_currentUserType == 'youth' && _isSchoolHours) {
      if (priority != MessagePriority.emergency) {
        return;
      }
    }
    
    final notificationId = _getNotificationId(priority);
    final channelId = _getChannelId(priority);
    final title = _getMessageNotificationTitle(senderName, priority);
    final body = _getMessageNotificationBody(content, type);
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(priority),
      channelDescription: 'Family chat messages',
      importance: _getImportance(priority),
      priority: _getPriority(priority),
      playSound: true,
      sound: priority == MessagePriority.emergency 
          ? const RawResourceAndroidNotificationSound('emergency_alert') 
          : null,
      enableVibration: true,
      vibrationPattern: _getVibrationPattern(priority),
      enableLights: priority == MessagePriority.emergency,
      ledColor: priority == MessagePriority.emergency 
          ? const Color.fromARGB(255, 255, 0, 0) 
          : null,
      fullScreenIntent: priority == MessagePriority.emergency,
      category: AndroidNotificationCategory.message,
      groupKey: 'family_chat',
      autoCancel: priority != MessagePriority.emergency,
      ongoing: priority == MessagePriority.emergency,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: id,
    );
    
    // Voice announcement for elders on urgent/emergency messages
    if (_currentUserType == 'elder' && 
        (priority == MessagePriority.emergency || 
         priority == MessagePriority.urgent)) {
      await _announceMessage(senderName, content, priority);
    }
    
    // Haptic feedback for emergency
    if (priority == MessagePriority.emergency) {
      _triggerEmergencyHaptics();
    }
  }

  // MARK: - Alert Notifications (for Caregiver)

  /// Show care alert notification
  Future<void> showAlert({
    required String id,
    required String title,
    required String description,
    required AlertPriority priority,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'alerts_channel',
      'Care Alerts',
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
      _alertNotificationId++,
      title,
      description,
      details,
      payload: id,
    );
  }

  /// Show critical alert (for Caregiver)
  Future<void> showCriticalAlert({
    required String id,
    required String title,
    required String description,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
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
      _alertNotificationId++,
      '🚨 CRITICAL: $title',
      description,
      details,
      payload: id,
    );
  }

  // MARK: - Appointment Notifications

  /// Schedule appointment reminder
  Future<void> scheduleAppointmentReminder({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
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
      _appointmentNotificationId++,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: id,
    );
  }

  // MARK: - Emergency Notifications

  /// Send emergency notification to all family members
  Future<void> sendEmergencyNotification({
    required String familyId,
    required String senderName,
    required String message,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'Critical emergency alerts',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('emergency_alert'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      enableLights: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      autoCancel: false,
      ongoing: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'emergency_alert.wav',
      interruptionLevel: InterruptionLevel.critical,
      criticalSound: CriticalSound(name: 'emergency_alert.wav', volume: 1.0),
    );
    
    await _notifications.show(
      _emergencyNotificationId++,
      '🆘 EMERGENCY ALERT',
      '$senderName needs immediate assistance - Check family chat now!',
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
    
    // Voice announcement for elders
    if (_currentUserType == 'elder') {
      await _tts.speak('Emergency alert from $senderName. Please check your family chat immediately.');
    }
    
    _triggerEmergencyHaptics();
  }

  /// Cancel all emergency notifications
  Future<void> cancelEmergencyNotifications() async {
    for (int i = 1000; i < _emergencyNotificationId; i++) {
      await _notifications.cancel(i);
    }
  }

  // MARK: - Utility Methods

  /// Voice announcement for elders
  Future<void> _announceMessage(String senderName, String content, MessagePriority priority) async {
    if (_currentUserType != 'elder') return;
    
    String announcement = '';
    
    switch (priority) {
      case MessagePriority.emergency:
        announcement = 'Emergency message from $senderName. $content';
        break;
      case MessagePriority.urgent:
        announcement = 'Urgent message from $senderName.';
        break;
      case MessagePriority.important:
        announcement = 'Important message from $senderName.';
        break;
      default:
        announcement = 'New message from $senderName.';
    }
    
    await _tts.speak(announcement);
  }

  /// Trigger emergency haptic feedback pattern
  void _triggerEmergencyHaptics() {
    HapticFeedback.heavyImpact();
    
    Future.delayed(const Duration(milliseconds: 500), () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 1000), () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 1500), () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 2000), () => HapticFeedback.mediumImpact());
    Future.delayed(const Duration(milliseconds: 2500), () => HapticFeedback.mediumImpact());
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

  /// Get channel ID for priority
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

  /// Get channel name for priority
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

  /// Get Android importance level
  Importance _getImportance(MessagePriority priority) {
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

  /// Get Android priority level
  Priority _getPriority(MessagePriority priority) {
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

  /// Get vibration pattern for priority
  Int64List _getVibrationPattern(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return Int64List.fromList([0, 1000, 500, 1000, 500, 1000]);
      case MessagePriority.urgent:
        return Int64List.fromList([0, 500, 200, 500]);
      case MessagePriority.important:
        return Int64List.fromList([0, 300, 100, 300]);
      case MessagePriority.normal:
        return Int64List.fromList([0, 200]);
    }
  }

  /// Get notification title for messages
  String _getMessageNotificationTitle(String senderName, MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return '🆘 EMERGENCY - $senderName';
      case MessagePriority.urgent:
        return '🔴 Urgent - $senderName';
      case MessagePriority.important:
        return '🟡 Important - $senderName';
      case MessagePriority.normal:
        return senderName;
    }
  }

  /// Get notification body for messages
  String _getMessageNotificationBody(String content, MessageType type) {
    switch (type) {
      case MessageType.voice:
        return '🎵 Voice message';
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.location:
        return '📍 Location';
      default:
        return content;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Implement navigation based on notification payload
  }

  /// Set app foreground state
  void setAppForegroundState(bool isForeground) {
    _isAppInForeground = isForeground;
  }

  /// Update user type
  void updateUserType(String userType) {
    _currentUserType = userType;
    _setupTTS();
    _setupSchoolHoursCheck();
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Get notification count
  Future<int> getNotificationCount() async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    return pendingNotifications.length;
  }
}

// Enums for type safety
enum MessagePriority {
  normal,
  important,
  urgent,
  emergency,
}

enum MessageType {
  text,
  voice,
  image,
  video,
  location,
  careNote,
  announcement,
  achievement,
}

enum AlertPriority {
  low,
  medium,
  high,
  critical,
}