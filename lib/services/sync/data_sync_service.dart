import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/hive/user_model.dart';
import '../../models/hive/message_model.dart';
import '../../models/hive/health_data_model.dart';
import '../../models/hive/appointment_model.dart';
import '../../models/hive/medication_model.dart';
import '../network/network_manager.dart';
import 'conflict_resolver.dart';
import 'sync_queue.dart';

typedef Json = Map<String, dynamic>;

class DataSyncService {
  DataSyncService._internal();
  static final DataSyncService instance = DataSyncService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  late Box<HiveUserProfile> usersBox;
  late Box<HiveChatMessage> messagesBox;
  late Box<HiveHealthRecord> healthBox;
  late Box<HiveAppointment> appointmentsBox;
  late Box<HiveMedicationSchedule> medicationsBox;
  late Box<dynamic> metaBox; // for cursors

  bool _initialized = false;
  StreamSubscription<NetworkStatus>? _netSub;

  Future<void> initialize() async {
    try { await Hive.initFlutter(); } catch (_) {}
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HiveUserProfileAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(HiveChatMessageAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(HiveHealthRecordAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(HiveAppointmentAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(HiveMedicationScheduleAdapter());

    usersBox = await Hive.openBox<HiveUserProfile>('users');
    messagesBox = await Hive.openBox<HiveChatMessage>('messages');
    healthBox = await Hive.openBox<HiveHealthRecord>('health_records');
    appointmentsBox = await Hive.openBox<HiveAppointment>('appointments');
    medicationsBox = await Hive.openBox<HiveMedicationSchedule>('medications');
    metaBox = await Hive.openBox('sync_meta');

    await SyncQueue.instance.initialize();

    _netSub?.cancel();
    _netSub = NetworkManager.instance.statusStream.listen((status) async {
      if (status.isOnline) {
        await syncAll();
      }
    });

    _initialized = true;
  }

  Future<void> dispose() async {
    await _netSub?.cancel();
  }

  Future<void> syncAll() async {
    if (!_initialized) return;
    try {
      await _pushQueue();
      await _pullUpdates('users', usersBox);
      await _pullUpdates('messages', messagesBox);
      await _pullUpdates('health_records', healthBox);
      await _pullUpdates('appointments', appointmentsBox);
      await _pullUpdates('medications', medicationsBox);
    } catch (e, st) {
      debugPrint('Sync error: $e\n$st');
    }
  }

  Future<void> _pushQueue() async {
    final ops = SyncQueue.instance.getAll();
    for (final op in ops) {
      try {
        switch (op.type) {
          case SyncOpType.create:
          case SyncOpType.update:
            await _supabase.from(op.table).upsert(op.payload);
            break;
          case SyncOpType.delete:
            await _supabase.from(op.table).delete().eq('id', op.payload['id']);
            break;
        }
        await SyncQueue.instance.remove(op.id);
      } catch (e) {
        op.retryCount += 1;
        op.lastError = e.toString();
        await op.save();
      }
    }
  }

  Future<void> _pullUpdates<T>(String table, Box box) async {
    final lastKey = 'cursor:$table';
    final since = metaBox.get(lastKey) as String?; // ISO string
    final query = _supabase.from(table).select();
    if (since != null) {
      query.gte('updated_at', since);
    }
    // For messages, limit to recent to reduce bandwidth
    if (table == 'messages') {
      query.order('updated_at').limit(500);
    }
    final List data = await query; // throws on error
    for (final row in data.cast<Json>()) {
      switch (table) {
        case 'users':
          final model = HiveUserProfile.fromMap(row);
          await usersBox.put(model.id, model);
          break;
        case 'messages':
          final model = HiveChatMessage.fromMap(row);
          await messagesBox.put(model.id, model);
          break;
        case 'health_records':
          final model = HiveHealthRecord.fromMap(row);
          await healthBox.put(model.id, model);
          break;
        case 'appointments':
          final model = HiveAppointment.fromMap(row);
          await appointmentsBox.put(model.id, model);
          break;
        case 'medications':
          final model = HiveMedicationSchedule.fromMap(row);
          await medicationsBox.put(model.id, model);
          break;
      }
    }
    final nowIso = DateTime.now().toIso8601String();
    await metaBox.put(lastKey, nowIso);
  }

  // Conflict-aware upsert: pull remote row and merge with local then push
  Future<void> upsertWithMerge({
    required String table,
    required Json local,
    required ConflictStrategy strategy,
    List<String> mergeArrayKeys = const [],
  }) async {
    try {
      // Try fetch remote
      final id = local['id'];
      final remote = await _tryFetchById(table, id);
      final resolved = remote == null
          ? local
          : ConflictResolver.resolve(
              local: local,
              remote: remote,
              strategy: strategy,
              mergeArrayKeys: mergeArrayKeys,
            );
      await _supabase.from(table).upsert(resolved);
    } catch (e) {
      // Queue if failed
      await SyncQueue.instance.enqueue(SyncOperation(
        id: local['id'],
        box: table,
        table: table,
        type: SyncOpType.update,
        payload: local,
      ));
    }
  }

  Future<Json?> _tryFetchById(String table, String id) async {
    try {
      final result = await _supabase.from(table).select().eq('id', id).maybeSingle();
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return null;
    }
  }
}
