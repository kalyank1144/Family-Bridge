import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';

abstract class CacheStore {
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
}

class MemoryCacheStore implements CacheStore {
  final Map<String, String> _store = {};
  @override
  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }
  @override
  Future<String?> getString(String key) async {
    return _store[key];
  }
}

abstract class PaymentGateway {
  Future<bool> startCheckout({required String userId, required String planName});
}

class TrialService {
  final dynamic supabase;
  final CacheStore cache;
  final PaymentGateway? paymentGateway;
  TrialService({this.supabase, CacheStore? cache, this.paymentGateway}) : cache = cache ?? MemoryCacheStore();
  bool isInTrialPeriod(UserProfile user) {
    if (user.subscriptionStatus == 'premium') return false;
    if (user.trialEndDate == null) return false;
    final now = DateTime.now().toUtc();
    return now.isBefore(user.trialEndDate!.toUtc());
  }
  int getRemainingTrialDays(UserProfile user) {
    if (user.trialEndDate == null) return 0;
    final now = DateTime.now().toUtc();
    final diff = user.trialEndDate!.toUtc().difference(now).inDays;
    return diff > 0 ? diff : 0;
  }
  bool isFeatureAvailable(String featureKey, UserProfile user) {
    if (isInTrialPeriod(user)) return true;
    if (user.subscriptionStatus == 'premium') return true;
    const premiumOnly = {
      'advanced_health_analytics',
      'professional_reports',
      'family_archive_export',
    };
    if (premiumOnly.contains(featureKey)) return false;
    return true;
  }
  Future<void> trackFeatureUsage(String featureKey, UserProfile user) async {
    final key = 'feature_usage_${user.id}';
    final now = DateTime.now().toIso8601String();
    final tracking = Map<String, dynamic>.from(user.featureUsageTracking);
    final f = Map<String, dynamic>.from(tracking[featureKey] ?? {});
    final c = (f['count'] ?? 0) is int ? f['count'] : int.tryParse(f['count']?.toString() ?? '0') ?? 0;
    f['count'] = c + 1;
    f['last_used_at'] = now;
    tracking[featureKey] = f;
    final cached = jsonEncode(tracking);
    await cache.setString(key, cached);
    try {
      if (supabase != null) {
        await supabase.from('user_profiles').update({'feature_usage_tracking': tracking}).eq('id', user.id);
      }
    } catch (e) {
      if (kDebugMode) {}
    }
  }
  Future<bool> convertTrialToPremium(UserProfile user) async {
    bool paid = true;
    if (paymentGateway != null) {
      paid = await paymentGateway!.startCheckout(userId: user.id, planName: 'premium');
    }
    if (!paid) return false;
    try {
      if (supabase != null) {
        await supabase.from('user_profiles').update({'subscription_status': 'premium'}).eq('id', user.id);
      }
    } catch (e) {
      if (kDebugMode) {}
      return false;
    }
    return true;
  }
  Map<String, dynamic> getTrialUsageAnalytics(UserProfile user) {
    final tracking = Map<String, dynamic>.from(user.featureUsageTracking);
    final result = <String, dynamic>{};
    for (final entry in tracking.entries) {
      final v = Map<String, dynamic>.from(entry.value is Map ? entry.value : {});
      result[entry.key] = {
        'count': v['count'] ?? 0,
        'last_used_at': v['last_used_at'],
      };
    }
    result['remaining_trial_days'] = getRemainingTrialDays(user);
    result['in_trial'] = isInTrialPeriod(user);
    return result;
  }
}