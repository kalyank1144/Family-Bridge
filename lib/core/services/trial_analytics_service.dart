import 'dart:math';

import 'package:family_bridge/core/models/user_profile_model.dart';

class TrialAnalyticsService {
  final Map<String, Duration> _featureTime = {};
  void trackFeatureEngagement(String feature, Duration timeSpent) {
    final current = _featureTime[feature] ?? Duration.zero;
    _featureTime[feature] = current + timeSpent;
  }
  double calculateConversionProbability(UserProfile user) {
    double score = 0;
    final t = user.featureUsageTracking;
    void addScore(String k, double w) {
      final m = t[k];
      if (m is Map && (m['count'] ?? 0) is int) {
        final c = m['count'] as int;
        score += min(c * w, w * 5);
      }
    }
    addScore('media_storage', 0.25);
    addScore('voice_transcription', 0.15);
    addScore('story_recordings', 0.25);
    addScore('advanced_health_analytics', 0.2);
    addScore('message_history', 0.1);
    final totalMinutes = _featureTime.values.fold<int>(0, (a, b) => a + b.inMinutes);
    score += min(totalMinutes / 120.0, 0.3);
    if (user.subscriptionStatus == 'trial' && user.trialEndDate != null) {
      final daysLeft = user.trialEndDate!.difference(DateTime.now()).inDays;
      if (daysLeft <= 5) score += 0.2;
    }
    if (score < 0) score = 0;
    if (score > 1) score = 1;
    return score;
  }
  String getPersonalizedUpgradeMessage(UserProfile user) {
    final t = user.featureUsageTracking;
    String topFeature = '';
    int topCount = 0;
    for (final e in t.entries) {
      final m = e.value;
      if (m is Map && (m['count'] ?? 0) is int) {
        final c = m['count'] as int;
        if (c > topCount) {
          topCount = c;
          topFeature = e.key;
        }
      }
    }
    if (topFeature.isEmpty) return '';
    if (topFeature == 'media_storage') return 'Upgrade for unlimited photo and video storage.';
    if (topFeature == 'story_recordings') return 'Upgrade to record unlimited family stories.';
    if (topFeature == 'voice_transcription') return 'Upgrade for unlimited voice transcription minutes.';
    if (topFeature == 'advanced_health_analytics') return 'Upgrade to unlock advanced health analytics.';
    if (topFeature == 'message_history') return 'Upgrade to view your full message history.';
    return '';
  }
}