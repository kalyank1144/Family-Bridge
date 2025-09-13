import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  late String userId;

  @HiveField(1)
  late String userType;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late String email;

  @HiveField(4)
  String? phoneNumber;

  @HiveField(5)
  String? profileImageUrl;

  @HiveField(6)
  Map<String, dynamic>? metadata;

  @HiveField(7)
  DateTime? lastSynced;

  @HiveField(8)
  DateTime? createdAt;

  @HiveField(9)
  DateTime? updatedAt;

  @HiveField(10)
  bool isOnline = false;

  @HiveField(11)
  String? familyId;

  @HiveField(12)
  List<String>? connectedUsers;

  UserModel({
    required this.userId,
    required this.userType,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.metadata,
    this.lastSynced,
    this.createdAt,
    this.updatedAt,
    this.isOnline = false,
    this.familyId,
    this.connectedUsers,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userType': userType,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'metadata': metadata,
      'lastSynced': lastSynced?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isOnline': isOnline,
      'familyId': familyId,
      'connectedUsers': connectedUsers,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      userType: json['userType'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      metadata: json['metadata'],
      lastSynced: json['lastSynced'] != null 
          ? DateTime.parse(json['lastSynced']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      isOnline: json['isOnline'] ?? false,
      familyId: json['familyId'],
      connectedUsers: json['connectedUsers'] != null 
          ? List<String>.from(json['connectedUsers']) 
          : null,
    );
  }
}