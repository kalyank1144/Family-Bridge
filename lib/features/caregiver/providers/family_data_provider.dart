import 'package:flutter/material.dart';
import '../models/family_member.dart';
import '../services/family_data_service.dart';

class FamilyDataProvider extends ChangeNotifier {
  final FamilyDataService _service = FamilyDataService();
  
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = false;
  String? _error;
  FamilyMember? _selectedMember;

  List<FamilyMember> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  FamilyMember? get selectedMember => _selectedMember;

  List<FamilyMember> get elderMembers => 
      _familyMembers.where((m) => m.type == MemberType.elder).toList();
  
  List<FamilyMember> get youthMembers => 
      _familyMembers.where((m) => m.type == MemberType.youth).toList();

  List<FamilyMember> get criticalMembers => 
      _familyMembers.where((m) => m.healthStatus == HealthStatus.critical).toList();

  List<FamilyMember> get warningMembers => 
      _familyMembers.where((m) => m.healthStatus == HealthStatus.warning).toList();

  FamilyDataProvider() {
    loadFamilyMembers();
    _setupRealTimeUpdates();
  }

  Future<void> loadFamilyMembers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _familyMembers = await _service.getFamilyMembers();
      _error = null;
    } catch (e) {
      _error = e.toString();
      // Load mock data for demo
      _loadMockData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadMockData() {
    _familyMembers = [
      FamilyMember(
        id: '1',
        name: 'Walter',
        type: MemberType.elder,
        isOnline: true,
        lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
        healthStatus: HealthStatus.normal,
        medicationCompliance: 0.95,
        hasCompletedDailyCheckIn: true,
        vitals: {
          'bloodPressure': '120/80',
          'heartRate': 72,
          'steps': 3500,
        },
      ),
      FamilyMember(
        id: '2',
        name: 'Eva',
        type: MemberType.elder,
        isOnline: false,
        lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
        healthStatus: HealthStatus.warning,
        medicationCompliance: 0.60,
        hasCompletedDailyCheckIn: false,
        activeAlerts: ['Missed medication'],
        vitals: {
          'bloodPressure': '140/90',
          'heartRate': 85,
          'steps': 1200,
        },
      ),
      FamilyMember(
        id: '3',
        name: 'Eugene',
        type: MemberType.youth,
        isOnline: true,
        lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
        healthStatus: HealthStatus.normal,
        hasCompletedDailyCheckIn: true,
        vitals: {
          'steps': 8500,
        },
      ),
      FamilyMember(
        id: '4',
        name: 'Sophia',
        type: MemberType.youth,
        isOnline: true,
        lastActivity: DateTime.now().subtract(const Duration(minutes: 15)),
        healthStatus: HealthStatus.normal,
        hasCompletedDailyCheckIn: true,
        vitals: {
          'steps': 6200,
        },
      ),
    ];
  }

  void selectMember(FamilyMember member) {
    _selectedMember = member;
    notifyListeners();
  }

  FamilyMember? getMemberById(String id) {
    try {
      return _familyMembers.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  void updateMemberStatus(String memberId, HealthStatus status) {
    final index = _familyMembers.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      final member = _familyMembers[index];
      _familyMembers[index] = FamilyMember(
        id: member.id,
        name: member.name,
        profileImageUrl: member.profileImageUrl,
        type: member.type,
        isOnline: member.isOnline,
        lastActivity: member.lastActivity,
        healthStatus: status,
        currentLocation: member.currentLocation,
        activeAlerts: member.activeAlerts,
        vitals: member.vitals,
        medicationCompliance: member.medicationCompliance,
        moodStatus: member.moodStatus,
        hasCompletedDailyCheckIn: member.hasCompletedDailyCheckIn,
      );
      notifyListeners();
    }
  }

  void _setupRealTimeUpdates() {
    _service.subscribeToFamilyUpdates((member) {
      final index = _familyMembers.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        _familyMembers[index] = member;
        notifyListeners();
      }
    });
  }

  Future<void> refresh() async {
    await loadFamilyMembers();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}