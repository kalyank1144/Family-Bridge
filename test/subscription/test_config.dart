import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';

/// Test configuration and utilities for subscription tests
class SubscriptionTestConfig {
  /// Setup common test environment
  static void setUp() {
    // Initialize SharedPreferences with empty values
    SharedPreferences.setMockInitialValues({});
    
    // Setup test-specific configuration
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Clean up after tests
  static void tearDown() {
    // Clear any persistent test data
    clearInteractions(any);
  }

  /// Test environment variables for Stripe testing
  static const Map<String, String> testEnvVars = {
    'STRIPE_PUBLISHABLE_KEY': 'pk_test_...',
    'STRIPE_SECRET_KEY': 'sk_test_...',
    'STRIPE_WEBHOOK_SECRET': 'whsec_test...',
    'STRIPE_PRICE_ID_PREMIUM': 'price_test_premium',
    'TRIAL_PERIOD_DAYS': '30',
  };

  /// Mock payment methods for testing
  static const Map<String, dynamic> mockValidCard = {
    'id': 'pm_test_valid',
    'type': 'card',
    'card': {
      'brand': 'visa',
      'last4': '4242',
      'exp_month': 12,
      'exp_year': 2025,
    },
    'is_default': true,
  };

  static const Map<String, dynamic> mockExpiredCard = {
    'id': 'pm_test_expired',
    'type': 'card',
    'card': {
      'brand': 'visa',
      'last4': '4000',
      'exp_month': 1,
      'exp_year': 2020,
    },
    'is_default': false,
  };

  static const Map<String, dynamic> mockDeclinedCard = {
    'id': 'pm_test_declined',
    'type': 'card',
    'card': {
      'brand': 'visa',
      'last4': '0002',
      'exp_month': 12,
      'exp_year': 2025,
    },
    'is_default': false,
  };

  /// Mock subscription data for testing
  static const Map<String, dynamic> mockTrialSubscription = {
    'id': 'sub_test_trial',
    'status': 'trial',
    'current_period_end': '2025-10-21T00:00:00Z',
    'customer_id': 'cus_test_123',
    'price_id': 'price_premium_monthly',
    'trial_end': '2025-10-21T00:00:00Z',
  };

  static const Map<String, dynamic> mockActiveSubscription = {
    'id': 'sub_test_active',
    'status': 'active',
    'current_period_end': '2025-11-21T00:00:00Z',
    'customer_id': 'cus_test_123',
    'price_id': 'price_premium_monthly',
  };

  static const Map<String, dynamic> mockPastDueSubscription = {
    'id': 'sub_test_past_due',
    'status': 'past_due',
    'current_period_end': '2025-09-21T00:00:00Z',
    'customer_id': 'cus_test_123',
    'price_id': 'price_premium_monthly',
  };

  static const Map<String, dynamic> mockCancelledSubscription = {
    'id': 'sub_test_cancelled',
    'status': 'cancelled',
    'current_period_end': '2025-09-21T00:00:00Z',
    'customer_id': 'cus_test_123',
    'price_id': 'price_premium_monthly',
    'cancelled_at': '2025-09-15T00:00:00Z',
  };

  /// Mock user profiles for testing
  static const Map<String, dynamic> mockUserWithStripe = {
    'id': 'user_test_123',
    'email': 'test@example.com',
    'full_name': 'Test User',
    'stripe_customer_id': 'cus_test_123',
    'stripe_subscription_id': 'sub_test_active',
    'subscription_status': 'active',
  };

  static const Map<String, dynamic> mockUserWithoutStripe = {
    'id': 'user_test_456',
    'email': 'newuser@example.com',
    'full_name': 'New User',
  };

  static const Map<String, dynamic> mockUserOnTrial = {
    'id': 'user_test_789',
    'email': 'trial@example.com',
    'full_name': 'Trial User',
    'stripe_customer_id': 'cus_test_789',
    'stripe_subscription_id': 'sub_test_trial',
    'subscription_status': 'trial',
    'trial_end_date': '2025-10-21T00:00:00Z',
  };

  /// Mock payment intents for testing
  static const Map<String, dynamic> mockSuccessfulPaymentIntent = {
    'id': 'pi_test_success',
    'amount': 999, // $9.99 in cents
    'currency': 'usd',
    'status': 'succeeded',
    'client_secret': 'pi_test_success_secret_123',
  };

  static const Map<String, dynamic> mockFailedPaymentIntent = {
    'id': 'pi_test_failed',
    'amount': 999,
    'currency': 'usd',
    'status': 'payment_failed',
    'client_secret': 'pi_test_failed_secret_123',
    'last_payment_error': {
      'code': 'card_declined',
      'message': 'Your card was declined.',
      'decline_code': 'generic_decline',
    },
  };

  /// Mock Stripe webhook events for testing
  static const Map<String, dynamic> mockSubscriptionCreatedEvent = {
    'id': 'evt_test_subscription_created',
    'type': 'customer.subscription.created',
    'data': {
      'object': mockActiveSubscription,
    },
  };

  static const Map<String, dynamic> mockPaymentSucceededEvent = {
    'id': 'evt_test_payment_succeeded',
    'type': 'invoice.payment_succeeded',
    'data': {
      'object': {
        'id': 'in_test_success',
        'customer': 'cus_test_123',
        'subscription': 'sub_test_active',
        'amount_paid': 999,
        'status': 'paid',
        'billing_reason': 'subscription_cycle',
      },
    },
  };

  static const Map<String, dynamic> mockPaymentFailedEvent = {
    'id': 'evt_test_payment_failed',
    'type': 'invoice.payment_failed',
    'data': {
      'object': {
        'id': 'in_test_failed',
        'customer': 'cus_test_123',
        'subscription': 'sub_test_active',
        'amount_due': 999,
        'status': 'open',
        'attempt_count': 1,
        'billing_reason': 'subscription_cycle',
        'last_finalization_error': {
          'message': 'Your card was declined.',
          'code': 'card_declined',
        },
      },
    },
  };

  /// Test error scenarios
  static const Map<String, String> errorScenarios = {
    'network_error': 'Network connection failed',
    'stripe_api_error': 'Stripe API error occurred',
    'card_declined': 'Your card was declined',
    'insufficient_funds': 'Your card has insufficient funds',
    'expired_card': 'Your card has expired',
    'invalid_cvc': 'Your card\'s security code is invalid',
    'invalid_expiry_month': 'Your card\'s expiration month is invalid',
    'invalid_expiry_year': 'Your card\'s expiration year is invalid',
    'processing_error': 'An error occurred while processing your card',
  };

  /// Utility methods for tests
  
  /// Create a future that completes after a delay (for testing async operations)
  static Future<T> delayedResult<T>(T result, {Duration delay = const Duration(milliseconds: 100)}) async {
    await Future.delayed(delay);
    return result;
  }

  /// Create a future that throws an exception after a delay
  static Future<T> delayedError<T>(Exception error, {Duration delay = const Duration(milliseconds: 100)}) async {
    await Future.delayed(delay);
    throw error;
  }

  /// Generate a test payment attempt
  static Map<String, dynamic> generatePaymentAttempt({
    String id = 'pa_test_123',
    String type = 'subscription',
    Map<String, dynamic>? data,
    int retryCount = 0,
  }) {
    return {
      'id': id,
      'type': type,
      'data': data ?? {
        'customer_id': 'cus_test_123',
        'price_id': 'price_premium_monthly',
      },
      'retry_count': retryCount,
      'queued_at': DateTime.now().toIso8601String(),
      'next_retry_at': DateTime.now().add(const Duration(minutes: 2)).toIso8601String(),
    };
  }

  /// Assert that a future completes within a timeout
  static Future<void> expectCompletes<T>(
    Future<T> future, {
    Duration timeout = const Duration(seconds: 5),
    String? reason,
  }) async {
    await expectLater(
      future.timeout(timeout),
      completes,
      reason: reason ?? 'Future should complete within $timeout',
    );
  }

  /// Assert that a future throws a specific exception
  static Future<void> expectThrows<T extends Exception>(
    Future future,
    Matcher matcher, {
    String? reason,
  }) async {
    await expectLater(
      future,
      throwsA(matcher),
      reason: reason,
    );
  }

  /// Setup mock responses for common API calls
  static Map<String, dynamic> mockApiResponses = {
    'create_customer': {
      'success': true,
      'customer_id': 'cus_test_123',
    },
    'create_subscription': {
      'success': true,
      'subscription_id': 'sub_test_123',
      'status': 'active',
    },
    'cancel_subscription': {
      'success': true,
      'cancelled': true,
    },
    'update_payment_method': {
      'success': true,
      'updated': true,
    },
    'start_trial': {
      'success': true,
      'trial_started': true,
    },
  };

  /// Feature flags for testing different scenarios
  static const Map<String, bool> testFeatureFlags = {
    'apple_pay_enabled': true,
    'google_pay_enabled': true,
    'subscription_retry_enabled': true,
    'offline_payment_queue_enabled': true,
    'trial_notifications_enabled': true,
    'subscription_analytics_enabled': false,
  };

  /// Test timeouts for different operations
  static const Map<String, Duration> testTimeouts = {
    'payment_processing': Duration(seconds: 10),
    'subscription_creation': Duration(seconds: 15),
    'api_request': Duration(seconds: 5),
    'offline_sync': Duration(seconds: 30),
    'notification_delivery': Duration(seconds: 3),
  };
}