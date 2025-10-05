import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerLifecycleService {
  static final CustomerLifecycleService instance = CustomerLifecycleService._internal();
  final SupabaseClient _supabase = Supabase.instance.client;
  CustomerLifecycleService._internal();

  Future<String> getTrialStage(String userId) async {
    try {
      final startedRows = await _supabase
          .from('trial_events')
          .select('created_at')
          .eq('user_id', userId)
          .eq('event_type', 'trial_started')
          .order('created_at', ascending: true)
          .limit(1);
      if (startedRows is List && startedRows.isNotEmpty) {
        final start = DateTime.tryParse(startedRows.first['created_at'] as String) ?? DateTime.now();
        final days = DateTime.now().difference(start).inDays + 1;
        if (days <= 7) return 'Getting Started';
        if (days <= 14) return 'Building Habits';
        if (days <= 21) return 'Value Realization';
        return 'Decision Time';
      }
      return 'Getting Started';
    } catch (_) {
      return 'Getting Started';
    }
  }

  Future<String> getPostConversionStage(String userId) async {
    try {
      final convRows = await _supabase
          .from('trial_events')
          .select('created_at')
          .eq('user_id', userId)
          .eq('event_type', 'converted')
          .order('created_at', ascending: true)
          .limit(1);
      if (convRows is List && convRows.isNotEmpty) {
        final at = DateTime.tryParse(convRows.first['created_at'] as String) ?? DateTime.now();
        final months = (DateTime.now().difference(at).inDays / 30).floor();
        if (months < 1) return 'New Subscriber';
        if (months < 6) return 'Engaged User';
        return 'Loyal Customer';
      }
      return 'New Subscriber';
    } catch (_) {
      return 'New Subscriber';
    }
  }

  Future<Map<String, bool>> getRiskFlags(String userId) async {
    try {
      final rows = await _supabase
          .from('trial_events')
          .select('event_type, created_at, event_data')
          .eq('user_id', userId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());
      final events = rows as List<dynamic>;
      final lastActivity = events.isEmpty
          ? null
          : events.map((e) => DateTime.tryParse(e['created_at'] as String) ?? DateTime.now()).reduce((a, b) => a.isAfter(b) ? a : b);
      final usageDrop = events.where((e) => e['event_type'] == 'feature_used').length < 5;
      final familyInactive = events.where((e) => e['event_type'] == 'family_member_active').isEmpty;
      final billingIssues = events.any((e) => e['event_type'] == 'payment_failed');
      final noActivity7d = lastActivity == null || DateTime.now().difference(lastActivity).inDays > 7;
      return {
        'churn_risk': usageDrop,
        'engagement_risk': noActivity7d || familyInactive,
        'billing_risk': billingIssues,
      };
    } catch (_) {
      return {
        'churn_risk': false,
        'engagement_risk': false,
        'billing_risk': false,
      };
    }
  }
}
