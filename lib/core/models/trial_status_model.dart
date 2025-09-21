class TrialStatus {
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final String subscriptionStatus;
  const TrialStatus({required this.trialStartDate, required this.trialEndDate, required this.subscriptionStatus});
  factory TrialStatus.fromJson(Map<String, dynamic> json) {
    return TrialStatus(
      trialStartDate: json['trial_start_date'] != null ? DateTime.tryParse(json['trial_start_date'].toString()) : null,
      trialEndDate: json['trial_end_date'] != null ? DateTime.tryParse(json['trial_end_date'].toString()) : null,
      subscriptionStatus: (json['subscription_status'] ?? 'trial').toString(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'trial_start_date': trialStartDate?.toIso8601String(),
      'trial_end_date': trialEndDate?.toIso8601String(),
      'subscription_status': subscriptionStatus,
    };
  }
  bool get isInTrialPeriod {
    if (subscriptionStatus == 'premium') return false;
    if (trialStartDate == null || trialEndDate == null) return false;
    final now = DateTime.now().toUtc();
    return now.isAfter(trialStartDate!.toUtc()) && now.isBefore(trialEndDate!.toUtc());
  }
  int get remainingTrialDays {
    if (trialEndDate == null) return 0;
    final now = DateTime.now().toUtc();
    final diff = trialEndDate!.toUtc().difference(now).inDays;
    return diff > 0 ? diff : 0;
  }
  int get daysIntoTrial {
    if (trialStartDate == null) return 0;
    final now = DateTime.now().toUtc();
    final diff = now.difference(trialStartDate!.toUtc()).inDays;
    return diff > 0 ? diff : 0;
  }
  bool get isExpired {
    if (subscriptionStatus == 'premium') return false;
    if (trialEndDate == null) return true;
    return DateTime.now().toUtc().isAfter(trialEndDate!.toUtc());
  }
}