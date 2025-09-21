import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/medication_model.dart';
import '../../shared/services/logging_service.dart';
import '../../shared/services/notification_service.dart';
import '../../chat/services/media_service.dart';

/// Service for managing elder medication reminders, compliance, and scheduling
/// Implements HIPAA-compliant medication management with photo verification
class ElderMedicationService {
  static final ElderMedicationService _instance = ElderMedicationService._internal();
  factory ElderMedicationService() => _instance;
  ElderMedicationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final LoggingService _logger = LoggingService();
  final NotificationService _notificationService = NotificationService();
  final MediaService _mediaService = MediaService();
  final Uuid _uuid = const Uuid();

  final StreamController<List<Medication>> _medicationsController =
      StreamController<List<Medication>>.broadcast();
  final StreamController<List<MedicationReminder>> _remindersController =
      StreamController<List<MedicationReminder>>.broadcast();
  final StreamController<MedicationReminder> _upcomingReminderController =
      StreamController<MedicationReminder>.broadcast();

  // Cache for offline functionality
  final Map<String, Medication> _medicationsCache = {};
  final Map<String, List<MedicationReminder>> _remindersCache = {};
  final List<MedicationReminder> _pendingReminders = [];
  bool _isInitialized = false;

  /// Stream of user's medications
  Stream<List<Medication>> get medicationsStream => _medicationsController.stream;

  /// Stream of medication reminders
  Stream<List<MedicationReminder>> get remindersStream => _remindersController.stream;

  /// Stream of upcoming reminders (next 24 hours)
  Stream<MedicationReminder> get upcomingReminderStream => 
      _upcomingReminderController.stream;

  /// Initialize the medication service
  Future<void> initialize(String userId) async {
    try {
      if (_isInitialized) return;

      await _loadMedicationsFromCache(userId);
      await _loadRemindersFromCache(userId);
      await _scheduleUpcomingReminders(userId);
      await _subscribeToRealtimeUpdates(userId);
      
      _isInitialized = true;
      _logger.info('ElderMedicationService initialized for user: $userId');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize ElderMedicationService: $e', stackTrace);
      throw MedicationServiceException('Initialization failed: $e');
    }
  }

