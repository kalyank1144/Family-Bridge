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
      final healthData = await _service.getHealthData(memberId);
      final medications = await _service.getMedicationRecords(memberId);
      
      _memberHealthData[memberId] = healthData;
      _memberMedications[memberId] = medications;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _loadMockHealthData(memberId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadMockHealthData(String memberId) {
    final now = DateTime.now();
    final healthData = <HealthData>[];
    final medications = <MedicationRecord>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      
      healthData.add(HealthData(
        timestamp: DateTime(date.year, date.month, date.day, 8, 0),
        bloodPressureSystolic: 115 + (i * 2).toDouble(),
        bloodPressureDiastolic: 75 + (i * 1).toDouble(),
        heartRate: 70 + (i * 2).toDouble(),
        temperature: 98.2 + (i * 0.1),
        oxygenLevel: 96 + (i * 0.5),
        steps: 1000 + (i * 500),
        moodScore: 3 + (i % 3),
        medicationTaken: i != 2,
      ));

      healthData.add(HealthData(
        timestamp: DateTime(date.year, date.month, date.day, 20, 0),
        bloodPressureSystolic: 120 + (i * 2).toDouble(),
        bloodPressureDiastolic: 80 + (i * 1).toDouble(),
        heartRate: 75 + (i * 2).toDouble(),
        steps: 5000 + (i * 1000),
        moodScore: 4 + (i % 2),
      ));

      medications.add(MedicationRecord(
        id: 'med_${i}_morning',
        name: 'Lisinopril',
        dosage: '10mg',
        scheduledTime: DateTime(date.year, date.month, date.day, 8, 0),
        takenTime: i != 2 ? DateTime(date.year, date.month, date.day, 8, 15) : null,
        isTaken: i != 2,
      ));

      medications.add(MedicationRecord(
        id: 'med_${i}_evening',
        name: 'Metformin',
        dosage: '500mg',
        scheduledTime: DateTime(date.year, date.month, date.day, 20, 0),
        takenTime: DateTime(date.year, date.month, date.day, 20, 10),
        isTaken: true,
      ));
    }

    _memberHealthData[memberId] = healthData;
    _memberMedications[memberId] = medications;
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
      
      await _service.markMedicationTaken(memberId, medicationId);
    }
  }

  void subscribeToHealthUpdates(String memberId) {
    _service.subscribeToHealthUpdates(memberId, (data) {
      _memberHealthData[memberId] ??= [];
      _memberHealthData[memberId]!.add(data);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}