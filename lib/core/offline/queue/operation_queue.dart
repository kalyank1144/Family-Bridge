import 'dart:async';
import 'dart:collection';
import '../storage/local_storage_manager.dart';
import '../models/offline_operation.dart';

class OperationQueue {
  final LocalStorageManager storageManager;
  final Function(OfflineOperation) onOperationComplete;
  final Function(OfflineOperation, dynamic) onOperationFailed;
  
  final Queue<OfflineOperation> _queue = Queue();
  
  OperationQueue({
    required this.storageManager,
    required this.onOperationComplete,
    required this.onOperationFailed,
  });
  
  Future<void> initialize() async {
    final operations = await storageManager.getPendingOperations();
    _queue.addAll(operations);
  }
  
  Future<void> enqueue(OfflineOperation operation) async {
    _queue.add(operation);
  }
  
  Future<bool> process(OfflineOperation operation) async {
    try {
      // Simulate processing
      await Future.delayed(const Duration(milliseconds: 100));
      onOperationComplete(operation);
      return true;
    } catch (e) {
      onOperationFailed(operation, e);
      return false;
    }
  }
  
  void dispose() {
    _queue.clear();
  }
}