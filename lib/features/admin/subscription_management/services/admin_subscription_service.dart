import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSubscriptionService {
  static final AdminSubscriptionService instance = AdminSubscriptionService._internal();
  final SupabaseClient _supabase = Supabase.instance.client;
  AdminSubscriptionService._internal();

  Future<void> extendTrial({required String userId, required int extraDays}) async {
    await _supabase.from('trial_events').insert({
      'id': _uuid(),
      'user_id': userId,
      'event_type': 'trial_extended',
      'event_data': {'extra_days': extraDays},
    });
  }

  Future<void> applyDiscount({required String userId, required String code, required int percent}) async {
    await _supabase.from('trial_events').insert({
      'id': _uuid(),
      'user_id': userId,
      'event_type': 'discount_applied',
      'event_data': {'code': code, 'percent': percent},
    });
  }

  Future<void> sendUpgradeReminder({required String userId, required String channel, String? message}) async {
    await _supabase.from('trial_events').insert({
      'id': _uuid(),
      'user_id': userId,
      'event_type': 'upgrade_reminder_sent',
      'event_data': {'channel': channel, if (message != null) 'message': message},
    });
  }

  Future<void> issueRefund({required String userId, required int cents, String? reason}) async {
    await _supabase.from('trial_events').insert({
      'id': _uuid(),
      'user_id': userId,
      'event_type': 'refund_issued',
      'event_data': {'amount_cents': cents, if (reason != null) 'reason': reason},
    });
  }

  Future<void> bulkAction({required Map<String, dynamic> filter, required String action, Map<String, dynamic>? data}) async {
    await _supabase.from('trial_events').insert({
      'id': _uuid(),
      'user_id': 'bulk',
      'event_type': 'bulk_action',
      'event_data': {'action': action, 'filter': filter, if (data != null) 'data': data},
    });
  }

  Future<Map<String, dynamic>> getUserTrialStatus(String userId) async {
    try {
      final rows = await _supabase
          .from('trial_events')
          .select('event_type, created_at, event_data')
          .eq('user_id', userId)
          .order('created_at');
      DateTime? start;
      DateTime? convertedAt;
      bool cancelled = false;
      for (final r in rows as List<dynamic>) {
        final t = r['event_type'] as String;
        if (t == 'trial_started') start ??= DateTime.tryParse(r['created_at'] as String);
        if (t == 'converted') convertedAt ??= DateTime.tryParse(r['created_at'] as String);
        if (t == 'cancelled') cancelled = true;
      }
      final now = DateTime.now();
      final elapsed = start != null ? now.difference(start!).inDays + 1 : 0;
      final daysLeft = 30 - elapsed;
      return {
        'trial_started_at': start?.toIso8601String(),
        'days_elapsed': elapsed,
        'days_left': daysLeft,
        'converted_at': convertedAt?.toIso8601String(),
        'cancelled': cancelled,
      };
    } catch (_) {
      return {'days_left': 0};
    }
  }

  String _uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '00000000-0000-4${now % 10}${now % 10}-${now % 10}${now % 10}${now % 10}${now % 10}-${now % 10}${now % 10}${now % 10}${now % 10}-${now.toRadixString(16).padLeft(12, '0')}';
  }
}
