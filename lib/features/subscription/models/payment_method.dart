import 'package:stripe_flutter/stripe_flutter.dart' as stripe;

class PaymentMethodInfo {
  final String? id;
  final String stripePaymentMethodId;
  final PaymentMethodType type;
  final CardInfo? card;
  final String? billingName;
  final String? billingEmail;
  final BillingAddress? billingAddress;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentMethodInfo({
    this.id,
    required this.stripePaymentMethodId,
    required this.type,
    this.card,
    this.billingName,
    this.billingEmail,
    this.billingAddress,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethodInfo.fromStripe(stripe.PaymentMethod stripePaymentMethod) {
    return PaymentMethodInfo(
      stripePaymentMethodId: stripePaymentMethod.id,
      type: PaymentMethodType.fromStripe(stripePaymentMethod.type),
      card: stripePaymentMethod.card != null
          ? CardInfo.fromStripe(stripePaymentMethod.card!)
          : null,
      billingName: stripePaymentMethod.billingDetails?.name,
      billingEmail: stripePaymentMethod.billingDetails?.email,
      billingAddress: stripePaymentMethod.billingDetails?.address != null
          ? BillingAddress.fromStripe(stripePaymentMethod.billingDetails!.address!)
          : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      id: json['id'] as String?,
      stripePaymentMethodId: json['stripe_payment_method_id'] as String,
      type: PaymentMethodType.fromString(json['type'] as String? ?? 'card'),
      card: json['card'] != null
          ? CardInfo.fromJson(json['card'] as Map<String, dynamic>)
          : null,
      billingName: json['billing_name'] as String?,
      billingEmail: json['billing_email'] as String?,
      billingAddress: json['billing_address'] != null
          ? BillingAddress.fromJson(json['billing_address'] as Map<String, dynamic>)
          : null,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stripe_payment_method_id': stripePaymentMethodId,
      'type': type.value,
      'card': card?.toJson(),
      'billing_name': billingName,
      'billing_email': billingEmail,
      'billing_address': billingAddress?.toJson(),
      'is_default': isDefault,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PaymentMethodInfo copyWith({
    String? id,
    String? stripePaymentMethodId,
    PaymentMethodType? type,
    CardInfo? card,
    String? billingName,
    String? billingEmail,
    BillingAddress? billingAddress,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethodInfo(
      id: id ?? this.id,
      stripePaymentMethodId: stripePaymentMethodId ?? this.stripePaymentMethodId,
      type: type ?? this.type,
      card: card ?? this.card,
      billingName: billingName ?? this.billingName,
      billingEmail: billingEmail ?? this.billingEmail,
      billingAddress: billingAddress ?? this.billingAddress,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    if (card != null) {
      return '${card!.brand.toUpperCase()} •••• ${card!.last4}';
    }
    return type.displayName;
  }
}

enum PaymentMethodType {
  card('card'),
  applePay('apple_pay'),
  googlePay('google_pay'),
  bankAccount('bank_account');

  const PaymentMethodType(this.value);
  
  final String value;

  static PaymentMethodType fromString(String type) {
    return PaymentMethodType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => PaymentMethodType.card,
    );
  }

  static PaymentMethodType fromStripe(stripe.PaymentMethodType stripeType) {
    switch (stripeType) {
      case stripe.PaymentMethodType.Card:
        return PaymentMethodType.card;
      case stripe.PaymentMethodType.GooglePay:
        return PaymentMethodType.googlePay;
      case stripe.PaymentMethodType.ApplePay:
        return PaymentMethodType.applePay;
      default:
        return PaymentMethodType.card;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethodType.card:
        return 'Credit Card';
      case PaymentMethodType.applePay:
        return 'Apple Pay';
      case PaymentMethodType.googlePay:
        return 'Google Pay';
      case PaymentMethodType.bankAccount:
        return 'Bank Account';
    }
  }
}

class CardInfo {
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final String? funding;
  final String? country;

  const CardInfo({
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    this.funding,
    this.country,
  });

  factory CardInfo.fromStripe(stripe.CardDetails card) {
    return CardInfo(
      brand: card.brand?.name ?? 'unknown',
      last4: card.last4 ?? '0000',
      expMonth: card.expiryMonth ?? 0,
      expYear: card.expiryYear ?? 0,
      funding: card.funding?.name,
      country: card.country,
    );
  }

  factory CardInfo.fromJson(Map<String, dynamic> json) {
    return CardInfo(
      brand: json['brand'] as String,
      last4: json['last4'] as String,
      expMonth: json['exp_month'] as int,
      expYear: json['exp_year'] as int,
      funding: json['funding'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'last4': last4,
      'exp_month': expMonth,
      'exp_year': expYear,
      'funding': funding,
      'country': country,
    };
  }

  bool get isExpired {
    final now = DateTime.now();
    final cardExpiry = DateTime(expYear, expMonth + 1, 0);
    return cardExpiry.isBefore(now);
  }

  bool get isExpiringSoon {
    final now = DateTime.now();
    final threeMonthsFromNow = now.add(const Duration(days: 90));
    final cardExpiry = DateTime(expYear, expMonth + 1, 0);
    return cardExpiry.isBefore(threeMonthsFromNow) && !isExpired;
  }

  String get displayExpiry => '${expMonth.toString().padLeft(2, '0')}/${expYear.toString().substring(2)}';
}

class BillingAddress {
  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  const BillingAddress({
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  factory BillingAddress.fromStripe(stripe.Address address) {
    return BillingAddress(
      line1: address.line1,
      line2: address.line2,
      city: address.city,
      state: address.state,
      postalCode: address.postalCode,
      country: address.country,
    );
  }

  factory BillingAddress.fromJson(Map<String, dynamic> json) {
    return BillingAddress(
      line1: json['line1'] as String?,
      line2: json['line2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
    };
  }

  String get displayAddress {
    final parts = <String>[];
    if (line1?.isNotEmpty == true) parts.add(line1!);
    if (line2?.isNotEmpty == true) parts.add(line2!);
    if (city?.isNotEmpty == true) parts.add(city!);
    if (state?.isNotEmpty == true) parts.add(state!);
    if (postalCode?.isNotEmpty == true) parts.add(postalCode!);
    return parts.join(', ');
  }
}

enum PaymentResult {
  success,
  canceled,
  failed,
  requiresAction,
  processing,
  networkError,
  unknownError
}

class PaymentOperationResult {
  final PaymentResult result;
  final String? message;
  final PaymentMethodInfo? paymentMethod;
  final String? errorCode;
  final String? clientSecret;

  const PaymentOperationResult({
    required this.result,
    this.message,
    this.paymentMethod,
    this.errorCode,
    this.clientSecret,
  });

  bool get isSuccess => result == PaymentResult.success;
  bool get isError => result == PaymentResult.failed || result == PaymentResult.networkError || result == PaymentResult.unknownError;
  bool get requiresAction => result == PaymentResult.requiresAction;
}

class PaymentIntent {
  final String id;
  final String clientSecret;
  final double amount;
  final String currency;
  final String status;
  final String? customerId;
  final DateTime created;

  const PaymentIntent({
    required this.id,
    required this.clientSecret,
    required this.amount,
    this.currency = 'usd',
    required this.status,
    this.customerId,
    required this.created,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['id'] as String,
      clientSecret: json['client_secret'] as String,
      amount: (json['amount'] as num).toDouble() / 100, // Stripe stores amounts in cents
      currency: json['currency'] as String? ?? 'usd',
      status: json['status'] as String,
      customerId: json['customer'] as String?,
      created: DateTime.fromMillisecondsSinceEpoch((json['created'] as int) * 1000),
    );
  }

  bool get requiresAction => status == 'requires_action' || status == 'requires_source_action';
  bool get isSucceeded => status == 'succeeded';
  bool get isCanceled => status == 'canceled';
  bool get requiresPaymentMethod => status == 'requires_payment_method';
  bool get isProcessing => status == 'processing' || status == 'requires_confirmation';
}

class PaymentAttempt {
  final String id;
  final String userId;
  final PaymentMethodInfo? paymentMethod;
  final double amount;
  final String currency;
  final String type; // subscription_upgrade, payment_method_update, retry_failed_payment
  final Map<String, dynamic> metadata;
  final int attemptNumber;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final String? failureReason;
  final String? failureCode;

  const PaymentAttempt({
    required this.id,
    required this.userId,
    this.paymentMethod,
    required this.amount,
    this.currency = 'usd',
    required this.type,
    this.metadata = const {},
    this.attemptNumber = 1,
    required this.createdAt,
    this.scheduledFor,
    this.failureReason,
    this.failureCode,
  });

  factory PaymentAttempt.fromJson(Map<String, dynamic> json) {
    return PaymentAttempt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      paymentMethod: json['payment_method'] != null
          ? PaymentMethodInfo.fromJson(json['payment_method'] as Map<String, dynamic>)
          : null,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'usd',
      type: json['type'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      attemptNumber: json['attempt_number'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.parse(json['scheduled_for'] as String)
          : null,
      failureReason: json['failure_reason'] as String?,
      failureCode: json['failure_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'payment_method': paymentMethod?.toJson(),
      'amount': amount,
      'currency': currency,
      'type': type,
      'metadata': metadata,
      'attempt_number': attemptNumber,
      'created_at': createdAt.toIso8601String(),
      'scheduled_for': scheduledFor?.toIso8601String(),
      'failure_reason': failureReason,
      'failure_code': failureCode,
    };
  }
}