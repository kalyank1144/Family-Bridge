import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_preferences.dart';

class NotificationPreferencesService {
  NotificationPreferencesService._internal();
  static final NotificationPreferencesService instance = NotificationPreferencesService._internal();
  final _supabase = Supabase.instance.client;

  Future<NotificationPreferences> getPreferences(String userId) async {
    try {
      final res = await _supabase.from('user_notification_preferences').select().eq('user_id', userId).maybeSingle();
      if (res == null) return const NotificationPreferences();
      return NotificationPreferences.fromJson(res['preferences'] as Map<String, dynamic>?);
    } catch (_) {
      return const NotificationPreferences();
    }
  }

  Future<void> updatePreferences(String userId, NotificationPreferences prefs) async {
    await _supabase.from('user_notification_preferences').upsert({
      'user_id': userId,
      'preferences': prefs.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
