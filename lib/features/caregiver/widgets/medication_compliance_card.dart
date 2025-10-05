import 'package:flutter/material.dart';

import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/caregiver/models/health_data.dart';

class MedicationComplianceCard extends StatelessWidget {
  final double compliance;
  final List<MedicationRecord> medications;
  final Function(String) onMedicationTaken;

  const MedicationComplianceCard({
    super.key,
    required this.compliance,
    required this.medications,
    required this.onMedicationTaken,
  });

  @override
  Widget build(BuildContext context) {
    final complianceColor = _getComplianceColor();
    final todayMedications = _getTodayMedications();
    final takenCount = todayMedications.where((m) => m.isTaken).length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medication Compliance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This Week',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                CircularPercentIndicator(
                  radius: 45.0,
                  lineWidth: 8.0,
                  percent: compliance,
                  center: Text(
                    '${(compliance * 100).toInt()}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: complianceColor,
                  backgroundColor: complianceColor.withOpacity(0.1),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Medications",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: takenCount == todayMedications.length
                              ? AppTheme.successColor.withOpacity(0.1)
                              : AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$takenCount / ${todayMedications.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: takenCount == todayMedications.length
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  if (todayMedications.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        child: Text(
                          'No medications scheduled for today',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...todayMedications.map((med) => _buildMedicationItem(
                      context,
                      med,
                    )),
                ],
              ),
            ),
            if (compliance < 0.8) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Compliance below target. Consider setting reminders.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getComplianceColor() {
    if (compliance >= 0.9) return AppTheme.successColor;
    if (compliance >= 0.7) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  List<MedicationRecord> _getTodayMedications() {
    final now = DateTime.now();
    return medications.where((med) {
      return med.scheduledTime.year == now.year &&
          med.scheduledTime.month == now.month &&
          med.scheduledTime.day == now.day;
    }).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  Widget _buildMedicationItem(BuildContext context, MedicationRecord med) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: med.isTaken
                  ? AppTheme.successColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              med.isTaken ? Icons.check : Icons.access_time,
              size: 16,
              color: med.isTaken ? AppTheme.successColor : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: med.isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${med.dosage} - ${_formatTime(med.scheduledTime)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!med.isTaken)
            TextButton(
              onPressed: () => onMedicationTaken(med.id),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: const Text(
                'Mark Taken',
                style: TextStyle(fontSize: 12),
              ),
            ),
          if (med.isTaken)
            Text(
              _formatTime(med.takenTime!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.successColor,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}