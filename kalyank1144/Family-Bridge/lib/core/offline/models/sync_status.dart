class SyncStatus {
  final bool isProcessing;
  final int pendingCount;
  final String message;
  final DateTime timestamp;
  final double? progress;
  
  SyncStatus({
    required this.isProcessing,
    required this.pendingCount,
    required this.message,
    DateTime? timestamp,
    this.progress,
  }) : timestamp = timestamp ?? DateTime.now();
  
  bool get hasP
endingItems => pendingCount > 0;
  
  Map<String, dynamic> toJson() {
    return {
      'isProcessing': isProcessing,
      'pendingCount': pendingCount,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'progress': progress,
    };
  }
  
  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      isProcessing: json['isProcessing'],
      pendingCount: json['pendingCount'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      progress: json['progress'],
    );
  }
}