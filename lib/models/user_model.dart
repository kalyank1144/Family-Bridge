enum UserType {
  elder,
  caregiver,
  youth,
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserType userType;
  final String? familyId;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.familyId,
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      userType: _parseUserType(json['user_type'] as String),
      familyId: json['family_id'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'user_type': userType.toString().split('.').last,
      'family_id': familyId,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static UserType _parseUserType(String type) {
    switch (type.toLowerCase()) {
      case 'elder':
        return UserType.elder;
      case 'caregiver':
        return UserType.caregiver;
      case 'youth':
        return UserType.youth;
      default:
        return UserType.caregiver;
    }
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserType? userType,
    String? familyId,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      familyId: familyId ?? this.familyId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
