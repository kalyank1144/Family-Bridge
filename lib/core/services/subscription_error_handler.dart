import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/models/user_model.dart';
import '../../features/subscription/models/payment_method.dart';
import '../../features/subscription/models/subscription_status.dart';
import 'notification_service.dart';
import 'subscription_backend_service.dart';
import 'subscription_lifecycle_service.dart';

class SubscriptionErrorHandler {
  final SupabaseClient _supabase;
  final NotificationService _notificationService;
  final SubscriptionBackendService _backend;
  final SubscriptionLifecycleService _lifecycle;
  final Connectivity _connectivity;

  // Error tracking
  final Map<String, int> _retryCount = {};
  final Map<String, DateTime> _lastErrorTime = {};
  
  // Constants for retry logic
  static const int maxRetryAttempts = 3;
  static const Duration retryBackoffBase = Duration(seconds: 2);
  static const Duration maxBackoffTime = Duration(minutes: 5);

  SubscriptionErrorHandler({
    SupabaseClient? supabase,
    NotificationService? notificationService,
    SubscriptionBackendService? backend,
    SubscriptionLifecycleService? lifecycle,
    Connectivity? connectivity,
  }) : _supabase = supabase ?? Supabase.instance.client,
        _notificationService = notificationService ?? NotificationService(),
        _backend = backend ?? SubscriptionBackendService(),
        _lifecycle = lifecycle ?? SubscriptionLifecycleService(),
        _connectivity = connectivity ?? Connectivity();

  // Payment failures

  /// Handle payment declined errors
  Future<void> handlePaymentDeclined(UserProfile user, String reason) async {
    try {
      print('Payment declined for user ${user.name}: $reason');
      
      // Log the error
      await _logPaymentError(user, 'payment_declined', reason);
      
      // Determine the specific decline reason and handle accordingly
      final declineCode = _extractDeclineCode(reason);
      
      switch (declineCode) {
        case 'insufficient_funds':
          await handleInsufficientFunds(user);
          break;
        case 'expired_card':
          await handleExpiredCard(user);
          break;
        case 'card_declined':
          await _handleCardDeclined(user, reason);
          break;
        case 'invalid_cvc':
          await _handleInvalidCVC(user);
          break;
        case 'processing_error':
          await _handleProcessingError(user, reason);
          break;
        default:
          await _handleGenericDecline(user, reason);
      }
      
      // Offer alternative payment methods
      await offerAlternativePaymentMethods(user);
      
    } catch (e) {
      print('Error handling payment declined: $e');
      await _logSystemError('handlePaymentDeclined', e.toString(), {'user_id': user.id});
    }
  }

  /// Handle insufficient funds scenario
  Future<void> handleInsufficientFunds(UserProfile user) async {
    try {
      print('Insufficient funds for user ${user.name}');
      
      // Send specific notification about insufficient funds
      await _notificationService.sendNotification(
        userId: user.id,
        title: 'Payment Failed - Insufficient Funds 💳',
        message: 'Your payment couldn\'t be processed due to insufficient funds. Please check your account or use a different payment method.',
        type: 'payment_insufficient_funds',
        data: {
          'action': 'update_payment_method',
          'suggested_actions': ['add_funds', 'change_card', 'contact_bank'],
        },
      );
      
      // Schedule a retry in 24 hours
      await schedulePaymentRetry(user, 24 * 60); // 24 hours in minutes
      
      // Log the failed payment attempt
      await _logFailedPaymentAttempt(user, 'insufficient_funds', 'Insufficient funds in account');
      
    } catch (e) {
      print('Error handling insufficient funds: $e');
      await _logSystemError('handleInsufficientFunds', e.toString(), {'user_id': user.id});
    }
  }

