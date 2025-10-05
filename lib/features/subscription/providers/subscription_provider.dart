import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:family_bridge/core/models/user_model.dart';
import 'package:family_bridge/core/services/auth_service.dart';
import 'package:family_bridge/core/services/notification_service.dart';
import 'package:family_bridge/core/services/offline_payment_service.dart';
import 'package:family_bridge/core/services/payment_service.dart';
import 'package:family_bridge/core/services/subscription_backend_service.dart';
import 'package:family_bridge/core/services/subscription_error_handler.dart';
import 'package:family_bridge/core/services/subscription_lifecycle_service.dart';
import 'package:family_bridge/features/subscription/models/payment_method.dart';
import 'package:family_bridge/features/subscription/models/subscription_status.dart';

/// Provider for managing subscription state and operations
class SubscriptionProvider extends ChangeNotifier {
  final PaymentService _paymentService;
  final SubscriptionBackendService _backendService;
  final SubscriptionLifecycleService _lifecycleService;
  final SubscriptionErrorHandler _errorHandler;
  final OfflinePaymentService _offlinePaymentService;
  final NotificationService _notificationService;
  final AuthService _authService;

  // State variables
  SubscriptionInfo? _subscription;
  List<PaymentMethodInfo> _paymentMethods = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  Timer? _statusCheckTimer;
  Timer? _trialWarningTimer;

  // Getters
  SubscriptionInfo? get subscription => _subscription;
  List<PaymentMethodInfo> get paymentMethods => List.unmodifiable(_paymentMethods);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Subscription status getters
  bool get hasActiveSubscription => 
      _subscription?.status.isActive ?? false;
  bool get isTrialActive => 
      _subscription?.status.isTrial ?? false;
  bool get isPremiumActive => 
      _subscription?.status == SubscriptionStatus.active;
  bool get isTrialExpired => 
      _subscription?.status == SubscriptionStatus.trialExpired;
  bool get isPaymentPastDue => 
      _subscription?.status == SubscriptionStatus.pastDue;
  bool get isCancelled => 
      _subscription?.status == SubscriptionStatus.cancelled;

  // Trial-specific getters
  int get trialDaysRemaining {
    if (_subscription == null || !isTrialActive) return 0;
    final now = DateTime.now();
    final trialEnd = _subscription!.currentPeriodEnd;
    if (trialEnd == null) return 0;
    return trialEnd.difference(now).inDays.clamp(0, 30);
  }

  bool get isTrialEnding => trialDaysRemaining <= 3 && trialDaysRemaining > 0;
  
  DateTime? get nextBillingDate => _subscription?.currentPeriodEnd;
  
  String get subscriptionStatusText {
    if (_subscription == null) return 'Unknown';
    
    switch (_subscription!.status) {
      case SubscriptionStatus.trial:
        return 'Trial ($trialDaysRemaining days remaining)';
      case SubscriptionStatus.active:
        return 'Premium Active';
      case SubscriptionStatus.pastDue:
        return 'Payment Past Due';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.trialExpired:
        return 'Trial Expired';
      case SubscriptionStatus.incomplete:
        return 'Payment Required';
    }
  }

  // Feature access getters
  bool get canAccessPremiumFeatures => 
      hasActiveSubscription || isTrialActive;
  bool get canAccessCaregiverDashboard => canAccessPremiumFeatures;
  bool get canUseAdvancedHealthMonitoring => canAccessPremiumFeatures;
  bool get canCreateFamilyGroups => canAccessPremiumFeatures;
  bool get hasUnlimitedMembers => isPremiumActive;
  int get maxFamilyMembers => isPremiumActive ? -1 : 5; // -1 = unlimited

  SubscriptionProvider({
    required PaymentService paymentService,
    required SubscriptionBackendService backendService,
    required SubscriptionLifecycleService lifecycleService,
    required SubscriptionErrorHandler errorHandler,
    required OfflinePaymentService offlinePaymentService,
    required NotificationService notificationService,
    required AuthService authService,
  })  : _paymentService = paymentService,
        _backendService = backendService,
        _lifecycleService = lifecycleService,
        _errorHandler = errorHandler,
        _offlinePaymentService = offlinePaymentService,
        _notificationService = notificationService,
        _authService = authService;

