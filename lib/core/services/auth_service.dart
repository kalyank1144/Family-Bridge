import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:family_bridge/core/models/family_model.dart';
import 'package:family_bridge/core/models/user_model.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _supabase = Supabase.instance.client;
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  static const _kBiometricEnabled = 'biometric_enabled';
  static const _kLastEmail = 'last_email';
  static const _kOfflineUnlock = 'offline_unlock';

  Future<void> initialize() async {}

  Future<bool> isBiometricSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _kBiometricEnabled, value: enabled ? '1' : '0');
  }

  Future<bool> getBiometricEnabled() async {
    final v = await _storage.read(key: _kBiometricEnabled);
    return v == '1';
    
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required UserRole role,
    required String name,
    DateTime? dateOfBirth,
  }) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': role.name,
        'name': name,
      },
      emailRedirectTo: kIsWeb ? null : null,
    );

    await _storage.write(key: _kLastEmail, value: email);

    final user = res.user;
    if (user != null) {
      try {
        await _supabase.from('users').upsert({
          'id': user.id,
          'name': name,
          'role': role.name,
          'date_of_birth': dateOfBirth?.toIso8601String(),
        });
      } catch (_) {}
    }

    return res;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _storage.write(key: _kLastEmail, value: email);
    return res;
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      Provider.google,
      redirectTo: null,
      queryParams: {
        'access_type': 'offline',
        'prompt': 'consent',
      },
    );
  }

  Future<void> signInWithApple() async {
    await _supabase.auth.signInWithOAuth(
      Provider.apple,
      redirectTo: null,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<bool> resetPasswordViaSecurityAnswer({
    required String email,
    required String answer,
  }) async {
    // Requires SQL function installed via migration. See supabase/migrations.
    final res = await _supabase.rpc('reset_password_via_security_answer', params: {
      'p_email': email,
      'p_answer': answer,
    });
    return (res as Map?)?['ok'] == true;
  }

  Future<void> signOut({bool allDevices = false}) async {
    try {
      await _supabase.auth.signOut(
        scope: allDevices ? SignOutScope.global : SignOutScope.local,
      );
    } finally {
      await _storage.delete(key: _kOfflineUnlock);
    }
  }

  Future<UserProfile?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final row = await _supabase
        .from('users')
        .select('id, name, role, phone, date_of_birth')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;

    // Merge with auth email + extended profile if present
    final ext = await _supabase
        .from('user_profiles')
        .select('photo_url, medical_conditions, accessibility, consent')
        .eq('user_id', user.id)
        .maybeSingle();

    return UserProfile(
      id: row['id'] as String,
      email: user.email ?? '',
      name: (row['name'] as String?) ?? '',
      phone: row['phone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == ((row['role'] as String?) ?? 'elder'),
        orElse: () => UserRole.elder,
      ),
      dateOfBirth: row['date_of_birth'] != null
          ? DateTime.tryParse(row['date_of_birth'] as String)
          : null,
      photoUrl: ext?['photo_url'] as String?,
      medicalConditions:
          List<String>.from(ext?['medical_conditions'] ?? const []),
      emergencyContacts: const [],
      accessibility: AccessibilityPrefs.fromJson(
        (ext?['accessibility'] as Map?)?.cast<String, dynamic>(),
      ),
      consent: ConsentInfo.fromJson(
        (ext?['consent'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }

  Future<void> upsertExtendedProfile(UserProfile profile) async {
    final userId = profile.id;
    await _supabase.from('user_profiles').upsert({
      'user_id': userId,
      'photo_url': profile.photoUrl,
      'medical_conditions': profile.medicalConditions,
      'accessibility': profile.accessibility.toJson(),
      'consent': profile.consent.toJson(),
    });
  }

  Future<FamilyGroup> createFamilyGroup({
    required String name,
  }) async {
    final uid = _supabase.auth.currentUser!.id;
    final row = await _supabase
        .from('family_groups')
        .insert({
          'name': name,
          'created_by': uid,
        })
        .select()
        .single();

    // Server generates unique code
    return FamilyGroup.fromJson(row as Map<String, dynamic>);
  }

  Future<void> joinFamilyByCode({
    required String code,
    required FamilyRole role,
  }) async {
    final uid = _supabase.auth.currentUser!.id;
    // Use RPC to validate and join
    await _supabase.rpc('join_family_by_code', params: {
      'p_code': code,
      'p_role': role.name,
    });

    // Backend should insert into family_members with correct permissions
  }

  Future<List<Map<String, dynamic>>> listFamilyMembers(String familyId) async {
    final rows = await _supabase
        .from('family_members_view')
        .select()
        .eq('family_id', familyId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> inviteFamilyMember({
    required String familyId,
    required String email,
    required FamilyRole role,
  }) async {
    await _supabase.from('family_invites').insert({
      'family_id': familyId,
      'email': email,
      'role': role.name,
    });
  }

  Future<void> removeFamilyMember({
    required String familyId,
    required String userId,
  }) async {
    await _supabase
        .from('family_members')
        .delete()
        .eq('family_id', familyId)
        .eq('user_id', userId);
  }

  // Offline unlock with biometrics if an active session is cached
  Future<bool> unlockOfflineWithBiometrics() async {
    final isSupported = await isBiometricSupported();
    final enabled = await getBiometricEnabled();
    if (!isSupported || !enabled) return false;

    final didAuth = await _localAuth.authenticate(
      localizedReason: 'Authenticate to access FamilyBridge',
      options: const AuthenticationOptions(biometricOnly: true),
    );

    if (didAuth) {
      await _storage.write(key: _kOfflineUnlock, value: '1');
      return true;
    }
    return false;
  }

  Future<bool> hasOfflineUnlock() async {
    return (await _storage.read(key: _kOfflineUnlock)) == '1';
  }

  Future<String?> getLastEmail() async => _storage.read(key: _kLastEmail);
}
