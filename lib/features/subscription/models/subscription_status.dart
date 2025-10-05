enum SubscriptionStatus {
  trial('trial'),
  active('active'),
  pastDue('past_due'),
  canceled('canceled'),
  unpaid('unpaid'),
  incomplete('incomplete'),
  incompleteExpired('incomplete_expired'),
  trialing('trialing');

  const SubscriptionStatus(this.value);
  
  final String value;

  static SubscriptionStatus fromString(String status) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => SubscriptionStatus.trial,
    );
  }

  bool get isActive => this == SubscriptionStatus.active || this == SubscriptionStatus.trial;
  bool get isTrial => this == SubscriptionStatus.trial || this == SubscriptionStatus.trialing;
  bool get isPaid => this == SubscriptionStatus.active;
  bool get needsPayment => this == SubscriptionStatus.pastDue || this == SubscriptionStatus.unpaid;
  bool get isExpired => this == SubscriptionStatus.canceled || this == SubscriptionStatus.incompleteExpired;
}

class SubscriptionInfo {
  final String? id;
  final String? customerId;
  final SubscriptionStatus status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? trialStart;
  final DateTime? trialEnd;
  final String? priceId;
  final double? amount;
  final String currency;
  final bool cancelAtPeriodEnd;
  final DateTime? canceledAt;
  final int? trialDaysRemaining;
  final bool isTrialEnding;

  const SubscriptionInfo({
    this.id,
    this.customerId,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.trialStart,
    this.trialEnd,
    this.priceId,
    this.amount,
    this.currency = 'usd',
    this.cancelAtPeriodEnd = false,
    this.canceledAt,
    this.trialDaysRemaining,
    this.isTrialEnding = false,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      id: json['id'] as String?,
      customerId: json['customer_id'] as String?,
      status: SubscriptionStatus.fromString(json['status'] as String? ?? 'trial'),
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.parse(json['current_period_start'])
          : null,
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'])
          : null,
      trialStart: json['trial_start'] != null
          ? DateTime.parse(json['trial_start'])
          : null,
      trialEnd: json['trial_end'] != null
          ? DateTime.parse(json['trial_end'])
          : null,
      priceId: json['price_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'usd',
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      canceledAt: json['canceled_at'] != null
          ? DateTime.parse(json['canceled_at'])
          : null,
      trialDaysRemaining: json['trial_days_remaining'] as int?,
      isTrialEnding: json['is_trial_ending'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'status': status.value,
      'current_period_start': currentPeriodStart?.toIso8601String(),
      'current_period_end': currentPeriodEnd?.toIso8601String(),
      'trial_start': trialStart?.toIso8601String(),
      'trial_end': trialEnd?.toIso8601String(),
      'price_id': priceId,
      'amount': amount,
      'currency': currency,
      'cancel_at_period_end': cancelAtPeriodEnd,
      'canceled_at': canceledAt?.toIso8601String(),
      'trial_days_remaining': trialDaysRemaining,
      'is_trial_ending': isTrialEnding,
    };
  }

  SubscriptionInfo copyWith({
    String? id,
    String? customerId,
    SubscriptionStatus? status,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? trialStart,
    DateTime? trialEnd,
    String? priceId,
    double? amount,
    String? currency,
    bool? cancelAtPeriodEnd,
    DateTime? canceledAt,
    int? trialDaysRemaining,
    bool? isTrialEnding,
  }) {
    return SubscriptionInfo(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      trialStart: trialStart ?? this.trialStart,
      trialEnd: trialEnd ?? this.trialEnd,
      priceId: priceId ?? this.priceId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      canceledAt: canceledAt ?? this.canceledAt,
      trialDaysRemaining: trialDaysRemaining ?? this.trialDaysRemaining,
      isTrialEnding: isTrialEnding ?? this.isTrialEnding,
    );
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final String stripePriceId;
  final double amount;
  final String currency;
  final String interval; // day, week, month, year
  final int intervalCount;
  final int trialPeriodDays;
  final Map<String, dynamic> features;
  final bool isActive;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.stripePriceId,
    required this.amount,
    this.currency = 'usd',
    required this.interval,
    this.intervalCount = 1,
    this.trialPeriodDays = 30,
    this.features = const {},
    this.isActive = true,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      stripePriceId: json['stripe_price_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'usd',
      interval: json['interval'] as String,
      intervalCount: json['interval_count'] as int? ?? 1,
      trialPeriodDays: json['trial_period_days'] as int? ?? 30,
      features: json['features'] as Map<String, dynamic>? ?? {},
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'stripe_price_id': stripePriceId,
      'amount': amount,
      'currency': currency,
      'interval': interval,
      'interval_count': intervalCount,
      'trial_period_days': trialPeriodDays,
      'features': features,
      'is_active': isActive,
    };
  }

  String get displayPrice {
    return '\$${amount.toStringAsFixed(2)}/$interval${intervalCount > 1 ? ' (every $intervalCount ${interval}s)' : ''}';
  }

  bool hasFeature(String feature) {
    return features[feature] == true;
  }
}

enum SubscriptionResult {
  success,
  paymentRequired,
  paymentFailed,
  subscriptionExists,
  invalidPaymentMethod,
  networkError,
  unknownError
}

class SubscriptionOperationResult {
  final SubscriptionResult result;
  final String? message;
  final SubscriptionInfo? subscription;
  final String? errorCode;

  const SubscriptionOperationResult({
    required this.result,
    this.message,
    this.subscription,
    this.errorCode,
  });

  bool get isSuccess => result == SubscriptionResult.success;
  bool get isError => !isSuccess;
}