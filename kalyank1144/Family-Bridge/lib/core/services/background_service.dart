import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../offline/offline_manager.dart';
import '../offline/sync/sync_manager.dart';
import '../offline/storage/local_storage_manager.dart';
import '../network/network_manager.dart';

class BackgroundService {
  static const String syncTaskName = 'syncData';
  static const String cleanupTaskName = 'cleanupStorage';
  static const String healthCheckTaskName = 'healthCheck';
  static const String medicationReminderTaskName = 'medicationReminder';
  
  static Future<bool> handleBackgroundTask(
    String task,
    Map<String, dynamic>? inputData,
  ) async {
    debugPrint('Background task started: $task');
    
    try {
      switch (task) {
        case syncTaskName:
          return await _performSync();
          
        case cleanupTaskName:
          return await _performCleanup();
          
        case healthCheckTaskName:
          return await _performHealthCheck();
          
        case medicationReminderTaskName:
          return await _performMedicationReminder(inputData);
          
        default:
          debugPrint('Unknown background task: $task');
          return false;
      }
    } catch (e) {
      debugPrint('Background task error: $e');
      return false;
    }
  }
  
  static Future<bool> _performSync() async {
    try {
      final storageManager = LocalStorageManager();
      await storageManager.initialize();
      
      final networkManager = NetworkManager();
      await networkManager.initialize();
      
      if (!networkManager.isOnline) {
        debugPrint('Background sync skipped - offline');
        return true;
      }
      
      final offlineManager = OfflineManager(
        storageManager: storageManager,
        networkManager: networkManager,
      );
      await offlineManager.initialize();
      
      final syncManager = SyncManager(
        offlineManager: offlineManager,
        networkManager: networkManager,
        storageManager: storageManager,
      );
      await syncManager.initialize();
      
      final result = await syncManager.performSync();
      
      debugPrint('Background sync completed: ${result.message}');
      
      // Cleanup
      offlineManager.dispose();
      syncManager.dispose();
      networkManager.dispose();
      storageManager.dispose();
      
      return result.success;
    } catch (e) {
      debugPrint('Background sync error: $e');
      return false;
    }
  }
  
  static Future<bool> _performCleanup() async {
    try {
      final storageManager = LocalStorageManager();
      await storageManager.initialize();
      
      // Clear expired cache
      await storageManager.clearExpiredCache();
      
      // Optimize storage
      await storageManager.optimizeStorage();
      
      // Get storage stats
      final stats = await storageManager.getStorageStats();
      debugPrint('Storage stats after cleanup: $stats');
      
      storageManager.dispose();
      
      return true;
    } catch (e) {
      debugPrint('Background cleanup error: $e');
      return false;
    }
  }
  
  static Future<bool> _performHealthCheck() async {
    try {
      final storageManager = LocalStorageManager();
      await storageManager.initialize();
      
      // Get current user
      final userId = await storageManager.getConfig('currentUserId');
      if (userId == null) {
        debugPrint('No current user for health check');
        return true;
      }
      
      // Check if health check is due
      final lastHealthCheck = await storageManager.getConfig('lastHealthCheck');
      if (lastHealthCheck != null) {
        final lastCheck = DateTime.parse(lastHealthCheck);
        final hoursSinceLastCheck = DateTime.now().difference(lastCheck).inHours;
        
        if (hoursSinceLastCheck < 12) {
          debugPrint('Health check not due yet');
          return true;
        }
      }
      
      // TODO: Send health check notification
      await _sendHealthCheckNotification();
      
      // Update last check time
      await storageManager.saveConfig('lastHealthCheck', DateTime.now().toIso8601String());
      
      storageManager.dispose();
      
      return true;
    } catch (e) {
      debugPrint('Background health check error: $e');
      return false;
    }
  }
  
  static Future<bool> _performMedicationReminder(Map<String, dynamic>? inputData) async {
    try {
      if (inputData == null) {
        debugPrint('No input data for medication reminder');
        return false;
      }
      
      final medicationId = inputData['medicationId'] as String?;
      final userId = inputData['userId'] as String?;
      
      if (medicationId == null || userId == null) {
        debugPrint('Invalid medication reminder data');
        return false;
      }
      
      // TODO: Send medication reminder notification
      await _sendMedicationReminder(medicationId, userId);
      
      return true;
    } catch (e) {
      debugPrint('Background medication reminder error: $e');
      return false;
    }
  }
  
  static Future<void> _sendHealthCheckNotification() async {
    // TODO: Implement notification logic
    debugPrint('Sending health check notification');
  }
  
  static Future<void> _sendMedicationReminder(String medicationId, String userId) async {
    // TODO: Implement notification logic
    debugPrint('Sending medication reminder for $medicationId to user $userId');
  }
  
  static Future<void> registerBackgroundTasks() async {
    // Register periodic sync task
    await Workmanager().registerPeriodicTask(
      'periodic-sync',
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    // Register daily cleanup task
    await Workmanager().registerPeriodicTask(
      'daily-cleanup',
      cleanupTaskName,
      frequency: const Duration(days: 1),
      initialDelay: const Duration(hours: 2),
    );
    
    // Register health check task
    await Workmanager().registerPeriodicTask(
      'health-check',
      healthCheckTaskName,
      frequency: const Duration(hours: 12),
    );
    
    debugPrint('Background tasks registered');
  }
  
  static Future<void> cancelAllBackgroundTasks() async {
    await Workmanager().cancelAll();
    debugPrint('All background tasks cancelled');
  }
  
  static Future<void> cancelBackgroundTask(String uniqueName) async {
    await Workmanager().cancelByUniqueName(uniqueName);
    debugPrint('Background task cancelled: $uniqueName');
  }
}