import 'package:uuid/uuid.dart';

enum ConflictResolution {
  useLocal,
  useRemote,
  merge,
  manual,
}

class SyncConflict {
  final String id;
  final String itemId;
  final String type;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;
  final DateTime detectedAt;
  ConflictResolution? resolution;
  Map<String, dynamic>? resolvedData;
  String? resolvedBy;
  DateTime? resolvedAt;
  
  SyncConflict({
    String? id,
    required this.itemId,
    required this.type,
    required this.localData,
    required this.remoteData,
    required this.localTimestamp,
    required this.remoteTimestamp,
    DateTime? detectedAt,
    this.resolution,
    this.resolvedData,
    this.resolvedBy,
    this.resolvedAt,
  }) : id = id ?? const Uuid().v4(),
       detectedAt = detectedAt ?? DateTime.now();
  
  bool get isResolved => resolution != null && resolvedData != null;
  
  bool get canAutoResolve {
    // Check if conflict can be automatically resolved
    if (type == 'message') {
      // Messages can be auto-resolved by keeping both
      return true;
    }
    
    if (type == 'health_record' || type == 'medication') {
      // Health data should use the most recent
      return localTimestamp.isAfter(remoteTimestamp) || 
             remoteTimestamp.isAfter(localTimestamp);
    }
    
    // Check if changes are non-conflicting
    final conflicts = _findConflictingFields();
    return conflicts.isEmpty;
  }
  
  List<String> _findConflictingFields() {
    final conflicts = <String>[];
    
    for (final key in localData.keys) {
      if (remoteData.containsKey(key)) {
        if (localData[key] != remoteData[key]) {
          conflicts.add(key);
        }
      }
    }
    
    return conflicts;
  }
  
  void resolve(ConflictResolution resolution, Map<String, dynamic> data, String userId) {
    this.resolution = resolution;
    resolvedData = data;
    resolvedBy = userId;
    resolvedAt = DateTime.now();
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'type': type,
      'localData': localData,
      'remoteData': remoteData,
      'localTimestamp': localTimestamp.toIso8601String(),
      'remoteTimestamp': remoteTimestamp.toIso8601String(),
      'detectedAt': detectedAt.toIso8601String(),
      'resolution': resolution?.index,
      'resolvedData': resolvedData,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
  
  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'],
      itemId: json['itemId'],
      type: json['type'],
      localData: Map<String, dynamic>.from(json['localData']),
      remoteData: Map<String, dynamic>.from(json['remoteData']),
      localTimestamp: DateTime.parse(json['localTimestamp']),
      remoteTimestamp: DateTime.parse(json['remoteTimestamp']),
      detectedAt: DateTime.parse(json['detectedAt']),
      resolution: json['resolution'] != null 
        ? ConflictResolution.values[json['resolution']] 
        : null,
      resolvedData: json['resolvedData'] != null
        ? Map<String, dynamic>.from(json['resolvedData'])
        : null,
      resolvedBy: json['resolvedBy'],
      resolvedAt: json['resolvedAt'] != null 
        ? DateTime.parse(json['resolvedAt']) 
        : null,
    );
  }
}