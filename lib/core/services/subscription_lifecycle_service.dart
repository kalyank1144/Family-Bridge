import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/models/user_model.dart';
import '../../features/subscription/models/subscription_status.dart';
import 'notification_service.dart';
import 'subscription_backend_service.dart';

class SubscriptionLifecycleService {
  final SupabaseClient _supabase;
  final NotificationService _notificationService;
  final SubscriptionBackendService _backend;
  final FlutterLocalNotificationsPlugin _localNotifications;

  SubscriptionLifecycleService({
    SupabaseClient? supabase,
    NotificationService? notificationService,
    SubscriptionBackendService? backend,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _supabase = supabase ?? Supabase.instance.client,
        _notificationService = notificationService ?? NotificationService(),
        _backend = backend ?? SubscriptionBackendService(),
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin();

  // Trial lifecycle

  /// Handle when trial is started for a user
  Future<void> onTrialStarted(UserProfile user) async {
    try {
      print('Trial started for user: ${user.name} (${user.email})');
      
      // Log the event for analytics
      await _logSubscriptionEvent(
        userId: user.id,
        eventType: 'trial_started',
        eventData: {
          'user_id': user.id,
          'user_role': user.role,
          'trial_length_days': 30,
          'started_at': DateTime.now().toIso8601String(),
        },
      );

      // Schedule trial ending notification (3 days before)
      await _scheduleTrialEndingNotification(user);

      // Send welcome notification
      await _sendTrialStartedNotification(user);

      // Update feature access
      await updateFeatureAccess(user);
      
      // Schedule background check for trial ending
      await _scheduleTrialEndingCheck(user.id);
      
      print('Trial lifecycle setup completed for ${user.name}');
    } catch (e) {
      print('Error handling trial started: $e');
    }
  }

  /// Handle when trial is ending (3 days before expiry)
  Future<void> onTrialEnding(UserProfile user) async {
    try {
      print('Trial ending soon for user: ${user.name}');
      
      // Log the event
      await _logSubscriptionEvent(
        userId: user.id,
        eventType: 'trial_ending_soon',
        eventData: {
          'user_id': user.id,
          'days_remaining': 3,
          'trial_end_date': user.trialEndsAt?.toIso8601String(),
        },
      );

      // Send notification about trial ending
      await sendTrialEndingNotification(user);

      // Maybe offer a discount or incentive
      await _offerTrialConversionIncentive(user);
      
      print('Trial ending notifications sent to ${user.name}');
    } catch (e) {
      print('Error handling trial ending: $e');
    }
  }

  /// Handle when trial has ended
  Future<void> onTrialEnded(UserProfile user) async {
    try {
      print('Trial ended for user: ${user.name}');
      
      // Log the event
      await _logSubscriptionEvent(
        userId: user.id,
        eventType: 'trial_ended',
        eventData: {
          'user_id': user.id,
          'ended_at': DateTime.now().toIso8601String(),
          'converted': false, // Will be updated if they convert
        },
      );

      // Check if user has subscribed during trial
      final subscriptionStatus = await _backend.getSubscriptionStatus(user.stripeCustomerId ?? '');
      
      if (subscriptionStatus?.status == SubscriptionStatus.active) {
        // User converted during trial
        await onSubscriptionActivated(user);
        return;
      }

      // Handle graceful degradation
      await handleGracefulDegradation(user);

      // Send trial ended notification
      await _sendTrialEndedNotification(user);
      
      print('Trial ended handling completed for ${user.name}');
    } catch (e) {
      print('Error handling trial ended: $e');
    }
  }

  // Subscription lifecycle

  /// Handle when subscription is activated
  Future<void> onSubscriptionActivated(UserProfile user) async {
    try {
      print('Subscription activated for user: ${user.name}');
      
      // Log the event
      await _logSubscriptionEvent(
        userId: user.id,
        eventType: 'subscription_activated',
        eventData: {
          'user_id': user.id,
          'activated_at': DateTime.now().toIso8601String(),
          'plan': 'premium',
        },
      );

      // Update feature access to full premium
      await updateFeatureAccess(user);

      // Send confirmation notification
      await sendSubscriptionConfirmation(user);
      
      // Schedule renewal reminder
      await _scheduleRenewalReminder(user);
      
      print('Subscription activation completed for ${user.name}');
    } catch (e) {
      print('Error handling subscription activation: $e');
    }
  }

  /// Handle when subscription is renewed
  Future<void> onSubscriptionRenewed(UserProfile user) async {
    try {
      print('Subscription renewed for user: ${user.name}');
      
      // Log the event
      await _logSubscriptionEvent(
        userId: user.id,
        eventType: 'subscription_renewed',
        eventData: {
          'user_id': user.id,
          'renewed_at': DateTime.now().toIso8601String(),
        },
      );

      // Send renewal confirmation
      await _sendRenewalConfirmation(user);
      
      // Schedule next renewal reminder
      await _scheduleRenewalReminder(user);
      
      print('Subscription renewal handled for ${user.name}');
    } catch (e) {
      print('Error handling subscription renewal: $e');
    }
  }

  /// Handle when subscription is cancelled
  Future<void> onSubscriptionCancelled(UserProfile user) async {
    try {
      print('Subscription cancelled for user: ${user.name}');
      
      // Log the event
      await _logSubscriptionEvent(
        userId: user.id,
        eventType: 'subscription_cancelled',
        eventData: {
          'user_id': user.id,
          'cancelled_at': DateTime.now().toIso8601String(),
        },
      );

      // Handle graceful degradation (maintain access until period end)
      await handleGracefulDegradation(user);

      // Send cancellation confirmation
      await _sendCancellationConfirmation(user);
      
      // Cancel scheduled notifications
      await _cancelScheduledNotifications(user.id);
      
      print('Subscription cancellation handled for ${user.name}');
    } catch (e) {
      print('Error handling subscription cancellation: $e');
    }
  }

  /// Handle payment failures
  Future<void> onPaymentFailed(UserProfile user, int attemptNumber) async {
    try {
      print('Payment failed for user: ${user.name}, attempt: $attemptNumber');
      
      // Log the event
      await _logSubscriptionEvent(
        userId: user.id,
        eventType: 'payment_failed',
        eventData: {
          'user_id': user.id,
          'failed_at': DateTime.now().toIso8601String(),
          'attempt_number': attemptNumber,
        },
      );

      // Send payment failure notification
      await sendPaymentFailureNotification(user);
      
      if (attemptNumber < 3) {
        // Schedule retry
        await _schedulePaymentRetry(user, attemptNumber);
      } else {
        // Final attempt failed - handle graceful degradation
        await handleGracefulDegradation(user);
        await _sendFinalPaymentFailureNotification(user);
      }
      
      print('Payment failure handled for ${user.name}');
    } catch (e) {
      print('Error handling payment failure: $e');
    }
  }

  // Feature access management

  /// Update user's feature access based on subscription status
  Future<void> updateFeatureAccess(UserProfile user) async {
    try {
      final subscriptionStatus = await _backend.getSubscriptionStatus(user.stripeCustomerId ?? '');
      
      Map<String, dynamic> featureAccess;
      
      if (subscriptionStatus?.status.isActive == true) {
        // Full premium access
        featureAccess = {
          'unlimited_family_members': true,
          'advanced_health_monitoring': true,
          'professional_reports': true,
          'priority_support': true,
          'offline_mode': true,
          'data_export': true,
          'custom_reminders': true,
          'video_calls': true,
          'unlimited_storage': true,
        };
      } else {
        // Limited free access
        featureAccess = {
          'unlimited_family_members': false,
          'advanced_health_monitoring': false,
          'professional_reports': false,
          'priority_support': false,
          'offline_mode': true, // Basic offline still available
          'data_export': false,
          'custom_reminders': false,
          'video_calls': false,
          'unlimited_storage': false,
        };
      }

      // Update user profile with feature access
      await _supabase
          .from('user_profiles')
          .update({
            'consent': {
              ...user.consent ?? {},
              'feature_access': featureAccess,
              'updated_at': DateTime.now().toIso8601String(),
            }
          })
          .eq('user_id', user.id);
      
      print('Feature access updated for ${user.name}');
    } catch (e) {
      print('Error updating feature access: $e');
    }
  }

  /// Handle graceful degradation when subscription becomes inactive
  Future<void> handleGracefulDegradation(UserProfile user) async {
    try {
      print('Handling graceful degradation for user: ${user.name}');
      
      // Update feature access to free tier
      await updateFeatureAccess(user);
      
      // Preserve essential data but limit access
      // This is a graceful way to handle subscription lapses
      
      // Log the degradation
      await _logSubscriptionEvent(
        userId: user.id,
        eventType: 'graceful_degradation',
        eventData: {
          'user_id': user.id,
          'degraded_at': DateTime.now().toIso8601String(),
        },
      );
      
      print('Graceful degradation completed for ${user.name}');
    } catch (e) {
      print('Error handling graceful degradation: $e');
    }
  }

  // Notification methods

  /// Send trial ending notification
  Future<void> sendTrialEndingNotification(UserProfile user) async {
    try {
      await _notificationService.sendNotification(
        userId: user.id,
        title: 'Your trial ends soon! 📅',
        message: 'Only 3 days left on your FamilyBridge trial. Upgrade now to keep all features.',
        type: 'subscription',
        data: {
          'action': 'upgrade_to_premium',
          'days_remaining': 3,
        },
      );

      // Also send local notification
      await _localNotifications.show(
        100, // Notification ID for trial ending
        'Your trial ends soon! 📅',
        'Only 3 days left on your FamilyBridge trial. Tap to upgrade.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'subscription_channel',
            'Subscription Notifications',
            channelDescription: 'Notifications about subscription and billing',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'subscription',
          ),
        ),
      );
      
      print('Trial ending notification sent to ${user.name}');
    } catch (e) {
      print('Error sending trial ending notification: $e');
    }
  }

