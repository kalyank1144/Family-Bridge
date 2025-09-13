import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../providers/auth_providers.dart';

class AuthService {
  final SupabaseClient _client;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _authBox = Hive.box(StorageKeys.authBox);

  AuthService(this._client);

  // Email/password for caregivers and youth
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String userType,
    Map<String, dynamic>? metadata,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'user_type': userType,
        ...?metadata,
      },
    );
    if (res.user != null) {
      await _client.from('profiles').insert({
        'id': res.user!.id,
        'email': email,
        'user_type': userType,
      });
    }
    return res;
  }

  Future<AuthResponse> signInWithEmail({required String email, required String password}) async {
    final resp = await _client.auth.signInWithPassword(email: email, password: password);
    return resp;
  }

  Future<void> startEmailOtp({required String email}) async {
    await _client.auth.signInWithOtp(email: email);
  }

  // Phone auth for elders
  Future<void> signInWithPhoneOtp({required String phone}) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyPhoneOtp({required String phone, required String token}) async {
    return _client.auth.verifyOTP(type: OtpType.sms, token: token, phone: phone);
  }

  // Password reset
  Future<void> resetPasswordEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Biometric authentication
  Future<bool> canCheckBiometrics() async => _localAuth.canCheckBiometrics;

  Future<bool> authenticateBiometric({String reason = 'Authenticate to continue'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } on PlatformException {
      return false;
    }
  }

  // Trusted device registration
  Future<void> registerTrustedDevice() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final info = await DeviceInfoPlugin().deviceInfo;
    final data = info.data;
    final deviceId = (data['id'] ?? data['androidId'] ?? data['identifierForVendor'] ?? '${Random().nextInt(1<<32)}').toString();
    final deviceName = (data['model'] ?? data['utsname.machine'] ?? 'device').toString();
    await _client.from('trusted_devices').upsert({
      'user_id': user.id,
      'device_id': deviceId,
      'device_name': deviceName,
    }, onConflict: 'user_id,device_id');
    await _authBox.put('trusted_device_id', deviceId);
  }

  bool get isLockedOut {
    final attempts = (_authBox.get('failed_attempts') ?? 0) as int;
    final until = _authBox.get('lockout_until') as String?;
    if (until != null) {
      final dt = DateTime.tryParse(until);
      if (dt != null && DateTime.now().isBefore(dt)) return true;
    }
    return attempts >= 5;
  }

  void recordFailedAttempt() {
    final attempts = (_authBox.get('failed_attempts') ?? 0) as int;
    final next = attempts + 1;
    _authBox.put('failed_attempts', next);
    if (next >= 5) {
      _authBox.put('lockout_until', DateTime.now().add(const Duration(minutes: 15)).toIso8601String());
    }
  }

  void resetFailedAttempts() {
    _authBox..delete('failed_attempts')..delete('lockout_until');
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.watch(supabaseProvider)));