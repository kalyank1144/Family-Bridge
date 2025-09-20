import 'dart:async';
import 'package:flutter/foundation.dart';
import '../network/network_manager.dart';
import 'storage/local_storage_manager.dart';
import 'queue/operation_queue.dart';
import 'models/offline_operation.dart';
import 'models/sync_status.dart';

class OfflineManager {
  final LocalStorageManager storageManager;
  final NetworkManager networkManager;
  late OperationQueue _operationQueue;
  
  final _offlineOperations = <String, OfflineOperation>{};
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  
  Timer? _retryTimer;
  bool _isInitialized = false;
  bool _isProcessing = false;
  
  OfflineManager({
    required this.storageManager,
    required this.networkManager,
  });
  
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  bool get isOffline => !networkManager.isOnline;
  bool get hasOfflineData => _offlineOperations.isNotEmpty;
  int get pendingOperationsCount => _offlineOperations.length;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _operationQueue = OperationQueue(
      storageManager: storageManager,
      onOperationComplete: _handleOperationComplete,
      onOperationFailed: _handleOperationFailed,
    );
    
    await _operationQueue.initialize();
    await _loadPendingOperations();
    
    // Listen to network changes
    networkManager.connectionStream.listen((isOnline) {
      if (isOnline && hasOfflineData) {
        _startProcessing();
      } else if (!isOnline) {
        _stopProcessing();
      }
    });
    
    _isInitialized = true;
  }
  
  Future<void> queueOperation(OfflineOperation operation) async {
    _offlineOperations[operation.id] = operation;
    await _operationQueue.enqueue(operation);
    await _savePendingOperations();
    
    _syncStatusController.add(SyncStatus(
      isProcessing: _isProcessing,
      pendingCount: pendingOperationsCount,
      message: 'Operation queued for sync',
    ));
    
    if (networkManager.isOnline) {
      _startProcessing();
    }
  }
  
  Future<T> executeOfflineFirst<T>({
    required String operationType,
    required Map<String, dynamic> data,
    required Future<T> Function() localOperation,
    required Future<T> Function() remoteOperation,
    bool requiresSync = true,
  }) async {
    try {
      // Always execute local operation first
      final localResult = await localOperation();
      
      if (networkManager.isOnline && requiresSync) {
        // Try to sync immediately if online
        try {
          await remoteOperation();
        } catch (e) {
          // Queue for later sync if remote fails
          await queueOperation(OfflineOperation(
            type: operationType,
            data: data,
            timestamp: DateTime.now(),
            retryCount: 0,
          ));
        }
      } else if (requiresSync) {
        // Queue for sync when online
        await queueOperation(OfflineOperation(
          type: operationType,
          data: data,
          timestamp: DateTime.now(),
          retryCount: 0,
        ));
      }
      
      return localResult;
    } catch (e) {
      debugPrint('Offline operation failed: $e');
      rethrow;
    }
  }
  
  Future<void> processOfflineQueue() async {
    if (!networkManager.isOnline || _isProcessing || !hasOfflineData) {
      return;
    }
    
    _isProcessing = true;
    _syncStatusController.add(SyncStatus(
      isProcessing: true,
      pendingCount: pendingOperationsCount,
      message: 'Processing offline queue...',
    ));
    
    try {
      final operations = List<OfflineOperation>.from(_offlineOperations.values);
      
      for (final operation in operations) {
        if (!networkManager.isOnline) break;
        
        final success = await _operationQueue.process(operation);
        
        if (success) {
          _offlineOperations.remove(operation.id);
          await _savePendingOperations();
        }
      }
    } finally {
      _isProcessing = false;
      
      if (hasOfflineData && networkManager.isOnline) {
        _scheduleRetry();
      }
      
      _syncStatusController.add(SyncStatus(
        isProcessing: false,
        pendingCount: pendingOperationsCount,
        message: pendingOperationsCount > 0 
          ? '$pendingOperationsCount items pending sync'
          : 'All data synced',
      ));
    }
  }
  
  void _startProcessing() {
    if (!_isProcessing && hasOfflineData) {
      processOfflineQueue();
    }
  }
  
  void _stopProcessing() {
    _retryTimer?.cancel();
    _isProcessing = false;
  }
  
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      if (networkManager.isOnline && hasOfflineData) {
        processOfflineQueue();
      }
    });
  }
  
  void _handleOperationComplete(OfflineOperation operation) {
    debugPrint('Operation completed: ${operation.type}');
  }
  
  void _handleOperationFailed(OfflineOperation operation, dynamic error) {
    debugPrint('Operation failed: ${operation.type} - $error');
    
    if (operation.retryCount < 3) {
      operation.incrementRetry();
      _operationQueue.enqueue(operation);
    } else {
      operation.markAsFailed(error.toString());
      _offlineOperations[operation.id] = operation;
      _savePendingOperations();
    }
  }
  
  Future<void> _loadPendingOperations() async {
    final operations = await storageManager.getPendingOperations();
    for (final operation in operations) {
      _offlineOperations[operation.id] = operation;
    }
  }
  
  Future<void> _savePendingOperations() async {
    await storageManager.savePendingOperations(
      _offlineOperations.values.toList(),
    );
  }
  
  Future<void> cleanup() async {
    await _savePendingOperations();
    _retryTimer?.cancel();
  }
  
  void dispose() {
    _retryTimer?.cancel();
    _syncStatusController.close();
    _operationQueue.dispose();
  }
}