  /// Handle expired card scenario
  Future<void> handleExpiredCard(UserProfile user) async {
    try {
      print('Expired card for user ${user.name}');
      
      // Send notification about expired card
      await _notificationService.sendNotification(
        userId: user.id,
        title: 'Payment Failed - Card Expired 📅',
        message: 'Your payment card has expired. Please update your payment method to continue your subscription.',
        type: 'payment_expired_card',
        data: {
          'action': 'update_payment_method',
          'urgency': 'high',
        },
      );
      
      // Don't retry automatically for expired cards - user must update
      await _logFailedPaymentAttempt(user, 'expired_card', 'Payment method has expired');
      
      // Start grace period
      await _lifecycle.handleGracefulDegradation(user);
      
    } catch (e) {
      print('Error handling expired card: $e');
      await _logSystemError('handleExpiredCard', e.toString(), {'user_id': user.id});
    }
  }

  // Subscription issues

  /// Handle subscription creation failure
  Future<void> handleSubscriptionCreationFailure(UserProfile user) async {
    try {
      print('Subscription creation failed for user ${user.name}');
      
      final errorKey = 'subscription_creation_${user.id}';
      _retryCount[errorKey] = (_retryCount[errorKey] ?? 0) + 1;
      
      if (_retryCount[errorKey]! < maxRetryAttempts) {
        // Retry with exponential backoff
        final retryDelay = _calculateRetryDelay(_retryCount[errorKey]!);
        
        await Future.delayed(retryDelay);
        
        // Attempt to recreate subscription
        await _retrySubscriptionCreation(user);
      } else {
        // Maximum retries reached
        await _notificationService.sendNotification(
          userId: user.id,
          title: 'Subscription Setup Failed',
          message: 'We couldn\'t set up your subscription. Our support team has been notified.',
          type: 'subscription_creation_failed',
          data: {'action': 'contact_support'},
        );
        
        await _escalateToSupport(user, 'subscription_creation_failed');
      }
      
    } catch (e) {
      print('Error handling subscription creation failure: $e');
      await _logSystemError('handleSubscriptionCreationFailure', e.toString(), {'user_id': user.id});
    }
  }

  /// Handle webhook processing failure
  Future<void> handleWebhookProcessingFailure(String eventId) async {
    try {
      print('Webhook processing failed for event: $eventId');
      
      final errorKey = 'webhook_$eventId';
      _retryCount[errorKey] = (_retryCount[errorKey] ?? 0) + 1;
      
      if (_retryCount[errorKey]! < maxRetryAttempts) {
        // Schedule webhook retry
        await _scheduleWebhookRetry(eventId, _retryCount[errorKey]!);
      } else {
        // Log as permanent failure
        await _supabase.from('subscription_events').update({
          'processed': false,
          'processing_error': 'Max retry attempts exceeded',
        }).eq('stripe_event_id', eventId);
        
        await _logSystemError('webhook_processing_failure', 'Max retries exceeded', {'event_id': eventId});
      }
      
    } catch (e) {
      print('Error handling webhook processing failure: $e');
      await _logSystemError('handleWebhookProcessingFailure', e.toString(), {'event_id': eventId});
    }
  }

  /// Handle duplicate subscription scenario
  Future<void> handleDuplicateSubscription(UserProfile user) async {
    try {
      print('Duplicate subscription detected for user ${user.name}');
      
      // Cancel the duplicate subscription
      final userSubscriptions = await _getAllUserSubscriptions(user.stripeCustomerId!);
      
      if (userSubscriptions.length > 1) {
        // Keep the most recent active subscription
        userSubscriptions.sort((a, b) => b['created'].compareTo(a['created']));
        
        for (int i = 1; i < userSubscriptions.length; i++) {
          await _backend.cancelSubscription(userSubscriptions[i]['id']);
        }
        
        await _notificationService.sendNotification(
          userId: user.id,
          title: 'Subscription Duplicate Resolved',
          message: 'We found and resolved duplicate subscriptions on your account.',
          type: 'duplicate_subscription_resolved',
          data: {'action': 'view_billing'},
        );
      }
      
    } catch (e) {
      print('Error handling duplicate subscription: $e');
      await _logSystemError('handleDuplicateSubscription', e.toString(), {'user_id': user.id});
    }
  }

