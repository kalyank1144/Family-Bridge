import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';
import '../models/message_model.dart';
import 'notification_service.dart';
import 'package:family_bridge/features/chat/services/emergency_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  await PushNotificationService.instance._handleRemoteMessage(message, fromBackground: true);
}

class PushNotificationService {
  PushNotificationService._internal();
  static final PushNotificationService instance = PushNotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;
  final _flutterLocal = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _userId;
  String? _role;
  String? _familyId;
  String? _token;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      try {
        await Firebase.initializeApp();
      } catch (_) {}

      if (Platform.isIOS) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      await _requestPermission();

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((message) async {
        await _handleRemoteMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        await _handleRemoteMessage(message, openedApp: true);
      });

      _token = await _messaging.getToken();
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Push init failed: $e');
      }
    }
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
    }
  }

  Future<void> syncUser({required String userId, required String role, String? familyId}) async {
    _userId = userId;
    _role = role;
    _familyId = familyId;
    if (!_initialized) return;
    _token ??= await _messaging.getToken();
    if (_token == null) return;
    await _upsertDeviceToken(_token!);
    await _subscribeTopics();
  }

  Future<void> _upsertDeviceToken(String token) async {
    try {
      await _supabase.from('device_tokens').upsert({
        'user_id': _userId,
        'role': _role,
        'family_id': _familyId,
        'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
        'token': token,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _subscribeTopics() async {
    if (kIsWeb) return;
    try {
      if (_role != null) {
        await _messaging.subscribeToTopic('role_${_role!}');
      }
      if (_familyId != null && _familyId!.isNotEmpty) {
        await _messaging.subscribeToTopic('family_${_familyId!}');
      }
    } catch (_) {}
  }

  MessagePriority _parsePriority(String? p) {
    switch (p) {
      case 'emergency':
        return MessagePriority.emergency;
      case 'urgent':
        return MessagePriority.urgent;
      case 'important':
        return MessagePriority.important;
      default:
        return MessagePriority.normal;
    }
  }

  Future<void> _handleRemoteMessage(RemoteMessage message, {bool fromBackground = false, bool openedApp = false}) async {
    final data = message.data;
    final type = data['type'] ?? message.category;
    if (type == 'message') {
      final sender = data['sender_name'] ?? 'Family';
      final content = data['preview'] ?? message.notification?.body ?? '';
      final priority = _parsePriority(data['priority']);
      await NotificationService.instance.showMessageNotification(
        sender,
        content,
        priority,
        familyId: data['family_id'],
        messageId: data['message_id'],
      );
      return;
    }
    if (type == 'alert') {
      await NotificationService.instance.sendCareAlert(
        title: data['title'] ?? message.notification?.title ?? 'Alert',
        message: data['body'] ?? message.notification?.body ?? '',
        alertType: data['alert_type'] ?? 'general',
        familyMemberId: data['member_id'],
      );
      return;
    }
    if (type == 'emergency') {
      final loc = data['location'];
      final help = data['help_type'] ?? 'medical';
      final p = _parsePriority('emergency');
      await NotificationService.instance.sendEmergencyNotification(
        title: data['title'] ?? 'Emergency',
        message: data['body'] ?? 'Emergency alert',
        helpType: HelpRequestType.values.firstWhere(
          (e) => e.name == help,
          orElse: () => HelpRequestType.medical,
        ),
        location: loc,
      );
      return;
    }
    if (type == 'appointment') {
      await NotificationService.instance.showMessageNotification(
        data['title'] ?? 'Appointment',
        data['body'] ?? '',
        _parsePriority('important'),
        familyId: data['family_id'],
        messageId: data['appointment_id'],
      );
      return;
    }
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    await _flutterLocal.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'important_channel',
          'Important Messages',
          channelDescription: 'Important family communications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'generic',
    );
  }
}
