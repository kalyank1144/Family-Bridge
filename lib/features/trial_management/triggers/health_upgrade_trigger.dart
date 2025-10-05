import 'package:flutter/material.dart';

import 'package:family_bridge/features/trial_management/models/subscription_model.dart';

class HealthUpgradeTrigger {
  static const List<String> PREMIUM_HEALTH_FEATURES = [
    'Trend Analysis',
    'Predictive Alerts',
    'Detailed Reports',
    'Export to PDF',
    'Share with Doctors',
    'Historical Comparisons',
  ];

  static void showHealthFeatureDialog({
    required BuildContext context,
    required SubscriptionModel subscription,
    required String featureName,
    required VoidCallback onUpgrade,
  }) {
    final isCaregiver = subscription.userType == UserType.caregiver;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Premium Health Analytics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCaregiver
                          ? 'Advanced insights for professional care'
                          : 'Deeper health understanding',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current limitation message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.orange.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '"$featureName" requires premium subscription',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Benefits list
                    const Text(
                      'Unlock these powerful features:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...PREMIUM_HEALTH_FEATURES.map((feature) => _buildFeatureItem(
                      feature,
                      _getFeatureDescription(feature, isCaregiver),
                    )).toList(),
                    const SizedBox(height: 20),
                    // ROI message for caregivers
                    if (isCaregiver)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              color: Colors.green.shade700,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Save 2+ hours per week',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  Text(
                                    'Automated monitoring and instant alerts',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Maybe Later',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onUpgrade();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isCaregiver
                                  ? 'Upgrade for \$9.99/mo'
                                  : 'Get Premium Access',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.deepPurple.shade600,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _getFeatureDescription(String feature, bool isCaregiver) {
    final descriptions = {
      'Trend Analysis': isCaregiver
          ? 'Identify patterns in vitals and behaviors over time'
          : 'See how health metrics change over weeks and months',
      'Predictive Alerts': isCaregiver
          ? 'AI-powered early warning system for health changes'
          : 'Get notified before issues become serious',
      'Detailed Reports': isCaregiver
          ? 'Professional PDF reports for medical consultations'
          : 'Comprehensive health summaries to share',
      'Export to PDF': isCaregiver
          ? 'Generate reports for insurance and care planning'
          : 'Save and print health information easily',
      'Share with Doctors': isCaregiver
          ? 'Direct secure sharing with healthcare providers'
          : 'Send health data to medical professionals',
      'Historical Comparisons': isCaregiver
          ? 'Compare current vs baseline measurements'
          : 'Track progress and improvements over time',
    };
    return descriptions[feature] ?? '';
  }
}