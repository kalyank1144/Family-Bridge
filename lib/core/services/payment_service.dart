import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stripe_flutter/stripe_flutter.dart' as stripe;

import '../../core/models/user_model.dart';
import '../../features/subscription/models/payment_method.dart';
import '../../features/subscription/models/subscription_status.dart';
import 'subscription_backend_service.dart';
import 'auth_service.dart';

class PaymentService {
  final stripe.Stripe _stripe = stripe.Stripe.instance;
  final SubscriptionBackendService _backend;

  PaymentService({
    SubscriptionBackendService? backend,
  }) : _backend = backend ?? SubscriptionBackendService();

  /// Initialize Stripe with publishable key
  Future<void> initialize() async {
    try {
      final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
      if (publishableKey.isEmpty) {
        throw Exception('Stripe publishable key not found in environment');
      }

      stripe.Stripe.publishableKey = publishableKey;
      stripe.Stripe.merchantIdentifier = 'family_bridge';
      stripe.Stripe.urlScheme = 'familybridge';

      // Enable Apple Pay and Google Pay if available
      if (Platform.isIOS) {
        await stripe.Stripe.instance.isPlatformPaySupported(
          googlePay: stripe.PlatformPayGooglePay(),
        );
      } else if (Platform.isAndroid) {
        await stripe.Stripe.instance.isPlatformPaySupported(
          googlePay: stripe.PlatformPayGooglePay(
            merchantName: 'FamilyBridge',
            merchantCountryCode: 'US',
            testEnvironment: kDebugMode,
          ),
        );
      }

      print('Stripe initialized successfully');
    } catch (e) {
      print('Error initializing Stripe: $e');
      throw Exception('Failed to initialize Stripe: $e');
    }
  }

  /// Handle payment method collection
  Future<PaymentMethodInfo?> collectPaymentMethod(BuildContext context) async {
    try {
      // Create setup intent for future payments
      final setupIntent = await _createSetupIntent();
      if (setupIntent == null) {
        return null;
      }

      // Present payment sheet
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          setupIntentClientSecret: setupIntent.clientSecret,
          merchantDisplayName: 'FamilyBridge',
          style: _getPaymentSheetStyle(context),
          applePay: _getApplePayConfig(),
          googlePay: _getGooglePayConfig(),
        ),
      );

      // Display the payment sheet
      await stripe.Stripe.instance.presentPaymentSheet();

      // Retrieve the setup intent to get the payment method
      final confirmedSetupIntent = await stripe.Stripe.instance.retrieveSetupIntent(
        setupIntent.clientSecret,
      );

      if (confirmedSetupIntent.paymentMethodId != null) {
        // Webhooks will persist details; return a minimal success marker
        return PaymentMethodInfo(
          stripePaymentMethodId: confirmedSetupIntent.paymentMethodId!,
          type: PaymentMethodType.card,
          card: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return null;
    } on stripe.StripeException catch (e) {
      print('Stripe error collecting payment method: ${e.error.localizedMessage}');
      if (e.error.code == stripe.FailureCode.Canceled) {
        // User canceled, this is not an error
        return null;
      }
      throw PaymentException('Failed to collect payment method: ${e.error.localizedMessage}');
    } catch (e) {
      print('Error collecting payment method: $e');
      throw PaymentException('Failed to collect payment method');
    }
  }

