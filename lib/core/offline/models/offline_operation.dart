import 'package:uuid/uuid.dart';

class OfflineOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retryCount;
  String? error;
  bool isFailed;
  DateTime? lastAttempt;
  
  OfflineOperation({
    String? id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.error,
    this.isFailed = false,
    this.lastAttempt,
  }) : id = id ?? const Uuid().v4();
  
  void incrementRetry() {
    retryCount++;
    lastAttempt = DateTime.now();
  }
  
  void markAsFailed(String errorMessage) {
    isFailed = true;
    error = errorMessage;
    lastAttempt = DateTime.now();
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'error': error,
      'isFailed': isFailed,
      'lastAttempt': lastAttempt?.toIso8601String(),
    };
  }
  
  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'],
      type: json['type'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
      error: json['error'],
      isFailed: json['isFailed'] ?? false,
      lastAttempt: json['lastAttempt'] != null 
        ? DateTime.parse(json['lastAttempt']) 
        : null,
    );
  }
}

// Simplified Hive adapter for demo
class OfflineOperationAdapter {
  static const int typeId = 1;
}