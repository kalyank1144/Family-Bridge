import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/medication_model.dart';
import '../services/medication_service.dart';
import '../../shared/services/logging_service.dart';

/// Provider for managing elder interface functionality
/// Integrates ElderMedicationService and other elder-specific services with Flutter UI
class ElderProvider extends ChangeNotifier {
  final ElderMedicationService _medicationService = ElderMedicationService();
  final LoggingService _logger = LoggingService();

  List<Medication> _medications = [];
  List<MedicationReminder> _todaysReminders = [];
  MedicationComplianceStats? _complianceStats;
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  bool _isDailyCheckInComplete = false;
  String? _currentMood;

  // Getters
  List<Medication> get medications => _medications;
  List<MedicationReminder> get todaysReminders => _todaysReminders;
  MedicationComplianceStats? get complianceStats => _complianceStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDailyCheckInComplete => _isDailyCheckInComplete;
  String? get currentMood => _currentMood;

  List<MedicationReminder> get pendingReminders => _todaysReminders
      .where((reminder) => reminder.status == MedicationReminderStatus.pending)
      .toList();
  
  List<MedicationReminder> get overdueReminders => _todaysReminders
      .where((reminder) => reminder.isOverdue)
      .toList();

  List<Medication> get activeMedications => _medications
      .where((med) => med.isActive)
      .toList();

  /// Initialize the provider with user ID
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    _setLoading(true);
    _clearError();

