import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../../models/sync/sync_item.dart';
import '../../models/hive/user_model.dart';
import '../../models/hive/health_data_model.dart';
import '../../models/hive/medication_model.dart';
import '../../models/hive/message_model.dart';
import '../../models/hive/appointment_model.dart';
import '../offline/offline_manager.dart';
import '../network/network_manager.dart';
import 'sync_queue.dart';
import 'conflict_resolver.dart';

class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  final Logger _logger = Logger();
  final SupabaseClient _supabase = Supabase.instance.client;
  final SyncQueue _syncQueue = SyncQueue();
  final ConflictResolver _conflictResolver = ConflictResolver();
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  final StreamController<SyncProgress> _progressController = 
      StreamController<SyncProgress>.broadcast();
  
  Stream<SyncProgress> get progressStream => _progressController.stream;

  // Priority definitions
  static const Map<String, SyncPriority> _tablePriorities = {
    'emergency_alerts': SyncPriority.critical,
    'medication_confirmations': SyncPriority.critical,
    'health_alerts': SyncPriority.critical,
    'fall_detection': SyncPriority.critical,
    'messages': SyncPriority.high,
    'health_data': SyncPriority.high,
    'daily_checkins': SyncPriority.high,
    'appointments': SyncPriority.high,
    'photos': SyncPriority.normal,
    'stories': SyncPriority.normal,
    'game_scores': SyncPriority.normal,
    'activity_data': SyncPriority.normal,
    'analytics': SyncPriority.low,
    'usage_stats': SyncPriority.low,
    'preferences': SyncPriority.low,
  };

  Future<void> initialize() async {
    // Start periodic sync
    _startPeriodicSync();
    
    // Listen to network changes
    NetworkManager().connectionStream.listen((isOnline) {
      if (isOnline) {
        _logger.i('Network connected, triggering sync');
        performFullSync();
      }
    });
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (NetworkManager().isOnline && !_isSyncing) {
        performIncrementalSync();
      }
    });
  }

  Future<void> performFullSync() async {
    if (_isSyncing) {
      _logger.d('Sync already in progress');
      return;
    }
    
    if (!NetworkManager().isOnline) {
      _logger.d('Cannot sync - offline');
      return;
    }
    
    _isSyncing = true;
    _updateProgress(SyncProgress(
      phase: SyncPhase.starting,
      totalItems: 0,
      syncedItems: 0,
    ));
    
    try {
      _logger.i('Starting full sync');
      
      // Process sync queue first
      await _syncQueue.processQueue();
      
      // Then sync all tables
      await _syncUsers();
      await _syncHealthData();
      await _syncMedications();
      await _syncMessages();
      await _syncAppointments();
      
      _updateProgress(SyncProgress(
        phase: SyncPhase.completed,
        totalItems: 0,
        syncedItems: 0,
      ));
      
      _logger.i('Full sync completed');
      
    } catch (e) {
      _logger.e('Full sync failed', error: e);
      _updateProgress(SyncProgress(
        phase: SyncPhase.failed,
        totalItems: 0,
        syncedItems: 0,
        error: e.toString(),
      ));
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> performIncrementalSync() async {
    if (_isSyncing) return;
    if (!NetworkManager().isOnline) return;
    
    _isSyncing = true;
    
    try {
      _logger.d('Starting incremental sync');
      
      // Get last sync time for each table
      final box = await Hive.openBox('sync_metadata');
      
      await _deltaSync('users', box.get('last_sync_users'));
      await _deltaSync('health_data', box.get('last_sync_health'));
      await _deltaSync('medications', box.get('last_sync_medications'));
      await _deltaSync('messages', box.get('last_sync_messages'));
      await _deltaSync('appointments', box.get('last_sync_appointments'));
      
      _logger.d('Incremental sync completed');
      
    } catch (e) {
      _logger.e('Incremental sync failed', error: e);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _deltaSync(String table, DateTime? lastSync) async {
    try {
      final query = _supabase.from(table).select();
      
      if (lastSync != null) {
        query.gte('updated_at', lastSync.toIso8601String());
      }
      
      final changes = await query;
      
      if (changes.isEmpty) {
        _logger.d('No changes for $table');
        return;
      }
      
      _logger.d('Found ${changes.length} changes for $table');
      
      // Apply changes based on table
      await _applyChanges(table, changes);
      
      // Update last sync time
      final box = await Hive.openBox('sync_metadata');
      await box.put('last_sync_$table', DateTime.now());
      
    } catch (e) {
      _logger.e('Delta sync failed for $table', error: e);
    }
  }

  Future<void> _applyChanges(String table, List<dynamic> changes) async {
    switch (table) {
      case 'users':
        await _applyUserChanges(changes);
        break;
      case 'health_data':
        await _applyHealthDataChanges(changes);
        break;
      case 'medications':
        await _applyMedicationChanges(changes);
        break;
      case 'messages':
        await _applyMessageChanges(changes);
        break;
      case 'appointments':
        await _applyAppointmentChanges(changes);
        break;
    }
  }

  Future<void> _syncUsers() async {
    _updateProgress(SyncProgress(
      phase: SyncPhase.syncingUsers,
      totalItems: 0,
      syncedItems: 0,
    ));
    
    try {
      final remoteUsers = await _supabase
          .from('users')
          .select()
          .order('updated_at', ascending: false);
      
      for (final userData in remoteUsers) {
        final user = UserModel.fromJson(userData);
        user.lastSynced = DateTime.now();
        await OfflineManager.saveUser(user);
      }
      
      _logger.d('Synced ${remoteUsers.length} users');
      
    } catch (e) {
      _logger.e('Failed to sync users', error: e);
    }
  }

  Future<void> _syncHealthData() async {
    _updateProgress(SyncProgress(
      phase: SyncPhase.syncingHealth,
      totalItems: 0,
      syncedItems: 0,
    ));
    
    try {
      // Get current user ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      // Sync last 30 days of health data
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      final remoteData = await _supabase
          .from('health_data')
          .select()
          .eq('user_id', userId)
          .gte('recorded_at', cutoffDate.toIso8601String())
          .order('recorded_at', ascending: false);
      
      for (final data in remoteData) {
        final healthData = HealthDataModel.fromJson(data);
        healthData.isSynced = true;
        healthData.lastSynced = DateTime.now();
        await OfflineManager.saveHealthData(healthData);
      }
      
      _logger.d('Synced ${remoteData.length} health records');
      
    } catch (e) {
      _logger.e('Failed to sync health data', error: e);
    }
  }

  Future<void> _syncMedications() async {
    _updateProgress(SyncProgress(
      phase: SyncPhase.syncingMedications,
      totalItems: 0,
      syncedItems: 0,
    ));
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      final remoteMeds = await _supabase
          .from('medications')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      
      for (final medData in remoteMeds) {
        final medication = MedicationModel.fromJson(medData);
        medication.lastSynced = DateTime.now();
        await OfflineManager.saveMedication(medication);
      }
      
      _logger.d('Synced ${remoteMeds.length} medications');
      
    } catch (e) {
      _logger.e('Failed to sync medications', error: e);
    }
  }

  Future<void> _syncMessages() async {
    _updateProgress(SyncProgress(
      phase: SyncPhase.syncingMessages,
      totalItems: 0,
      syncedItems: 0,
    ));
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      // Sync last 100 messages
      final remoteMessages = await _supabase
          .from('messages')
          .select()
          .or('sender_id.eq.$userId,recipient_id.eq.$userId')
          .order('timestamp', ascending: false)
          .limit(100);
      
      for (final msgData in remoteMessages) {
        final message = MessageModel.fromJson(msgData);
        message.isSynced = true;
        await OfflineManager.saveMessage(message);
      }
      
      _logger.d('Synced ${remoteMessages.length} messages');
      
    } catch (e) {
      _logger.e('Failed to sync messages', error: e);
    }
  }

  Future<void> _syncAppointments() async {
    _updateProgress(SyncProgress(
      phase: SyncPhase.syncingAppointments,
      totalItems: 0,
      syncedItems: 0,
    ));
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      // Sync upcoming appointments
      final now = DateTime.now();
      
      final remoteAppointments = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .gte('date_time', now.toIso8601String())
          .order('date_time', ascending: true);
      
      for (final apptData in remoteAppointments) {
        final appointment = AppointmentModel.fromJson(apptData);
        appointment.isSynced = true;
        appointment.lastSynced = DateTime.now();
        await OfflineManager.saveAppointment(appointment);
      }
      
      _logger.d('Synced ${remoteAppointments.length} appointments');
      
    } catch (e) {
      _logger.e('Failed to sync appointments', error: e);
    }
  }

  Future<void> _applyUserChanges(List<dynamic> changes) async {
    for (final change in changes) {
      final user = UserModel.fromJson(change);
      user.lastSynced = DateTime.now();
      await OfflineManager.saveUser(user);
    }
  }

  Future<void> _applyHealthDataChanges(List<dynamic> changes) async {
    for (final change in changes) {
      final data = HealthDataModel.fromJson(change);
      data.isSynced = true;
      data.lastSynced = DateTime.now();
      await OfflineManager.saveHealthData(data);
    }
  }

  Future<void> _applyMedicationChanges(List<dynamic> changes) async {
    for (final change in changes) {
      final med = MedicationModel.fromJson(change);
      med.lastSynced = DateTime.now();
      await OfflineManager.saveMedication(med);
    }
  }

  Future<void> _applyMessageChanges(List<dynamic> changes) async {
    for (final change in changes) {
      final msg = MessageModel.fromJson(change);
      msg.isSynced = true;
      await OfflineManager.saveMessage(msg);
    }
  }

  Future<void> _applyAppointmentChanges(List<dynamic> changes) async {
    for (final change in changes) {
      final appt = AppointmentModel.fromJson(change);
      appt.isSynced = true;
      appt.lastSynced = DateTime.now();
      await OfflineManager.saveAppointment(appt);
    }
  }

  void _updateProgress(SyncProgress progress) {
    _progressController.add(progress);
  }

  SyncPriority getPriorityForTable(String table) {
    return _tablePriorities[table] ?? SyncPriority.normal;
  }

  Future<void> syncCriticalData() async {
    // Sync only critical priority items
    final criticalTables = _tablePriorities.entries
        .where((e) => e.value == SyncPriority.critical)
        .map((e) => e.key)
        .toList();
    
    for (final table in criticalTables) {
      await _deltaSync(table, null);
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _progressController.close();
  }
}

enum SyncPhase {
  starting,
  syncingUsers,
  syncingHealth,
  syncingMedications,
  syncingMessages,
  syncingAppointments,
  processingQueue,
  completed,
  failed,
}

class SyncProgress {
  final SyncPhase phase;
  final int totalItems;
  final int syncedItems;
  final String? error;

  SyncProgress({
    required this.phase,
    required this.totalItems,
    required this.syncedItems,
    this.error,
  });

  double get progress => 
      totalItems > 0 ? syncedItems / totalItems : 0.0;

  String get phaseDescription {
    switch (phase) {
      case SyncPhase.starting:
        return 'Starting sync...';
      case SyncPhase.syncingUsers:
        return 'Syncing users...';
      case SyncPhase.syncingHealth:
        return 'Syncing health data...';
      case SyncPhase.syncingMedications:
        return 'Syncing medications...';
      case SyncPhase.syncingMessages:
        return 'Syncing messages...';
      case SyncPhase.syncingAppointments:
        return 'Syncing appointments...';
      case SyncPhase.processingQueue:
        return 'Processing sync queue...';
      case SyncPhase.completed:
        return 'Sync completed';
      case SyncPhase.failed:
        return 'Sync failed';
    }
  }
}