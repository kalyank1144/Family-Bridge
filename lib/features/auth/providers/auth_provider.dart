import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/push_notification_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated, onboarding }

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  final _auth = AuthService.instance;
  final _supabase = Supabase.instance.client;

  AuthStatus _status = AuthStatus.unknown;
  Session? _session;
  UserProfile? _profile;
  UserRole? _selectedRole; // from onboarding selection

  Timer? _inactivityTimer;
  Duration inactivityTimeout = const Duration(minutes: 20);

  AuthStatus get status => _status;
  Session? get session => _session;
  UserProfile? get profile => _profile;
  UserRole? get selectedRole => _selectedRole;

  AuthProvider() {
    WidgetsBinding.instance.addObserver(this);
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      _session = session;
      if (event == AuthChangeEvent.signedIn && session != null) {
        await _loadProfile();
        _status = AuthStatus.authenticated;
        _startInactivityTimer();
      } else if (event == AuthChangeEvent.signedOut) {
        _status = AuthStatus.unauthenticated;
        _profile = null;
        _cancelInactivityTimer();
      }
      notifyListeners();
    });

    // Initialize current session
    _session = _supabase.auth.currentSession;
    if (_session != null) {
      _status = AuthStatus.authenticated;
      _loadProfile();
      _startInactivityTimer();
    } else {
      _status = AuthStatus.unauthenticated;
    }
  }

  Future<void> _loadProfile() async {
    _profile = await _auth.getCurrentProfile();
    if (_profile != null) {
      await PushNotificationService.instance.syncUser(
        userId: _profile!.id,
        role: _profile!.role.name,
      );
    }
  }

  void setSelectedRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    DateTime? dob,
  }) async {
    final res = await _auth.signUpWithEmail(
      email: email,
      password: password,
      role: role,
      name: name,
      dateOfBirth: dob,
    );

    // Supabase may require email verification; status remains unauthenticated until verified
    if (res.user != null && res.session != null) {
      _status = AuthStatus.authenticated;
      await _loadProfile();
      _startInactivityTimer();
      notifyListeners();
    }
    return res;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final res = await _auth.signInWithEmail(email: email, password: password);
    if (res.session != null) {
      _status = AuthStatus.authenticated;
      await _loadProfile();
      _startInactivityTimer();
      notifyListeners();
    }
    return res;
  }

  Future<void> signInWithGoogle() async {
    await _auth.signInWithGoogle();
  }

  Future<void> signInWithApple() async {
    await _auth.signInWithApple();
  }

  Future<void> signOut({bool allDevices = false}) async {
    await _auth.signOut(allDevices: allDevices);
    _status = AuthStatus.unauthenticated;
    _profile = null;
    _session = null;
    _cancelInactivityTimer();
    notifyListeners();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, () async {
      await signOut();
    });
  }

  void bumpActivity() {
    if (_status == AuthStatus.authenticated) {
      _startInactivityTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      bumpActivity();
    }
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  String roleBasedHomePath() {
    final r = _profile?.role ?? _selectedRole ?? UserRole.elder;
    switch (r) {
      case UserRole.elder:
        return '/elder';
      case UserRole.caregiver:
        return '/caregiver';
      case UserRole.youth:
        return '/caregiver';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelInactivityTimer();
    super.dispose();
  }
}
