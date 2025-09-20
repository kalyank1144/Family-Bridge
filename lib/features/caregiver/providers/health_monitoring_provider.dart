import 'package:flutter/material.dart';
import '../models/health_data.dart';
import '../services/health_data_service.dart';

class HealthMonitoringProvider extends ChangeNotifier {
  final HealthDataService _service = HealthDataService();
  
  Map<String, List<HealthData>> _memberHealthData = {};
  Map<String, List<MedicationRecord>> _memberMedications = {};
  bool _isLoading = false;
  String? _error;
  String? _selectedMemberId;
  DateTime _selectedDate = DateTime.now();

  Map<String, List<HealthData>> get memberHealthData => _memberHealthData;
  Map<String, List<MedicationRecord>> get memberMedications => _memberMedications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedMemberId => _selectedMemberId;
  DateTime get selectedDate => _selectedDate;

  List<HealthData> getHealthDataForMember(String memberId) {
    return _memberHealthData[memberId] ?? [];
  }

  List<MedicationRecord> getMedicationsForMember(String memberId) {
    return _memberMedications[memberId] ?? [];
  }

  HealthData? getLatestHealthData(String memberId) {
    final data = getHealthDataForMember(memberId);
    if (data.isEmpty) return null;
    return data.last;
  }

  double getMedicationCompliance(String memberId, {int days = 7}) {
    final medications = getMedicationsForMember(memberId);
    if (medications.isEmpty) return 1.0;

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    
    final recentMeds = medications.where((m) => m.scheduledTime.isAfter(cutoff)).toList();
    if (recentMeds.isEmpty) return 1.0;

    final takenCount = recentMeds.where((m) => m.isTaken).length;
    return takenCount / recentMeds.length;
  }

  List<double> getHeartRateHistory(String memberId, {int days = 7}) {
    final data = getHealthDataForMember(memberId);
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    
    return data
        .where((d) => d.timestamp.isAfter(cutoff) && d.heartRate != null)
        .map((d) => d.heartRate!)
        .toList();
  }

  List<Map<String, double>> getBloodPressureHistory(String memberId, {int days = 7}) {
    final data = getHealthDataForMember(memberId);
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    
    return data
        .where((d) => d.timestamp.isAfter(cutoff) && 
               d.bloodPressureSystolic != null && 
               d.bloodPressureDiastolic != null)
        .map((d) => {
          'systolic': d.bloodPressureSystolic!,
          'diastolic': d.bloodPressureDiastolic!,
        })
        .toList();
  }

  List<int> getStepsHistory(String memberId, {int days = 7}) {
    final data = getHealthDataForMember(memberId);
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    
    return data
        .where((d) => d.timestamp.isAfter(cutoff) && d.steps != null)
        .map((d) => d.steps!)
        .toList();
  }

  List<int> getMoodHistory(String memberId, {int days = 7}) {
    final data = getHealthDataForMember(memberId);
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    
    return data
        .where((d) => d.timestamp.isAfter(cutoff) && d.moodScore != null)
        .map((d) => d.moodScore!)
        .toList();
  }

  Future<void> loadHealthData(String memberId) async {
    _isLoading = true;
    _selectedMemberId = memberId;
    _error = null;
    notifyListeners();

    try {
      await _service.initialize();
      final healthData = await _service.getHealthData(memberId);
      final medications = await _service.getMedicationRecords(memberId);
      
      _memberHealthData[memberId] = healthData;
      _memberMedications[memberId] = medications;
      _error = null;
    } catch (e) {
      _error = e.toString();
      // Don't load mock data anymore - offline-first approach will provide local data
      debugPrint('Health data error (offline data may still be available): $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addHealthData(String memberId, HealthData data) async {
    try {
      await _service.initialize();
      await _service.addHealthData(memberId, data);
      
      // Update local state
      _memberHealthData[memberId] ??= [];
      _memberHealthData[memberId]!.add(data);
      _memberHealthData[memberId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> markMedicationTaken(String memberId, String medicationId) async {
    final medications = _memberMedications[memberId];
    if (medications == null) return;

    final index = medications.indexWhere((m) => m.id == medicationId);
    if (index != -1) {
      // Optimistically update UI
      medications[index] = MedicationRecord(
        id: medications[index].id,
        name: medications[index].name,
        dosage: medications[index].dosage,
        scheduledTime: medications[index].scheduledTime,
        takenTime: DateTime.now(),
        isTaken: true,
        notes: medications[index].notes,
      );
      notifyListeners();
      
      // Update backend (offline-first)
      try {
        await _service.initialize();
        await _service.markMedicationTaken(memberId, medicationId);
      } catch (e) {
        // Offline-first approach will queue this for later sync
        debugPrint('Medication update queued for sync: $e');
      }
    }
  }

  void subscribeToHealthUpdates(String memberId) {
    _service.subscribeToHealthUpdates(memberId, (data) {
      _memberHealthData[memberId] ??= [];
      _memberHealthData[memberId]!.add(data);
      _memberHealthData[memberId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}