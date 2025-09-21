import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../widgets/upgrade_prompt_widget.dart';

class StorageUpgradeTrigger {
  static const double FREE_STORAGE_LIMIT_GB = 0.5; // 500MB for trial users
  static const double WARNING_THRESHOLD = 0.4; // Warn at 80% usage

  static bool shouldTrigger({
    required double currentStorageGB,
    required SubscriptionStatus status,
  }) {
    if (status == SubscriptionStatus.active) return false;
    return currentStorageGB >= WARNING_THRESHOLD;
  }

  static void showStorageLimitDialog({
    required BuildContext context,
    required SubscriptionModel subscription,
    required String fileName,
    required double fileSize,
    required VoidCallback onUpgrade,
    VoidCallback? onCancel,
  }) {
    final isElder = subscription.userType == UserType.elder;
    final currentUsage = subscription.usageStats['storageUsedGB'] ?? 0.0;
    final percentUsed = ((currentUsage / FREE_STORAGE_LIMIT_GB) * 100).toInt();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isElder ? 24 : 16),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          constraints: BoxConstraints(
            maxWidth: isElder ? 400 : 350,
            minHeight: isElder ? 400 : 350,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: EdgeInsets.all(isElder ? 24 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.red.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isElder ? 24 : 16),
                    topRight: Radius.circular(isElder ? 24 : 16),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.white,
                      size: isElder ? 64 : 48,
                    ),
                    SizedBox(height: isElder ? 12 : 8),
                    Text(
                      'Storage Limit Reached!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isElder ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(isElder ? 24 : 20),
                child: Column(
                  children: [
                    Text(
                      isElder
                          ? 'This precious family moment won\'t be saved!'
                          : 'You\'ve reached your trial storage limit',
                      style: TextStyle(
                        fontSize: isElder ? 20 : 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isElder ? 20 : 16),
                    // Storage indicator
                    _buildStorageIndicator(
                      percentUsed: percentUsed,
                      currentGB: currentUsage,
                      maxGB: FREE_STORAGE_LIMIT_GB,
                      isElder: isElder,
                    ),
                    SizedBox(height: isElder ? 20 : 16),
                    // What they'll get
                    Container(
                      padding: EdgeInsets.all(isElder ? 16 : 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(isElder ? 12 : 8),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: isElder ? 28 : 24,
                          ),
                          SizedBox(width: isElder ? 12 : 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upgrade to Premium',
                                  style: TextStyle(
                                    fontSize: isElder ? 18 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                Text(
                                  'Unlimited storage for all family memories',
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: onCancel ?? () => Navigator.pop(context),
            child: Text(
              'Cancel Upload',
              style: TextStyle(
                fontSize: isElder ? 18 : 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onUpgrade();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(
                horizontal: isElder ? 32 : 24,
                vertical: isElder ? 16 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isElder ? 12 : 8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_upload_rounded,
                  size: isElder ? 24 : 20,
                ),
                SizedBox(width: isElder ? 8 : 6),
                Text(
                  'Upgrade & Save',
                  style: TextStyle(
                    fontSize: isElder ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStorageIndicator({
    required int percentUsed,
    required double currentGB,
    required double maxGB,
    required bool isElder,
  }) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: isElder ? 16 : 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentUsed / 100,
              child: Container(
                height: isElder ? 16 : 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: percentUsed > 90
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : percentUsed > 75
                            ? [Colors.orange.shade400, Colors.orange.shade600]
                            : [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isElder ? 12 : 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${currentGB.toStringAsFixed(1)} GB used',
              style: TextStyle(
                fontSize: isElder ? 16 : 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '$percentUsed% full',
              style: TextStyle(
                fontSize: isElder ? 16 : 12,
                fontWeight: FontWeight.bold,
                color: percentUsed > 90
                    ? Colors.red
                    : percentUsed > 75
                        ? Colors.orange
                        : Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}