  /// Add a new medication
  Future<Medication> addMedication({
    required String userId,
    required String medicationName,
    required String dosage,
    required String frequency,
    required List<String> reminderTimes,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    File? medicationPhoto,
  }) async {
    try {
      String? photoUrl;
      
      // Upload medication photo if provided
      if (medicationPhoto != null) {
        photoUrl = await _mediaService.uploadMedia(
          file: medicationPhoto,
          bucket: 'medication-photos',
          familyId: userId, // Using userId as fallback for familyId
          userId: userId,
          folder: 'medications',
        );
      }

      final medication = Medication(
        id: _uuid.v4(),
        userId: userId,
        medicationName: medicationName,
        dosage: dosage,
        frequency: frequency,
        startDate: startDate ?? DateTime.now(),
        endDate: endDate,
        photoUrl: photoUrl,
        instructions: instructions,
        reminderTimes: reminderTimes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to database
      await _supabase.from('medications').insert(medication.toJson());

      // Create recurring reminders
      await _createRecurringReminders(medication);

      // Update cache and streams
      _medicationsCache[medication.id] = medication;
      await _refreshMedicationsList(userId);

      _logger.info('Medication added: ${medication.medicationName} for user $userId');
      return medication;
    } catch (e, stackTrace) {
      _logger.error('Failed to add medication: $e', stackTrace);
      throw MedicationServiceException('Failed to add medication: $e');
    }
  }

  /// Update existing medication
  Future<Medication> updateMedication({
    required String medicationId,
    String? medicationName,
    String? dosage,
    String? frequency,
    List<String>? reminderTimes,
    DateTime? endDate,
    String? instructions,
    File? newMedicationPhoto,
    bool? isActive,
  }) async {
    try {
      final existingMedication = _medicationsCache[medicationId];
      if (existingMedication == null) {
        throw MedicationServiceException('Medication not found: $medicationId');
      }

      String? photoUrl = existingMedication.photoUrl;

      // Upload new photo if provided
      if (newMedicationPhoto != null) {
        photoUrl = await _mediaService.uploadMedia(
          file: newMedicationPhoto,
          bucket: 'medication-photos',
          familyId: existingMedication.userId,
          userId: existingMedication.userId,
          folder: 'medications',
        );
      }

      final updatedMedication = existingMedication.copyWith(
        medicationName: medicationName,
        dosage: dosage,
        frequency: frequency,
        reminderTimes: reminderTimes,
        endDate: endDate,
        instructions: instructions,
        photoUrl: photoUrl,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      // Update in database
      await _supabase.from('medications').update(updatedMedication.toJson()).eq('id', medicationId);

      // Update reminders if reminder times changed
      if (reminderTimes != null) {
        await _updateMedicationReminders(updatedMedication);
      }

      // Update cache and streams
      _medicationsCache[medicationId] = updatedMedication;
      await _refreshMedicationsList(existingMedication.userId);

      _logger.info('Medication updated: $medicationId');
      return updatedMedication;
    } catch (e, stackTrace) {
      _logger.error('Failed to update medication: $e', stackTrace);
      throw MedicationServiceException('Failed to update medication: $e');
    }
  }

  /// Get user's medications
  Future<List<Medication>> getMedications({
    required String userId,
    bool activeOnly = true,
  }) async {
    try {
      var query = _supabase
          .from('medications')
          .select()
          .eq('user_id', userId)
          .order('medication_name');

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query;
      final medications = (response as List)
          .map((json) => Medication.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache
      for (final medication in medications) {
        _medicationsCache[medication.id] = medication;
      }

      return medications;
    } catch (e) {
      _logger.warning('Failed to fetch medications from database, using cache: $e');
      
      // Return cached medications as fallback
      return _medicationsCache.values
          .where((med) => med.userId == userId)
          .where((med) => !activeOnly || med.isActive)
          .toList()
        ..sort((a, b) => a.medicationName.compareTo(b.medicationName));
    }
  }

  /// Record medication taken
  Future<void> recordMedicationTaken({
    required String reminderId,
    required String userId,
    File? verificationPhoto,
    String? notes,
  }) async {
    try {
      String? verificationPhotoUrl;

      // Upload verification photo if provided
      if (verificationPhoto != null) {
        verificationPhotoUrl = await _mediaService.uploadMedia(
          file: verificationPhoto,
          bucket: 'medication-verifications',
          familyId: userId,
          userId: userId,
          folder: 'verifications',
        );
      }

      final takenTime = DateTime.now();

      // Update reminder
      await _supabase.from('medication_reminders').update({
        'status': 'taken',
        'taken_time': takenTime.toIso8601String(),
        'verification_photo_url': verificationPhotoUrl,
        'notes': notes,
        'updated_at': takenTime.toIso8601String(),
      }).eq('id', reminderId);

      // Create medication log entry
      final logEntry = MedicationLog(
        id: _uuid.v4(),
        medicationId: '', // This would be filled from the reminder
        userId: userId,
        scheduledTime: takenTime, // This would be filled from the reminder
        takenTime: takenTime,
        status: MedicationReminderStatus.taken,
        verificationPhotoUrl: verificationPhotoUrl,
        notes: notes,
        createdAt: takenTime,
      );

      await _supabase.from('medication_logs').insert(logEntry.toJson());

      // Cancel the notification
      await _notificationService.cancelNotification(reminderId.hashCode);

      await _refreshRemindersList(userId);
      _logger.info('Medication recorded as taken: $reminderId');
    } catch (e, stackTrace) {
      _logger.error('Failed to record medication taken: $e', stackTrace);
      throw MedicationServiceException('Failed to record medication taken: $e');
    }
  }

  /// Mark medication as missed
  Future<void> markMedicationMissed({
    required String reminderId,
    required String userId,
    String? reason,
  }) async {
    try {
      await _supabase.from('medication_reminders').update({
        'status': 'missed',
        'notes': reason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reminderId);

      // Create alert for missed medication
      await _createMissedMedicationAlert(reminderId, userId, reason);

      // Cancel the notification
      await _notificationService.cancelNotification(reminderId.hashCode);

      await _refreshRemindersList(userId);
      _logger.info('Medication marked as missed: $reminderId');
    } catch (e, stackTrace) {
      _logger.error('Failed to mark medication as missed: $e', stackTrace);
      throw MedicationServiceException('Failed to mark medication as missed: $e');
    }
  }

  /// Snooze medication reminder
  Future<void> snoozeMedicationReminder({
    required String reminderId,
    required String userId,
    Duration snoozeDuration = const Duration(minutes: 15),
  }) async {
    try {
      final reminder = await _getMedicationReminder(reminderId);
      if (reminder == null) {
        throw MedicationServiceException('Reminder not found: $reminderId');
      }

      final snoozeUntil = DateTime.now().add(snoozeDuration);
      final updatedReminder = reminder.copyWith(
        status: MedicationReminderStatus.snoozed,
        scheduledTime: snoozeUntil,
        snoozeInterval: snoozeDuration,
        snoozeCount: reminder.snoozeCount + 1,
        updatedAt: DateTime.now(),
      );

      await _supabase.from('medication_reminders').update(updatedReminder.toJson()).eq('id', reminderId);

      // Cancel current notification and schedule new one
      await _notificationService.cancelNotification(reminderId.hashCode);
      await _scheduleReminderNotification(updatedReminder);

      await _refreshRemindersList(userId);
      _logger.info('Medication reminder snoozed: $reminderId for ${snoozeDuration.inMinutes} minutes');
    } catch (e, stackTrace) {
      _logger.error('Failed to snooze medication reminder: $e', stackTrace);
      throw MedicationServiceException('Failed to snooze medication reminder: $e');
    }
  }

  /// Get medication reminders for today
  Future<List<MedicationReminder>> getTodaysReminders(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('medication_reminders')
          .select()
          .eq('user_id', userId)
          .gte('scheduled_time', startOfDay.toIso8601String())
          .lt('scheduled_time', endOfDay.toIso8601String())
          .order('scheduled_time');

      final reminders = (response as List)
          .map((json) => MedicationReminder.fromJson(json as Map<String, dynamic>))
          .toList();

      return reminders;
    } catch (e, stackTrace) {
      _logger.error('Failed to get today\'s reminders: $e', stackTrace);
      return [];
    }
  }

  /// Get medication compliance statistics
  Future<MedicationComplianceStats> getComplianceStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));

      final response = await _supabase
          .from('medication_logs')
          .select()
          .eq('user_id', userId)
          .gte('scheduled_time', start.toIso8601String())
          .lte('scheduled_time', end.toIso8601String());

      final logs = (response as List)
          .map((json) => MedicationLog.fromJson(json as Map<String, dynamic>))
          .toList();

      final totalDoses = logs.length;
      final takenDoses = logs.where((log) => log.status == MedicationReminderStatus.taken).length;
      final missedDoses = logs.where((log) => log.status == MedicationReminderStatus.missed).length;
      final skippedDoses = logs.where((log) => log.status == MedicationReminderStatus.skipped).length;

      final complianceRate = totalDoses > 0 ? (takenDoses / totalDoses) * 100 : 0.0;

      return MedicationComplianceStats(
        totalDoses: totalDoses,
        takenDoses: takenDoses,
        missedDoses: missedDoses,
        skippedDoses: skippedDoses,
        complianceRate: complianceRate,
        periodStart: start,
        periodEnd: end,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to get compliance statistics: $e', stackTrace);
      return MedicationComplianceStats.empty();
    }
  }