  // Network issues

  /// Handle Stripe API failures
  Future<void> handleStripeApiFailure(Exception error) async {
    try {
      print('Stripe API failure: $error');
      
      final errorMessage = error.toString();
      final errorKey = 'stripe_api_failure';
      
      // Check if it's a temporary network issue
      if (await _isNetworkAvailable()) {
        // Network is available, likely a Stripe API issue
        if (errorMessage.contains('rate_limit')) {
          await _handleRateLimitError(errorMessage);
        } else if (errorMessage.contains('api_connection_error')) {
          await _handleApiConnectionError(errorMessage);
        } else {
          await _handleGenericApiError(errorMessage);
        }
      } else {
        // Network is unavailable
        await _handleNetworkUnavailableError();
      }
      
    } catch (e) {
      print('Error handling Stripe API failure: $e');
      await _logSystemError('handleStripeApiFailure', e.toString(), {'original_error': error.toString()});
    }
  }

  /// Handle offline payment attempts
  Future<void> handleOfflinePaymentAttempt(UserProfile user) async {
    try {
      print('Offline payment attempt for user ${user.name}');
      
      // Queue the payment for later processing
      await _queueOfflinePayment(user);
      
      // Notify user about offline mode
      await _notificationService.sendNotification(
        userId: user.id,
        title: 'Payment Queued - No Internet',
        message: 'Your payment will be processed when you\'re back online.',
        type: 'payment_queued_offline',
        data: {'action': 'check_connection'},
      );
      
      // Set up connectivity listener to retry when online
      await _setupConnectivityRetry(user.id);
      
    } catch (e) {
      print('Error handling offline payment attempt: $e');
      await _logSystemError('handleOfflinePaymentAttempt', e.toString(), {'user_id': user.id});
    }
  }

  // Recovery mechanisms

  /// Retry a failed payment
  Future<bool> retryFailedPayment(String subscriptionId) async {
    try {
      print('Retrying failed payment for subscription: $subscriptionId');
      
      final success = await _backend.retryFailedPayment(subscriptionId);
      
      if (success) {
        // Clear retry count on success
        _retryCount.remove('payment_$subscriptionId');
        print('Payment retry successful');
      } else {
        print('Payment retry failed');
      }
      
      return success;
      
    } catch (e) {
      print('Error retrying failed payment: $e');
      await _logSystemError('retryFailedPayment', e.toString(), {'subscription_id': subscriptionId});
      return false;
    }
  }

  /// Schedule payment retry with delay
  Future<void> schedulePaymentRetry(UserProfile user, int delayMinutes) async {
    try {
      await Workmanager().registerOneOffTask(
        'payment_retry_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
        'retry_payment',
        inputData: {
          'user_id': user.id,
          'stripe_customer_id': user.stripeCustomerId,
        },
        initialDelay: Duration(minutes: delayMinutes),
      );
      
      print('Payment retry scheduled for ${user.name} in $delayMinutes minutes');
      
    } catch (e) {
      print('Error scheduling payment retry: $e');
      await _logSystemError('schedulePaymentRetry', e.toString(), {'user_id': user.id});
    }
  }

  /// Offer alternative payment methods
  Future<void> offerAlternativePaymentMethods(UserProfile user) async {
    try {
      // Check available payment methods
      final availablePaymentMethods = <String>[];
      
      // Check if Apple Pay is available
      if (Platform.isIOS) {
        availablePaymentMethods.add('apple_pay');
      }
      
      // Check if Google Pay is available
      if (Platform.isAndroid) {
        availablePaymentMethods.add('google_pay');
      }
      
      // Always offer credit card as alternative
      availablePaymentMethods.add('credit_card');
      
      await _notificationService.sendNotification(
        userId: user.id,
        title: 'Try a Different Payment Method',
        message: 'Having payment issues? Try using a different payment method.',
        type: 'alternative_payment_methods',
        data: {
          'action': 'choose_payment_method',
          'available_methods': availablePaymentMethods,
        },
      );
      
    } catch (e) {
      print('Error offering alternative payment methods: $e');
      await _logSystemError('offerAlternativePaymentMethods', e.toString(), {'user_id': user.id});
    }
  }

