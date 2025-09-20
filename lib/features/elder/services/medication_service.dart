import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../repositories/offline_first/medication_repository.dart';
import '../../../services/sync/data_sync_service.dart';
import '../../../models/hive/medication_model.dart';
import '../models/medication_model.dart';
import '../../../core/services/notification_service.dart';
import 'package:flutter/material.dart';

class ElderMedicationService {
  final _uuid = const Uuid();
  
  late MedicationRepository _repo;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await DataSyncService.instance.initialize();
    _repo = MedicationRepository(box: DataSyncService.instance.medicationsBox);
    _initialized = true;
  }

  Future<List<Medication>> getUserMedications(String userId) async {
    await initialize();
    
    try {
      final hiveMedications = _repo.getUserMedications(userId);
      return hiveMedications.map(_fromHiveMedication).toList();
    } catch (e) {
      debugPrint('Error loading medications: $e');
      return [];
    }
  }

  Stream<List<Medication>> watchUserMedications(String userId) async* {
    await initialize();
    
    await for (final hiveMedications in _repo.watchUserMedications(userId)) {
      yield hiveMedications.map(_fromHiveMedication).toList();
    }
  }

  Future<List<Medication>> getActiveMedications(String userId) async {
    await initialize();
    
    try {
      final hiveMedications = _repo.getActiveMedications(userId);
      return hiveMedications.map(_fromHiveMedication).toList();
    } catch (e) {
      debugPrint('Error loading active medications: $e');
      return [];
    }
  }

  Future<List<Medication>> getTodayDueMedications(String userId) async {
    await initialize();
    
    try {
      final hiveMedications = _repo.getTodayDueMedications(userId);
      return hiveMedications.map(_fromHiveMedication).toList();
    } catch (e) {
      debugPrint('Error loading due medications: $e');
      return [];
    }
  }

  Future<void> markMedicationTaken(String medicationId, String userId) async {
    await initialize();
    
    await _repo.markMedicationTaken(medicationId, DateTime.now());
  }

  Future<Medication> addMedication(Medication medication, String userId) async {
    await initialize();
    
    final id = medication.id.isNotEmpty ? medication.id : _uuid.v4();
    final hiveMedication = _toHiveMedication(medication, id, userId);
    
    await _repo.create(hiveMedication);
    
    for (final t in medication.times) {
      final parts = t.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]) ?? 8;
        final m = int.tryParse(parts[1]) ?? 0;
        await NotificationService.instance.scheduleDailyCheckinReminder(
          title: 'Medication Reminder: ${medication.name}',
          message: 'Take ${medication.dosage}',
          time: TimeOfDay(hour: h, minute: m),
        );
      }
    }
    
    return medication.copyWith(id: id);
  }

  Future<void> updateMedication(Medication medication, String userId) async {
    await initialize();
    
    final hiveMedication = _toHiveMedication(medication, medication.id, userId);
    await _repo.upsert(hiveMedication);
    for (final t in medication.times) {
      final parts = t.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]) ?? 8;
        final m = int.tryParse(parts[1]) ?? 0;
        await NotificationService.instance.scheduleDailyCheckinReminder(
          title: 'Medication Reminder: ${medication.name}',
          message: 'Take ${medication.dosage}',
          time: TimeOfDay(hour: h, minute: m),
        );
      }
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    await initialize();
    
    await _repo.delete(medicationId);
  }

  Future<double> getComplianceRate(String userId, {int days = 7}) async {
    await initialize();
    
    return _repo.getComplianceRate(userId, days: days);
  }

  void dispose() {
    // Nothing to dispose for offline-first approach
  }

  // Conversion helpers
  HiveMedicationSchedule _toHiveMedication(Medication medication, String id, String userId) {
    return HiveMedicationSchedule(
      id: id,
      userId: userId,
      familyId: 'default', // Should come from context
      name: medication.name,
      dosage: medication.dosage,
      times: medication.times,
      takenLog: const [], // Will be populated as medication is taken
      startDate: medication.createdAt,
      endDate: null, // Could be added to Medication model
    );
  }

  Medication _fromHiveMedication(HiveMedicationSchedule hiveMedication) {
    // Calculate next dose time based on times and taken log
    final nextDose = _calculateNextDose(hiveMedication);
    
    return Medication(
      id: hiveMedication.id,
      name: hiveMedication.name,
      dosage: hiveMedication.dosage,
      frequency: _getFrequencyFromTimes(hiveMedication.times),
      nextDoseTime: nextDose,
      instructions: null, // Could be stored in metadata
      photoUrl: null, // Could be stored in metadata
      requiresPhotoConfirmation: false, // Could be stored in metadata
      times: hiveMedication.times,
      createdAt: hiveMedication.startDate,
    );
  }

  DateTime _calculateNextDose(HiveMedicationSchedule medication) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if any scheduled time today is still due
    for (final timeStr in medication.times) {
      final parts = timeStr.split(':');
      if (parts.length != 2) continue;
      
      final scheduledTime = today.add(Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
      ));
      
      // Check if this time was already taken today
      final alreadyTaken = medication.takenLog.any((takenTime) {
        final takenToday = DateTime(takenTime.year, takenTime.month, takenTime.day);
        return takenToday.isAtSameMomentAs(today) && 
               _isSameTimeSlot(takenTime, scheduledTime);
      });
      
      if (!alreadyTaken && scheduledTime.isAfter(now)) {
        return scheduledTime;
      }
    }
    
    // No more doses today, return first dose tomorrow
    final tomorrow = today.add(const Duration(days: 1));
    final firstTimeToday = medication.times.isNotEmpty ? medication.times.first : '08:00';
    final parts = firstTimeToday.split(':');
    return tomorrow.add(Duration(
      hours: int.tryParse(parts[0]) ?? 8,
      minutes: int.tryParse(parts[1]) ?? 0,
    ));
  }

  String _getFrequencyFromTimes(List<String> times) {
    switch (times.length) {
      case 1:
        return 'daily';
      case 2:
        return 'twice daily';
      case 3:
        return 'three times daily';
      case 4:
        return 'four times daily';
      default:
        return 'daily';
    }
  }

  bool _isSameTimeSlot(DateTime takenTime, DateTime scheduledTime) {
    // Consider same time slot if within 2 hours of scheduled time
    return takenTime.difference(scheduledTime).abs() < const Duration(hours: 2);
  }
}

extension MedicationCopyWith on Medication {
  Medication copyWith({String? id}) {
    return Medication(
      id: id ?? this.id,
      name: name,
      dosage: dosage,
      frequency: frequency,
      nextDoseTime: nextDoseTime,
      instructions: instructions,
      photoUrl: photoUrl,
      requiresPhotoConfirmation: requiresPhotoConfirmation,
      times: times,
      createdAt: createdAt,
    );
  }
}