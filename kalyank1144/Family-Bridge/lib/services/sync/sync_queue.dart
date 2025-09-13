import 'dart:async';
import 'package:hive/hive.dart';
import '../../models/sync/sync_item.dart';
import '../network/network_manager.dart';
import 'package:logger/logger.dart';

class SyncQueue {
  static final SyncQueue _instance = SyncQueue._internal();
  factory SyncQueue() => _instance;
  SyncQueue._internal();

  late Box<SyncItem> _syncBox;
  final Logger _logger = Logger();
  Timer? _processTimer;
  bool _isProcessing = false;
  final StreamController<SyncQueueStatus> _statusController = 
      StreamController<SyncQueueStatus>.broadcast();

  Stream<SyncQueueStatus> get statusStream => _statusController.stream;

  Future<void> initialize(Box<SyncItem> syncBox) async {
    _syncBox = syncBox;
    
    // Start periodic processing
    _startPeriodicProcessing();
    
    // Process immediately if items exist
    if (_syncBox.isNotEmpty) {
      await processQueue();
    }
  }

  void _startPeriodicProcessing() {
    _processTimer?.cancel();
    _processTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isProcessing && NetworkManager().isOnline) {
        processQueue();
      }
    });
  }

  Future<void> addItem(SyncItem item) async {
    try {
      await _syncBox.put(item.id, item);
      _logger.d('Added sync item: ${item.id} - ${item.operation} ${item.tableName}');
      
      _updateStatus();
      
      // Try immediate sync if online and high priority
      if (NetworkManager().isOnline && 
          item.syncPriority == SyncPriority.critical) {
        await processQueue();
      }
    } catch (e) {
      _logger.e('Error adding sync item', error: e);
    }
  }

  Future<void> addBatch(List<SyncItem> items) async {
    try {
      final Map<String, SyncItem> itemMap = {
        for (var item in items) item.id: item
      };
      
      await _syncBox.putAll(itemMap);
      _logger.d('Added ${items.length} sync items in batch');
      
      _updateStatus();
      
      // Check if any critical items
      final hasCritical = items.any((i) => i.syncPriority == SyncPriority.critical);
      
      if (NetworkManager().isOnline && hasCritical) {
        await processQueue();
      }
    } catch (e) {
      _logger.e('Error adding batch sync items', error: e);
    }
  }

  Future<void> processQueue() async {
    if (_isProcessing) {
      _logger.d('Queue already processing, skipping');
      return;
    }
    
    if (!NetworkManager().isOnline) {
      _logger.d('Offline, skipping queue processing');
      return;
    }
    
    _isProcessing = true;
    _updateStatus();
    
    try {
      // Get items sorted by priority and timestamp
      final items = _getPendingItems();
      
      if (items.isEmpty) {
        _logger.d('No pending items to sync');
        return;
      }
      
      _logger.i('Processing ${items.length} sync items');
      
      for (final item in items) {
        await _processItem(item);
      }
      
      // Clean up completed items
      await _cleanupCompleted();
      
    } catch (e) {
      _logger.e('Error processing sync queue', error: e);
    } finally {
      _isProcessing = false;
      _updateStatus();
    }
  }

  List<SyncItem> _getPendingItems() {
    final items = _syncBox.values
        .where((item) => 
            item.syncStatus == SyncStatus.pending || 
            (item.syncStatus == SyncStatus.failed && item.canRetry))
        .toList();
    
    // Sort by priority then timestamp
    items.sort((a, b) {
      // First compare by priority
      final priorityCompare = _priorityValue(a.syncPriority)
          .compareTo(_priorityValue(b.syncPriority));
      if (priorityCompare != 0) return priorityCompare;
      
      // Then by timestamp
      return a.timestamp.compareTo(b.timestamp);
    });
    
    return items;
  }

  int _priorityValue(SyncPriority priority) {
    switch (priority) {
      case SyncPriority.critical:
        return 0;
      case SyncPriority.high:
        return 1;
      case SyncPriority.normal:
        return 2;
      case SyncPriority.low:
        return 3;
    }
  }

  Future<void> _processItem(SyncItem item) async {
    try {
      item.markAsSyncing();
      await item.save();
      
      _logger.d('Processing: ${item.operation} ${item.tableName} [${item.id}]');
      
      // Simulate API call - replace with actual implementation
      final success = await _syncToServer(item);
      
      if (success) {
        item.markAsCompleted();
        await item.save();
        _logger.i('Successfully synced: ${item.id}');
      } else {
        throw Exception('Sync failed');
      }
      
    } catch (e) {
      _logger.e('Failed to sync item ${item.id}', error: e);
      item.markAsFailed(e.toString());
      await item.save();
      
      // If can't retry anymore, notify user
      if (!item.canRetry) {
        _notifyPermanentFailure(item);
      }
    }
  }

  Future<bool> _syncToServer(SyncItem item) async {
    // This would be replaced with actual API calls
    // For now, simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate 95% success rate for testing
    return DateTime.now().millisecond > 50;
  }

  Future<void> _cleanupCompleted() async {
    final completedItems = _syncBox.values
        .where((item) => item.syncStatus == SyncStatus.completed)
        .toList();
    
    if (completedItems.length > 100) {
      // Keep only last 50 completed items for history
      completedItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final toDelete = completedItems.skip(50).map((i) => i.id);
      await _syncBox.deleteAll(toDelete);
      _logger.d('Cleaned up ${toDelete.length} completed sync items');
    }
  }

  void _notifyPermanentFailure(SyncItem item) {
    // This would trigger a notification to the user
    _logger.w('Permanent sync failure for ${item.id}: ${item.errorMessage}');
  }

  void _updateStatus() {
    final status = SyncQueueStatus(
      pendingCount: _syncBox.values
          .where((i) => i.syncStatus == SyncStatus.pending)
          .length,
      failedCount: _syncBox.values
          .where((i) => i.syncStatus == SyncStatus.failed)
          .length,
      isProcessing: _isProcessing,
      lastSync: _getLastSyncTime(),
    );
    
    _statusController.add(status);
  }

  DateTime? _getLastSyncTime() {
    final completed = _syncBox.values
        .where((i) => i.syncStatus == SyncStatus.completed)
        .toList();
    
    if (completed.isEmpty) return null;
    
    completed.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return completed.first.timestamp;
  }

  Future<void> retryFailed() async {
    final failedItems = _syncBox.values
        .where((i) => i.syncStatus == SyncStatus.failed && i.canRetry)
        .toList();
    
    for (final item in failedItems) {
      item.status = SyncStatus.pending.toString().split('.').last;
      await item.save();
    }
    
    if (failedItems.isNotEmpty) {
      _logger.i('Retrying ${failedItems.length} failed items');
      await processQueue();
    }
  }

  Future<void> clear() async {
    await _syncBox.clear();
    _updateStatus();
  }

  Future<Map<String, int>> getStatistics() async {
    final stats = <String, int>{
      'pending': 0,
      'syncing': 0,
      'completed': 0,
      'failed': 0,
      'total': _syncBox.length,
    };
    
    for (final item in _syncBox.values) {
      stats[item.status] = (stats[item.status] ?? 0) + 1;
    }
    
    return stats;
  }

  List<SyncItem> getFailedItems() {
    return _syncBox.values
        .where((i) => i.syncStatus == SyncStatus.failed)
        .toList();
  }

  Future<void> removeItem(String id) async {
    await _syncBox.delete(id);
    _updateStatus();
  }

  void dispose() {
    _processTimer?.cancel();
    _statusController.close();
  }
}

class SyncQueueStatus {
  final int pendingCount;
  final int failedCount;
  final bool isProcessing;
  final DateTime? lastSync;

  SyncQueueStatus({
    required this.pendingCount,
    required this.failedCount,
    required this.isProcessing,
    this.lastSync,
  });

  bool get hasItems => pendingCount > 0 || failedCount > 0;
  bool get hasFailures => failedCount > 0;
}