  // Private helper methods

  String _extractDeclineCode(String reason) {
    final lowerReason = reason.toLowerCase();
    
    if (lowerReason.contains('insufficient') || lowerReason.contains('funds')) {
      return 'insufficient_funds';
    } else if (lowerReason.contains('expired')) {
      return 'expired_card';
    } else if (lowerReason.contains('declined') || lowerReason.contains('decline')) {
      return 'card_declined';
    } else if (lowerReason.contains('cvc') || lowerReason.contains('security')) {
      return 'invalid_cvc';
    } else if (lowerReason.contains('processing') || lowerReason.contains('error')) {
      return 'processing_error';
    }
    
    return 'generic_decline';
  }

  Future<void> _handleCardDeclined(UserProfile user, String reason) async {
    await _notificationService.sendNotification(
      userId: user.id,
      title: 'Payment Declined 🚫',
      message: 'Your card was declined. Please contact your bank or try a different payment method.',
      type: 'payment_card_declined',
      data: {
        'action': 'contact_bank_or_change_card',
        'decline_reason': reason,
      },
    );
  }

  Future<void> _handleInvalidCVC(UserProfile user) async {
    await _notificationService.sendNotification(
      userId: user.id,
      title: 'Invalid Security Code',
      message: 'The security code (CVC) for your card is invalid. Please update your payment method.',
      type: 'payment_invalid_cvc',
      data: {'action': 'update_payment_method'},
    );
  }

  Future<void> _handleProcessingError(UserProfile user, String reason) async {
    // Schedule retry for processing errors
    await schedulePaymentRetry(user, 30); // Retry in 30 minutes
    
    await _notificationService.sendNotification(
      userId: user.id,
      title: 'Payment Processing Issue',
      message: 'We encountered a temporary issue processing your payment. We\'ll try again shortly.',
      type: 'payment_processing_error',
      data: {'action': 'wait_for_retry'},
    );
  }

  Future<void> _handleGenericDecline(UserProfile user, String reason) async {
    await _notificationService.sendNotification(
      userId: user.id,
      title: 'Payment Failed',
      message: 'Your payment couldn\'t be processed. Please try a different payment method.',
      type: 'payment_generic_decline',
      data: {
        'action': 'update_payment_method',
        'reason': reason,
      },
    );
  }

  Duration _calculateRetryDelay(int attemptNumber) {
    final exponentialDelay = retryBackoffBase * (1 << (attemptNumber - 1));
    return exponentialDelay > maxBackoffTime ? maxBackoffTime : exponentialDelay;
  }

  Future<void> _retrySubscriptionCreation(UserProfile user) async {
    try {
      // Implementation would depend on specific subscription creation logic
      // This is a placeholder for the retry mechanism
      print('Retrying subscription creation for ${user.name}');
    } catch (e) {
      print('Error in subscription creation retry: $e');
    }
  }

