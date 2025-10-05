import 'package:flutter/foundation.dart';

enum SubscriptionStatus {
  trial,
  active,
  cancelled,
  paused,
  expired,
  pending
}

enum SubscriptionPlan {
  monthly,
  annual,
  family
}

enum UserType {
  elder,
  caregiver,
  youth
}

@immutable
class SubscriptionModel {
  final String userId;
  final String familyId;
  final SubscriptionStatus status;
  final SubscriptionPlan? plan;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final DateTime? pausedAt;
  final DateTime? resumeAt;
  final double price;
  final String currency;
  final bool autoRenew;
  final int daysRemaining;
  final Map<String, dynamic> usageStats;
  final List<String> connectedFamilyMembers;
  final UserType userType;

  const SubscriptionModel({
    required this.userId,
    required this.familyId,
    required this.status,
    this.plan,
    this.trialStartDate,
    this.trialEndDate,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.pausedAt,
    this.resumeAt,
    this.price = 9.99,
    this.currency = 'USD',
    this.autoRenew = true,
    this.daysRemaining = 30,
    this.usageStats = const {},
    this.connectedFamilyMembers = const [],
    required this.userType,
  });

  bool get isTrialExpired {
    if (trialEndDate == null) return false;
    return DateTime.now().isAfter(trialEndDate!);
  }

  bool get isInGracePeriod {
    if (status != SubscriptionStatus.trial) return false;
    if (trialEndDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(trialEndDate!) && 
           now.isBefore(trialEndDate!.add(const Duration(days: 3)));
  }

  String get trialMessage {
    if (daysRemaining > 15) {
      return "You're loving FamilyBridge! $daysRemaining days of premium features left";
    } else if (daysRemaining > 7) {
      return "Don't lose your family memories! $daysRemaining days remaining";
    } else if (daysRemaining > 0) {
      return "Your family depends on these features! Upgrade now to keep them";
    } else if (isInGracePeriod) {
      return "Your trial ended but we're giving you 3 more days! Upgrade now";
    } else {
      return "Your trial has ended - upgrade to continue caring for your family";
    }
  }

  String get upgradeButtonText {
    switch (userType) {
      case UserType.elder:
        return "Keep My Family Connected - \$${price}/month";
      case UserType.caregiver:
        return "Continue Professional Care - \$${price}/month";
      case UserType.youth:
        return "Be the Family Hero - \$${price}/month";
    }
  }

  Map<String, String> get personalizedStats {
    return {
      'photos': '${usageStats['photosUploaded'] ?? 0} family photos (${usageStats['storageUsedGB'] ?? 0}GB)',
      'voiceMessages': '${usageStats['voiceMessages'] ?? 0} voice messages shared',
      'stories': '${usageStats['storiesRecorded'] ?? 0} precious family stories',
      'checkIns': '${usageStats['dailyCheckIns'] ?? 0} daily check-ins completed',
      'healthAlerts': '${usageStats['healthAlerts'] ?? 0} health trends detected',
      'familyMembers': '${connectedFamilyMembers.length} family members connected',
    };
  }

  SubscriptionModel copyWith({
    String? userId,
    String? familyId,
    SubscriptionStatus? status,
    SubscriptionPlan? plan,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    DateTime? pausedAt,
    DateTime? resumeAt,
    double? price,
    String? currency,
    bool? autoRenew,
    int? daysRemaining,
    Map<String, dynamic>? usageStats,
    List<String>? connectedFamilyMembers,
    UserType? userType,
  }) {
    return SubscriptionModel(
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      status: status ?? this.status,
      plan: plan ?? this.plan,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      pausedAt: pausedAt ?? this.pausedAt,
      resumeAt: resumeAt ?? this.resumeAt,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      autoRenew: autoRenew ?? this.autoRenew,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      usageStats: usageStats ?? this.usageStats,
      connectedFamilyMembers: connectedFamilyMembers ?? this.connectedFamilyMembers,
      userType: userType ?? this.userType,
    );
  }
}