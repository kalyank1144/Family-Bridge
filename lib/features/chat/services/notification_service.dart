import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/message_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  final FlutterTts _tts = FlutterTts();
  
  String? _currentUserType;
  bool _isAppInForeground = true;
  bool _isSchoolHours = false;
  
  // Priority notification counters
  int _emergencyNotificationId = 1000;
  int _urgentNotificationId = 2000;
  int _importantNotificationId = 3000;
  int _normalNotificationId = 4000;
  
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize({required String userType}) async {
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

  /// Create notification channels for different priorities
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
      ];

      for (final channel in channels) {
        await _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
      }
    }
  }

  Future<void> _setupTTS() async {
    if (_currentUserType == 'elder') {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.8);
      await _tts.setVolume(1.0);
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      
      // Request special permissions for emergency notifications
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
        critical: true, // For emergency alerts
      );
    }
  }

  void _setupSchoolHoursCheck() {
    if (_currentUserType == 'youth') {
      final now = DateTime.now();
      final hour = now.hour;
      final weekday = now.weekday;
      
      _isSchoolHours = weekday >= 1 && weekday <= 5 && hour >= 8 && hour < 15;
    }
  }

  /// Show notification for regular messages
  Future<void> showMessageNotification(Message message) async {
    if (_isAppInForeground && message.priority != MessagePriority.emergency) return;
    
    // School hours filtering (except emergencies)
    if (_currentUserType == 'youth' && _isSchoolHours) {
      if (message.priority != MessagePriority.emergency) {
        return;
      }
    }
    
    final notificationId = _getNotificationId(message.priority);
    final channelId = _getChannelId(message.priority);
    final title = _getNotificationTitle(message);
    final body = _getNotificationBody(message);
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(message.priority),
      channelDescription: 'Family chat messages',
      importance: _getImportance(message.priority),
      priority: _getPriority(message.priority),
      playSound: true,
      sound: message.priority == MessagePriority.emergency 
          ? const RawResourceAndroidNotificationSound('emergency_alert') 
          : null,
      enableVibration: true,
      vibrationPattern: _getVibrationPattern(message.priority),
      enableLights: message.priority == MessagePriority.emergency,
      ledColor: message.priority == MessagePriority.emergency 
          ? const Color.fromARGB(255, 255, 0, 0) 
          : null,
      fullScreenIntent: message.priority == MessagePriority.emergency,
      category: AndroidNotificationCategory.message,
      groupKey: 'family_chat',
      setAsGroupSummary: false,
      autoCancel: message.priority != MessagePriority.emergency,
      ongoing: message.priority == MessagePriority.emergency,
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
      payload: message.id,
    );
    
    // Voice announcement for elders on urgent/emergency messages
    if (_currentUserType == 'elder' && 
        (message.priority == MessagePriority.emergency || 
         message.priority == MessagePriority.urgent)) {
      await _announceMessage(message);
    }
    
    // Haptic feedback for emergency
    if (message.priority == MessagePriority.emergency) {
      HapticFeedback.heavyImpact();
      // Repeat vibration for emergency
      Future.delayed(const Duration(seconds: 2), () => HapticFeedback.heavyImpact());
      Future.delayed(const Duration(seconds: 4), () => HapticFeedback.heavyImpact());
    }
  }

  /// Send emergency notification to all family members
  Future<void> sendEmergencyNotification({
    required String familyId,
    required String senderName,
    required String message,
  }) async {
    final notificationId = _emergencyNotificationId++;
    
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
      showWhen: true,
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/emergency_icon'),
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
      notificationId,
      '🆘 EMERGENCY ALERT',
      '$senderName needs immediate assistance - Check family chat now!',
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
    
    // Voice announcement
    if (_currentUserType == 'elder') {
      await _tts.speak('Emergency alert from $senderName. Please check your family chat immediately.');
    }
    
    // Continuous haptic feedback
    _triggerEmergencyHaptics();
  }

  /// Send help request notification
  Future<void> sendHelpRequestNotification({
    required String familyId,
    required String senderName,
    required HelpRequestType helpType,
    required String message,
  }) async {
    final typeText = _getHelpTypeText(helpType);
    final emoji = _getHelpTypeEmoji(helpType);
    
    await _notifications.show(
      _urgentNotificationId++,
      '$emoji Help Request: $typeText',
      '$senderName needs assistance - $message',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'urgent_channel',
          'Urgent Messages',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  /// Send emergency cancelled notification
  Future<void> sendEmergencyCancelledNotification({
    required String familyId,
    required String senderName,
    String? reason,
  }) async {
    // Cancel all emergency notifications first
    await cancelEmergencyNotifications();
    
    await _notifications.show(
      _importantNotificationId++,
      '✅ Emergency Cancelled',
      '$senderName has cancelled the emergency alert. ${reason ?? "Everything is okay now."}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'important_channel',
          'Important Messages',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Cancel all emergency notifications
  Future<void> cancelEmergencyNotifications() async {
    // Cancel specific emergency notification IDs
    for (int i = 1000; i < _emergencyNotificationId; i++) {
      await _notifications.cancel(i);
    }
  }

  /// Voice announcement for elders
  Future<void> _announceMessage(Message message) async {
    if (_currentUserType != 'elder') return;
    
    String announcement = '';
    
    switch (message.priority) {
      case MessagePriority.emergency:
        announcement = 'Emergency message from ${message.senderName}. ${message.content}';
        break;
      case MessagePriority.urgent:
        announcement = 'Urgent message from ${message.senderName}.';
        break;
      case MessagePriority.important:
        announcement = 'Important message from ${message.senderName}.';
        break;
      default:
        announcement = 'New message from ${message.senderName}.';
    }
    
    await _tts.speak(announcement);
  }

  /// Trigger emergency haptic feedback pattern
  void _triggerEmergencyHaptics() {
    HapticFeedback.heavyImpact();
    
    // Create emergency vibration pattern
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

  /// Get notification title
  String _getNotificationTitle(Message message) {
    switch (message.priority) {
      case MessagePriority.emergency:
        return '🆘 EMERGENCY - ${message.senderName}';
      case MessagePriority.urgent:
        return '🔴 Urgent - ${message.senderName}';
      case MessagePriority.important:
        return '🟡 Important - ${message.senderName}';
      case MessagePriority.normal:
        return message.senderName;
    }
  }

  /// Get notification body
  String _getNotificationBody(Message message) {
    if (message.type == MessageType.voice) {
      return '🎵 Voice message';
    } else if (message.type == MessageType.image) {
      return '📷 Photo';
    } else if (message.type == MessageType.video) {
      return '🎥 Video';
    } else if (message.type == MessageType.location) {
      return '📍 Location';
    } else {
      return message.content ?? 'New message';
    }
  }

  /// Get help type emoji
  String _getHelpTypeEmoji(dynamic helpType) {
    return '🆘'; // Simplified for now
  }

  /// Get help type text
  String _getHelpTypeText(dynamic helpType) {
    return 'Assistance'; // Simplified for now
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on notification payload
    debugPrint('Notification tapped: ${response.payload}');
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

  /// Get notification count
  Future<int> getNotificationCount() async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    return pendingNotifications.length;
  }
}

// Notification service provider is defined in chat_providers.dart