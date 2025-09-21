import 'package:hive/hive.dart';
import 'user_model.dart';

part 'family_model.g.dart';

@HiveType(typeId: 20)
class Family extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String familyName;

  @HiveField(2)
  String createdBy;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  String familyCode;

  @HiveField(6)
  Map<String, dynamic>? privacySettings;

  @HiveField(7)
  bool isActive;

  Family({
    required this.id,
    required this.familyName,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.familyCode,
    this.privacySettings,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_name': familyName,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'family_code': familyCode,
      'privacy_settings': privacySettings,
      'is_active': isActive,
    };
  }

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as String,
      familyName: json['family_name'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      familyCode: json['family_code'] as String,
      privacySettings: json['privacy_settings'] as Map<String, dynamic>?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Family copyWith({
    String? id,
    String? familyName,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? familyCode,
    Map<String, dynamic>? privacySettings,
    bool? isActive,
  }) {
    return Family(
      id: id ?? this.id,
      familyName: familyName ?? this.familyName,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      familyCode: familyCode ?? this.familyCode,
      privacySettings: privacySettings ?? this.privacySettings,
      isActive: isActive ?? this.isActive,
    );
  }
}

@HiveType(typeId: 21)
class FamilyMember extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String familyId;

  @HiveField(2)
  String userId;

  @HiveField(3)
  FamilyRole role;

  @HiveField(4)
  Map<String, dynamic>? permissions;

  @HiveField(5)
  DateTime joinedAt;

  @HiveField(6)
  bool isActive;

  @HiveField(7)
  String? nickname;

  @HiveField(8)
  String? relationship;

  FamilyMember({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.role,
    this.permissions,
    required this.joinedAt,
    this.isActive = true,
    this.nickname,
    this.relationship,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'role': role.toString().split('.').last,
      'permissions': permissions,
      'joined_at': joinedAt.toIso8601String(),
      'is_active': isActive,
      'nickname': nickname,
      'relationship': relationship,
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      userId: json['user_id'] as String,
      role: FamilyRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => FamilyRole.youth,
      ),
      permissions: json['permissions'] as Map<String, dynamic>?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      nickname: json['nickname'] as String?,
      relationship: json['relationship'] as String?,
    );
  }

  FamilyMember copyWith({
    String? id,
    String? familyId,
    String? userId,
    FamilyRole? role,
    Map<String, dynamic>? permissions,
    DateTime? joinedAt,
    bool? isActive,
    String? nickname,
    String? relationship,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      nickname: nickname ?? this.nickname,
      relationship: relationship ?? this.relationship,
    );
  }
}

@HiveType(typeId: 22)
class FamilyInvitation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String familyId;

  @HiveField(2)
  String invitedBy;

  @HiveField(3)
  String? invitedEmail;

  @HiveField(4)
  String? invitedPhone;

  @HiveField(5)
  FamilyRole suggestedRole;

  @HiveField(6)
  String invitationCode;

  @HiveField(7)
  DateTime expiresAt;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  InvitationStatus status;

  @HiveField(10)
  String? acceptedBy;

  @HiveField(11)
  DateTime? acceptedAt;

  FamilyInvitation({
    required this.id,
    required this.familyId,
    required this.invitedBy,
    this.invitedEmail,
    this.invitedPhone,
    required this.suggestedRole,
    required this.invitationCode,
    required this.expiresAt,
    required this.createdAt,
    this.status = InvitationStatus.pending,
    this.acceptedBy,
    this.acceptedAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'invited_by': invitedBy,
      'invited_email': invitedEmail,
      'invited_phone': invitedPhone,
      'suggested_role': suggestedRole.toString().split('.').last,
      'invitation_code': invitationCode,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'accepted_by': acceptedBy,
      'accepted_at': acceptedAt?.toIso8601String(),
    };
  }

  factory FamilyInvitation.fromJson(Map<String, dynamic> json) {
    return FamilyInvitation(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      invitedBy: json['invited_by'] as String,
      invitedEmail: json['invited_email'] as String?,
      invitedPhone: json['invited_phone'] as String?,
      suggestedRole: FamilyRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['suggested_role'],
        orElse: () => FamilyRole.youth,
      ),
      invitationCode: json['invitation_code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      status: InvitationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => InvitationStatus.pending,
      ),
      acceptedBy: json['accepted_by'] as String?,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
    );
  }
}

@HiveType(typeId: 23)
enum InvitationStatus {
  @HiveField(0)
  pending,
  
  @HiveField(1)
  accepted,
  
  @HiveField(2)
  declined,
  
  @HiveField(3)
  expired,
  
  @HiveField(4)
  cancelled,
}