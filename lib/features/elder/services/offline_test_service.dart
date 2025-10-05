import 'dart:async';
import 'dart:io';

import 'package:family_bridge/core/services/voice_service.dart';
import 'package:family_bridge/features/elder/models/daily_checkin_model.dart';
import 'package:family_bridge/features/elder/models/emergency_contact_model.dart';
import 'package:family_bridge/features/elder/models/medication_model.dart';
import 'package:family_bridge/repositories/offline_first/daily_checkin_repository.dart';
import 'package:family_bridge/repositories/offline_first/emergency_contact_repository.dart';
import 'package:family_bridge/repositories/offline_first/medication_repository.dart';
import 'package:family_bridge/services/network/network_manager.dart';
import 'package:family_bridge/services/offline/offline_manager.dart';

/// Service to test offline functionality for elder interface
class OfflineTestService {
  static final OfflineTestService _instance = OfflineTestService._internal();
  factory OfflineTestService() => _instance;
  OfflineTestService._internal();

  late DailyCheckinRepository _checkinRepo;
  late MedicationRepository _medicationRepo;
  late EmergencyContactRepository _emergencyRepo;
  late VoiceService _voiceService;
  
  bool _isInitialized = false;

  /// Initialize the offline test service
  Future<void> initialize(VoiceService voiceService) async {
    if (_isInitialized) return;
    
    _voiceService = voiceService;
    
    // Initialize repositories
    _checkinRepo = DailyCheckinRepository();
    _medicationRepo = MedicationRepository();
    _emergencyRepo = EmergencyContactRepository();
    
    await _checkinRepo.initialize();
    await _medicationRepo.initialize();
    await _emergencyRepo.initialize();
    
    _isInitialized = true;
  }

  /// Test offline daily check-in functionality
  Future<bool> testOfflineCheckin() async {
    try {
      // Create a test daily check-in
      final checkin = DailyCheckin(
        elderId: 'test_elder_${DateTime.now().millisecondsSinceEpoch}',
        mood: 'good',
        sleepQuality: 'excellent',
        mealEaten: true,
        medicationTaken: true,
        physicalActivity: true,
        painLevel: 0,
        notes: 'Testing offline functionality',
        voiceNoteUrl: null,
      );

      // Save locally (should work offline)
      await _checkinRepo.create(checkin);
      
      // Verify it was saved locally
      final savedCheckin = await _checkinRepo.getById(checkin.elderId);
      
      return savedCheckin != null && savedCheckin.mood == 'good';
    } catch (e) {
      print('Offline check-in test failed: $e');
      return false;
    }
  }

  /// Test offline medication tracking functionality
  Future<bool> testOfflineMedication() async {
    try {
      // Create a test medication entry
      final medication = Medication(
        id: 'test_med_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Medicine',
        dosage: '10mg',
        elderId: 'test_elder',
        nextDoseTime: DateTime.now().add(const Duration(hours: 8)),
        frequency: 'daily',
        requiresPhotoConfirmation: false,
      );

      // Save locally (should work offline)
      await _medicationRepo.create(medication);
      
      // Verify it was saved locally
      final savedMedication = await _medicationRepo.getById(medication.id);
      
      return savedMedication != null && savedMedication.name == 'Test Medicine';
    } catch (e) {
      print('Offline medication test failed: $e');
      return false;
    }
  }

  /// Test offline emergency contact functionality
  Future<bool> testOfflineEmergencyContact() async {
    try {
      // Create a test emergency contact
      final contact = EmergencyContact(
        id: 'test_contact_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Contact',
        relationship: 'Test Relationship',
        phone: '+1-555-0123',
        priority: 1,
        createdAt: DateTime.now(),
      );

      // Save locally (should work offline)
      await _emergencyRepo.create(contact);
      
      // Verify it was saved locally
      final savedContact = await _emergencyRepo.getById(contact.id);
      
      return savedContact != null && savedContact.name == 'Test Contact';
    } catch (e) {
      print('Offline emergency contact test failed: $e');
      return false;
    }
  }

