import '../models/user_profile_model.dart';
import 'trial_service.dart';
import 'trial_analytics_service.dart';

class ConversionOptimizationService {
  final TrialService trialService;
  final TrialAnalyticsService analyticsService;
  ConversionOptimizationService({required this.trialService, required this.analyticsService});
  bool shouldPromptUpgrade(String featureKey, UserProfile user, {Map<String, dynamic>? contextData}) {
    if (user.subscriptionStatus == 'premium') return false;
    if (trialService.isInTrialPeriod(user)) return false;
    if (featureKey == 'media_storage') return true;
    if (featureKey == 'advanced_health_analytics') return true;
    if (featureKey == 'emergency_contacts_exceeded') return true;
    if (featureKey == 'story_recordings') return true;
    if (featureKey == 'family_archive_export') return true;
    return false;
  }
  String getUpgradeMessage(UserProfile user, String featureKey) {
    final msg = analyticsService.getPersonalizedUpgradeMessage(user);
    if (msg.isNotEmpty) return msg;
    if (featureKey == 'media_storage') return 'Keep your family memories safe with unlimited storage.';
    if (featureKey == 'advanced_health_analytics') return 'Unlock advanced health analytics for deeper insights.';
    if (featureKey == 'emergency_contacts_exceeded') return 'Add unlimited emergency contacts for peace of mind.';
    if (featureKey == 'story_recordings') return 'Record unlimited stories from your loved ones.';
    if (featureKey == 'family_archive_export') return 'Export and preserve your entire family archive.';
    return 'Upgrade to continue enjoying premium features.';
  }
}