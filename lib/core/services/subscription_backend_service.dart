import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/user_model.dart';
import '../../features/subscription/models/subscription_status.dart';
import '../../features/subscription/models/payment_method.dart';

class SubscriptionBackendService {
  final SupabaseClient _supabase;

  SubscriptionBackendService({
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client;

  // Secure operations are handled by Supabase Edge Functions.
  // No Stripe secret keys in the client.

  Future<bool> createStripeCustomer(UserProfile user) async {
    try {
      final res = await _supabase.functions.invoke(
        'stripe-manage-subscription',
        headers: { 'Content-Type': 'application/json' },
        queryParameters: { 'action': 'status' },
      );
      final data = (res.data is String) ? json.decode(res.data as String) : res.data as Map<String, dynamic>;
      return (data['stripe_customer_id'] as String?)?.isNotEmpty == true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> createSubscription(String customerId, String priceId) async {
    try {
      final res = await _supabase.functions.invoke(
        'stripe-manage-subscription',
        body: jsonEncode({ 'action': 'create', 'price_id': priceId }),
      );
      final data = (res.data is String) ? json.decode(res.data as String) : res.data as Map<String, dynamic>;
      return data['subscription_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      final res = await _supabase.functions.invoke(
        'stripe-manage-subscription',
        body: jsonEncode({ 'action': 'cancel', 'subscription_id': subscriptionId }),
      );
      final data = (res.data is String) ? json.decode(res.data as String) : res.data as Map<String, dynamic>;
      return data['cancelled'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updatePaymentMethod(String customerId, String paymentMethodId) async {
    try {
      final res = await _supabase.functions.invoke(
        'stripe-manage-subscription',
        body: jsonEncode({ 'action': 'set_default_payment_method', 'payment_method_id': paymentMethodId }),
      );
      final data = (res.data is String) ? json.decode(res.data as String) : res.data as Map<String, dynamic>;
      return data['updated'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> startTrial(UserProfile user) async {
    try {
      final response = await _supabase.rpc('start_user_trial', params: {
        'p_user_id': user.id,
      });
      return response == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> convertTrialToPaid(UserProfile user, String paymentMethodId) async {
    try {
      final ok = await updatePaymentMethod('', paymentMethodId);
      if (!ok) return false;
      final priceId = dotenv.env['STRIPE_PRICE_ID_PREMIUM'] ?? '';
      if (priceId.isEmpty) return false;
      final subId = await createSubscription('', priceId);
      return subId != null && subId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<SubscriptionInfo?> getSubscriptionStatus(String customerId) async {
    try {
      final dbResponse = await _supabase
          .from('user_profiles')
          .select('stripe_subscription_id, stripe_customer_id, subscription_status, subscription_current_period_end, trial_started_at, trial_ends_at')
          .eq('user_id', _supabase.auth.currentUser?.id ?? '')
          .maybeSingle();

      if (dbResponse != null) {
        return SubscriptionInfo.fromJson({
          'id': dbResponse['stripe_subscription_id'],
          'customer_id': dbResponse['stripe_customer_id'],
          'status': dbResponse['subscription_status'] ?? 'trial',
          'current_period_end': dbResponse['subscription_current_period_end'],
          'trial_start': dbResponse['trial_started_at'],
          'trial_end': dbResponse['trial_ends_at'],
        });
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PaymentIntent?> createPaymentIntent(double amount, String customerId) async {
    try {
      final res = await _supabase.functions.invoke(
        'stripe-create-payment-intent',
        body: jsonEncode({ 'amount': amount }),
      );
      final data = (res.data is String) ? json.decode(res.data as String) : res.data as Map<String, dynamic>;
      return PaymentIntent.fromJson({
        'id': data['id'],
        'client_secret': data['client_secret'],
        'amount': data['amount'],
        'currency': data['currency'] ?? 'usd',
        'customer': data['customer_id'],
        'status': 'requires_confirmation',
        'created': (DateTime.now().millisecondsSinceEpoch / 1000).round(),
      });
    } catch (e) {
      return null;
    }
  }

  Future<List<PaymentMethodInfo>> getStoredPaymentMethods(String customerId) async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? '';
      if (userId.isEmpty) return [];
      final dbResponse = await _supabase
          .from('payment_methods')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (dbResponse as List<dynamic>)
          .map((data) => PaymentMethodInfo.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> retryFailedPayment(String subscriptionId) async {
    // Handled via server-side billing retries and webhook; client can trigger checks elsewhere
    return false;
  }

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final response = await _supabase
          .from('subscription_plans')
          .select('*')
          .eq('is_active', true)
          .order('amount');

      return (response as List<dynamic>)
          .map((data) => SubscriptionPlan.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> _isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('api.stripe.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<T?> _executeWithRetry<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        if (!await _isNetworkAvailable()) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          attempt++;
          continue;
        }
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          return null;
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    return null;
  }

  void dispose() {}
}
