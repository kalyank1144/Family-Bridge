import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication_model.dart';
import '../models/emergency_contact_model.dart';
import '../models/daily_checkin_model.dart';

class ElderProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
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
  String get weatherDescription => _weatherDescription;
  double get temperature => _temperature;
  String get weatherIcon => _weatherIcon;
  int get unreadMessages => _unreadMessages;
  
  // Initialize Elder Data
  Future<void> initializeElderData(String userId) async {
    _userId = userId;
    await Future.wait([
      loadUserProfile(),
      loadEmergencyContacts(),
      loadMedications(),
      checkTodayCheckin(),
      loadWeatherData(),
      loadUnreadMessages(),
    ]);
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
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }
  
  // Load Emergency Contacts
  Future<void> loadEmergencyContacts() async {
    _isLoadingContacts = true;
    notifyListeners();
    
    try {
      final response = await _supabase
          .from('emergency_contacts')
          .select()
          .eq('elder_id', _userId)
          .order('priority', ascending: true);
      
      _emergencyContacts = (response as List)
          .map((contact) => EmergencyContact.fromJson(contact))
          .toList();
    } catch (e) {
      print('Error loading emergency contacts: $e');
    } finally {
      _isLoadingContacts = false;
      notifyListeners();
    }
  }
  
  // Add Emergency Contact
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    try {
      await _supabase.from('emergency_contacts').insert({
        'elder_id': _userId,
        'name': contact.name,
        'relationship': contact.relationship,
        'phone': contact.phone,
        'photo_url': contact.photoUrl,
        'priority': contact.priority,
      });
      
      await loadEmergencyContacts();
    } catch (e) {
      print('Error adding emergency contact: $e');
    }
  }
  
  // Load Medications
  Future<void> loadMedications() async {
    _isLoadingMedications = true;
    notifyListeners();
    
    try {
      final response = await _supabase
          .from('medications')
          .select()
          .eq('elder_id', _userId)
          .order('next_dose_time', ascending: true);
      
      _medications = (response as List)
          .map((med) => Medication.fromJson(med))
          .toList();
      
      // Find next medication
      final now = DateTime.now();
      _nextMedication = _medications.firstWhere(
        (med) => med.nextDoseTime.isAfter(now),
        orElse: () => _medications.first,
      );
    } catch (e) {
      print('Error loading medications: $e');
    } finally {
      _isLoadingMedications = false;
      notifyListeners();
    }
  }
  
  // Mark Medication as Taken
  Future<void> markMedicationTaken(String medicationId, {String? photoUrl}) async {
    try {
      await _supabase.from('medication_logs').insert({
        'medication_id': medicationId,
        'elder_id': _userId,
        'taken_at': DateTime.now().toIso8601String(),
        'photo_url': photoUrl,
        'confirmation_photo_url': photoUrl,
        'confirmed': true,
      });
      
      // Update next dose time
      final medication = _medications.firstWhere((med) => med.id == medicationId);
      final nextDose = medication.calculateNextDose();
      
      await _supabase
          .from('medications')
          .update({'next_dose_time': nextDose.toIso8601String()})
          .eq('id', medicationId);
      
      await loadMedications();
    } catch (e) {
      print('Error marking medication taken: $e');
    }
  }
  
  // Skip Medication
  Future<void> skipMedication(String medicationId, String reason) async {
    try {
      await _supabase.from('medication_logs').insert({
        'medication_id': medicationId,
        'elder_id': _userId,
        'taken_at': DateTime.now().toIso8601String(),
        'skipped': true,
        'skip_reason': reason,
      });
      
      await loadMedications();
    } catch (e) {
      print('Error skipping medication: $e');
    }
  }
  
  // Check Today's Check-in
  Future<void> checkTodayCheckin() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final response = await _supabase
          .from('daily_checkins')
          .select()
          .eq('elder_id', _userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .maybeSingle();
      
      if (response != null) {
        _todayCheckin = DailyCheckin.fromJson(response);
        _hasCheckedInToday = true;
      } else {
        _hasCheckedInToday = false;
      }
    } catch (e) {
      print('Error checking today\'s check-in: $e');
    }
    notifyListeners();
  }
  
  // Submit Daily Check-in
  Future<void> submitDailyCheckin(DailyCheckin checkin) async {
    try {
      await _supabase.from('daily_checkins').insert({
        'elder_id': _userId,
        'mood': checkin.mood,
        'sleep_quality': checkin.sleepQuality,
        'meal_eaten': checkin.mealEaten,
        'medication_taken': checkin.medicationTaken,
        'physical_activity': checkin.physicalActivity,
        'pain_level': checkin.painLevel,
        'notes': checkin.notes,
        'voice_note_url': checkin.voiceNoteUrl,
      });
      
      _todayCheckin = checkin;
      _hasCheckedInToday = true;
      notifyListeners();
    } catch (e) {
      print('Error submitting daily check-in: $e');
    }
  }
  
  // Load Weather Data
  Future<void> loadWeatherData() async {
    try {
      // This would integrate with a weather API
      // For now, using mock data
      _weatherDescription = 'Sunny';
      _temperature = 72;
      _weatherIcon = '☀️';
    } catch (e) {
      print('Error loading weather: $e');
    }
    notifyListeners();
  }
  
  // Load Unread Messages
  Future<void> loadUnreadMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('recipient_id', _userId)
          .eq('read', false);
      
      _unreadMessages = (response as List).length;
    } catch (e) {
      print('Error loading unread messages: $e');
    }
    notifyListeners();
  }
  
  // Real-time subscriptions
  void setupRealtimeSubscriptions() {
    // Subscribe to medication reminders
    _supabase
        .channel('medications')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'medications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'elder_id',
            value: _userId,
          ),
          callback: (payload) => loadMedications(),
        )
        .subscribe();
    
    // Subscribe to messages
    _supabase
        .channel('messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: _userId,
          ),
          callback: (payload) => loadUnreadMessages(),
        )
        .subscribe();
  }
  
  @override
  void dispose() {
    _supabase.removeAllChannels();
    super.dispose();
  }
}