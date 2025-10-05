class UserProfile {
  final String id;
  final String? familyId;
  final bool isFamilyCreator;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final String subscriptionStatus;
  final Map<String, dynamic> featureUsageTracking;
  final int storageUsedBytes;
  final int voiceTranscriptionMinutesThisMonth;
  final int storyRecordingsThisMonth;
  final int emergencyContactsCount;
  const UserProfile({
    required this.id,
    this.familyId,
    this.isFamilyCreator = false,
    this.trialStartDate,
    this.trialEndDate,
    this.subscriptionStatus = 'trial',
    this.featureUsageTracking = const {},
    this.storageUsedBytes = 0,
    this.voiceTranscriptionMinutesThisMonth = 0,
    this.storyRecordingsThisMonth = 0,
    this.emergencyContactsCount = 0,
  });
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      familyId: json['family_id']?.toString(),
      isFamilyCreator: json['is_family_creator'] == true,
      trialStartDate: json['trial_start_date'] != null ? DateTime.tryParse(json['trial_start_date'].toString()) : null,
      trialEndDate: json['trial_end_date'] != null ? DateTime.tryParse(json['trial_end_date'].toString()) : null,
      subscriptionStatus: (json['subscription_status'] ?? 'trial').toString(),
      featureUsageTracking: Map<String, dynamic>.from(json['feature_usage_tracking'] ?? {}),
      storageUsedBytes: (json['storage_used_bytes'] ?? 0) is int ? json['storage_used_bytes'] : int.tryParse(json['storage_used_bytes']?.toString() ?? '0') ?? 0,
      voiceTranscriptionMinutesThisMonth: (json['voice_minutes_month'] ?? 0) is int ? json['voice_minutes_month'] : int.tryParse(json['voice_minutes_month']?.toString() ?? '0') ?? 0,
      storyRecordingsThisMonth: (json['story_recordings_month'] ?? 0) is int ? json['story_recordings_month'] : int.tryParse(json['story_recordings_month']?.toString() ?? '0') ?? 0,
      emergencyContactsCount: (json['emergency_contacts_count'] ?? 0) is int ? json['emergency_contacts_count'] : int.tryParse(json['emergency_contacts_count']?.toString() ?? '0') ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'is_family_creator': isFamilyCreator,
      'trial_start_date': trialStartDate?.toIso8601String(),
      'trial_end_date': trialEndDate?.toIso8601String(),
      'subscription_status': subscriptionStatus,
      'feature_usage_tracking': featureUsageTracking,
      'storage_used_bytes': storageUsedBytes,
      'voice_minutes_month': voiceTranscriptionMinutesThisMonth,
      'story_recordings_month': storyRecordingsThisMonth,
      'emergency_contacts_count': emergencyContactsCount,
    };
  }
}