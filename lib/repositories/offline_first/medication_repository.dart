import 'package:hive/hive.dart';

import '../../models/hive/medication_model.dart';
import 'base_offline_repository.dart';

class MedicationRepository extends BaseOfflineRepository<HiveMedicationSchedule> {
  MedicationRepository({required Box<HiveMedicationSchedule> box})
      : super(
          table: 'medications',
          box: box,
          fromMap: (m) => HiveMedicationSchedule.fromMap(m),
          toMap: (m) => m.toMap(),
        );

  List<HiveMedicationSchedule> getUserMedications(String userId) {
    return box.values
        .where((medication) => medication.userId == userId)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Stream<List<HiveMedicationSchedule>> watchUserMedications(String userId) {
    return box.watch().map((_) => getUserMedications(userId));
  }

  List<HiveMedicationSchedule> getActiveMedications(String userId) {
    final now = DateTime.now();
    return box.values
        .where((medication) => 
            medication.userId == userId &&
            medication.startDate.isBefore(now) &&
            (medication.endDate == null || medication.endDate!.isAfter(now)))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  List<HiveMedicationSchedule> getTodayDueMedications(String userId) {
    final activeMeds = getActiveMedications(userId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return activeMeds.where((med) {
      // Check if any scheduled time for today is due
      for (final timeStr in med.times) {
        final parts = timeStr.split(':');
        if (parts.length != 2) continue;
        
        final scheduledTime = today.add(Duration(
          hours: int.tryParse(parts[0]) ?? 0,
          minutes: int.tryParse(parts[1]) ?? 0,
        ));
        
        // Check if this medication was already taken today at this time
        final alreadyTaken = med.takenLog.any((takenTime) {
          final takenToday = DateTime(takenTime.year, takenTime.month, takenTime.day);
          return takenToday.isAtSameMomentAs(today) && 
                 _isSameTimeSlot(takenTime, scheduledTime);
        });
        
        if (!alreadyTaken && scheduledTime.isBefore(now)) {
          return true; // This medication is due
        }
      }
      return false;
    }).toList();
  }

  Future<void> markMedicationTaken(String medicationId, DateTime takenAt) async {
    final medication = box.get(medicationId);
    if (medication != null) {
      medication.takenLog.add(takenAt);
      medication.updatedAt = DateTime.now();
      await upsert(medication);
    }
  }

  double getComplianceRate(String userId, {int days = 7}) {
    final medications = getActiveMedications(userId);
    if (medications.isEmpty) return 1.0;

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    
    int totalDoses = 0;
    int takenDoses = 0;

    for (final med in medications) {
      // Calculate expected doses in the period
      final startDate = med.startDate.isAfter(cutoff) ? med.startDate : cutoff;
      final endDate = med.endDate?.isBefore(now) ?? false ? med.endDate! : now;
      
      if (startDate.isAfter(endDate)) continue;
      
      final periodDays = endDate.difference(startDate).inDays + 1;
      totalDoses += med.times.length * periodDays;
      
      // Count actual taken doses in the period
      final takenInPeriod = med.takenLog.where((takenTime) =>
          takenTime.isAfter(cutoff) && takenTime.isBefore(now.add(const Duration(days: 1)))).length;
      takenDoses += takenInPeriod;
    }

    return totalDoses > 0 ? takenDoses / totalDoses : 1.0;
  }

  bool _isSameTimeSlot(DateTime takenTime, DateTime scheduledTime) {
    // Consider same time slot if within 2 hours of scheduled time
    return takenTime.difference(scheduledTime).abs() < const Duration(hours: 2);
  }
}