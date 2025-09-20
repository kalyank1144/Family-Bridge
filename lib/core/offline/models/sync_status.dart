class SyncStatus {
  final bool isProcessing;
  final int pendingCount;
  final String message;
  final DateTime timestamp;
  
  SyncStatus({
    required this.isProcessing,
    required this.pendingCount,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}