import 'dart:async';
import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../offline/offline_manager.dart';
import '../sync/data_sync_service.dart';
import '../sync/sync_queue.dart';
import '../network/network_manager.dart';
import '../cache/cache_manager.dart';

// Background task names
const String periodicSyncTask = 'periodic_sync';
const String criticalSyncTask = 'critical_sync';
const String cleanupTask = 'cleanup_task';
const String healthCheckTask = 'health_check';
const String medicationReminderTask = 'medication_reminder';

// Top-level callback function for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final logger = Logger();
    
    try {
      logger.i('Background task started: $task');
      
      // Initialize services needed for background work
      await Hive.initFlutter();
      await Supabase.initialize(
        url: inputData?['supabaseUrl'] ?? '',
        anonKey: inputData?['supabaseKey'] ?? '',
      );
      
      switch (task) {
        case periodicSyncTask:
          await _performPeriodicSync();
          break;
          
        case criticalSyncTask:
          await _performCriticalSync();
          break;
          
        case cleanupTask:
          await _performCleanup();
          break;
          
        case healthCheckTask:
          await _performHealthCheck(inputData);
          break;
          
        case medicationReminderTask:
          await _performMedicationReminder(inputData);
          break;
          
        default:
          logger.w('Unknown task: $task');
      }
      
      logger.i('Background task completed: $task');
      return Future.value(true);
      
    } catch (e, stackTrace) {
      logger.e('Background task failed: $task', error: e, stackTrace: stackTrace);
      return Future.value(false);
    }
  });
}

// Background task implementations
Future<void> _performPeriodicSync() async {
  final logger = Logger();
  
  try {
    // Initialize necessary services
    await OfflineManager.initialize();
    final networkManager = NetworkManager();
    await networkManager.initialize();
    
    if (!networkManager.isOnline) {
      logger.d('Device offline, skipping sync');
      return;
    }
    
    // Initialize sync services
    final syncQueue = SyncQueue();
    final dataSyncService = DataSyncService();
    
    await dataSyncService.initialize();
    
    // Process sync queue
    await syncQueue.processQueue();
    
    // Perform incremental sync
    await dataSyncService.performIncrementalSync();
    
    logger.i('Periodic sync completed successfully');
    
  } catch (e) {
    logger.e('Periodic sync failed', error: e);
  }
}

Future<void> _performCriticalSync() async {
  final logger = Logger();
  
  try {
    await OfflineManager.initialize();
    final networkManager = NetworkManager();
    await networkManager.initialize();
    
    if (!networkManager.isOnline) {
      logger.d('Device offline, queuing critical data');
      return;
    }
    
    final dataSyncService = DataSyncService();
    await dataSyncService.initialize();
    
    // Sync only critical data
    await dataSyncService.syncCriticalData();
    
    logger.i('Critical sync completed');
    
  } catch (e) {
    logger.e('Critical sync failed', error: e);
  }
}

Future<void> _performCleanup() async {
  final logger = Logger();
  
  try {
    // Initialize cache manager
    final cacheManager = CacheManager();
    await cacheManager.initialize();
    
    // Clean old cache data
    await cacheManager.clearOldData(maxAge: const Duration(days: 7));
    
    // Clean temporary files
    final tempDir = Directory.systemTemp;
    if (await tempDir.exists()) {
      final files = tempDir.listSync();
      final cutoff = DateTime.now().subtract(const Duration(days: 1));
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoff)) {
            await file.delete();
          }
        }
      }
    }
    
    logger.i('Cleanup completed');
    
  } catch (e) {
    logger.e('Cleanup failed', error: e);
  }
}

Future<void> _performHealthCheck(Map<String, dynamic>? inputData) async {
  final logger = Logger();
  
  try {
    final userId = inputData?['userId'];
    if (userId == null) return;
    
    await OfflineManager.initialize();
    
    // Check for abnormal health readings
    // This would analyze recent health data and send notifications if needed
    
    logger.i('Health check completed for user: $userId');
    
  } catch (e) {
    logger.e('Health check failed', error: e);
  }
}

Future<void> _performMedicationReminder(Map<String, dynamic>? inputData) async {
  final logger = Logger();
  
  try {
    final userId = inputData?['userId'];
    final medicationId = inputData?['medicationId'];
    final medicationName = inputData?['medicationName'];
    final dosage = inputData?['dosage'];
    
    if (userId == null || medicationId == null) return;
    
    // Send medication reminder notification
    await _sendNotification(
      title: 'Medication Reminder',
      body: 'Time to take $medicationName ($dosage)',
      payload: {
        'type': 'medication',
        'medicationId': medicationId,
        'userId': userId,
      },
    );
    
    logger.i('Medication reminder sent for: $medicationName');
    
  } catch (e) {
    logger.e('Medication reminder failed', error: e);
  }
}

