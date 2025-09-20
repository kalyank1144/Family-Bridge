import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../network/network_manager.dart';
import '../offline_manager.dart';
import '../storage/local_storage_manager.dart';
import '../models/sync_operation.dart';
import '../models/sync_conflict.dart';
import '../models/sync_result.dart';
import 'sync_strategy.dart';
import 'conflict_resolver.dart';
import 'sync_queue.dart';

enum SyncPriority {
  critical,  // Emergency data, health alerts
  high,      // Messages, health data
  medium,    // Profile updates, preferences
  low,       // Analytics, logs
}

enum SyncMode {
  automatic,
  manual,
  scheduled,
  bandwidth_aware,
}

class SyncManager {
  final OfflineManager offlineManager;
  final NetworkManager networkManager;
  final LocalStorageManager storageManager;
  
  late SyncQueue _syncQueue;
  late ConflictResolver _conflictResolver;
  late SyncStrategy _syncStrategy;
  
  final _syncStatusController = StreamController<SyncResult>.broadcast();
  final _conflictController = StreamController<SyncConflict>.broadcast();
  
  bool _isSyncing = false;
  bool _isPaused = false;
  SyncMode _syncMode = SyncMode.automatic;
  
  Timer? _scheduledSyncTimer;
  Timer? _retryTimer;
  