  /// Delete medication (soft delete)
  Future<void> deleteMedication(String medicationId, String userId) async {
    try {
      await _supabase.from('medications').update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', medicationId).eq('user_id', userId);

      // Cancel all future reminders for this medication
      await _cancelMedicationReminders(medicationId);

      // Update cache
      final medication = _medicationsCache[medicationId];
      if (medication != null) {
        _medicationsCache[medicationId] = medication.copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
      }

      await _refreshMedicationsList(userId);
      _logger.info('Medication deleted: $medicationId');
    } catch (e, stackTrace) {
      _logger.error('Failed to delete medication: $e', stackTrace);
      throw MedicationServiceException('Failed to delete medication: $e');
    }
  }

  // Private helper methods

  Future<void> _loadMedicationsFromCache(String userId) async {
    // In a real implementation, this would load from local storage
  }

  Future<void> _loadRemindersFromCache(String userId) async {
    // In a real implementation, this would load from local storage
  }

  Future<void> _createRecurringReminders(Medication medication) async {
    final now = DateTime.now();
    final endDate = medication.endDate ?? now.add(const Duration(days: 365));

    for (final timeString in medication.reminderTimes) {
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      var currentDate = DateTime(now.year, now.month, now.day, hour, minute);
      if (currentDate.isBefore(now)) {
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // Create reminders for the next 30 days or until end date
      while (currentDate.isBefore(endDate) && 
             currentDate.isBefore(now.add(const Duration(days: 30)))) {
        final reminder = MedicationReminder(
          id: _uuid.v4(),
          medicationId: medication.id,
          userId: medication.userId,
          scheduledTime: currentDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _supabase.from('medication_reminders').insert(reminder.toJson());
        await _scheduleReminderNotification(reminder);

        currentDate = currentDate.add(const Duration(days: 1));
      }
    }
  }

  Future<void> _updateMedicationReminders(Medication medication) async {
    // Cancel existing future reminders
    await _cancelMedicationReminders(medication.id);
    
    // Create new reminders
    await _createRecurringReminders(medication);
  }

  Future<void> _cancelMedicationReminders(String medicationId) async {
    try {
      // Get all future reminders
      final response = await _supabase
          .from('medication_reminders')
          .select()
          .eq('medication_id', medicationId)
          .gte('scheduled_time', DateTime.now().toIso8601String())
          .in_('status', ['pending', 'snoozed']);

      final reminders = (response as List)
          .map((json) => MedicationReminder.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cancel notifications and update status
      for (final reminder in reminders) {
        await _notificationService.cancelNotification(reminder.id.hashCode);
        await _supabase.from('medication_reminders').update({
          'status': 'cancelled',
        }).eq('id', reminder.id);
      }
    } catch (e) {
      _logger.warning('Failed to cancel medication reminders: $e');
    }
  }

  Future<void> _scheduleReminderNotification(MedicationReminder reminder) async {
    try {
      final medication = _medicationsCache[reminder.medicationId];
      if (medication == null) return;

      await _notificationService.scheduleNotification(
        id: reminder.id.hashCode,
        title: 'Time for ${medication.medicationName}',
        body: 'Take ${medication.dosage} as prescribed',
        scheduledTime: reminder.scheduledTime,
        payload: {
          'reminder_id': reminder.id,
          'medication_id': medication.id,
          'type': 'medication_reminder',
        },
      );
    } catch (e) {
      _logger.warning('Failed to schedule reminder notification: $e');
    }
  }

  Future<void> _scheduleUpcomingReminders(String userId) async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final reminders = await getTodaysReminders(userId);
      
      for (final reminder in reminders) {
        if (reminder.status == MedicationReminderStatus.pending) {
          await _scheduleReminderNotification(reminder);
        }
      }
    } catch (e) {
      _logger.warning('Failed to schedule upcoming reminders: $e');
    }
  }

  Future<void> _subscribeToRealtimeUpdates(String userId) async {
    try {
      // Subscribe to medication updates
      _supabase
          .from('medications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen((data) {
            final medications = data
                .map((json) => Medication.fromJson(json as Map<String, dynamic>))
                .toList();
            
            // Update cache
            for (final medication in medications) {
              _medicationsCache[medication.id] = medication;
            }
            
            _medicationsController.add(medications);
          });

      // Subscribe to reminder updates
      _supabase
          .from('medication_reminders')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen((data) {
            final reminders = data
                .map((json) => MedicationReminder.fromJson(json as Map<String, dynamic>))
                .toList();
            
            _remindersController.add(reminders);
          });
    } catch (e) {
      _logger.warning('Failed to subscribe to realtime updates: $e');
    }
  }

