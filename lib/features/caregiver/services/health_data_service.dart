import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../models/hive/health_data_model.dart';
import '../../../repositories/offline_first/health_repository.dart';
import '../../../services/network/network_manager.dart';
import '../../../services/offline/offline_manager.dart';
import '../../../services/sync/data_sync_service.dart';
import '../models/health_data.dart';

class HealthDataService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  
  late HealthRepository _repo;
  RealtimeChannel? _channel;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await DataSyncService.instance.initialize();
    _repo = HealthRepository(box: DataSyncService.instance.healthBox);
    _initialized = true;
  }

  Future<List<HealthData>> getHealthData(String memberId, {int days = 7}) async {
    await initialize();
    
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final hiveRecords = _repo.box.values
          .where((record) => 
              record.userId == memberId && 
              record.category == 'vitals' &&
              record.recordedAt.isAfter(cutoff))
          .toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

      return hiveRecords.map(_fromHiveHealthRecord).toList();
    } catch (e) {
      debugPrint('Error loading health data: $e');
      return [];
    }
  }

  Future<List<MedicationRecord>> getMedicationRecords(String memberId, {int days = 7}) async {
    await initialize();
    
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final hiveRecords = _repo.box.values
          .where((record) => 
              record.userId == memberId && 
              record.category == 'medication_log' &&
              record.recordedAt.isAfter(cutoff))
          .toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

      return hiveRecords.map(_fromHiveMedicationRecord).toList();
    } catch (e) {
      debugPrint('Error loading medication records: $e');
      return [];
    }
  }

  Future<void> addHealthData(String memberId, HealthData data) async {
    await initialize();
    
    final id = _uuid.v4();
    final hiveRecord = HiveHealthRecord(
      id: id,
      userId: memberId,
      familyId: 'default', // Should be passed from context
      category: 'vitals',
      data: data.toJson(),
      recordedAt: data.timestamp,
    );

    await _repo.upsertMerge(hiveRecord);
  }

  Future<void> markMedicationTaken(String memberId, String medicationId) async {
    await initialize();
    
    // Find existing medication record
    final existing = _repo.box.values
        .where((record) => 
            record.userId == memberId && 
            record.category == 'medication_log' &&
            record.data['id'] == medicationId)
        .firstOrNull;

    if (existing != null) {
      // Update existing record
      existing.data['is_taken'] = true;
      existing.data['taken_time'] = DateTime.now().toIso8601String();
      existing.updatedAt = DateTime.now();
      await _repo.upsertMerge(existing);
    } else {
      // Create new medication log record
      final id = _uuid.v4();
      final hiveRecord = HiveHealthRecord(
        id: id,
        userId: memberId,
        familyId: 'default',
        category: 'medication_log',
        data: {
          'id': medicationId,
          'is_taken': true,
          'taken_time': DateTime.now().toIso8601String(),
          'scheduled_time': DateTime.now().toIso8601String(), // Should come from context
        },
        recordedAt: DateTime.now(),
      );
      
      await _repo.upsertMerge(hiveRecord);
    }
  }

  void subscribeToHealthUpdates(String memberId, Function(HealthData) onUpdate) {
    if (!NetworkManager.instance.current.isOnline) return;
    
    _channel = _supabase.channel('health_updates_$memberId')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'health_records',
          filter: 'user_id=eq.$memberId',
        ),
        (payload, [ref]) async {
          if (payload['new'] != null) {
            final record = HiveHealthRecord.fromMap(payload['new']);
            if (record.category == 'vitals') {
              final data = _fromHiveHealthRecord(record);
              onUpdate(data);
              // Also update local storage
              await _repo.upsertLocal(record);
            }
          }
        },
      )
      ..subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
  }

  // Conversion helpers
  HealthData _fromHiveHealthRecord(HiveHealthRecord record) {
    final data = record.data;
    return HealthData(
      timestamp: record.recordedAt,
      bloodPressureSystolic: (data['blood_pressure_systolic'] as num?)?.toDouble(),
      bloodPressureDiastolic: (data['blood_pressure_diastolic'] as num?)?.toDouble(),
      heartRate: (data['heart_rate'] as num?)?.toDouble(),
      temperature: (data['temperature'] as num?)?.toDouble(),
      oxygenLevel: (data['oxygen_level'] as num?)?.toDouble(),
      bloodSugar: (data['blood_sugar'] as num?)?.toDouble(),
      steps: data['steps'] as int?,
      weight: (data['weight'] as num?)?.toDouble(),
      mood: data['mood'] as String?,
      moodScore: data['mood_score'] as int?,
      medicationTaken: data['medication_taken'] as bool?,
      notes: data['notes'] as String?,
    );
  }

  MedicationRecord _fromHiveMedicationRecord(HiveHealthRecord record) {
    final data = record.data;
    return MedicationRecord(
      id: data['id'] as String? ?? record.id,
      name: data['name'] as String? ?? 'Medication',
      dosage: data['dosage'] as String? ?? '',
      scheduledTime: data['scheduled_time'] != null 
          ? DateTime.parse(data['scheduled_time'])
          : record.recordedAt,
      takenTime: data['taken_time'] != null 
          ? DateTime.parse(data['taken_time'])
          : null,
      isTaken: data['is_taken'] as bool? ?? false,
      notes: data['notes'] as String?,
    );
  }
}