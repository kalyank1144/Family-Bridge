import 'dart:async';
import 'package:flutter/foundation.dart';
import '../storage/local_storage_manager.dart';
import '../models/sync_operation.dart';
import 'sync_manager.dart';

class SyncQueue {
  final LocalStorageManager storageManager;
  final Map<String, SyncOperation> _operations = {};
  final Map<String, SyncOperation> _failedOperations = {};
  
  SyncQueue({required this.storageManager});
  
  Future<void> initialize() async {
    await _loadOperations();
  }
  
  Future<void> _loadOperations() async {
    // Load operations from storage
    final data = await storageManager.getConfig('syncQueue');
    if (data != null && data is Map) {
      for (final entry in data.entries) {
        final operation = SyncOperation.fromJson(Map<String, dynamic>.from(entry.value));
        _operations[operation.id] = operation;
      }
    }
    
    // Load failed operations
    final failedData = await storageManager.getConfig('failedSyncQueue');
    if (failedData != null && failedData is Map) {
      for (final entry in failedData.entries) {
        final operation = SyncOperation.fromJson(Map<String, dynamic>.from(entry.value));
        _failedOperations[operation.id] = operation;
      }
    }
  }
  
  Future<void> _saveOperations() async {
    final data = <String, dynamic>{};
    for (final entry in _operations.entries) {
      data[entry.key] = entry.value.toJson();
    }
    await storageManager.saveConfig('syncQueue', data);
    
    final failedData = <String, dynamic>{};
    for (final entry in _failedOperations.entries) {
      failedData[entry.key] = entry.value.toJson();
    }
    await storageManager.saveConfig('failedSyncQueue', failedData);
  }
  
  Future<void> enqueue(SyncOperation operation) async {
    _operations[operation.id] = operation;
    await _saveOperations();
  }
  
  Future<void> requeue(SyncOperation operation) async {
    // Remove from failed if it was there
    _failedOperations.remove(operation.id);
    
    // Add back to main queue
    _operations[operation.id] = operation;
    await _saveOperations();
  }
  
  Future<void> markAsCompleted(String operationId) async {
    _operations.remove(operationId);
    _failedOperations.remove(operationId);
    await _saveOperations();
  }
  
  Future<void> markAsFailed(String operationId, String error) async {
    final operation = _operations.remove(operationId);
    if (operation != null) {
      operation.error = error;
      _failedOperations[operationId] = operation;
      await _saveOperations();
    }
  }
  
  Future<List<SyncOperation>> getPendingOperations() async {
    return _operations.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
  
  Future<List<SyncOperation>> getFailedOperations() async {
    return _failedOperations.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
  
  Future<SyncOperation?> getOperation(String operationId) async {
    return _operations[operationId] ?? _failedOperations[operationId];
  }
  
  Future<void> updateOperation(SyncOperation operation) async {
    if (_operations.containsKey(operation.id)) {
      _operations[operation.id] = operation;
    } else if (_failedOperations.containsKey(operation.id)) {
      _failedOperations[operation.id] = operation;
    }
    await _saveOperations();
  }
  
  Future<void> clear() async {
    _operations.clear();
    _failedOperations.clear();
    await _saveOperations();
  }
  
  Future<void> clearFailed() async {
    _failedOperations.clear();
    await _saveOperations();
  }
  
  Future<Map<String, int>> getStatistics() async {
    final stats = <String, int>{};
    
    // Count by priority
    final priorityCounts = <SyncPriority, int>{};
    for (final op in _operations.values) {
      priorityCounts[op.priority] = (priorityCounts[op.priority] ?? 0) + 1;
    }
    
    stats['total'] = _operations.length;
    stats['failed'] = _failedOperations.length;
    stats['critical'] = priorityCounts[SyncPriority.critical] ?? 0;
    stats['high'] = priorityCounts[SyncPriority.high] ?? 0;
    stats['medium'] = priorityCounts[SyncPriority.medium] ?? 0;
    stats['low'] = priorityCounts[SyncPriority.low] ?? 0;
    
    return stats;
  }
  
  void dispose() {
    _operations.clear();
    _failedOperations.clear();
  }
}