  /// Initialize the subscription provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      await _paymentService.initialize();
      await loadSubscriptionStatus();
      await loadPaymentMethods();
      _setupTimers();
      _isInitialized = true;
      developer.log('SubscriptionProvider initialized successfully');
    } catch (error) {
      _setError('Failed to initialize subscription system: $error');
      developer.log('SubscriptionProvider initialization failed: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Load current subscription status from backend
  Future<void> loadSubscriptionStatus() async {
    try {
      final user = _authService.currentUser;
      if (user?.stripeCustomerId == null) {
        _subscription = null;
        notifyListeners();
        return;
      }

      final status = await _backendService.getSubscriptionStatus(
        user!.stripeCustomerId!,
      );
      
      _subscription = status;
      _clearError();
      notifyListeners();

      // Handle status-specific actions
      await _handleSubscriptionStatusChange(status);

    } catch (error) {
      _setError('Failed to load subscription status: $error');
      _errorHandler.handleSubscriptionStatusLoadError(error);
    }
  }

  /// Load user's payment methods
  Future<void> loadPaymentMethods() async {
    try {
      final user = _authService.currentUser;
      if (user?.stripeCustomerId == null) {
        _paymentMethods = [];
        notifyListeners();
        return;
      }

      final methods = await _backendService.getStoredPaymentMethods(
        user!.stripeCustomerId!,
      );
      
      _paymentMethods = methods;
      notifyListeners();

    } catch (error) {
      _setError('Failed to load payment methods: $error');
      developer.log('Error loading payment methods: $error');
    }
  }

  /// Start trial for new user
  Future<bool> startTrial() async {
    try {
      _setLoading(true);
      final user = _authService.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        return false;
      }

      final success = await _backendService.startTrial(user);
      if (success) {
        await _lifecycleService.onTrialStarted(user);
        await loadSubscriptionStatus();
        return true;
      } else {
        _setError('Failed to start trial');
        return false;
      }
    } catch (error) {
      _setError('Error starting trial: $error');
      _errorHandler.handleTrialStartError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Upgrade trial to premium subscription
  Future<SubscriptionUpgradeResult> upgradeTrialToPremium(
    PaymentMethodInfo paymentMethod,
  ) async {
    try {
      _setLoading(true);
      final user = _authService.currentUser;
      if (user == null) {
        return SubscriptionUpgradeResult.failure('User not authenticated');
      }

      // Process payment
      final result = await _paymentService.processSubscriptionPayment(
        user: user,
        priceId: (dotenv.env['STRIPE_PRICE_ID_PREMIUM'] ?? ''),
        paymentMethod: paymentMethod,
      );

      if (result.isSuccess) {
        await _lifecycleService.onSubscriptionActivated(user);
        await loadSubscriptionStatus();
        await loadPaymentMethods();
        
        return SubscriptionUpgradeResult.success(
          'Successfully upgraded to premium subscription',
        );
      } else {
        final errorMessage = result.error ?? 'Payment processing failed';
        _setError(errorMessage);
        return SubscriptionUpgradeResult.failure(errorMessage);
      }

    } catch (error) {
      final errorMessage = 'Error upgrading subscription: $error';
      _setError(errorMessage);
      _errorHandler.handleSubscriptionUpgradeError(error);
      return SubscriptionUpgradeResult.failure(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription({String? reason}) async {
    try {
      _setLoading(true);
      final user = _authService.currentUser;
      if (user?.stripeSubscriptionId == null) {
        _setError('No active subscription to cancel');
        return false;
      }

      final success = await _backendService.cancelSubscription(
        user!.stripeSubscriptionId!,
      );

      if (success) {
        await _lifecycleService.onSubscriptionCancelled(user);
        await loadSubscriptionStatus();
        
        await _notificationService.showLocalNotification(
          title: 'Subscription Cancelled',
          body: 'Your subscription has been cancelled successfully',
          data: {'type': 'subscription_cancelled'},
        );
        
        return true;
      } else {
        _setError('Failed to cancel subscription');
        return false;
      }

    } catch (error) {
      _setError('Error cancelling subscription: $error');
      _errorHandler.handleSubscriptionCancellationError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update payment method
  Future<bool> updatePaymentMethod(PaymentMethodInfo newMethod) async {
    try {
      _setLoading(true);
      final user = _authService.currentUser;
      if (user?.stripeCustomerId == null) {
        _setError('User not authenticated');
        return false;
      }

      final success = await _backendService.updatePaymentMethod(
        user!.stripeCustomerId!,
        newMethod.id,
      );

      if (success) {
        await loadPaymentMethods();
        _clearError();
        return true;
      } else {
        _setError('Failed to update payment method');
        return false;
      }

    } catch (error) {
      _setError('Error updating payment method: $error');
      _errorHandler.handlePaymentMethodUpdateError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Add new payment method
  Future<bool> addPaymentMethod(BuildContext context) async {
    try {
      _setLoading(true);
      
      final paymentMethod = await _paymentService.collectPaymentMethod(context);
      if (paymentMethod == null) {
        return false; // User cancelled
      }

      await loadPaymentMethods();
      _clearError();
      return true;

    } catch (error) {
      _setError('Error adding payment method: $error');
      _errorHandler.handlePaymentMethodAddError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Handle payment failure
  Future<void> handlePaymentFailure(String subscriptionId, String reason) async {
    try {
      await _paymentService.handlePaymentFailure(subscriptionId, reason);
      await loadSubscriptionStatus();
      
      // Show user notification
      await _notificationService.showLocalNotification(
        title: 'Payment Failed',
        body: 'Please update your payment method to continue service',
        data: {
          'type': 'payment_failed',
          'subscription_id': subscriptionId,
          'reason': reason,
        },
      );

    } catch (error) {
      _errorHandler.handlePaymentFailureProcessingError(error);
    }
  }

  /// Retry failed payment
  Future<bool> retryFailedPayment() async {
    try {
      _setLoading(true);
      final user = _authService.currentUser;
      if (user?.stripeSubscriptionId == null) {
        _setError('No subscription found for retry');
        return false;
      }

      final success = await _errorHandler.retryFailedPayment(
        user!.stripeSubscriptionId!,
      );

      if (success) {
        await loadSubscriptionStatus();
        return true;
      } else {
        _setError('Payment retry failed');
        return false;
      }

    } catch (error) {
      _setError('Error retrying payment: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user can access specific feature
  bool canAccessFeature(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'caregiver_dashboard':
        return canAccessCaregiverDashboard;
      case 'advanced_health_monitoring':
        return canUseAdvancedHealthMonitoring;
      case 'family_groups':
        return canCreateFamilyGroups;
      case 'unlimited_members':
        return hasUnlimitedMembers;
      case 'premium_support':
        return isPremiumActive;
      default:
        return canAccessPremiumFeatures;
    }
  }

  /// Get feature access status with details
  FeatureAccessInfo getFeatureAccess(String featureName) {
    final hasAccess = canAccessFeature(featureName);
    
    if (hasAccess) {
      return FeatureAccessInfo(
        hasAccess: true,
        reason: isPremiumActive ? 'Premium subscriber' : 'Trial period',
      );
    }

    // Determine why access is denied
    String reason;
    if (isTrialExpired) {
      reason = 'Trial period expired';
    } else if (isPaymentPastDue) {
      reason = 'Payment past due';
    } else if (isCancelled) {
      reason = 'Subscription cancelled';
    } else {
      reason = 'Premium subscription required';
    }

    return FeatureAccessInfo(
      hasAccess: false,
      reason: reason,
      canUpgrade: !isPremiumActive,
    );
  }

  /// Setup periodic timers for status checks and notifications
  void _setupTimers() {
    // Check subscription status every 5 minutes
    _statusCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => loadSubscriptionStatus(),
    );

    // Check for trial ending warning
    if (isTrialActive && isTrialEnding) {
      _setupTrialWarningNotifications();
    }
  }

  /// Setup trial ending notifications
  void _setupTrialWarningNotifications() {
    _trialWarningTimer = Timer.periodic(
      const Duration(hours: 12),
      (_) async {
        if (isTrialEnding) {
          await _notificationService.showLocalNotification(
            title: 'Trial Ending Soon',
            body: 'Your trial expires in $trialDaysRemaining days. Upgrade now to continue premium features.',
            data: {
              'type': 'trial_ending',
              'days_remaining': trialDaysRemaining.toString(),
            },
          );
        }
      },
    );
  }

  /// Handle subscription status changes
  Future<void> _handleSubscriptionStatusChange(SubscriptionInfo status) async {
    final user = _authService.currentUser;
    if (user == null) return;

    switch (status.status) {
      case SubscriptionStatus.active:
        await _lifecycleService.updateFeatureAccess(user);
        break;
      case SubscriptionStatus.pastDue:
        await _lifecycleService.handleGracefulDegradation(user);
        break;
      case SubscriptionStatus.cancelled:
        await _lifecycleService.updateFeatureAccess(user);
        break;
      case SubscriptionStatus.trialExpired:
        await _lifecycleService.onTrialEnded(user);
        break;
      default:
        break;
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void _setError(String error) {
    _error = error;
    developer.log('SubscriptionProvider error: $error');
    notifyListeners();
  }

  /// Clear error state
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh subscription data
  Future<void> refresh() async {
    await Future.wait([
      loadSubscriptionStatus(),
      loadPaymentMethods(),
    ]);
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _trialWarningTimer?.cancel();
    super.dispose();
  }
}

/// Result class for subscription upgrade operations
class SubscriptionUpgradeResult {
  final bool isSuccess;
  final String message;

  const SubscriptionUpgradeResult._({
    required this.isSuccess,
    required this.message,
  });

  factory SubscriptionUpgradeResult.success(String message) =>
      SubscriptionUpgradeResult._(isSuccess: true, message: message);

  factory SubscriptionUpgradeResult.failure(String message) =>
      SubscriptionUpgradeResult._(isSuccess: false, message: message);
}

/// Information about feature access
class FeatureAccessInfo {
  final bool hasAccess;
  final String reason;
  final bool canUpgrade;

  const FeatureAccessInfo({
    required this.hasAccess,
    required this.reason,
    this.canUpgrade = false,
  });
}