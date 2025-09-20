class SyncResult {
  final bool success;
  final String message;
  final DateTime timestamp;
  final bool isInProgress;
  final double? progress;
  final int? itemsSynced;
  final int? itemsFailed;
  final int? conflicts;
  final Duration? duration;
  final String? error;
  
  SyncResult({
    required this.success,
    required this.message,
    required this.timestamp,
    this.isInProgress = false,
    this.progress,
    this.itemsSynced,
    this.itemsFailed,
    this.conflicts,
    this.duration,
    this.error,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isInProgress': isInProgress,
      'progress': progress,
      'itemsSynced': itemsSynced,
      'itemsFailed': itemsFailed,
      'conflicts': conflicts,
      'duration': duration?.inSeconds,
      'error': error,
    };
  }
  
  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      success: json['success'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isInProgress: json['isInProgress'] ?? false,
      progress: json['progress'],
      itemsSynced: json['itemsSynced'],
      itemsFailed: json['itemsFailed'],
      conflicts: json['conflicts'],
      duration: json['duration'] != null 
        ? Duration(seconds: json['duration']) 
        : null,
      error: json['error'],
    );
  }
}