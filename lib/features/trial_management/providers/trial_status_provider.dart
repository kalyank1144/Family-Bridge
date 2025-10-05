import 'package:flutter/foundation.dart';

import 'package:family_bridge/core/models/user_profile_model.dart';
import 'package:family_bridge/core/services/conversion_optimization_service.dart';
import 'package:family_bridge/core/services/feature_gate_service.dart';
import 'package:family_bridge/core/services/trial_analytics_service.dart';
import 'package:family_bridge/core/services/trial_service.dart';

class TrialStatusProvider extends ChangeNotifier {
  final TrialService trialService;
  final FeatureGateService featureGateService;
  final ConversionOptimizationService conversionService;
  final TrialAnalyticsService analyticsService;
  UserProfile? _user;
  TrialStatusProvider({required this.trialService, required this.featureGateService, required this.conversionService, required this.analyticsService});
  void setUser(UserProfile user) {
    _user = user;
    notifyListeners();
  }
  UserProfile? get user => _user;
  bool get isInTrial => _user != null && trialService.isInTrialPeriod(_user!);
  int get remainingDays => _user == null ? 0 : trialService.getRemainingTrialDays(_user!);
  Map<String, dynamic> get usage => _user?.featureUsageTracking ?? {};
  Future<void> trackUsage(String featureKey) async {
    if (_user == null) return;
    await trialService.trackFeatureUsage(featureKey, _user!);
    final m = Map<String, dynamic>.from(_user!.featureUsageTracking);
    final f = Map<String, dynamic>.from(m[featureKey] ?? {});
    final c = (f['count'] ?? 0) is int ? f['count'] : int.tryParse(f['count']?.toString() ?? '0') ?? 0;
    f['count'] = c + 1;
    f['last_used_at'] = DateTime.now().toIso8601String();
    m[featureKey] = f;
    _user = UserProfile(
      id: _user!.id,
      familyId: _user!.familyId,
      isFamilyCreator: _user!.isFamilyCreator,
      trialStartDate: _user!.trialStartDate,
      trialEndDate: _user!.trialEndDate,
      subscriptionStatus: _user!.subscriptionStatus,
      featureUsageTracking: m,
      storageUsedBytes: _user!.storageUsedBytes,
      voiceTranscriptionMinutesThisMonth: _user!.voiceTranscriptionMinutesThisMonth,
      storyRecordingsThisMonth: _user!.storyRecordingsThisMonth,
      emergencyContactsCount: _user!.emergencyContactsCount,
    );
    notifyListeners();
  }
  bool canUploadMedia(int fileSizeBytes) {
    if (_user == null) return false;
    return featureGateService.canUploadMedia(_user!, fileSizeBytes);
  }
  bool canUseVoiceTranscription() {
    if (_user == null) return false;
    return featureGateService.canUseVoiceTranscription(_user!);
  }
  bool canRecordStory() {
    if (_user == null) return false;
    return featureGateService.canRecordStory(_user!);
  }
  bool shouldPromptUpgrade(String featureKey, {Map<String, dynamic>? contextData}) {
    if (_user == null) return false;
    return conversionService.shouldPromptUpgrade(featureKey, _user!, contextData: contextData);
  }
  String upgradeMessage(String featureKey) {
    if (_user == null) return '';
    return conversionService.getUpgradeMessage(_user!, featureKey);
  }
  void trackEngagement(String feature, Duration timeSpent) {
    analyticsService.trackFeatureEngagement(feature, timeSpent);
    notifyListeners();
  }
  double get conversionProbability => _user == null ? 0 : analyticsService.calculateConversionProbability(_user!);
  Future<bool> upgradeToPremium() async {
    if (_user == null) return false;
    final ok = await trialService.convertTrialToPremium(_user!);
    if (!ok) return false;
    _user = UserProfile(
      id: _user!.id,
      familyId: _user!.familyId,
      isFamilyCreator: _user!.isFamilyCreator,
      trialStartDate: _user!.trialStartDate,
      trialEndDate: _user!.trialEndDate,
      subscriptionStatus: 'premium',
      featureUsageTracking: _user!.featureUsageTracking,
      storageUsedBytes: _user!.storageUsedBytes,
      voiceTranscriptionMinutesThisMonth: _user!.voiceTranscriptionMinutesThisMonth,
      storyRecordingsThisMonth: _user!.storyRecordingsThisMonth,
      emergencyContactsCount: _user!.emergencyContactsCount,
    );
    notifyListeners();
    return true;
  }
}