  /// Process subscription payment
  Future<SubscriptionOperationResult> processSubscriptionPayment({
    required UserProfile user,
    required String priceId,
    PaymentMethodInfo? paymentMethod,
  }) async {
    try {
      // Ensure user has a Stripe customer ID
      bool customerCreated = await _backend.createStripeCustomer(user);
      if (!customerCreated) {
        return const SubscriptionOperationResult(
          result: SubscriptionResult.unknownError,
          message: 'Failed to create customer account',
        );
      }

      // Update payment method if provided
      if (paymentMethod != null) {
        bool paymentMethodUpdated = await _backend.updatePaymentMethod(
          '',
          paymentMethod.stripePaymentMethodId,
        );
        
        if (!paymentMethodUpdated) {
          return const SubscriptionOperationResult(
            result: SubscriptionResult.invalidPaymentMethod,
            message: 'Failed to save payment method',
          );
        }
      }

      // Create subscription
      final subscriptionId = await _backend.createSubscription('', priceId);
      if (subscriptionId == null) {
        return const SubscriptionOperationResult(
          result: SubscriptionResult.paymentFailed,
          message: 'Failed to create subscription',
        );
      }

      // Get updated subscription info
      final subscriptionInfo = await _backend.getSubscriptionStatus('');
      
      return SubscriptionOperationResult(
        result: SubscriptionResult.success,
        message: 'Subscription created successfully',
        subscription: subscriptionInfo,
      );
      
    } catch (e) {
      print('Error processing subscription payment: $e');
      return SubscriptionOperationResult(
        result: SubscriptionResult.unknownError,
        message: 'Payment processing failed: $e',
      );
    }
  }

  /// Handle payment failures
  Future<void> handlePaymentFailure(String subscriptionId, String reason) async {
    try {
      print('Handling payment failure for subscription $subscriptionId: $reason');
      
      // Log the failure for analytics and debugging
      // In a real app, you might want to send this to your analytics service
      
      // You could also notify the user or trigger retry logic here
      // For now, we'll just log it
      
    } catch (e) {
      print('Error handling payment failure: $e');
    }
  }

  /// Check if Apple Pay is available
  Future<bool> canUseApplePay() async {
    try {
      if (!Platform.isIOS) return false;
      
      return await stripe.Stripe.instance.isPlatformPaySupported();
    } catch (e) {
      print('Error checking Apple Pay availability: $e');
      return false;
    }
  }

  /// Check if Google Pay is available
  Future<bool> canUseGooglePay() async {
    try {
      if (!Platform.isAndroid) return false;
      
      return await stripe.Stripe.instance.isPlatformPaySupported(
        googlePay: stripe.PlatformPayGooglePay(
          merchantName: 'FamilyBridge',
          merchantCountryCode: 'US',
          testEnvironment: kDebugMode,
        ),
      );
    } catch (e) {
      print('Error checking Google Pay availability: $e');
      return false;
    }
  }

  /// Process Apple Pay payment
  Future<PaymentOperationResult> processApplePayPayment(double amount) async {
    try {
      if (!await canUseApplePay()) {
        return const PaymentOperationResult(
          result: PaymentResult.failed,
          message: 'Apple Pay not available',
        );
      }

      final paymentIntent = await _backend.createPaymentIntent(amount, '');
      if (paymentIntent == null) {
        return const PaymentOperationResult(
          result: PaymentResult.failed,
          message: 'Failed to create payment intent',
        );
      }

      await stripe.Stripe.instance.presentApplePay(
        params: stripe.ApplePayPresentParams(
          cartItems: [
            stripe.ApplePayCartSummaryItem.immediate(
              label: 'FamilyBridge Premium',
              amount: amount.toStringAsFixed(2),
            ),
          ],
          country: 'US',
          currency: 'USD',
        ),
      );

      final confirmedPaymentIntent = await stripe.Stripe.instance.confirmApplePayPayment(
        paymentIntent.clientSecret,
      );

      if (confirmedPaymentIntent.status == stripe.PaymentIntentsStatus.Succeeded) {
        return const PaymentOperationResult(
          result: PaymentResult.success,
          message: 'Apple Pay payment successful',
        );
      }

      return const PaymentOperationResult(
        result: PaymentResult.failed,
        message: 'Apple Pay payment failed',
      );
      
    } on stripe.StripeException catch (e) {
      if (e.error.code == stripe.FailureCode.Canceled) {
        return const PaymentOperationResult(
          result: PaymentResult.canceled,
          message: 'Payment canceled by user',
        );
      }
      
      return PaymentOperationResult(
        result: PaymentResult.failed,
        message: e.error.localizedMessage ?? 'Apple Pay failed',
      );
    } catch (e) {
      return PaymentOperationResult(
        result: PaymentResult.failed,
        message: 'Apple Pay error: $e',
      );
    }
  }

