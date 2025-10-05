import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:family_bridge/features/trial_management/models/subscription_model.dart';

class SubscriptionService {
  final String _baseUrl = 'https://api.familybridge.app';
  
  Future<SubscriptionModel> getCurrentSubscription() async {
    // Mock implementation - replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate fetching subscription data
    return SubscriptionModel(
      userId: 'user_123',
      familyId: 'family_456',
      status: SubscriptionStatus.trial,
      trialStartDate: DateTime.now().subtract(const Duration(days: 10)),
      trialEndDate: DateTime.now().add(const Duration(days: 20)),
      daysRemaining: 20,
      userType: UserType.elder, // This would come from user preferences
      usageStats: {
        'photosUploaded': 156,
        'storageUsedGB': 1.8,
        'voiceMessages': 89,
        'storiesRecorded': 12,
        'dailyCheckIns': 45,
        'healthAlerts': 3,
        'emergencyContacts': 8,
      },
      connectedFamilyMembers: [
        'Sarah (Daughter)',
        'Michael (Son)',
        'Emma (Granddaughter)',
        'James (Grandson)',
        'Linda (Caregiver)',
      ],
    );
  }

  Future<SubscriptionModel> upgrade({
    required String userId,
    required SubscriptionPlan plan,
  }) async {
    // Mock API call
    await Future.delayed(const Duration(seconds: 1));
    
    final subscription = await getCurrentSubscription();
    return subscription.copyWith(
      status: SubscriptionStatus.active,
      plan: plan,
      subscriptionStartDate: DateTime.now(),
      subscriptionEndDate: plan == SubscriptionPlan.monthly
          ? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 365)),
    );
  }

  Future<SubscriptionModel> pauseSubscription({
    required String userId,
  }) async {
    // Mock API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    final subscription = await getCurrentSubscription();
    return subscription.copyWith(
      status: SubscriptionStatus.paused,
      pausedAt: DateTime.now(),
      resumeAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  Future<SubscriptionModel> cancelSubscription({
    required String userId,
  }) async {
    // Mock API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    final subscription = await getCurrentSubscription();
    return subscription.copyWith(
      status: SubscriptionStatus.cancelled,
      subscriptionEndDate: DateTime.now(),
      autoRenew: false,
    );
  }

  Future<Map<String, dynamic>> getUsageStatistics({
    required String userId,
    required String familyId,
  }) async {
    // Mock API call
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'photosUploaded': 156,
      'storageUsedGB': 1.8,
      'voiceMessages': 89,
      'storiesRecorded': 12,
      'dailyCheckIns': 45,
      'healthAlerts': 3,
      'emergencyContacts': 8,
      'familyInteractions': {
        'messages': 234,
        'reactions': 567,
        'sharedMoments': 89,
      },
      'healthMetrics': {
        'vitalsRecorded': 120,
        'medicationCompliance': 95.5,
        'moodTracking': 30,
      },
    };
  }

  Future<List<String>> getConnectedFamilyMembers({
    required String familyId,
  }) async {
    // Mock API call
    await Future.delayed(const Duration(milliseconds: 200));
    
    return [
      'Sarah (Daughter)',
      'Michael (Son)',
      'Emma (Granddaughter)',
      'James (Grandson)',
      'Linda (Caregiver)',
    ];
  }

  Future<bool> checkTrialEligibility({
    required String userId,
    required String email,
  }) async {
    // Check if user is eligible for trial
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<void> startTrial({
    required String userId,
    required String familyId,
  }) async {
    // Start 30-day trial
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<Map<String, dynamic>> getSubscriptionPlans() async {
    // Fetch available subscription plans
    await Future.delayed(const Duration(milliseconds: 200));
    
    return {
      'monthly': {
        'price': 9.99,
        'currency': 'USD',
        'features': [
          'Unlimited storage',
          'All premium features',
          'Priority support',
          'Cancel anytime',
        ],
      },
      'annual': {
        'price': 99.99,
        'currency': 'USD',
        'savings': 20.00,
        'features': [
          'Everything in Monthly',
          'Save 17% (2 months free!)',
          'Priority family support',
          'Advanced health analytics',
        ],
      },
    };
  }

  Future<void> notifyFamilyMembers({
    required String familyId,
    required String notificationType,
    required Map<String, dynamic> data,
  }) async {
    // Notify family members about subscription changes
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<Map<String, dynamic>> calculateProration({
    required String userId,
    required SubscriptionPlan fromPlan,
    required SubscriptionPlan toPlan,
  }) async {
    // Calculate proration for plan changes
    await Future.delayed(const Duration(milliseconds: 200));
    
    return {
      'credit': 0.00,
      'charge': 9.99,
      'effectiveDate': DateTime.now().toIso8601String(),
    };
  }
}