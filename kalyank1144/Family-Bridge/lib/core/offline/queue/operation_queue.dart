import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../storage/local_storage_manager.dart';
import '../models/offline_operation.dart';

class OperationQueue {
  final LocalStorageManager storageManager;
  final Function(OfflineOperation) onOperationComplete;
  final Function(OfflineOperation, dynamic) onOperationFailed;
  
  final Queue<OfflineOperation> _queue = Queue();
  final Set<String> _processingIds = {};
  bool _isProcessing = false;
  
  OperationQueue({
    required this.storageManager,
    required this.onOperationComplete,
    required this.onOperationFailed,
  });
  
  Future<void> initialize() async {
    // Load any persisted queue items
    final operations = await storageManager.getPendingOperations();
    _queue.addAll(operations);
  }
  
  Future<void> enqueue(OfflineOperation operation) async {
    if (_processingIds.contains(operation.id)) {
      debugPrint('Operation ${operation.id} is already being processed');
      return;
    }
    
    _queue.add(operation);
    await _persistQueue();
  }
  
  Future<bool> process(OfflineOperation operation) async {
    if (_processingIds.contains(operation.id)) {
      return false;
    }
    
    _processingIds.add(operation.id);
    
    try {
      // Process the operation based on its type
      await _processOperation(operation);
      onOperationComplete(operation);
      return true;
    } catch (e) {
      onOperationFailed(operation, e);
      return false;
    } finally {
      _processingIds.remove(operation.id);
    }
  }
  
  Future<void> _processOperation(OfflineOperation operation) async {
    // This is where the actual processing logic would go
    // For now, we'll simulate processing
    debugPrint('Processing operation: ${operation.type} - ${operation.id}');
    
    // Simulate network call
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Throw error for testing retry logic (10% chance)
    if (DateTime.now().millisecond % 10 == 0) {
      throw Exception('Simulated network error');
    }
  }
  
  Future<void> processAll() async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    try {
      while (_queue.isNotEmpty) {
        final operation = _queue.removeFirst();
        await process(operation);
      }
    } finally {
      _isProcessing = false;
      await _persistQueue();
    }
  }
  
  Future<void> clear() async {
    _queue.clear();
    _processingIds.clear();
    await _persistQueue();
  }
  
  Future<void> _persistQueue() async {
    await storageManager.savePendingOperations(_queue.toList());
  }
  
  int get length => _queue.length;
  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;
  bool get isProcessing => _isProcessing;
  
  void dispose() {
    _queue.clear();
    _processingIds.clear();
  }
}