  /// Send payment failure notification
  Future<void> sendPaymentFailureNotification(UserProfile user) async {
    try {
      await _notificationService.sendNotification(
        userId: user.id,
        title: 'Payment Issue 💳',
        message: 'We had trouble processing your payment. Please update your payment method.',
        type: 'payment_failure',
        data: {
          'action': 'update_payment_method',
        },
      );

      await _localNotifications.show(
        101, // Notification ID for payment failure
        'Payment Issue 💳',
        'We had trouble processing your payment. Tap to update your payment method.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'subscription_channel',
            'Subscription Notifications',
            channelDescription: 'Notifications about subscription and billing',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'payment',
          ),
        ),
      );
      
      print('Payment failure notification sent to ${user.name}');
    } catch (e) {
      print('Error sending payment failure notification: $e');
    }
  }

  /// Send subscription confirmation notification
  Future<void> sendSubscriptionConfirmation(UserProfile user) async {
    try {
      await _notificationService.sendNotification(
        userId: user.id,
        title: 'Welcome to Premium! 🎉',
        message: 'Your FamilyBridge Premium subscription is now active. Enjoy all features!',
        type: 'subscription_confirmation',
        data: {
          'action': 'explore_premium_features',
        },
      );

      await _localNotifications.show(
        102, // Notification ID for subscription confirmation
        'Welcome to Premium! 🎉',
        'Your FamilyBridge Premium subscription is now active.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'subscription_channel',
            'Subscription Notifications',
            channelDescription: 'Notifications about subscription and billing',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'subscription',
          ),
        ),
      );
      
      print('Subscription confirmation sent to ${user.name}');
    } catch (e) {
      print('Error sending subscription confirmation: $e');
    }
  }

  // Private helper methods

  Future<void> _logSubscriptionEvent({
    required String userId,
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      await _supabase.from('subscription_events').insert({
        'user_id': userId,
        'event_type': eventType,
        'event_data': eventData,
        'processed': true,
        'processed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging subscription event: $e');
    }
  }

  Future<void> _scheduleTrialEndingNotification(UserProfile user) async {
    try {
      final notificationDate = user.trialEndsAt?.subtract(const Duration(days: 3));
      if (notificationDate == null) return;

      await Workmanager().registerOneOffTask(
        'trial_ending_${user.id}',
        'trial_ending_notification',
        inputData: {
          'user_id': user.id,
          'user_name': user.name,
          'user_email': user.email,
        },
        initialDelay: notificationDate.difference(DateTime.now()),
      );
    } catch (e) {
      print('Error scheduling trial ending notification: $e');
    }
  }

  Future<void> _scheduleTrialEndingCheck(String userId) async {
    try {
      await Workmanager().registerPeriodicTask(
        'trial_check_$userId',
        'check_trial_status',
        frequency: const Duration(hours: 24),
        inputData: {'user_id': userId},
      );
    } catch (e) {
      print('Error scheduling trial ending check: $e');
    }
  }

  Future<void> _sendTrialStartedNotification(UserProfile user) async {
    try {
      await _notificationService.sendNotification(
        userId: user.id,
        title: 'Welcome to FamilyBridge! 👋',
        message: 'Your 30-day free trial has started. Explore all premium features!',
        type: 'trial_started',
        data: {'action': 'explore_features'},
      );
    } catch (e) {
      print('Error sending trial started notification: $e');
    }
  }

  Future<void> _offerTrialConversionIncentive(UserProfile user) async {
    // This could offer a discount or special promotion
    // Implementation depends on business requirements
  }

  Future<void> _sendTrialEndedNotification(UserProfile user) async {
    try {
      await _notificationService.sendNotification(
        userId: user.id,
        title: 'Trial Ended 🔒',
        message: 'Your free trial has ended. Upgrade to keep using premium features.',
        type: 'trial_ended',
        data: {'action': 'upgrade_to_premium'},
      );
    } catch (e) {
      print('Error sending trial ended notification: $e');
    }
  }

  Future<void> _scheduleRenewalReminder(UserProfile user) async {
    // Schedule renewal reminders based on subscription period
    // Implementation would depend on billing cycle
  }

  Future<void> _sendRenewalConfirmation(UserProfile user) async {
    try {
      await _notificationService.sendNotification(
        userId: user.id,
        title: 'Subscription Renewed ✅',
        message: 'Your FamilyBridge Premium subscription has been renewed successfully.',
        type: 'subscription_renewed',
        data: {'action': 'view_billing'},
      );
    } catch (e) {
      print('Error sending renewal confirmation: $e');
    }
  }

  Future<void> _sendCancellationConfirmation(UserProfile user) async {
    try {
      await _notificationService.sendNotification(
        userId: user.id,
        title: 'Subscription Cancelled',
        message: 'Your subscription has been cancelled. You\'ll keep access until your current period ends.',
        type: 'subscription_cancelled',
        data: {'action': 'feedback'},
      );
    } catch (e) {
      print('Error sending cancellation confirmation: $e');
    }
  }

  Future<void> _schedulePaymentRetry(UserProfile user, int attemptNumber) async {
    // Schedule payment retry with exponential backoff
    final retryDelay = Duration(days: attemptNumber * 2);
    
    await Workmanager().registerOneOffTask(
      'payment_retry_${user.id}_$attemptNumber',
      'retry_failed_payment',
      inputData: {
        'user_id': user.id,
        'attempt_number': attemptNumber + 1,
      },
      initialDelay: retryDelay,
    );
  }

  Future<void> _sendFinalPaymentFailureNotification(UserProfile user) async {
    try {
      await _notificationService.sendNotification(
        userId: user.id,
        title: 'Payment Failed - Action Required',
        message: 'We couldn\'t process your payment after multiple attempts. Your account will be downgraded.',
        type: 'payment_final_failure',
        data: {'action': 'update_payment_method'},
      );
    } catch (e) {
      print('Error sending final payment failure notification: $e');
    }
  }

  Future<void> _cancelScheduledNotifications(String userId) async {
    try {
      await Workmanager().cancelByUniqueName('trial_ending_$userId');
      await Workmanager().cancelByUniqueName('trial_check_$userId');
    } catch (e) {
      print('Error cancelling scheduled notifications: $e');
    }
  }

  /// Cleanup resources
  void dispose() {
    _backend.dispose();
  }
}