  /// Process Google Pay payment
  Future<PaymentOperationResult> processGooglePayPayment(double amount) async {
    try {
      if (!await canUseGooglePay()) {
        return const PaymentOperationResult(
          result: PaymentResult.failed,
          message: 'Google Pay not available',
        );
      }

      final paymentIntent = await _backend.createPaymentIntent(amount, '');
      if (paymentIntent == null) {
        return const PaymentOperationResult(
          result: PaymentResult.failed,
          message: 'Failed to create payment intent',
        );
      }

      await stripe.Stripe.instance.initGooglePay(
        stripe.GooglePayInitParams(
          testEnvironment: kDebugMode,
          merchantName: 'FamilyBridge',
          countryCode: 'US',
        ),
      );

      await stripe.Stripe.instance.presentGooglePay(
        params: stripe.PresentGooglePayParams(
          clientSecret: paymentIntent.clientSecret,
          forSetupIntent: false,
        ),
      );

      return const PaymentOperationResult(
        result: PaymentResult.success,
        message: 'Google Pay payment successful',
      );
      
    } on stripe.StripeException catch (e) {
      if (e.error.code == stripe.FailureCode.Canceled) {
        return const PaymentOperationResult(
          result: PaymentResult.canceled,
          message: 'Payment canceled by user',
        );
      }
      
      return PaymentOperationResult(
        result: PaymentResult.failed,
        message: e.error.localizedMessage ?? 'Google Pay failed',
      );
    } catch (e) {
      return PaymentOperationResult(
        result: PaymentResult.failed,
        message: 'Google Pay error: $e',
      );
    }
  }

  // Private helper methods

  Future<SetupIntentResult?> _createSetupIntent() async {
    try {
      final res = await SubscriptionBackendService()._supabase.functions.invoke(
        'stripe-create-setup-intent',
      );
      final data = (res.data is String)
          ? (jsonDecode(res.data as String) as Map<String, dynamic>)
          : res.data as Map<String, dynamic>;
      final clientSecret = data['client_secret'] as String?;
      final id = data['setup_intent_id'] as String?;
      if (clientSecret == null || id == null) return null;
      return SetupIntentResult(clientSecret: clientSecret, id: id);
    } catch (e) {
      print('Error creating setup intent: $e');
      return null;
    }
  }

  stripe.ThemeMode _getPaymentSheetStyle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark 
        ? stripe.ThemeMode.dark 
        : stripe.ThemeMode.light;
  }

  stripe.PaymentSheetApplePay? _getApplePayConfig() {
    if (!Platform.isIOS) return null;
    
    return const stripe.PaymentSheetApplePay(
      merchantCountryCode: 'US',
    );
  }

  stripe.PaymentSheetGooglePay? _getGooglePayConfig() {
    if (!Platform.isAndroid) return null;
    
    return stripe.PaymentSheetGooglePay(
      merchantCountryCode: 'US',
      testEnvironment: kDebugMode,
    );
  }

  /// Get current user from auth service
  UserProfile? getCurrentUser() {
    // Lightweight access via AuthService singleton
    // Returns basic profile (without Stripe fields)
    // Consumers should rely on backend for Stripe customer mapping
    return AuthService.instance.currentUser;
  }

  /// Cleanup resources
  void dispose() {
    _backend.dispose();
  }
}

class PaymentException implements Exception {
  final String message;
  final String? code;

  const PaymentException(this.message, [this.code]);

  @override
  String toString() => 'PaymentException: $message${code != null ? ' (Code: $code)' : ''}';
}

class SetupIntentResult {
  final String clientSecret;
  final String id;

  const SetupIntentResult({
    required this.clientSecret,
    required this.id,
  });
}