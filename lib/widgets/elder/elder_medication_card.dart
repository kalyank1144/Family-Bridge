import 'package:flutter/material.dart';
import 'package:family_bridge/config/app_config.dart';

class ElderMedicationCard extends StatelessWidget {
  final String medicationName;
  final String dosage;
  final String time;
  final bool taken;
  final VoidCallback onTakeMedication;

  const ElderMedicationCard({
    super.key,
    required this.medicationName,
    required this.dosage,
    required this.time,
    required this.taken,
    required this.onTakeMedication,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: taken 
              ? AppConfig.elderPrimaryColor 
              : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: taken 
                  ? AppConfig.elderPrimaryColor.withOpacity(0.2) 
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication,
              size: 32,
              color: taken 
                  ? AppConfig.elderPrimaryColor 
                  : Colors.grey[600],
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicationName,
                  style: TextStyle(
                    fontSize: AppConfig.elderButtonFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dosage,
                  style: TextStyle(
                    fontSize: AppConfig.elderMinimumFontSize,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: AppConfig.elderMinimumFontSize,
                    color: AppConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          SizedBox(
            width: AppConfig.elderMinimumTouchTarget,
            height: AppConfig.elderMinimumTouchTarget,
            child: ElevatedButton(
              onPressed: taken ? null : onTakeMedication,
              style: ElevatedButton.styleFrom(
                backgroundColor: taken 
                    ? AppConfig.elderPrimaryColor 
                    : AppConfig.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppConfig.elderPrimaryColor,
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Icon(
                taken ? Icons.check : Icons.touch_app,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
