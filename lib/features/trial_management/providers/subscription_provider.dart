import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../services/payment_service.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, AsyncValue<SubscriptionModel>>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return SubscriptionNotifier(service);
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<SubscriptionModel>> {
  final SubscriptionService _service;

  SubscriptionNotifier(this._service) : super(const AsyncValue.loading()) {
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    state = const AsyncValue.loading();
    try {
      final subscription = await _service.getCurrentSubscription();
      state = AsyncValue.data(subscription);
      
      // Start monitoring trial status
      if (subscription.status == SubscriptionStatus.trial) {
        _startTrialMonitoring();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> upgradeSubscription(SubscriptionPlan plan) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final updatedSubscription = await _service.upgrade(
        userId: currentState.userId,
        plan: plan,
      );
      state = AsyncValue.data(updatedSubscription);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> pauseSubscription() async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final updatedSubscription = await _service.pauseSubscription(
        userId: currentState.userId,
      );
      state = AsyncValue.data(updatedSubscription);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> cancelSubscription() async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final updatedSubscription = await _service.cancelSubscription(
        userId: currentState.userId,
      );
      state = AsyncValue.data(updatedSubscription);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void updateUsageStats(Map<String, dynamic> newStats) {
    final currentState = state.value;
    if (currentState == null) return;

    final mergedStats = {...currentState.usageStats, ...newStats};
    state = AsyncValue.data(
      currentState.copyWith(usageStats: mergedStats),
    );
  }

  void _startTrialMonitoring() {
    // Check trial status daily
    Future.delayed(const Duration(hours: 24), () {
      final currentState = state.value;
      if (currentState == null) return;

      if (currentState.status == SubscriptionStatus.trial) {
        final daysRemaining = currentState.trialEndDate != null
            ? currentState.trialEndDate!.difference(DateTime.now()).inDays
            : 0;

        if (daysRemaining != currentState.daysRemaining) {
          state = AsyncValue.data(
            currentState.copyWith(daysRemaining: daysRemaining),
          );
        }

        // Continue monitoring
        _startTrialMonitoring();
      }
    });
  }
}

// Provider for tracking upgrade triggers
final upgradeTriggersProvider = StateProvider<List<String>>((ref) => []);

// Provider for tracking conversion events
final conversionEventsProvider = StateNotifierProvider<ConversionEventsNotifier, List<ConversionEvent>>((ref) {
  return ConversionEventsNotifier();
});

class ConversionEvent {
  final String eventType;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  ConversionEvent({
    required this.eventType,
    required this.timestamp,
    required this.data,
  });
}

class ConversionEventsNotifier extends StateNotifier<List<ConversionEvent>> {
  ConversionEventsNotifier() : super([]);

  void trackEvent(String eventType, Map<String, dynamic> data) {
    state = [
      ...state,
      ConversionEvent(
        eventType: eventType,
        timestamp: DateTime.now(),
        data: data,
      ),
    ];
  }

  void trackUpgradeTrigger(String triggerType) {
    trackEvent('upgrade_trigger', {'type': triggerType});
  }

  void trackUpgradeView(String screen) {
    trackEvent('upgrade_view', {'screen': screen});
  }

  void trackPaymentAttempt(String method) {
    trackEvent('payment_attempt', {'method': method});
  }

  void trackConversionSuccess(String plan, double amount) {
    trackEvent('conversion_success', {
      'plan': plan,
      'amount': amount,
    });
  }
}