  int _syncFailureCount = 0;
  DateTime? _lastSyncTime;
  
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 5);
  static const Duration _scheduledSyncInterval = Duration(minutes: 15);
  
  Stream<SyncResult> get syncStatusStream => _syncStatusController.stream;
  Stream<SyncConflict> get conflictStream => _conflictController.stream;
  
  bool get isSyncing => _isSyncing;
  bool get isPaused => _isPaused;
  DateTime? get lastSyncTime => _lastSyncTime;
  SyncMode get syncMode => _syncMode;
  
  SyncManager({
    required this.offlineManager,
    required this.networkManager,
    required this.storageManager,
  });
  
  Future<void> initialize() async {
    _syncQueue = SyncQueue(storageManager: storageManager);
    await _syncQueue.initialize();
    
    _conflictResolver = ConflictResolver(
      storageManager: storageManager,
      onConflict: _handleConflict,
    );
    
    _syncStrategy = SyncStrategy(
      networkManager: networkManager,
      storageManager: storageManager,
    );
    
    // Load last sync time
    final lastSync = await storageManager.getConfig('lastSyncTime');
    if (lastSync != null) {
      _lastSyncTime = DateTime.parse(lastSync);
    }
    
    // Load sync mode
    final mode = await storageManager.getConfig('syncMode');
    if (mode != null) {
      _syncMode = SyncMode.values.firstWhere(
        (m) => m.toString() == mode,
        orElse: () => SyncMode.automatic,
      );
    }
    
    // Start monitoring network changes
    networkManager.connectionStream.listen((isOnline) {
      if (isOnline && !_isPaused && _syncMode == SyncMode.automatic) {
        checkAndSync();
      }
    });
    
    // Start scheduled sync if enabled
    if (_syncMode == SyncMode.scheduled) {
      _startScheduledSync();
    }
  }
  
  Future<void> checkAndSync() async {
    if (_isSyncing || _isPaused || !networkManager.isOnline) {
      return;
    }
    
    // Check if sync is needed
    if (!_shouldSync()) {
      return;
    }
    
    await performSync();
  }
  
  Future<SyncResult> performSync() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        timestamp: DateTime.now(),
      );
    }
    
    _isSyncing = true;
    final startTime = DateTime.now();
    
    try {
      _emitSyncStatus(SyncResult(
        success: true,
        message: 'Starting sync...',
        timestamp: startTime,
        isInProgress: true,
      ));
      
      // Get pending operations
      final operations = await _syncQueue.getPendingOperations();
      
      if (operations.isEmpty) {
        _lastSyncTime = DateTime.now();
        await storageManager.saveConfig('lastSyncTime', _lastSyncTime!.toIso8601String());
        
        return SyncResult(
          success: true,
          message: 'Nothing to sync',
          timestamp: DateTime.now(),
        );
      }
      
      // Sort operations by priority
      operations.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      
      // Determine sync strategy based on network quality
      final strategy = await _syncStrategy.determineStrategy();
      
      int successCount = 0;
      int failureCount = 0;
      final conflicts = <SyncConflict>[];
      
      // Process operations based on strategy
      for (final operation in operations) {
        if (!networkManager.isOnline || _isPaused) {
          break;
        }
        
        // Skip low priority items on poor network
        if (strategy == SyncStrategyType.minimal && 
            operation.priority == SyncPriority.low) {
          continue;
        }
        
        _emitSyncStatus(SyncResult(
          success: true,
          message: 'Syncing ${operation.type}...',
          timestamp: DateTime.now(),
          isInProgress: true,
          progress: successCount / operations.length,
        ));
        
        try {
          final result = await _syncOperation(operation);
          
          if (result.hasConflict) {
            conflicts.add(result.conflict!);
          } else if (result.success) {
            successCount++;
            await _syncQueue.markAsCompleted(operation.id);
          } else {
            failureCount++;
            await _handleSyncFailure(operation, result.error);
          }
        } catch (e) {
          failureCount++;
          await _handleSyncFailure(operation, e.toString());
        }
      }
      
      // Handle conflicts if any
      if (conflicts.isNotEmpty) {
        await _resolveConflicts(conflicts);
      }
      
      _lastSyncTime = DateTime.now();
      await storageManager.saveConfig('lastSyncTime', _lastSyncTime!.toIso8601String());
      
      _syncFailureCount = 0;
      
      final result = SyncResult(
        success: failureCount == 0,
        message: 'Sync completed: $successCount successful, $failureCount failed',
        timestamp: DateTime.now(),
        itemsSynced: successCount,
        itemsFailed: failureCount,
        conflicts: conflicts.length,
        duration: DateTime.now().difference(startTime),
      );
      
      _emitSyncStatus(result);
      return result;
      
    } catch (e) {
      debugPrint('Sync error: $e');
      
      _syncFailureCount++;
      _scheduleRetry();
      
      final result = SyncResult(
        success: false,
        message: 'Sync failed: $e',
        timestamp: DateTime.now(),
        error: e.toString(),
      );
      
      _emitSyncStatus(result);
      return result;
      
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<SyncOperationResult> _syncOperation(SyncOperation operation) async {
    try {
      // Check for conflicts before syncing
      final conflict = await _conflictResolver.checkForConflict(operation);
      
      if (conflict != null) {
        return SyncOperationResult(
          success: false,
          hasConflict: true,
          conflict: conflict,
        );
      }
      
      // Perform the actual sync based on operation type
      switch (operation.type) {
        case 'message':
          await _syncMessage(operation.data);
          break;
        case 'health_record':
          await _syncHealthRecord(operation.data);
          break;
        case 'medication':
          await _syncMedication(operation.data);
          break;
        case 'user_profile':
          await _syncUserProfile(operation.data);
          break;
        default:
          await _syncGenericData(operation);
      }
      
      return SyncOperationResult(success: true);
      
    } catch (e) {
      return SyncOperationResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> _syncMessage(Map<String, dynamic> data) async {
    // Implement message sync logic
    // This would typically involve calling an API endpoint
    debugPrint('Syncing message: ${data['id']}');
  }
  
  Future<void> _syncHealthRecord(Map<String, dynamic> data) async {
    // Implement health record sync logic
    debugPrint('Syncing health record: ${data['id']}');
  }
  
  Future<void> _syncMedication(Map<String, dynamic> data) async {
    // Implement medication sync logic
    debugPrint('Syncing medication: ${data['id']}');
  }
  
  Future<void> _syncUserProfile(Map<String, dynamic> data) async {
    // Implement user profile sync logic
    debugPrint('Syncing user profile: ${data['id']}');
  }
  
  Future<void> _syncGenericData(SyncOperation operation) async {
    // Implement generic data sync logic
    debugPrint('Syncing generic data: ${operation.type}');
  }
  
  Future<void> _resolveConflicts(List<SyncConflict> conflicts) async {
    for (final conflict in conflicts) {
      _conflictController.add(conflict);
      
      // Auto-resolve if possible based on strategy
      if (conflict.canAutoResolve) {
        await _conflictResolver.autoResolve(conflict);
      }
    }
  }
  
  Future<void> _handleSyncFailure(SyncOperation operation, String error) async {
    operation.incrementRetry();
    
    if (operation.retryCount < _maxRetries) {
      // Re-queue for retry
      await _syncQueue.requeue(operation);
    } else {
      // Mark as permanently failed
      await _syncQueue.markAsFailed(operation.id, error);
    }
  }
  
  void _handleConflict(SyncConflict conflict) {
    _conflictController.add(conflict);
  }
  
  bool _shouldSync() {
    if (_syncMode == SyncMode.manual) {
      return false;
    }
    
    if (_syncMode == SyncMode.bandwidth_aware) {
      final quality = networkManager.networkQuality;
      if (quality == null || !quality.isAcceptable) {
        return false;
      }
    }
    
    // Check if enough time has passed since last sync
    if (_lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      if (timeSinceLastSync < const Duration(minutes: 1)) {
        return false;
      }
    }
    
    return true;
  }
  
  void _scheduleRetry() {
    _retryTimer?.cancel();
    
    // Exponential backoff
    final delay = _baseRetryDelay * pow(2, min(_syncFailureCount, 5));
    
    _retryTimer = Timer(delay, () {
      if (networkManager.isOnline && !_isPaused) {
        checkAndSync();
      }
    });
  }
  
  void _startScheduledSync() {
    _scheduledSyncTimer?.cancel();
    _scheduledSyncTimer = Timer.periodic(_scheduledSyncInterval, (_) {
      if (networkManager.isOnline && !_isPaused) {
        checkAndSync();
      }
    });
  }
  
  void _emitSyncStatus(SyncResult result) {
    _syncStatusController.add(result);
  }
  
  Future<void> setSyncMode(SyncMode mode) async {
    _syncMode = mode;
    await storageManager.saveConfig('syncMode', mode.toString());
    
    if (mode == SyncMode.scheduled) {
      _startScheduledSync();
    } else {
      _scheduledSyncTimer?.cancel();
    }
    
    if (mode == SyncMode.automatic && networkManager.isOnline) {
      checkAndSync();
    }
  }
  
  void pauseSync() {
    _isPaused = true;
    _scheduledSyncTimer?.cancel();
    _retryTimer?.cancel();
  }
  
  void resumeSync() {
    _isPaused = false;
    
    if (_syncMode == SyncMode.scheduled) {
      _startScheduledSync();
    }
    
    if (networkManager.isOnline) {
      checkAndSync();
    }
  }
  
  Future<void> forceSyncItem(String itemId, SyncPriority priority) async {
    final operation = await _syncQueue.getOperation(itemId);
    if (operation != null) {
      operation.priority = priority;
      await _syncQueue.updateOperation(operation);
      
      if (networkManager.isOnline) {
        await performSync();
      }
    }
  }
  
  Future<Map<String, dynamic>> getSyncStatistics() async {
    final pending = await _syncQueue.getPendingOperations();
    final failed = await _syncQueue.getFailedOperations();
    
    final stats = <String, dynamic>{
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'isSyncing': _isSyncing,
      'isPaused': _isPaused,
      'syncMode': _syncMode.toString(),
      'pendingOperations': pending.length,
      'failedOperations': failed.length,
      'syncFailureCount': _syncFailureCount,
    };
    
    // Group pending by priority
    final priorityGroups = <SyncPriority, int>{};
    for (final op in pending) {
      priorityGroups[op.priority] = (priorityGroups[op.priority] ?? 0) + 1;
    }
    stats['pendingByPriority'] = priorityGroups;
    
    // Group pending by type
    final typeGroups = <String, int>{};
    for (final op in pending) {
      typeGroups[op.type] = (typeGroups[op.type] ?? 0) + 1;
    }
    stats['pendingByType'] = typeGroups;
    
    return stats;
  }
  
  Future<void> clearSyncQueue() async {
    await _syncQueue.clear();
  }
  
  void dispose() {
    _scheduledSyncTimer?.cancel();
    _retryTimer?.cancel();
    _syncStatusController.close();
    _conflictController.close();
    _syncQueue.dispose();
  }
}