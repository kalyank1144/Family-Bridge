import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'user.g.dart';

enum UserType {
  elder,
  caregiver,
  youth,
}

enum UserRole {
  primary,
  secondary,
  viewer,
}

@HiveType(typeId: 10)
class User {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final String? phone;
  
  @HiveField(4)
  final UserType userType;
  
  @HiveField(5)
  final UserRole role;
  
  @HiveField(6)
  final String? profileImage;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final DateTime updatedAt;
  
  @HiveField(9)
  final bool isActive;
  
  @HiveField(10)
  final Map<String, dynamic>? preferences;
  
  @HiveField(11)
  final List<String> familyIds;
  
  @HiveField(12)
  final Map<String, dynamic>? emergencyInfo;
  
  @HiveField(13)
  final Map<String, dynamic>? healthInfo;
  
  User({
    String? id,
    required this.name,
    required this.email,
    this.phone,
    required this.userType,
    this.role = UserRole.viewer,
    this.profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
    this.preferences,
    List<String>? familyIds,
    this.emergencyInfo,
    this.healthInfo,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       familyIds = familyIds ?? [];
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType.index,
      'role': role.index,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'preferences': preferences,
      'familyIds': familyIds,
      'emergencyInfo': emergencyInfo,
      'healthInfo': healthInfo,
    };
  }
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      userType: UserType.values[json['userType']],
      role: UserRole.values[json['role'] ?? 2],
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'] ?? true,
      preferences: json['preferences'] != null 
        ? Map<String, dynamic>.from(json['preferences']) 
        : null,
      familyIds: json['familyIds'] != null 
        ? List<String>.from(json['familyIds']) 
        : [],
      emergencyInfo: json['emergencyInfo'] != null 
        ? Map<String, dynamic>.from(json['emergencyInfo']) 
        : null,
      healthInfo: json['healthInfo'] != null 
        ? Map<String, dynamic>.from(json['healthInfo']) 
        : null,
    );
  }
  
  User copyWith({
    String? name,
    String? email,
    String? phone,
    UserType? userType,
    UserRole? role,
    String? profileImage,
    bool? isActive,
    Map<String, dynamic>? preferences,
    List<String>? familyIds,
    Map<String, dynamic>? emergencyInfo,
    Map<String, dynamic>? healthInfo,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      familyIds: familyIds ?? this.familyIds,
      emergencyInfo: emergencyInfo ?? this.emergencyInfo,
      healthInfo: healthInfo ?? this.healthInfo,
    );
  }
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 10;
  
  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      phone: fields[3] as String?,
      userType: UserType.values[fields[4] as int],
      role: UserRole.values[fields[5] as int],
      profileImage: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      isActive: fields[9] as bool,
      preferences: fields[10] != null 
        ? Map<String, dynamic>.from(fields[10] as Map) 
        : null,
      familyIds: fields[11] != null 
        ? List<String>.from(fields[11] as List) 
        : [],
      emergencyInfo: fields[12] != null 
        ? Map<String, dynamic>.from(fields[12] as Map) 
        : null,
      healthInfo: fields[13] != null 
        ? Map<String, dynamic>.from(fields[13] as Map) 
        : null,
    );
  }
  
  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.userType.index)
      ..writeByte(5)
      ..write(obj.role.index)
      ..writeByte(6)
      ..write(obj.profileImage)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.preferences)
      ..writeByte(11)
      ..write(obj.familyIds)
      ..writeByte(12)
      ..write(obj.emergencyInfo)
      ..writeByte(13)
      ..write(obj.healthInfo);
  }
  
  @override
  int get hashCode => typeId.hashCode;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}