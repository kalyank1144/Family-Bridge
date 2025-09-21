import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication_model.dart';
import '../models/emergency_contact_model.dart';
import '../models/daily_checkin_model.dart';
import '../services/medication_service.dart';
import '../services/emergency_contact_service.dart';
import '../services/daily_checkin_service.dart';

class ElderProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final ElderMedicationService _medicationService = ElderMedicationService();
  final EmergencyContactService _contactService = EmergencyContactService();
  final DailyCheckinService _checkinService = DailyCheckinService();
  
  // User Data
  String _userName = 'User';
  String _userId = '';
  
  // Emergency Contacts
  List<EmergencyContact> _emergencyContacts = [];
  bool _isLoadingContacts = false;
  
  // Medications
  List<Medication> _medications = [];
  Medication? _nextMedication;
  bool _isLoadingMedications = false;
  
  // Daily Check-in
  DailyCheckin? _todayCheckin;
  bool _hasCheckedInToday = false;
  Map<String, dynamic> _checkinStats = {};
  
  // Weather Data
  String _weatherDescription = 'Loading...';
  double _temperature = 0;
  String _weatherIcon = '☀️';
  
  // Unread Messages
  int _unreadMessages = 0;
  
  // Getters
  String get userName => _userName;
  String get userId => _userId;
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  bool get isLoadingContacts => _isLoadingContacts;
  List<Medication> get medications => _medications;
  Medication? get nextMedication => _nextMedication;
  bool get isLoadingMedications => _isLoadingMedications;
  DailyCheckin? get todayCheckin => _todayCheckin;
  bool get hasCheckedInToday => _hasCheckedInToday;
  Map<String, dynamic> get checkinStats => _checkinStats;
  String get weatherDescription => _weatherDescription;
  double get temperature => _temperature;
  String get weatherIcon => _weatherIcon;
  int get unreadMessages => _unreadMessages;

  // Initialize Elder Data
  Future<void> initializeElder(String userId, String userName) async {
    _userId = userId;
    _userName = userName;
    
    await Future.wait([
      loadEmergencyContacts(),
      loadMedications(),
      loadTodayCheckin(),
    ]);

    
    await loadCheckinStats();

    notifyListeners();
  }
  
  // Load User Profile
  Future<void> loadUserProfile() async {
    try {
      final response = await _supabase
          .from('users')
          .select('name, phone, date_of_birth')
          .eq('id', _userId)
          .single();
      
      _userName = response['name'] ?? 'User';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // Emergency Contacts Methods
  Future<void> loadEmergencyContacts() async {
    _isLoadingContacts = true;
    notifyListeners();
    
    try {
      await _contactService.initialize();
      _emergencyContacts = await _contactService.getUserContacts(_userId);
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');

      // Offline-first approach will provide local data

    } finally {
      _isLoadingContacts = false;
      notifyListeners();
    }
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    try {
      await _contactService.initialize();
      final addedContact = await _contactService.addContact(contact, _userId);
      
      _emergencyContacts.add(addedContact);
      _emergencyContacts.sort((a, b) => a.priority.compareTo(b.priority));
      notifyListeners();
    } catch (e) {

      debugPrint('Emergency contact creation queued for sync: $e');
      // Still add to local state for optimistic UI
      _emergencyContacts.add(contact);
      notifyListeners();

      debugPrint('Error adding emergency contact: $e');

    }
  }

  Future<void> updateEmergencyContact(EmergencyContact contact) async {
    try {
      await _contactService.initialize();
      await _contactService.updateContact(contact, _userId);
      
      final index = _emergencyContacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        _emergencyContacts[index] = contact;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Emergency contact update queued for sync: $e');
    }
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    try {
      // Optimistically update UI
      _emergencyContacts.removeWhere((c) => c.id == contactId);
      notifyListeners();
      
      await _contactService.initialize();
      await _contactService.deleteContact(contactId);
    } catch (e) {
      debugPrint('Emergency contact deletion queued for sync: $e');
    }
  }

  // Medications Methods
  Future<void> loadMedications() async {
    _isLoadingMedications = true;
    notifyListeners();
    
    try {
      await _medicationService.initialize();
      _medications = await _medicationService.getActiveMedications(_userId);
      _updateNextMedication();
    } catch (e) {
      debugPrint('Error loading medications: $e');
    } finally {
      _isLoadingMedications = false;
      notifyListeners();
    }
  }


  Future<List<Medication>> getTodayDueMedications() async {
    await _medicationService.initialize();
    return await _medicationService.getTodayDueMedications(_userId);
  }

  void _updateNextMedication() {
    if (_medications.isEmpty) {
      _nextMedication = null;
      return;
    }

    final now = DateTime.now();
    final dueMedications = _medications.where((m) => m.nextDoseTime.isAfter(now)).toList();
    dueMedications.sort((a, b) => a.nextDoseTime.compareTo(b.nextDoseTime));
    
    _nextMedication = dueMedications.isNotEmpty ? dueMedications.first : null;
  }

  Future<void> markMedicationTaken(String medicationId, {String? photoUrl}) async {
    try {
      await _medicationService.initialize();
      await _medicationService.markMedicationTaken(medicationId, _userId);
      
      // Reload medications to get updated state
      await loadMedications();
    } catch (e) {
      debugPrint('Medication taken update queued for sync: $e');
      // Still update local state optimistically
      _updateNextMedication();
      notifyListeners();
    }
  }

  Future<void> addMedication(Medication medication) async {
    try {
      await _medicationService.initialize();
      final addedMedication = await _medicationService.addMedication(medication, _userId);
      
      _medications.add(addedMedication);
      _updateNextMedication();
      notifyListeners();
    } catch (e) {
      debugPrint('Medication creation queued for sync: $e');
      _medications.add(medication);
      _updateNextMedication();
      notifyListeners();
    }
  }

  Future<double> getMedicationComplianceRate({int days = 7}) async {
    await _medicationService.initialize();
    return await _medicationService.getComplianceRate(_userId, days: days);
  }

  // Daily Check-in Methods
  Future<void> loadTodayCheckin() async {
    try {
      await _checkinService.initialize();
      _todayCheckin = await _checkinService.getTodayCheckin(_userId);
      _hasCheckedInToday = _todayCheckin != null;
    } catch (e) {
      debugPrint('Error loading today check-in: $e');
    }
    notifyListeners();
  }

  Future<void> loadCheckinStats({int days = 30}) async {
    try {
      await _checkinService.initialize();
      _checkinStats = await _checkinService.getCheckinStats(_userId, days: days);
    } catch (e) {
      debugPrint('Error loading check-in stats: $e');
      _checkinStats = {};
    }
    notifyListeners();
  }

  Future<void> submitDailyCheckin(DailyCheckin checkin) async {
    try {
      await _checkinService.initialize();
      final submittedCheckin = await _checkinService.submitCheckin(checkin, _userId);
      
      _todayCheckin = submittedCheckin;
      _hasCheckedInToday = true;
      notifyListeners();
      
      // Refresh stats
      await loadCheckinStats();
    } catch (e) {
      debugPrint('Daily check-in queued for sync: $e');
      // Still update local state optimistically
      _todayCheckin = checkin;
      _hasCheckedInToday = true;
      notifyListeners();
    }
  }

  Future<List<DailyCheckin>> getRecentCheckins({int days = 7}) async {
    await _checkinService.initialize();
    return await _checkinService.getUserCheckins(_userId, days: days);
  }

  // Weather Methods (simplified - could integrate with weather API)
  void updateWeather({
    required String description,
    required double temperature,
    required String icon,
  }) {
    _weatherDescription = description;
    _temperature = temperature;
    _weatherIcon = icon;
    notifyListeners();
  }

  // Message Methods
  void updateUnreadMessageCount(int count) {
    _unreadMessages = count;
    notifyListeners();
  }

  // Helper Methods
  bool isMedicationDue(Medication medication) {
    return medication.isDue();
  }

  String getTimeUntilNextMedication() {
    if (_nextMedication == null) return 'No medications scheduled';
    return _nextMedication!.getTimeUntilNext();
  }

  List<Medication> getOverdueMedications() {
    final now = DateTime.now();
    return _medications.where((m) => m.nextDoseTime.isBefore(now)).toList();
  }

  @override
  void dispose() {
    _medicationService.dispose();
    _contactService.dispose();
    _checkinService.dispose();
    super.dispose();
  }
}