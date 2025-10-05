import 'package:flutter/material.dart';

import 'package:family_bridge/features/trial_management/models/subscription_model.dart';

class EmergencyUpgradeTrigger {
  static const int TRIAL_CONTACT_LIMIT = 3;
  
  static bool shouldTrigger({
    required int currentContacts,
    required SubscriptionStatus status,
  }) {
    if (status == SubscriptionStatus.active) return false;
    return currentContacts >= TRIAL_CONTACT_LIMIT;
  }

  static void showEmergencyLimitDialog({
    required BuildContext context,
    required SubscriptionModel subscription,
    required VoidCallback onUpgrade,
  }) {
    final isElder = subscription.userType == UserType.elder;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isElder ? 24 : 16),
        ),
        content: Container(
          constraints: BoxConstraints(
            maxWidth: isElder ? 450 : 400,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emergency icon with pulse animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.2),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.all(isElder ? 24 : 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emergency_rounded,
                        color: Colors.red,
                        size: isElder ? 56 : 48,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isElder ? 24 : 20),
              Text(
                isElder
                    ? 'Add More Emergency Contacts'
                    : 'Emergency Contact Limit Reached',
                style: TextStyle(
                  fontSize: isElder ? 26 : 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isElder ? 16 : 12),
              Text(
                isElder
                    ? 'Keep your family informed in emergencies.\nAdd unlimited contacts with Premium.'
                    : 'You\'ve added 3 emergency contacts. Upgrade to add unlimited contacts and ensure everyone important can be reached.',
                style: TextStyle(
                  fontSize: isElder ? 18 : 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isElder ? 24 : 20),
              // Current contacts visualization
              Container(
                padding: EdgeInsets.all(isElder ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(isElder ? 16 : 12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: isElder ? 8 : 6,
                          ),
                          child: CircleAvatar(
                            radius: isElder ? 28 : 24,
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.blue.shade700,
                              size: isElder ? 28 : 24,
                            ),
                          ),
                        );
                      })..add(
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: isElder ? 8 : 6,
                          ),
                          child: CircleAvatar(
                            radius: isElder ? 28 : 24,
                            backgroundColor: Colors.orange.shade100,
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.orange.shade700,
                              size: isElder ? 28 : 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isElder ? 12 : 8),
                    Text(
                      'Current: 3 contacts | Want to add more?',
                      style: TextStyle(
                        fontSize: isElder ? 16 : 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isElder ? 24 : 20),
              // Benefits of unlimited
              Container(
                padding: EdgeInsets.all(isElder ? 16 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade50,
                      Colors.green.shade100,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isElder ? 12 : 8),
                  border: Border.all(
                    color: Colors.green.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      color: Colors.green.shade700,
                      size: isElder ? 32 : 28,
                    ),
                    SizedBox(width: isElder ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premium Safety',
                            style: TextStyle(
                              fontSize: isElder ? 18 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          Text(
                            'Add doctors, neighbors, and all family members',
                            style: TextStyle(
                              fontSize: isElder ? 16 : 12,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isElder ? 'Not Now' : 'Skip',
              style: TextStyle(
                fontSize: isElder ? 18 : 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onUpgrade();
            },
            icon: Icon(
              Icons.star_rounded,
              size: isElder ? 24 : 20,
            ),
            label: Text(
              isElder ? 'Add More Contacts' : 'Upgrade Now',
              style: TextStyle(
                fontSize: isElder ? 20 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(
                horizontal: isElder ? 24 : 20,
                vertical: isElder ? 16 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isElder ? 12 : 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}