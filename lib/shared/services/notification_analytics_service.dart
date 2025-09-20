import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationAnalyticsService {
  NotificationAnalyticsService._internal();
  static final NotificationAnalyticsService instance = NotificationAnalyticsService._internal();
  final _supabase = Supabase.instance.client;

  Future<void> logDelivered({required String type, required String priority, String? title, String? body, Map<String, dynamic>? payload}) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    await _supabase.from('notifications_log').insert({
      'user_id': uid,
      'type': type,
      'priority': priority,
      'title': title,
      'body': body,
      'payload': payload,
      'delivered_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logOpened({Map<String, dynamic>? payload}) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    await _supabase.from('notifications_log').insert({
      'user_id': uid,
      'type': 'opened',
      'priority': 'n/a',
      'payload': payload,
      'opened_at': DateTime.now().toIso8601String(),
    });
  }
}