  Future<void> _escalateToSupport(UserProfile user, String issue) async {
    await _supabase.from('support_tickets').insert({
      'user_id': user.id,
      'issue_type': issue,
      'priority': 'high',
      'description': 'Automatic escalation from subscription error handler',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _scheduleWebhookRetry(String eventId, int attemptNumber) async {
    final retryDelay = _calculateRetryDelay(attemptNumber);
    
    await Workmanager().registerOneOffTask(
      'webhook_retry_${eventId}_$attemptNumber',
      'retry_webhook_processing',
      inputData: {
        'event_id': eventId,
        'attempt_number': attemptNumber,
      },
      initialDelay: retryDelay,
    );
  }

  Future<List<Map<String, dynamic>>> _getAllUserSubscriptions(String customerId) async {
    // This would typically be done through Stripe API
    // Placeholder implementation
    return [];
  }

  Future<bool> _isNetworkAvailable() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleRateLimitError(String errorMessage) async {
    print('Rate limit error: $errorMessage');
    // Wait before retrying
    await Future.delayed(const Duration(seconds: 60));
  }

  Future<void> _handleApiConnectionError(String errorMessage) async {
    print('API connection error: $errorMessage');
    // Implement exponential backoff for connection errors
  }

  Future<void> _handleGenericApiError(String errorMessage) async {
    print('Generic API error: $errorMessage');
    await _logSystemError('stripe_api_error', errorMessage, {});
  }

  Future<void> _handleNetworkUnavailableError() async {
    print('Network unavailable during Stripe API call');
    // Queue operations for later when network is available
  }

  Future<void> _queueOfflinePayment(UserProfile user) async {
    await _supabase.from('offline_payment_queue').insert({
      'user_id': user.id,
      'payment_type': 'subscription_payment',
      'payment_data': {
        'customer_id': user.stripeCustomerId,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'status': 'pending',
    });
  }

  Future<void> _setupConnectivityRetry(String userId) async {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        // Network is back, process queued payments
        _processQueuedPayments(userId);
      }
    });
  }

  Future<void> _processQueuedPayments(String userId) async {
    try {
      final queuedPayments = await _supabase
          .from('offline_payment_queue')
          .select('*')
          .eq('user_id', userId)
          .eq('status', 'pending');

      for (final payment in queuedPayments) {
        // Process each queued payment
        await _processQueuedPayment(payment);
      }
    } catch (e) {
      print('Error processing queued payments: $e');
    }
  }

  Future<void> _processQueuedPayment(Map<String, dynamic> payment) async {
    try {
      // Update status to processing
      await _supabase
          .from('offline_payment_queue')
          .update({'status': 'processing'})
          .eq('id', payment['id']);

      // Process the payment based on type
      final paymentType = payment['payment_type'] as String;
      final paymentData = payment['payment_data'] as Map<String, dynamic>;

      bool success = false;
      switch (paymentType) {
        case 'subscription_payment':
          // Process subscription payment
          success = await _processSubscriptionPayment(paymentData);
          break;
        // Add other payment types as needed
      }

      // Update status based on result
      await _supabase
          .from('offline_payment_queue')
          .update({
            'status': success ? 'completed' : 'failed',
            'completed_at': success ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', payment['id']);

    } catch (e) {
      print('Error processing queued payment: $e');
      
      // Mark as failed
      await _supabase
          .from('offline_payment_queue')
          .update({'status': 'failed'})
          .eq('id', payment['id']);
    }
  }

  Future<bool> _processSubscriptionPayment(Map<String, dynamic> paymentData) async {
    // Implement subscription payment processing
    // This is a placeholder
    return true;
  }

  Future<void> _logPaymentError(UserProfile user, String errorType, String errorMessage) async {
    await _supabase.from('failed_payment_attempts').insert({
      'user_id': user.id,
      'stripe_subscription_id': user.stripeSubscriptionId,
      'failure_code': errorType,
      'failure_message': errorMessage,
      'attempt_number': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _logFailedPaymentAttempt(UserProfile user, String failureCode, String failureMessage) async {
    await _supabase.from('failed_payment_attempts').insert({
      'user_id': user.id,
      'failure_code': failureCode,
      'failure_message': failureMessage,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _logSystemError(String operation, String error, Map<String, dynamic> context) async {
    try {
      await _supabase.from('system_errors').insert({
        'operation': operation,
        'error_message': error,
        'context': context,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to log system error: $e');
    }
  }

  /// Cleanup resources
  void dispose() {
    _retryCount.clear();
    _lastErrorTime.clear();
  }
}