import 'dart:io';
import 'package:flutter/foundation.dart';
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
    
    await _setupTTS();
    await _requestPermissions();
    _setupSchoolHoursCheck();
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
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
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
    if (_isAppInForeground) return;
    
    if (_currentUserType == 'youth' && _isSchoolHours) {
      if (message.priority != MessagePriority.emergency) {
        return;
      }
    }
    
    final shouldGroup = _currentUserType == 'caregiver';
    final channelId = _getChannelId(message.priority);
    final channelName = _getChannelName(message.priority);
    final importance = _getImportance(message.priority);
    final priority = _getPriority(message.priority);
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Family chat messages',
      importance: importance,
      priority: priority,
      groupKey: shouldGroup ? 'family_chat' : null,
      styleInformation: _getStyleInformation(message),
      ticker: 'New message',
      playSound: true,
      enableVibration: true,
      vibrationPattern: _getVibrationPattern(message.priority),
    );
    
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'family_chat',
      interruptionLevel: _getInterruptionLevel(message.priority),
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      message.id.hashCode,
      _getNotificationTitle(message),
      _getNotificationBody(message),
      details,
      payload: message.id,
    );
    
    if (_currentUserType == 'elder' && message.priority == MessagePriority.urgent) {
      await _announceMessage(message);
    }
  }

  Future<void> _announceMessage(Message message) async {
    final announcement = 'New message from ${message.senderName}: ${message.content}';
    await _tts.speak(announcement);
  }

  String _getChannelId(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return 'emergency_channel';
      case MessagePriority.urgent:
        return 'urgent_channel';
      case MessagePriority.important:
        return 'important_channel';
      default:
        return 'default_channel';
    }
  }

  String _getChannelName(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return 'Emergency Messages';
      case MessagePriority.urgent:
        return 'Urgent Messages';
      case MessagePriority.important:
        return 'Important Messages';
      default:
        return 'Family Messages';
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
      default:
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
      default:
        return Priority.low;
    }
  }

  InterruptionLevel _getInterruptionLevel(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return InterruptionLevel.critical;
      case MessagePriority.urgent:
        return InterruptionLevel.timeSensitive;
      case MessagePriority.important:
        return InterruptionLevel.active;
      default:
        return InterruptionLevel.passive;
    }
  }

  Int64List? _getVibrationPattern(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return Int64List.fromList([0, 500, 250, 500, 250, 500]);
      case MessagePriority.urgent:
        return Int64List.fromList([0, 400, 200, 400]);
      case MessagePriority.important:
        return Int64List.fromList([0, 300, 150, 300]);
      default:
        return Int64List.fromList([0, 200]);
    }
  }

  StyleInformation _getStyleInformation(Message message) {
    switch (message.type) {
      case MessageType.voice:
        return BigTextStyleInformation(
          '🎤 Voice message (${message.voiceDuration ?? 0}s)',
          contentTitle: message.senderName,
          summaryText: message.voiceTranscription,
        );
      case MessageType.image:
        return BigTextStyleInformation(
          '📷 Photo',
          contentTitle: message.senderName,
          summaryText: message.content,
        );
      case MessageType.video:
        return BigTextStyleInformation(
          '🎥 Video',
          contentTitle: message.senderName,
          summaryText: message.content,
        );
      case MessageType.location:
        return BigTextStyleInformation(
          '📍 ${message.locationName ?? 'Shared location'}',
          contentTitle: message.senderName,
        );
      case MessageType.careNote:
        return BigTextStyleInformation(
          '📝 Care Note: ${message.content}',
          contentTitle: message.senderName,
        );
      case MessageType.announcement:
        return BigTextStyleInformation(
          '📢 ${message.content}',
          contentTitle: 'Family Announcement',
        );
      case MessageType.achievement:
        return BigTextStyleInformation(
          '🏆 ${message.content}',
          contentTitle: '${message.senderName} achieved',
        );
      default:
        return BigTextStyleInformation(
          message.content ?? '',
          contentTitle: message.senderName,
        );
    }
  }

  String _getNotificationTitle(Message message) {
    if (message.priority == MessagePriority.emergency) {
      return '🚨 EMERGENCY: ${message.senderName}';
    } else if (message.priority == MessagePriority.urgent) {
      return '⚠️ URGENT: ${message.senderName}';
    } else if (message.type == MessageType.announcement) {
      return '📢 Family Announcement';
    } else if (message.type == MessageType.careNote) {
      return '📝 Care Note from ${message.senderName}';
    }
    return message.senderName;
  }

  String _getNotificationBody(Message message) {
    switch (message.type) {
      case MessageType.voice:
        return '🎤 Voice message (${message.voiceDuration ?? 0}s)';
      case MessageType.image:
        return '📷 Sent a photo';
      case MessageType.video:
        return '🎥 Sent a video';
      case MessageType.location:
        return '📍 Shared location';
      case MessageType.achievement:
        return '🏆 ${message.content}';
      default:
        return message.content ?? 'New message';
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  void setAppInForeground(bool inForeground) {
    _isAppInForeground = inForeground;
  }

  Future<void> showGroupedNotifications(List<Message> messages) async {
    if (_currentUserType != 'caregiver') return;
    
    for (final message in messages) {
      await showMessageNotification(message);
    }
    
    final androidDetails = const AndroidNotificationDetails(
      'grouped_channel',
      'Grouped Messages',
      channelDescription: 'Grouped family messages',
      groupKey: 'family_chat',
      setAsGroupSummary: true,
    );
    
    const details = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      0,
      'Family Chat',
      '${messages.length} new messages',
      details,
    );
  }

  Future<void> updateBadgeCount(int count) async {
    if (Platform.isIOS) {
      // iOS badge update
    } else if (Platform.isAndroid) {
      // Android badge update (if supported)
    }
  }
}