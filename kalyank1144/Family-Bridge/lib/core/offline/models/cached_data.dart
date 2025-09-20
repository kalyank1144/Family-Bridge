import 'package:hive/hive.dart';

part 'cached_data.g.dart';

@HiveType(typeId: 2)
class CachedData {
  @HiveField(0)
  final String key;
  
  @HiveField(1)
  final dynamic data;
  
  @HiveField(2)
  final DateTime timestamp;
  
  @HiveField(3)
  final Duration? ttl; // Time to live
  
  @HiveField(4)
  final String? eTag;
  
  @HiveField(5)
  final Map<String, String>? metadata;
  
  CachedData({
    required this.key,
    required this.data,
    required this.timestamp,
    this.ttl,
    this.eTag,
    this.metadata,
  });
  
  bool isValid() {
    if (ttl == null) return true;
    
    final expiryTime = timestamp.add(ttl!);
    return DateTime.now().isBefore(expiryTime);
  }
  
  bool isExpired() => !isValid();
  
  Duration get age => DateTime.now().difference(timestamp);
  
  DateTime? get expiryTime => ttl != null ? timestamp.add(ttl!) : null;
  
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl?.inSeconds,
      'eTag': eTag,
      'metadata': metadata,
    };
  }
  
  factory CachedData.fromJson(Map<String, dynamic> json) {
    return CachedData(
      key: json['key'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      ttl: json['ttl'] != null ? Duration(seconds: json['ttl']) : null,
      eTag: json['eTag'],
      metadata: json['metadata'] != null 
        ? Map<String, String>.from(json['metadata']) 
        : null,
    );
  }
}

class CachedDataAdapter extends TypeAdapter<CachedData> {
  @override
  final int typeId = 2;
  
  @override
  CachedData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedData(
      key: fields[0] as String,
      data: fields[1],
      timestamp: fields[2] as DateTime,
      ttl: fields[3] as Duration?,
      eTag: fields[4] as String?,
      metadata: fields[5] != null 
        ? Map<String, String>.from(fields[5] as Map) 
        : null,
    );
  }
  
  @override
  void write(BinaryWriter writer, CachedData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.ttl)
      ..writeByte(4)
      ..write(obj.eTag)
      ..writeByte(5)
      ..write(obj.metadata);
  }
  
  @override
  int get hashCode => typeId.hashCode;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}