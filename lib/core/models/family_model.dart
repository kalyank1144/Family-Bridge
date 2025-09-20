enum FamilyRole { primaryCaregiver, secondaryCaregiver, elder, youth }

enum PermissionLevel { owner, admin, member, viewer }

class FamilyGroup {
  final String id;
  final String name;
  final String code;
  final String createdBy;
  final DateTime createdAt;

  const FamilyGroup({
    required this.id,
    required this.name,
    required this.code,
    required this.createdBy,
    required this.createdAt,
  });

  factory FamilyGroup.fromJson(Map<String, dynamic> json) => FamilyGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };
}

class FamilyMemberLink {
  final String familyId;
  final String userId;
  final FamilyRole role;
  final PermissionLevel permissions;
  final DateTime joinedAt;

  const FamilyMemberLink({
    required this.familyId,
    required this.userId,
    required this.role,
    required this.permissions,
    required this.joinedAt,
  });

  factory FamilyMemberLink.fromJson(Map<String, dynamic> json) => FamilyMemberLink(
        familyId: json['family_id'] as String,
        userId: json['user_id'] as String,
        role: FamilyRole.values.firstWhere(
          (e) => e.name == (json['role'] as String? ?? 'member').replaceAll('-', ''),
          orElse: () => FamilyRole.youth,
        ),
        permissions: PermissionLevel.values.firstWhere(
          (e) => e.name == (json['permissions'] as String? ?? 'member'),
          orElse: () => PermissionLevel.member,
        ),
        joinedAt: DateTime.parse(json['joined_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'family_id': familyId,
        'user_id': userId,
        'role': role.name,
        'permissions': permissions.name,
        'joined_at': joinedAt.toIso8601String(),
      };
}

class FamilyInvite {
  final String id;
  final String familyId;
  final String email;
  final String role; // string for cross-compat
  final String code;
  final DateTime expiresAt;
  final bool accepted;

  const FamilyInvite({
    required this.id,
    required this.familyId,
    required this.email,
    required this.role,
    required this.code,
    required this.expiresAt,
    this.accepted = false,
  });

  factory FamilyInvite.fromJson(Map<String, dynamic> json) => FamilyInvite(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        code: json['code'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        accepted: json['accepted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'email': email,
        'role': role,
        'code': code,
        'expires_at': expiresAt.toIso8601String(),
        'accepted': accepted,
      };
}