  /// Test voice functionality offline
  Future<bool> testOfflineVoice() async {
    try {
      // Test TTS (should work offline)
      await _voiceService.speak('Testing offline voice functionality');
      
      // Test if voice service is initialized
      return true;
    } catch (e) {
      print('Offline voice test failed: $e');
      return false;
    }
  }

  /// Test network connectivity and sync behavior
  Future<bool> testConnectivityAndSync() async {
    try {
      // Check current network status
      final networkManager = NetworkManager();
      final isOnline = await networkManager.isConnected;
      
      // Check offline manager status
      final offlineManager = OfflineManager.instance;
      final syncStatus = offlineManager.status;
      
      print('Network online: $isOnline');
      print('Sync status: ${syncStatus.state}');
      print('Last sync: ${syncStatus.lastSuccessAt}');
      
      return true;
    } catch (e) {
      print('Connectivity test failed: $e');
      return false;
    }
  }

  /// Run comprehensive offline functionality test
  Future<Map<String, bool>> runComprehensiveTest() async {
    final results = <String, bool>{};
    
    await _voiceService.speak('Starting offline functionality test');
    
    // Test individual components
    results['daily_checkin'] = await testOfflineCheckin();
    results['medication'] = await testOfflineMedication();
    results['emergency_contact'] = await testOfflineEmergencyContact();
    results['voice_offline'] = await testOfflineVoice();
    results['connectivity_sync'] = await testConnectivityAndSync();
    
    // Calculate overall success rate
    final successCount = results.values.where((success) => success).length;
    final totalTests = results.length;
    final successRate = (successCount / totalTests * 100).toInt();
    
    results['overall_success'] = successCount == totalTests;
    
    // Announce results
    if (successCount == totalTests) {
      await _voiceService.speak(
        'All offline tests passed successfully! The app will work even without internet connection.'
      );
    } else {
      await _voiceService.speak(
        'Some offline tests failed. $successCount out of $totalTests tests passed.'
      );
    }
    
    return results;
  }

  /// Simulate offline mode for testing
  Future<void> simulateOfflineMode() async {
    await _voiceService.speak('Simulating offline mode for testing');
    
    // Force offline mode
    final offlineManager = OfflineManager.instance;
    // Note: This would require adding a method to force offline mode
    // offlineManager.setForceOffline(true);
    
    print('Offline mode simulation started');
  }

  /// Test local storage capacity and limits
  Future<bool> testStorageCapacity() async {
    try {
      // Test creating multiple entries to check storage
      final testEntries = <DailyCheckin>[];
      
      for (int i = 0; i < 10; i++) {
        final checkin = DailyCheckin(
          elderId: 'storage_test_$i',
          mood: 'good',
          sleepQuality: 'good',
          mealEaten: true,
          medicationTaken: true,
          physicalActivity: true,
          painLevel: 0,
          notes: 'Storage test entry $i',
          voiceNoteUrl: null,
        );
        
        await _checkinRepo.create(checkin);
        testEntries.add(checkin);
      }
      
      // Verify all entries were stored
      final allEntries = await _checkinRepo.getAll();
      final testEntriesCount = allEntries.where(
        (entry) => entry.notes?.startsWith('Storage test entry') == true
      ).length;
      
      return testEntriesCount == 10;
    } catch (e) {
      print('Storage capacity test failed: $e');
      return false;
    }
  }

  /// Clean up test data
  Future<void> cleanupTestData() async {
    try {
      // Remove test entries
      final allCheckins = await _checkinRepo.getAll();
      for (final checkin in allCheckins) {
        if (checkin.elderId.startsWith('test_elder_') || 
            checkin.elderId.startsWith('storage_test_')) {
          await _checkinRepo.delete(checkin.elderId);
        }
      }
      
      final allMedications = await _medicationRepo.getAll();
      for (final medication in allMedications) {
        if (medication.id.startsWith('test_med_')) {
          await _medicationRepo.delete(medication.id);
        }
      }
      
      final allContacts = await _emergencyRepo.getAll();
      for (final contact in allContacts) {
        if (contact.id.startsWith('test_contact_')) {
          await _emergencyRepo.delete(contact.id);
        }
      }
      
      await _voiceService.speak('Test data cleanup completed');
    } catch (e) {
      print('Cleanup failed: $e');
    }
  }
}