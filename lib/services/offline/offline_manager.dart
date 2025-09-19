import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

import '../network/network_manager.dart';
import '../sync/data_sync_service.dart';
import '../sync/sync_queue.dart';

enum SyncState { idle, syncing, error }

class SyncStatus {
  final SyncState state;
  final DateTime? lastSuccessAt;
  final String? lastError;

  const SyncStatus({
    required this.state,
    this.lastSuccessAt,
    this.lastError,
  });
}

class OfflineManager {
  OfflineManager._internal();
  static final OfflineManager instance = OfflineManager._internal();

  final _uuid = const Uuid();
  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = const SyncStatus(state: SyncState.idle);

  bool _initialized = false;
  bool _forceOffline = false;

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus get status => _status;

  Future<void> initialize() async {
    await Hive.initFlutter();
    await DataSyncService.instance.initialize();
    await NetworkManager.instance.startMonitoring();

    // Background sync
    await Workmanager().initialize(_backgroundDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      'familybridge.periodicSync',
      'periodicSync',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
    _initialized = true;
  }

  void goOffline() {
    _forceOffline = true;
  }

  void goOnline() {
    _forceOffline = false;
    _trySync();
  }

  bool get isOffline => _forceOffline || !NetworkManager.instance.current.isOnline;

  Future<void> _trySync() async {
    if (!_initialized) return;
    if (isOffline) return;
    _emit(const SyncStatus(state: SyncState.syncing));
    try {
      await DataSyncService.instance.syncAll();
      _emit(SyncStatus(state: SyncState.idle, lastSuccessAt: DateTime.now()));
    } catch (e) {
      _emit(SyncStatus(state: SyncState.error, lastError: e.toString()));
    }
  }

  Future<void> executeOrQueue({
    required String table,
    required Map<String, dynamic> payload,
    required SyncOpType type,
  }) async {
    if (isOffline) {
      await SyncQueue.instance.enqueue(SyncOperation(
        id: payload['id'] ?? _uuid.v4(),
        box: table,
        table: table,
        type: type,
        payload: payload,
      ));
    } else {
      await DataSyncService.instance.upsertWithMerge(
        table: table,
        local: payload,
        strategy: ConflictStrategy.lastWriteWins,
      );
    }
  }

  void _emit(SyncStatus status) {
    _status = status;
    _statusController.add(status);
  }
}

void _backgroundDispatcher() async {
  // This method is invoked by Workmanager in a background isolate.
  Workmanager().executeTask((task, inputData) async {
    try {
      await Hive.initFlutter();
      await DataSyncService.instance.initialize();
      if (NetworkManager.instance.current.isOnline) {
        await DataSyncService.instance.syncAll();
      }
      return Future.value(true);
    } catch (_) {
      return Future.value(false);
    }
  });
}
