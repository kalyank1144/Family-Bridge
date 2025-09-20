import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'offline_operation.g.dart';

@HiveType(typeId: 1)
class OfflineOperation {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String type;
  
  @HiveField(2)
  final Map<String, dynamic> data;
  
  @HiveField(3)
  final DateTime timestamp;
  
  @HiveField(4)
  int retryCount;
  
  @HiveField(5)
  String? error;
  
  @HiveField(6)
  bool isFailed;
  
  @HiveField(7)
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
  
  void resetRetry() {
    retryCount = 0;
    error = null;
    isFailed = false;
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
  
  OfflineOperation copyWith({
    String? type,
    Map<String, dynamic>? data,
    int? retryCount,
    String? error,
    bool? isFailed,
    DateTime? lastAttempt,
  }) {
    return OfflineOperation(
      id: id,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
      isFailed: isFailed ?? this.isFailed,
      lastAttempt: lastAttempt ?? this.lastAttempt,
    );
  }
}

class OfflineOperationAdapter extends TypeAdapter<OfflineOperation> {
  @override
  final int typeId = 1;
  
  @override
  OfflineOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineOperation(
      id: fields[0] as String,
      type: fields[1] as String,
      data: Map<String, dynamic>.from(fields[2] as Map),
      timestamp: fields[3] as DateTime,
      retryCount: fields[4] as int,
      error: fields[5] as String?,
      isFailed: fields[6] as bool,
      lastAttempt: fields[7] as DateTime?,
    );
  }
  
  @override
  void write(BinaryWriter writer, OfflineOperation obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.retryCount)
      ..writeByte(5)
      ..write(obj.error)
      ..writeByte(6)
      ..write(obj.isFailed)
      ..writeByte(7)
      ..write(obj.lastAttempt);
  }
  
  @override
  int get hashCode => typeId.hashCode;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}