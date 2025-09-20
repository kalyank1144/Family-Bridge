import 'package:flutter/material.dart';

enum UserRole { elder, caregiver, youth }

class AccessibilityPrefs {
  final bool largeText;
  final bool highContrast;
  final bool voiceGuidance;
  final bool biometricEnabled;

  const AccessibilityPrefs({
    this.largeText = false,
    this.highContrast = false,
    this.voiceGuidance = true,
    this.biometricEnabled = false,
  });

  factory AccessibilityPrefs.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AccessibilityPrefs();
    return AccessibilityPrefs(
      largeText: json['large_text'] as bool? ?? false,
      highContrast: json['high_contrast'] as bool? ?? false,
      voiceGuidance: json['voice_guidance'] as bool? ?? true,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'large_text': largeText,
        'high_contrast': highContrast,
        'voice_guidance': voiceGuidance,
        'biometric_enabled': biometricEnabled,
      };
}

class ConsentInfo {
  final DateTime? termsAcceptedAt;
  final DateTime? privacyAcceptedAt;
  final bool shareHealthDataWithCaregivers;

  const ConsentInfo({
    this.termsAcceptedAt,
    this.privacyAcceptedAt,
    this.shareHealthDataWithCaregivers = true,
  });

  factory ConsentInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ConsentInfo();
    return ConsentInfo(
      termsAcceptedAt: json['terms_accepted_at'] != null
          ? DateTime.tryParse(json['terms_accepted_at'] as String)
          : null,
      privacyAcceptedAt: json['privacy_accepted_at'] != null
          ? DateTime.tryParse(json['privacy_accepted_at'] as String)
          : null,
      shareHealthDataWithCaregivers:
          json['share_health_with_caregivers'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'terms_accepted_at': termsAcceptedAt?.toIso8601String(),
        'privacy_accepted_at': privacyAcceptedAt?.toIso8601String(),
        'share_health_with_caregivers': shareHealthDataWithCaregivers,
      };
}

class EmergencyContactBasic {
  final String name;
  final String relationship;
  final String phone;

  const EmergencyContactBasic({
    required this.name,
    required this.relationship,
    required this.phone,
  });

  factory EmergencyContactBasic.fromJson(Map<String, dynamic> json) =>
      EmergencyContactBasic(
        name: json['name'] as String,
        relationship: (json['relationship'] as String?) ?? '',
        phone: json['phone'] as String,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'relationship': relationship,
        'phone': phone,
      };
}

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final DateTime? dateOfBirth;
  final String? photoUrl;
  final List<String> medicalConditions;
  final List<EmergencyContactBasic> emergencyContacts;
  final AccessibilityPrefs accessibility;
  final ConsentInfo consent;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.dateOfBirth,
    this.photoUrl,
    this.medicalConditions = const [],
    this.emergencyContacts = const [],
    this.accessibility = const AccessibilityPrefs(),
    this.consent = const ConsentInfo(),
  });

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years -= 1;
    }
    return years;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String?) ?? 'elder';
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == roleStr,
        orElse: () => UserRole.elder,
      ),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      photoUrl: json['photo_url'] as String?,
      medicalConditions: List<String>.from(json['medical_conditions'] ?? const []),
      emergencyContacts: (json['emergency_contacts'] as List<dynamic>? ?? const [])
          .map((e) => EmergencyContactBasic.fromJson(e as Map<String, dynamic>))
          .toList(),
      accessibility: AccessibilityPrefs.fromJson(
          json['accessibility'] as Map<String, dynamic>?),
      consent: ConsentInfo.fromJson(json['consent'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'role': role.name,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'photo_url': photoUrl,
        'medical_conditions': medicalConditions,
        'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
        'accessibility': accessibility.toJson(),
        'consent': consent.toJson(),
      };
}
