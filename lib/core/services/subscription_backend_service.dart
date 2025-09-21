import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/user_model.dart';
import '../../features/subscription/models/subscription_status.dart';
import '../../features/subscription/models/payment_method.dart';

class SubscriptionBackendService {
  static const String _stripeApiUrl = 'https://api.stripe.com/v1';
  
  final Dio _dio;
  final SupabaseClient _supabase;
  final String _stripeSecretKey;

  SubscriptionBackendService({
    Dio? dio,
    SupabaseClient? supabase,
  }) : _dio = dio ?? Dio(),
        _supabase = supabase ?? Supabase.instance.client,
        _stripeSecretKey = dotenv.env['STRIPE_SECRET_KEY'] ?? '' {
    
    _configureHttpClient();
  }

  void _configureHttpClient() {
    _dio.options.headers['Authorization'] = 'Bearer $_stripeSecretKey';
    _dio.options.headers['Content-Type'] = 'application/x-www-form-urlencoded';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add interceptor for logging and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('Stripe API Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onError: (error, handler) {
          _handleHttpError(error);
          handler.next(error);
        },
      ),
    );
  }

  void _handleHttpError(DioException error) {
    print('Stripe API Error: ${error.response?.statusCode} - ${error.message}');
    if (error.response?.data != null) {
      print('Error details: ${error.response?.data}');
    }
  }

  // Core subscription operations
  
  /// Create a Stripe customer for the user
  Future<bool> createStripeCustomer(UserProfile user) async {
    try {
      // Check if customer already exists
      if (user.stripeCustomerId?.isNotEmpty == true) {
        return true;
      }

      final response = await _dio.post(
        '$_stripeApiUrl/customers',
        data: {
          'name': user.name,
          'email': user.email,
          'metadata[user_id]': user.id,
          'metadata[family_role]': user.role,
        },
      );

      if (response.statusCode == 200) {
        final customerId = response.data['id'] as String;
        
        // Update user profile with Stripe customer ID
        await _supabase.from('user_profiles').update({
          'stripe_customer_id': customerId,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', user.id);

        return true;
      }
      
      return false;
    } catch (e) {
      print('Error creating Stripe customer: $e');
      return false;
    }
  }

  /// Create a subscription for the user
  Future<String?> createSubscription(String customerId, String priceId) async {
    try {
      final response = await _dio.post(
        '$_stripeApiUrl/subscriptions',
        data: {
          'customer': customerId,
          'items[0][price]': priceId,
          'payment_behavior': 'default_incomplete',
          'payment_settings[save_default_payment_method]': 'on_subscription',
          'expand[]': 'latest_invoice.payment_intent',
          'metadata[source]': 'family_bridge_app',
        },
      );

      if (response.statusCode == 200) {
        final subscriptionData = response.data;
        final subscriptionId = subscriptionData['id'] as String;
        
        // Update user profile with subscription ID
        await _updateUserSubscription(
          customerId: customerId,
          subscriptionId: subscriptionId,
          status: subscriptionData['status'] as String,
          currentPeriodEnd: subscriptionData['current_period_end'] != null 
              ? DateTime.fromMillisecondsSinceEpoch((subscriptionData['current_period_end'] as int) * 1000)
              : null,
        );

        return subscriptionId;
      }
      
      return null;
    } catch (e) {
      print('Error creating subscription: $e');
      return null;
    }
  }

  /// Cancel a subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      final response = await _dio.delete(
        '$_stripeApiUrl/subscriptions/$subscriptionId',
      );

      if (response.statusCode == 200) {
        final subscriptionData = response.data;
        final customerId = subscriptionData['customer'] as String;
        
        await _updateUserSubscription(
          customerId: customerId,
          subscriptionId: subscriptionId,
          status: 'canceled',
          currentPeriodEnd: subscriptionData['current_period_end'] != null 
              ? DateTime.fromMillisecondsSinceEpoch((subscriptionData['current_period_end'] as int) * 1000)
              : null,
        );

        return true;
      }
      
      return false;
    } catch (e) {
      print('Error canceling subscription: $e');
      return false;
    }
  }

  /// Update payment method for a customer
  Future<bool> updatePaymentMethod(String customerId, String paymentMethodId) async {
    try {
      // Attach payment method to customer
      final attachResponse = await _dio.post(
        '$_stripeApiUrl/payment_methods/$paymentMethodId/attach',
        data: {'customer': customerId},
      );

      if (attachResponse.statusCode != 200) {
        return false;
      }

      // Set as default payment method
      final updateResponse = await _dio.post(
        '$_stripeApiUrl/customers/$customerId',
        data: {
          'invoice_settings[default_payment_method]': paymentMethodId,
        },
      );

      if (updateResponse.statusCode == 200) {
        // Save payment method to database
        await _savePaymentMethod(customerId, attachResponse.data);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating payment method: $e');
      return false;
    }
  }

  // Trial management
  
  /// Start trial for a new user
  Future<bool> startTrial(UserProfile user) async {
    try {
      // Create Stripe customer if needed
      bool customerCreated = await createStripeCustomer(user);
      if (!customerCreated) {
        return false;
      }

      // Call database function to start trial
      final response = await _supabase.rpc('start_user_trial', params: {
        'p_user_id': user.id,
      });

      return response == true;
    } catch (e) {
      print('Error starting trial: $e');
      return false;
    }
  }

  /// Convert trial to paid subscription
  Future<bool> convertTrialToPaid(UserProfile user, String paymentMethodId) async {
    try {
      if (user.stripeCustomerId == null) {
        return false;
      }

      // Update payment method
      bool paymentMethodUpdated = await updatePaymentMethod(user.stripeCustomerId!, paymentMethodId);
      if (!paymentMethodUpdated) {
        return false;
      }

      // Create subscription
      final priceId = dotenv.env['STRIPE_PRICE_ID_PREMIUM'] ?? '';
      final subscriptionId = await createSubscription(user.stripeCustomerId!, priceId);
      
      return subscriptionId != null;
    } catch (e) {
      print('Error converting trial to paid: $e');
      return false;
    }
  }

  /// Get subscription status for a user
  Future<SubscriptionInfo?> getSubscriptionStatus(String customerId) async {
    try {
      // Get from database first (faster)
      final dbResponse = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('stripe_customer_id', customerId)
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
      print('Error getting subscription status: $e');
      return null;
    }
  }

  // Payment processing
  
  /// Create a payment intent
  Future<PaymentIntent?> createPaymentIntent(double amount, String customerId) async {
    try {
      final response = await _dio.post(
        '$_stripeApiUrl/payment_intents',
        data: {
          'amount': (amount * 100).round(), // Convert to cents
          'currency': 'usd',
          'customer': customerId,
          'automatic_payment_methods[enabled]': 'true',
          'metadata[source]': 'family_bridge_app',
        },
      );

      if (response.statusCode == 200) {
        return PaymentIntent.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      print('Error creating payment intent: $e');
      return null;
    }
  }

  /// Confirm a payment intent
  Future<bool> confirmPayment(String paymentIntentId) async {
    try {
      final response = await _dio.post(
        '$_stripeApiUrl/payment_intents/$paymentIntentId/confirm',
      );

      return response.statusCode == 200 && response.data['status'] == 'succeeded';
    } catch (e) {
      print('Error confirming payment: $e');
      return false;
    }
  }

  /// Get stored payment methods for a customer
  Future<List<PaymentMethodInfo>> getStoredPaymentMethods(String customerId) async {
    try {
      // Get from database
      final dbResponse = await _supabase
          .from('payment_methods')
          .select('*')
          .eq('user_id', _supabase.auth.currentUser?.id ?? '')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return dbResponse
          .map((data) => PaymentMethodInfo.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting stored payment methods: $e');
      return [];
    }
  }

  // Private helper methods

  Future<void> _updateUserSubscription({
    required String customerId,
    required String subscriptionId,
    required String status,
    DateTime? currentPeriodEnd,
  }) async {
    try {
      await _supabase.rpc('update_subscription_status', params: {
        'p_stripe_customer_id': customerId,
        'p_stripe_subscription_id': subscriptionId,
        'p_status': status,
        'p_current_period_end': currentPeriodEnd?.toIso8601String(),
      });
    } catch (e) {
      print('Error updating user subscription: $e');
    }
  }

  Future<void> _savePaymentMethod(String customerId, Map<String, dynamic> paymentMethodData) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final cardData = paymentMethodData['card'];
      
      await _supabase.from('payment_methods').insert({
        'user_id': userId,
        'stripe_payment_method_id': paymentMethodData['id'],
        'card_last_four': cardData?['last4'],
        'card_brand': cardData?['brand'],
        'card_exp_month': cardData?['exp_month'],
        'card_exp_year': cardData?['exp_year'],
        'billing_name': paymentMethodData['billing_details']?['name'],
        'billing_email': paymentMethodData['billing_details']?['email'],
        'billing_address': json.encode(paymentMethodData['billing_details']?['address'] ?? {}),
        'is_default': true,
        'is_active': true,
      });

      // Set all other payment methods as non-default
      await _supabase
          .from('payment_methods')
          .update({'is_default': false})
          .eq('user_id', userId)
          .neq('stripe_payment_method_id', paymentMethodData['id']);
          
    } catch (e) {
      print('Error saving payment method: $e');
    }
  }

  /// Retry failed payment
  Future<bool> retryFailedPayment(String subscriptionId) async {
    try {
      // Get latest invoice for subscription
      final invoiceResponse = await _dio.get(
        '$_stripeApiUrl/invoices',
        queryParameters: {
          'subscription': subscriptionId,
          'limit': 1,
        },
      );

      if (invoiceResponse.statusCode == 200) {
        final invoices = invoiceResponse.data['data'] as List;
        if (invoices.isNotEmpty) {
          final invoiceId = invoices.first['id'] as String;
          
          // Retry payment for invoice
          final retryResponse = await _dio.post(
            '$_stripeApiUrl/invoices/$invoiceId/pay',
          );

          return retryResponse.statusCode == 200;
        }
      }
      
      return false;
    } catch (e) {
      print('Error retrying failed payment: $e');
      return false;
    }
  }

  /// Get subscription plans
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final response = await _supabase
          .from('subscription_plans')
          .select('*')
          .eq('is_active', true)
          .order('amount');

      return response
          .map((data) => SubscriptionPlan.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting subscription plans: $e');
      return [];
    }
  }

  /// Check if network is available
  Future<bool> _isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('api.stripe.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Handle network errors with retry logic
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
          print('Operation failed after $maxRetries attempts: $e');
          return null;
        }
        
        // Exponential backoff
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    
    return null;
  }

  /// Cleanup resources
  void dispose() {
    _dio.close();
  }
}