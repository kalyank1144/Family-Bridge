import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_client.dart';

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signInWithEmail({required String email, required String password}) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail({required String email, required String password, Map<String, dynamic>? data}) async {
    return _client.auth.signUp(email: email, password: password, data: data);
  }

  Future<void> signInWithPhone({required String phone}) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<void> verifyPhoneOtp({required String phone, required String token}) async {
    await _client.auth.verifyOTP(token: token, type: OtpType.sms, phone: phone);
  }

  Future<void> signOut() => _client.auth.signOut();
}
