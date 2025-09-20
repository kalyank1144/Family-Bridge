import 'package:flutter/material.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../lib/core/services/auth_service.dart';
import '../../lib/core/services/encryption_service.dart';
import '../../lib/core/services/storage_service.dart';
import '../../lib/core/services/voice_service.dart';
import '../../lib/core/services/gamification_service.dart';
import '../../lib/core/services/hipaa_audit_service.dart';

import '../../lib/features/caregiver/services/health_data_service.dart';
import '../../lib/features/caregiver/services/appointments_service.dart';
import '../../lib/features/caregiver/services/notification_service.dart';
import '../../lib/features/chat/services/chat_service.dart';
import '../../lib/features/elder/services/medication_service.dart';
import '../../lib/features/elder/services/daily_checkin_service.dart';

import '../../lib/repositories/offline_first/base_offline_repository.dart';
import '../../lib/services/network/network_manager.dart';
import '../../lib/services/sync/data_sync_service.dart';

@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  SupabaseAuthClient,
  SharedPreferences,
  http.Client,
  Connectivity,
  
  AuthService,
  EncryptionService,
  StorageService,
  VoiceService,
  GamificationService,
  HipaaAuditService,
  
  HealthDataService,
  AppointmentsService,
  NotificationService,
  ChatService,
  MedicationService,
  DailyCheckInService,
  
  NetworkManager,
  DataSyncService,
], customMocks: [
  MockSpec<NavigatorObserver>(
    returnNullOnMissingStub: true,
  ),
  MockSpec<BuildContext>(
    returnNullOnMissingStub: true,
  ),
])
void main() {}

class MockSupabaseClient extends Mock implements SupabaseClient {
  @override
  final auth = MockGoTrueClient();
  
  @override
  String get realtimeUrl => 'wss://example.supabase.co';
  
  @override
  String get restUrl => 'https://example.supabase.co';
}

class MockGoTrueClient extends Mock implements GoTrueClient {
  User? _currentUser;
  Session? _currentSession;
  
  void setUser(User? user) {
    _currentUser = user;
  }
  
  void setSession(Session? session) {
    _currentSession = session;
  }
  
  @override
  User? get currentUser => _currentUser;
  
  @override
  Session? get currentSession => _currentSession;
  
  @override
  Stream<AuthState> get onAuthStateChange => Stream.value(
        AuthState(
          event: AuthChangeEvent.signedIn,
          session: _currentSession,
        ),
      );
}

class FakeUser extends Fake implements User {
  @override
  final String id = 'test-user-123';
  
  @override
  final String email = 'test@example.com';
  
  @override
  final Map<String, dynamic> userMetadata = {
    'name': 'Test User',
    'role': 'caregiver',
  };
  
  @override
  final DateTime createdAt = DateTime.now();
  
  @override
  final DateTime? emailConfirmedAt = DateTime.now();
  
  @override
  final DateTime? lastSignInAt = DateTime.now();
}

class FakeSession extends Fake implements Session {
  @override
  final String accessToken = 'fake-access-token';
  
  @override
  final String refreshToken = 'fake-refresh-token';
  
  @override
  final int expiresIn = 3600;
  
  @override
  final String tokenType = 'bearer';
  
  @override
  final User user = FakeUser();
  
  @override
  DateTime get expiresAt => DateTime.now().add(Duration(seconds: expiresIn));
}