    try {
      await _medicationService.initialize(userId);
      
      // Subscribe to real-time updates
      _medicationService.medicationsStream.listen(_onMedicationsUpdated);
      _medicationService.remindersStream.listen(_onRemindersUpdated);
      _medicationService.upcomingReminderStream.listen(_onUpcomingReminder);
      
      // Load initial data
      await _loadAllData();
      
      _logger.info('ElderProvider initialized for user: $userId');
    } catch (e, stackTrace) {
      _setError('Failed to initialize elder data: $e');
      _logger.error('ElderProvider initialization failed: $e', stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new medication
  Future<bool> addMedication({
    required String medicationName,
    required String dosage,
    required String frequency,
    required List<String> reminderTimes,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    File? medicationPhoto,
  }) async {
    if (_currentUserId == null) {
      _setError('User not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _medicationService.addMedication(
        userId: _currentUserId!,
        medicationName: medicationName,
        dosage: dosage,
        frequency: frequency,
        reminderTimes: reminderTimes,
        startDate: startDate,
        endDate: endDate,
        instructions: instructions,
        medicationPhoto: medicationPhoto,
      );
      
      await _loadAllData();
      notifyListeners();
      
      _logger.info('Medication added via provider: $medicationName');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to add medication: $e');
      _logger.error('Failed to add medication via provider: $e', stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing medication
  Future<bool> updateMedication({
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
    _clearError();

    try {
      await _medicationService.updateMedication(
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        frequency: frequency,
        reminderTimes: reminderTimes,
        endDate: endDate,
        instructions: instructions,
        newMedicationPhoto: newMedicationPhoto,
        isActive: isActive,
      );
      
      await _loadAllData();
      notifyListeners();
      
      _logger.info('Medication updated via provider: $medicationId');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to update medication: $e');
      _logger.error('Failed to update medication via provider: $e', stackTrace);
      return false;
    }
  }

  /// Record medication as taken
  Future<bool> recordMedicationTaken({
    required String reminderId,
    File? verificationPhoto,
    String? notes,
  }) async {
    if (_currentUserId == null) {
      _setError('User not initialized');
      return false;
    }

    _clearError();

    try {
      await _medicationService.recordMedicationTaken(
        reminderId: reminderId,
        userId: _currentUserId!,
        verificationPhoto: verificationPhoto,
        notes: notes,
      );
      
      await _loadTodaysReminders();
      await _loadComplianceStats();
      notifyListeners();
      
      _logger.info('Medication recorded as taken via provider: $reminderId');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to record medication: $e');
      _logger.error('Failed to record medication via provider: $e', stackTrace);
      return false;
    }
  }

  /// Mark medication as missed
  Future<bool> markMedicationMissed({
    required String reminderId,
    String? reason,
  }) async {
    if (_currentUserId == null) {
      _setError('User not initialized');
      return false;
    }

    _clearError();

    try {
      await _medicationService.markMedicationMissed(
        reminderId: reminderId,
        userId: _currentUserId!,
        reason: reason,
      );
      
      await _loadTodaysReminders();
      await _loadComplianceStats();
      notifyListeners();
      
      _logger.info('Medication marked as missed via provider: $reminderId');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to mark medication as missed: $e');
      _logger.error('Failed to mark medication as missed via provider: $e', stackTrace);
      return false;
    }
  }

  /// Snooze medication reminder
  Future<bool> snoozeMedicationReminder({
    required String reminderId,
    Duration snoozeDuration = const Duration(minutes: 15),
  }) async {
    if (_currentUserId == null) {
      _setError('User not initialized');
      return false;
    }

    _clearError();

    try {
      await _medicationService.snoozeMedicationReminder(
        reminderId: reminderId,
        userId: _currentUserId!,
        snoozeDuration: snoozeDuration,
      );
      
      await _loadTodaysReminders();
      notifyListeners();
      
      _logger.info('Medication reminder snoozed via provider: $reminderId');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to snooze reminder: $e');
      _logger.error('Failed to snooze reminder via provider: $e', stackTrace);
      return false;
    }
  }

  /// Delete medication
  Future<bool> deleteMedication(String medicationId) async {
    if (_currentUserId == null) {
      _setError('User not initialized');
      return false;
    }

    _clearError();

    try {
      await _medicationService.deleteMedication(medicationId, _currentUserId!);
      await _loadAllData();
      notifyListeners();
      
      _logger.info('Medication deleted via provider: $medicationId');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to delete medication: $e');
      _logger.error('Failed to delete medication via provider: $e', stackTrace);
      return false;
    }
  }

  /// Complete daily check-in
  Future<bool> completeDailyCheckIn({
    required String mood,
    String? notes,
    String? voiceNoteUrl,
  }) async {
    _clearError();

    try {
      _isDailyCheckInComplete = true;
      _currentMood = mood;
      
      // Here you would integrate with a daily check-in service
      // For now, just update the state
      
      notifyListeners();
      _logger.info('Daily check-in completed via provider: $mood');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to complete daily check-in: $e');
      _logger.error('Failed to complete daily check-in via provider: $e', stackTrace);
      return false;
    }
  }

  /// Get medication by ID
  Medication? getMedicationById(String medicationId) {
    try {
      return _medications.firstWhere((med) => med.id == medicationId);
    } catch (e) {
      return null;
    }
  }

  /// Get reminder by ID
  MedicationReminder? getReminderById(String reminderId) {
    try {
      return _todaysReminders.firstWhere((reminder) => reminder.id == reminderId);
    } catch (e) {
      return null;
    }
  }

  /// Check if any medications are overdue
  bool get hasOverdueMedications => overdueReminders.isNotEmpty;

  /// Get count of pending reminders
  int get pendingRemindersCount => pendingReminders.length;

  /// Refresh all data
  Future<void> refresh() async {
    _setLoading(true);
    await _loadAllData();
    _setLoading(false);
  }

  // Private helper methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _loadAllData() async {
    if (_currentUserId == null) return;

    await Future.wait([
      _loadMedications(),
      _loadTodaysReminders(),
      _loadComplianceStats(),
    ]);
  }

  Future<void> _loadMedications() async {
    if (_currentUserId == null) return;

    try {
      final medications = await _medicationService.getMedications(userId: _currentUserId!);
      _medications = medications;
    } catch (e) {
      _logger.warning('Failed to load medications: $e');
    }
  }

  Future<void> _loadTodaysReminders() async {
    if (_currentUserId == null) return;

    try {
      final reminders = await _medicationService.getTodaysReminders(_currentUserId!);
      _todaysReminders = reminders;
    } catch (e) {
      _logger.warning('Failed to load today\'s reminders: $e');
    }
  }

  Future<void> _loadComplianceStats() async {
    if (_currentUserId == null) return;

    try {
      final stats = await _medicationService.getComplianceStats(userId: _currentUserId!);
      _complianceStats = stats;
    } catch (e) {
      _logger.warning('Failed to load compliance stats: $e');
    }
  }

  void _onMedicationsUpdated(List<Medication> medications) {
    _medications = medications;
    notifyListeners();
  }

  void _onRemindersUpdated(List<MedicationReminder> reminders) {
    _todaysReminders = reminders;
    notifyListeners();
  }

  void _onUpcomingReminder(MedicationReminder reminder) {
    // Handle upcoming reminder notifications
    _logger.info('Upcoming reminder: ${reminder.id}');
  }

  @override
  void dispose() {
    _medicationService.dispose();
    super.dispose();
  }
}