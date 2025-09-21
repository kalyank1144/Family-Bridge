import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String email;

  @HiveField(2)
  UserType userType;

  @HiveField(3)
  String firstName;

  @HiveField(4)
  String lastName;

  @HiveField(5)
  String? phoneNumber;

  @HiveField(6)
  String? profilePhotoUrl;

  @HiveField(7)
  DateTime? dateOfBirth;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  bool isActive;

  @HiveField(11)
  String preferredLanguage;

  @HiveField(12)
  Map<String, dynamic>? accessibilitySettings;

  UserModel({
    required this.id,
    required this.email,
    required this.userType,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profilePhotoUrl,
    this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.preferredLanguage = 'en',
    this.accessibilitySettings,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'user_type': userType.toString().split('.').last,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'profile_photo_url': profilePhotoUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'preferred_language': preferredLanguage,
      'accessibility_settings': accessibilitySettings,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      userType: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == json['user_type'],
        orElse: () => UserType.elder,
      ),
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      accessibilitySettings: json['accessibility_settings'] as Map<String, dynamic>?,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    UserType? userType,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profilePhotoUrl,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? preferredLanguage,
    Map<String, dynamic>? accessibilitySettings,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      accessibilitySettings: accessibilitySettings ?? this.accessibilitySettings,
    );
  }
}

@HiveType(typeId: 1)
enum UserType {
  @HiveField(0)
  elder,
  
  @HiveField(1)
  caregiver,
  
  @HiveField(2)
  youth,
}

@HiveType(typeId: 2)
enum FamilyRole {
  @HiveField(0)
  elder,
  
  @HiveField(1)
  primaryCaregiver,
  
  @HiveField(2)
  secondaryCaregiver,
  
  @HiveField(3)
  youth,
}