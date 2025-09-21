import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class ABTestingService {
  static final ABTestingService instance = ABTestingService._internal();
  final SupabaseClient _supabase = Supabase.instance.client;
  ABTestingService._internal();

  Future<String> assignVariant(String experimentName, String userId, List<String> variants) async {
    try {
      final existing = await _supabase
          .from('conversion_experiments')
          .select('variant')
          .eq('experiment_name', experimentName)
          .eq('user_id', userId)
          .limit(1);
      if (existing is List && existing.isNotEmpty) {
        return existing.first['variant'] as String;
      }
      final variant = _deterministicPick(userId + experimentName, variants);
      await _supabase.from('conversion_experiments').insert({
        'id': _uuid(),
        'experiment_name': experimentName,
        'user_id': userId,
        'variant': variant,
      });
      return variant;
    } catch (_) {
      return variants.first;
    }
  }

  Future<void> markConverted(String experimentName, String userId) async {
    try {
      await _supabase
          .from('conversion_experiments')
          .update({'converted': true})
          .eq('experiment_name', experimentName)
          .eq('user_id', userId);
    } catch (_) {}
  }

  Future<String> getPromptTimingVariant(String userId) {
    return assignVariant('prompt_timing', userId, ['A', 'B', 'C']);
  }

  Future<String> getMessagingVariant(String userId) {
    return assignVariant('prompt_messaging', userId, ['family', 'benefit', 'value']);
  }

  Future<String> getTrialLengthVariant(String userId) {
    return assignVariant('trial_length', userId, ['30d', '14d_full', '7d_premium_onboarding']);
  }

  String _deterministicPick(String seed, List<String> values) {
    final h = seed.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    final idx = h % values.length;
    return values[idx];
    }

  String _uuid() {
    final rnd = Random();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return _bytesToUuid(bytes);
  }

  String _bytesToUuid(List<int> b) {
    int i(int idx) => b[idx];
    return '${_hex(i(0))}${_hex(i(1))}${_hex(i(2))}${_hex(i(3))}-${_hex(i(4))}${_hex(i(5))}-${_hex(i(6))}${_hex(i(7))}-${_hex(i(8))}${_hex(i(9))}-${_hex(i(10))}${_hex(i(11))}${_hex(i(12))}${_hex(i(13))}${_hex(i(14))}${_hex(i(15))}';
  }

  String _hex(int v) {
    return v.toRadixString(16).padLeft(2, '0');
  }
}
