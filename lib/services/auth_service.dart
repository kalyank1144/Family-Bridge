import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:family_bridge/services/supabase_service.dart';
import 'package:family_bridge/models/user_model.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  UserModel? _userProfile;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _init();
  }

  void _init() {
    _currentUser = SupabaseService.currentUser;
    if (_currentUser != null) {
      _loadUserProfile();
    }
    
    SupabaseService.authStateChanges.listen((event) {
      _currentUser = event.session?.user;
      if (_currentUser != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select()
          .eq('id', _currentUser!.id)
          .single();
      
      _userProfile = UserModel.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'user_type': userType.toString().split('.').last,
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error signing up: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (e) {
      debugPrint('Error signing in: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