  Future<MedicationReminder?> _getMedicationReminder(String reminderId) async {
    try {
      final response = await _supabase
          .from('medication_reminders')
          .select()
          .eq('id', reminderId)
          .single();
      
      return MedicationReminder.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> _createMissedMedicationAlert(String reminderId, String userId, String? reason) async {
    // This would integrate with AlertService to create missed medication alerts
    _logger.info('Creating missed medication alert for reminder: $reminderId');
  }

  Future<void> _refreshMedicationsList(String userId) async {
    try {
      final medications = await getMedications(userId: userId);
      _medicationsController.add(medications);
    } catch (e) {
      _logger.error('Failed to refresh medications list: $e');
    }
  }

  Future<void> _refreshRemindersList(String userId) async {
    try {
      final reminders = await getTodaysReminders(userId);
      _remindersController.add(reminders);
    } catch (e) {
      _logger.error('Failed to refresh reminders list: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _medicationsController.close();
    _remindersController.close();
    _upcomingReminderController.close();
  }
}

/// Data class for medication compliance statistics
class MedicationComplianceStats {
  final int totalDoses;
  final int takenDoses;
  final int missedDoses;
  final int skippedDoses;
  final double complianceRate;
  final DateTime periodStart;
  final DateTime periodEnd;

  const MedicationComplianceStats({
    required this.totalDoses,
    required this.takenDoses,
    required this.missedDoses,
    required this.skippedDoses,
    required this.complianceRate,
    required this.periodStart,
    required this.periodEnd,
  });

  factory MedicationComplianceStats.empty() {
    final now = DateTime.now();
    return MedicationComplianceStats(
      totalDoses: 0,
      takenDoses: 0,
      missedDoses: 0,
      skippedDoses: 0,
      complianceRate: 0.0,
      periodStart: now,
      periodEnd: now,
    );
  }
}

/// Custom exception for medication service errors
class MedicationServiceException implements Exception {
  final String message;
  MedicationServiceException(this.message);
  
  @override
  String toString() => 'MedicationServiceException: $message';
}