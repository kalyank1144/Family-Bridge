class SubscriptionPlan {
  final String? id;
  final String name;
  final double? priceMonthly;
  final Map<String, dynamic> features;
  const SubscriptionPlan({this.id, required this.name, this.priceMonthly, this.features = const {}});
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      priceMonthly: json['price_monthly'] == null ? null : (json['price_monthly'] as num).toDouble(),
      features: Map<String, dynamic>.from(json['features'] ?? {}),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price_monthly': priceMonthly,
      'features': features,
    };
  }
  bool get isPremium => name.toLowerCase() == 'premium';
  bool get isFree => name.toLowerCase() == 'free';
  int featureInt(String key, {int defaultValue = 0}) {
    final v = features[key];
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }
}