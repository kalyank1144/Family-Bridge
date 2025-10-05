class CachedData {
  final String key;
  final dynamic data;
  final DateTime timestamp;
  final Duration? ttl;
  
  CachedData({
    required this.key,
    required this.data,
    required this.timestamp,
    this.ttl,
  });
  
  bool isValid() {
    if (ttl == null) return true;
    final expiryTime = timestamp.add(ttl!);
    return DateTime.now().isBefore(expiryTime);
  }
  
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl?.inSeconds,
    };
  }
  
  factory CachedData.fromJson(Map<String, dynamic> json) {
    return CachedData(
      key: json['key'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      ttl: json['ttl'] != null ? Duration(seconds: json['ttl']) : null,
    );
  }
}

// Simplified adapter
class CachedDataAdapter {
  static const int typeId = 2;
}