// Main BackgroundSyncService class
class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();
  
  final Logger _logger = Logger();
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseKey,
  }) async {
    if (_isInitialized) return;
    
    try {
      // Initialize WorkManager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      
      // Initialize notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notifications.initialize(initSettings);
      
      // Register periodic tasks
      await _registerPeriodicTasks(
        supabaseUrl: supabaseUrl,
        supabaseKey: supabaseKey,
      );
      
      _isInitialized = true;
      _logger.i('BackgroundSyncService initialized');
      
    } catch (e) {
      _logger.e('Failed to initialize BackgroundSyncService', error: e);
    }
  }
  
  Future<void> _registerPeriodicTasks({
    required String supabaseUrl,
    required String supabaseKey,
  }) async {
    final inputData = {
      'supabaseUrl': supabaseUrl,
      'supabaseKey': supabaseKey,
    };
    
    // Register periodic sync (every 15 minutes minimum on Android)
    await Workmanager().registerPeriodicTask(
      'periodic_sync_1',
      periodicSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      inputData: inputData,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 10),
    );
    
    // Register daily cleanup task
    await Workmanager().registerPeriodicTask(
      'cleanup_1',
      cleanupTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
      ),
      inputData: inputData,
    );
    
    _logger.d('Periodic background tasks registered');
  }
  
  Future<void> scheduleOneTimeSync({
    required String taskId,
    required String taskName,
    Duration delay = const Duration(minutes: 5),
    Map<String, dynamic>? inputData,
  }) async {
    await Workmanager().registerOneOffTask(
      taskId,
      taskName,
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      inputData: inputData,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 10),
    );
    
    _logger.d('One-time task scheduled: $taskName');
  }
  
  Future<void> scheduleCriticalSync(Map<String, dynamic> data) async {
    await scheduleOneTimeSync(
      taskId: 'critical_${DateTime.now().millisecondsSinceEpoch}',
      taskName: criticalSyncTask,
      delay: const Duration(seconds: 30),
      inputData: data,
    );
  }
  
  Future<void> scheduleMedicationReminder({
    required String userId,
    required String medicationId,
    required String medicationName,
    required String dosage,
    required DateTime scheduleTime,
  }) async {
    final delay = scheduleTime.difference(DateTime.now());
    
    if (delay.isNegative) {
      _logger.w('Medication reminder time has passed');
      return;
    }
    
    await scheduleOneTimeSync(
      taskId: 'med_${medicationId}_${scheduleTime.millisecondsSinceEpoch}',
      taskName: medicationReminderTask,
      delay: delay,
      inputData: {
        'userId': userId,
        'medicationId': medicationId,
        'medicationName': medicationName,
        'dosage': dosage,
      },
    );
    
    _logger.d('Medication reminder scheduled for: $medicationName at $scheduleTime');
  }
  
  Future<void> scheduleHealthCheck({
    required String userId,
    Duration interval = const Duration(hours: 6),
  }) async {
    await Workmanager().registerPeriodicTask(
      'health_check_$userId',
      healthCheckTask,
      frequency: interval,
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
      inputData: {'userId': userId},
    );
    
    _logger.d('Health check scheduled for user: $userId');
  }
  
  Future<void> cancelTask(String taskId) async {
    await Workmanager().cancelByUniqueName(taskId);
    _logger.d('Task cancelled: $taskId');
  }
  
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    _logger.d('All background tasks cancelled');
  }
  
  Future<void> triggerImmediateSync() async {
    await scheduleOneTimeSync(
      taskId: 'immediate_${DateTime.now().millisecondsSinceEpoch}',
      taskName: periodicSyncTask,
      delay: Duration.zero,
    );
  }
  
  Future<bool> isBackgroundSyncEnabled() async {
    // Check if background sync is enabled in settings
    // This would read from user preferences
    return true;
  }
  
  Future<void> setBackgroundSyncEnabled(bool enabled) async {
    if (enabled) {
      // Re-register tasks
      await _registerPeriodicTasks(
        supabaseUrl: '', // Get from config
        supabaseKey: '', // Get from config
      );
    } else {
      // Cancel all tasks
      await cancelAllTasks();
    }
    
    _logger.i('Background sync ${enabled ? 'enabled' : 'disabled'}');
  }
}

// Helper function for notifications
Future<void> _sendNotification({
  required String title,
  required String body,
  Map<String, dynamic>? payload,
}) async {
  final notifications = FlutterLocalNotificationsPlugin();
  
  const androidDetails = AndroidNotificationDetails(
    'family_bridge_sync',
    'FamilyBridge Sync',
    channelDescription: 'Background sync notifications',
    importance: Importance.high,
    priority: Priority.high,
  );
  
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  
  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );
  
  await notifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    details,
    payload: payload != null ? payload.toString() : null,
  );
}