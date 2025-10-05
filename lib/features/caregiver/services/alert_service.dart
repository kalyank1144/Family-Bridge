import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:family_bridge/features/caregiver/models/alert.dart';

class AlertService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  Future<List<Alert>> getAlerts() async {
    try {
      final response = await _supabase
          .from('alerts')
          .select()
          .order('timestamp', ascending: false)
          .limit(100);
      
      return (response as List)
          .map((json) => Alert.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load alerts: $e');
    }
  }

  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _supabase
          .from('alerts')
          .update({'is_read': true})
          .eq('id', alertId);
    } catch (e) {
      throw Exception('Failed to mark alert as read: $e');
    }
  }

  Future<void> acknowledgeAlert(String alertId) async {
    try {
      await _supabase
          .from('alerts')
          .update({
            'is_read': true,
            'is_acknowledged': true,
          })
          .eq('id', alertId);
    } catch (e) {
      throw Exception('Failed to acknowledge alert: $e');
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      await _supabase
          .from('alerts')
          .delete()
          .eq('id', alertId);
    } catch (e) {
      throw Exception('Failed to delete alert: $e');
    }
  }

  Future<void> updateAlertPreferences(Map<AlertType, bool> preferences) async {
    try {
      final prefsJson = preferences.map((key, value) => 
        MapEntry(key.toString().split('.').last, value));
      
      await _supabase
          .from('user_preferences')
          .upsert({'alert_preferences': prefsJson});
    } catch (e) {
      throw Exception('Failed to update alert preferences: $e');
    }
  }

  Future<void> updateMemberAlertThreshold(String memberId, AlertPriority threshold) async {
    try {
      await _supabase
          .from('member_alert_settings')
          .upsert({
            'member_id': memberId,
            'threshold': threshold.toString().split('.').last,
          });
    } catch (e) {
      throw Exception('Failed to update member alert threshold: $e');
    }
  }

  void subscribeToAlerts(Function(Alert) onNewAlert) {
    _channel = _supabase.channel('alerts_channel')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'alerts',
        ),
        (payload, [ref]) {
          if (payload['new'] != null) {
            final alert = Alert.fromJson(payload['new']);
            onNewAlert(alert);
          }
        },
      )
      ..subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
  }
}