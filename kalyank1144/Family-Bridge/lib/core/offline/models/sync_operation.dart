import 'package:uuid/uuid.dart';
import '../sync/sync_manager.dart';

class SyncOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  SyncPriority priority;
  int retryCount;
  String? error;
  DateTime? lastAttempt;
  
  SyncOperation({
    String? id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.priority = SyncPriority.medium,
    this.retryCount = 0,
    this.error,
    this.lastAttempt,
  }) : id = id ?? const Uuid().v4();
  
  void incrementRetry() {
    retryCount++;
    lastAttempt = DateTime.now();
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'priority': priority.index,
      'retryCount': retryCount,
      'error': error,
      'lastAttempt': lastAttempt?.toIso8601String(),
    };
  }
  
  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'],
      type: json['type'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      priority: SyncPriority.values[json['priority'] ?? 2],
      retryCount: json['retryCount'] ?? 0,
      error: json['error'],
      lastAttempt: json['lastAttempt'] != null 
        ? DateTime.parse(json['lastAttempt']) 
        : null,
    );
  }
}

class SyncOperationResult {
  final bool success;
  final bool hasConflict;
  final SyncConflict? conflict;
  final String? error;
  
  SyncOperationResult({
    required this.success,
    this.hasConflict = false,
    this.conflict,
    this.error,
  });
}