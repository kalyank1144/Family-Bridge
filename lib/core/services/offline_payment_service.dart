import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/subscription/models/payment_method.dart';
import 'notification_service.dart';
import 'subscription_backend_service.dart';
import 'subscription_error_handler.dart';

/// Service for handling offline payment processing and queuing
class OfflinePaymentService {
  static const String _queueKey = 'offline_payment_queue';
  static const String _retryTaskName = 'process_offline_payments';
  static const int _maxRetryAttempts = 5;
  static const int _baseBackoffDelayMinutes = 2;

  final SubscriptionBackendService _backendService;
  final SubscriptionErrorHandler _errorHandler;
  final NotificationService _notificationService;
  final Workmanager _workManager;

  OfflinePaymentService({
    required SubscriptionBackendService backendService,
    required SubscriptionErrorHandler errorHandler,
    required NotificationService notificationService,
    required Workmanager workManager,
  })  : _backendService = backendService,
        _errorHandler = errorHandler,
        _notificationService = notificationService,
        _workManager = workManager;

  /// Initialize the offline payment service
  Future<void> initialize() async {
    // Set up connectivity listener
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);

    // Register background task for processing queued payments
    await _workManager.registerPeriodicTask(
      _retryTaskName,
      _retryTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresCharging: false,
      ),
    );

    // Process any existing queued payments on startup
    if (await _isConnected()) {
      unawaited(processQueuedPayments());
    }
  }

  /// Queue a payment attempt for retry when offline
  Future<void> queuePaymentForRetry(PaymentAttempt attempt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queuedPayments = await _getQueuedPaymentAttempts();

      // Check if this payment is already queued
      final existingIndex = queuedPayments.indexWhere(
        (queued) => queued.id == attempt.id,
      );

      if (existingIndex != -1) {
        // Update existing attempt
        queuedPayments[existingIndex] = attempt.copyWith(
          queuedAt: DateTime.now(),
          retryCount: attempt.retryCount + 1,
        );
      } else {
        // Add new attempt
        queuedPayments.add(attempt.copyWith(queuedAt: DateTime.now()));
      }

      // Store updated queue
      final queueJson = queuedPayments
          .map((attempt) => attempt.toJson())
          .toList();
      await prefs.setString(_queueKey, jsonEncode(queueJson));

      // Notify user that payment will be retried when online
      await _notificationService.showLocalNotification(
        title: 'Payment Queued',
        body: 'Payment will be processed when connection is restored',
        data: {
          'type': 'payment_queued',
          'payment_id': attempt.id,
        },
      );

      debugPrint('Payment attempt queued for retry: ${attempt.id}');
    } catch (error) {
      _errorHandler.handleOfflinePaymentError(attempt, error);
    }
  }

  /// Process all queued payment attempts
  Future<void> processQueuedPayments() async {
    if (!await _isConnected()) {
      debugPrint('No internet connection, skipping queued payment processing');
      return;
    }

    try {
      final queuedPayments = await _getQueuedPaymentAttempts();
      if (queuedPayments.isEmpty) return;

      debugPrint('Processing ${queuedPayments.length} queued payments');

      final processedPayments = <PaymentAttempt>[];
      final failedPayments = <PaymentAttempt>[];

      for (final attempt in queuedPayments) {
        try {
          final success = await _processQueuedPayment(attempt);
          
          if (success) {
            processedPayments.add(attempt);
            await _notificationService.showLocalNotification(
              title: 'Payment Processed',
              body: 'Your queued payment has been successfully processed',
              data: {
                'type': 'payment_success',
                'payment_id': attempt.id,
              },
            );
          } else {
            // Check if we should retry or give up
            if (attempt.retryCount >= _maxRetryAttempts) {
              failedPayments.add(attempt);
              await _notificationService.showLocalNotification(
                title: 'Payment Failed',
                body: 'Payment could not be processed after multiple attempts',
                data: {
                  'type': 'payment_failed',
                  'payment_id': attempt.id,
                },
              );
            } else {
              // Schedule for retry with backoff
              await _schedulePaymentRetry(attempt);
            }
          }
        } catch (error) {
          debugPrint('Error processing queued payment ${attempt.id}: $error');
          _errorHandler.handleQueuedPaymentProcessingError(attempt, error);
          
          if (attempt.retryCount >= _maxRetryAttempts) {
            failedPayments.add(attempt);
          }
        }
      }

      // Update queue by removing processed and permanently failed payments
      final remainingPayments = queuedPayments
          .where((attempt) => 
              !processedPayments.contains(attempt) && 
              !failedPayments.contains(attempt))
          .toList();

      await _updatePaymentQueue(remainingPayments);

      debugPrint(
        'Processed ${processedPayments.length} payments, '
        '${failedPayments.length} failed permanently, '
        '${remainingPayments.length} remaining in queue'
      );

    } catch (error) {
      debugPrint('Error processing queued payments: $error');
      _errorHandler.handleQueueProcessingError(error);
    }
  }

  /// Process a single queued payment with retry logic
  Future<bool> _processQueuedPayment(PaymentAttempt attempt) async {
    try {
      // Add exponential backoff delay
      final backoffDelay = _calculateBackoffDelay(attempt.retryCount);
      if (backoffDelay > 0) {
        debugPrint('Applying backoff delay of ${backoffDelay}ms for payment ${attempt.id}');
        await Future.delayed(Duration(milliseconds: backoffDelay));
      }

      // Process payment based on type
      switch (attempt.type) {
        case PaymentAttemptType.subscription:
          return await _processSubscriptionPayment(attempt);
        case PaymentAttemptType.paymentMethod:
          return await _processPaymentMethodUpdate(attempt);
        case PaymentAttemptType.cancellation:
          return await _processSubscriptionCancellation(attempt);
        default:
          debugPrint('Unknown payment attempt type: ${attempt.type}');
          return false;
      }
    } catch (error) {
      debugPrint('Error processing payment attempt ${attempt.id}: $error');
      return false;
    }
  }

  /// Process subscription payment
  Future<bool> _processSubscriptionPayment(PaymentAttempt attempt) async {
    try {
      final paymentData = attempt.data;
      final customerId = paymentData['customer_id'] as String?;
      final priceId = paymentData['price_id'] as String?;

      if (customerId == null || priceId == null) {
        debugPrint('Missing required data for subscription payment');
        return false;
      }

      final subscriptionId = await _backendService.createSubscription(
        customerId,
        priceId,
      );

      return subscriptionId.isNotEmpty;
    } catch (error) {
      debugPrint('Error processing subscription payment: $error');
      return false;
    }
  }

  /// Process payment method update
  Future<bool> _processPaymentMethodUpdate(PaymentAttempt attempt) async {
    try {
      final paymentData = attempt.data;
      final customerId = paymentData['customer_id'] as String?;
      final paymentMethodId = paymentData['payment_method_id'] as String?;

      if (customerId == null || paymentMethodId == null) {
        debugPrint('Missing required data for payment method update');
        return false;
      }

      return await _backendService.updatePaymentMethod(
        customerId,
        paymentMethodId,
      );
    } catch (error) {
      debugPrint('Error processing payment method update: $error');
      return false;
    }
  }

  /// Process subscription cancellation
  Future<bool> _processSubscriptionCancellation(PaymentAttempt attempt) async {
    try {
      final paymentData = attempt.data;
      final subscriptionId = paymentData['subscription_id'] as String?;

      if (subscriptionId == null) {
        debugPrint('Missing subscription ID for cancellation');
        return false;
      }

      return await _backendService.cancelSubscription(subscriptionId);
    } catch (error) {
      debugPrint('Error processing subscription cancellation: $error');
      return false;
    }
  }

  /// Schedule a payment attempt for retry with backoff
  Future<void> _schedulePaymentRetry(PaymentAttempt attempt) async {
    final retryDelay = _calculateBackoffDelay(attempt.retryCount + 1);
    final retryAt = DateTime.now().add(Duration(milliseconds: retryDelay));

    await queuePaymentForRetry(
      attempt.copyWith(
        retryCount: attempt.retryCount + 1,
        nextRetryAt: retryAt,
      ),
    );

    debugPrint(
      'Scheduled payment ${attempt.id} for retry at $retryAt '
      '(attempt ${attempt.retryCount + 1}/$_maxRetryAttempts)'
    );
  }

  /// Calculate exponential backoff delay in milliseconds
  int _calculateBackoffDelay(int retryCount) {
    if (retryCount <= 0) return 0;
    
    final delayMinutes = _baseBackoffDelayMinutes * (1 << (retryCount - 1));
    return delayMinutes * 60 * 1000; // Convert to milliseconds
  }

  /// Get all queued payment attempts
  Future<List<PaymentAttempt>> _getQueuedPaymentAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      
      if (queueJson == null) return [];

      final queueList = jsonDecode(queueJson) as List<dynamic>;
      return queueList
          .map((json) => PaymentAttempt.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Error reading payment queue: $error');
      return [];
    }
  }

  /// Update the payment queue
  Future<void> _updatePaymentQueue(List<PaymentAttempt> attempts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (attempts.isEmpty) {
        await prefs.remove(_queueKey);
      } else {
        final queueJson = attempts
            .map((attempt) => attempt.toJson())
            .toList();
        await prefs.setString(_queueKey, jsonEncode(queueJson));
      }
    } catch (error) {
      debugPrint('Error updating payment queue: $error');
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      debugPrint('Internet connection restored, processing queued payments');
      unawaited(processQueuedPayments());
    }
  }

  /// Check if device has internet connectivity
  Future<bool> _isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Get count of queued payments
  Future<int> getQueuedPaymentCount() async {
    final queuedPayments = await _getQueuedPaymentAttempts();
    return queuedPayments.length;
  }

  /// Clear all queued payments (for testing/admin purposes)
  Future<void> clearPaymentQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
    debugPrint('Payment queue cleared');
  }

  /// Handle app background/foreground changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground, try to process queued payments
      unawaited(processQueuedPayments());
    }
  }

  void dispose() {
    // Clean up resources if needed
  }
}

/// Extension for convenient async operations
extension AsyncOperations on OfflinePaymentService {
  void unawaited(Future<void> future) {
    future.catchError((error) {
      debugPrint('Unawaited operation failed: $error');
    });
  }
}