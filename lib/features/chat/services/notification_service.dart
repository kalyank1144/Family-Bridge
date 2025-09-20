import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/message_model.dart';
import 'emergency_service.dart' show HelpRequestType;

class ChatNotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FlutterTts _tts = FlutterTts();
  
  String? _currentUserType;
  bool _isAppInForeground = true;
  bool _isSchoolHours = false;
  
  int _emergencyNotificationId = 1000;
  int _urgentNotificationId = 2000;
  int _importantNotificationId = 3000;
  int _normalNotificationId = 4000;
  
  static final ChatNotificationService _instance = ChatNotificationService._internal();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._internal();

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
        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
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
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
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

  void _setupSchoolHoursCheck() {
    if (_currentUserType == 'youth') {
      final now = DateTime.now();
      final hour = now.hour;
      final weekday = now.weekday;
      _isSchoolHours = weekday >= 1 && weekday <= 5 && hour >= 8 && hour < 15;
    }
  }

  Future<void> showMessageNotification(Message message) async {
    if (_isAppInForeground && message.priority != MessagePriority.emergency) return;
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
    if (_currentUserType == 'elder' &&
        (message.priority == MessagePriority.emergency ||
            message.priority == MessagePriority.urgent)) {
      await _announceMessage(message);
    }
    if (message.priority == MessagePriority.emergency) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(seconds: 2), () => HapticFeedback.heavyImpact());
      Future.delayed(const Duration(seconds: 4), () => HapticFeedback.heavyImpact());
    }
  }

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
    if (_currentUserType == 'elder') {
      await _tts.speak('Emergency alert from $senderName. Please check your family chat immediately.');
    }
    _triggerEmergencyHaptics();
  }

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

  Future<void> sendEmergencyCancelledNotification({
    required String familyId,
    required String senderName,
    String? reason,
  }) async {
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

  Future<void> cancelEmergencyNotifications() async {
    for (int i = 1000; i < _emergencyNotificationId; i++) {
      await _notifications.cancel(i);
    }
  }

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

  void _triggerEmergencyHaptics() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 500), () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 1000), () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 1500), () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 2000), () => HapticFeedback.mediumImpact());
    Future.delayed(const Duration(milliseconds: 2500), () => HapticFeedback.mediumImpact());
  }

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

  String _getHelpTypeEmoji(HelpRequestType helpType) {
    switch (helpType) {
      case HelpRequestType.medical:
        return '🏥';
      case HelpRequestType.mobility:
        return '♿';
      case HelpRequestType.technology:
        return '💻';
      case HelpRequestType.household:
        return '🏠';
      case HelpRequestType.transportation:
        return '🚗';
      case HelpRequestType.shopping:
        return '🛒';
      case HelpRequestType.social:
        return '👥';
      case HelpRequestType.other:
        return '❓';
    }
  }

  String _getHelpTypeText(HelpRequestType helpType) {
    switch (helpType) {
      case HelpRequestType.medical:
        return 'Medical assistance';
      case HelpRequestType.mobility:
        return 'Mobility support';
      case HelpRequestType.technology:
        return 'Technology help';
      case HelpRequestType.household:
        return 'Household tasks';
      case HelpRequestType.transportation:
        return 'Transportation';
      case HelpRequestType.shopping:
        return 'Shopping assistance';
      case HelpRequestType.social:
        return 'Social support';
      case HelpRequestType.other:
        return 'General assistance';
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  void setAppForegroundState(bool isForeground) {
    _isAppInForeground = isForeground;
  }

  void updateUserType(String userType) {
    _currentUserType = userType;
    _setupTTS();
    _setupSchoolHoursCheck();
  }

  Future<void> clearAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<int> getNotificationCount() async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    return pendingNotifications.length;
  }
}

// Provider wrapper is defined in chat_providers.dart
