import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  Future<AuthResponse> signUpWithEmail({required String email, required String password, required String userType}) async {
    final res = await _client.auth.signUp(email: email, password: password);
    if (res.user != null) {
      await _client.from('profiles').insert({
        'id': res.user!.id,
        'email': email,
        'user_type': userType,
      });
    }
    return res;
  }

  Future<AuthResponse> signInWithEmail({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithPhoneOtp({required String phone}) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<void> verifyPhoneOtp({required String phone, required String token}) async {
    await _client.auth.verifyOTP(type: OtpType.sms, token: token, phone: phone);
  }

  Future<void> signOut() => _client.auth.signOut();
}
