import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:family_bridge/core/models/user_profile_model.dart';
import 'trial_service.dart';

class FeatureGateService {
  final TrialService trialService;
  FeatureGateService(this.trialService);
  bool canUploadMedia(UserProfile user, int fileSizeBytes) {
    if (trialService.isInTrialPeriod(user)) return true;
    if (user.subscriptionStatus == 'premium') return true;
    const gb = 1024 * 1024 * 1024;
    final limit = 1 * gb;
    return user.storageUsedBytes + fileSizeBytes <= limit;
  }
  bool canUseVoiceTranscription(UserProfile user) {
    if (trialService.isInTrialPeriod(user)) return true;
    if (user.subscriptionStatus == 'premium') return true;
    return user.voiceTranscriptionMinutesThisMonth < 60;
  }
  bool canRecordStory(UserProfile user) {
    if (trialService.isInTrialPeriod(user)) return true;
    if (user.subscriptionStatus == 'premium') return true;
    return user.storyRecordingsThisMonth < 3;
  }
  Widget buildUpgradePrompt(String featureKey, BuildContext context) {
    String title = 'Upgrade required';
    String message = 'This feature requires a premium subscription.';
    if (featureKey == 'media_storage') {
      title = 'Storage limit reached';
      message = 'Upgrade to continue uploading unlimited photos and videos.';
    } else if (featureKey == 'voice_transcription') {
      title = 'Voice minutes limit reached';
      message = 'Upgrade for unlimited voice transcription minutes.';
    } else if (featureKey == 'story_recordings') {
      title = 'Recording limit reached';
      message = 'Upgrade for unlimited story recordings.';
    } else if (featureKey == 'advanced_health_analytics') {
      title = 'Premium analytics';
      message = 'Upgrade to access advanced health analytics.';
    } else if (featureKey == 'professional_reports') {
      title = 'Premium reports';
      message = 'Upgrade to generate professional reports.';
    } else if (featureKey == 'message_history') {
      title = 'Message history limit';
      message = 'Upgrade for unlimited message history.';
    } else if (featureKey == 'family_archive_export') {
      title = 'Export memories';
      message = 'Upgrade to export your full family archive.';
    }
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not now'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/subscription/upgrade');
          },
          child: const Text('Upgrade'),
        ),
      ],
    );
  }
}