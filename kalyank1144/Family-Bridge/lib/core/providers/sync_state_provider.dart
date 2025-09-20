import 'dart:async';
import 'package:flutter/foundation.dart';
import '../offline/sync/sync_manager.dart';
import '../offline/models/sync_result.dart';
import '../offline/models/sync_conflict.dart';

class SyncStateProvider extends ChangeNotifier {
  final SyncManager syncManager;
  
  bool _isSyncing = false;
  SyncResult? _lastSyncResult;
  List<SyncConflict> _unresolvedConflicts = [];
  Map<String, dynamic> _syncStatistics = {};
  StreamSubscription? _syncStatusSubscription;
  StreamSubscription? _conflictSubscription;
  
  bool get isSyncing => _isSyncing;
  SyncResult? get lastSyncResult => _lastSyncResult;
  List<SyncConflict> get unresolvedConflicts => _unresolvedConflicts;
  Map<String, dynamic> get syncStatistics => _syncStatistics;
  DateTime? get lastSyncTime => syncManager.lastSyncTime;
  SyncMode get syncMode => syncManager.syncMode;
  
  SyncStateProvider({required this.syncManager}) {
    _initialize();
  }
  
  void _initialize() {
    _syncStatusSubscription = syncManager.syncStatusStream.listen((result) {
      _isSyncing = result.isInProgress;
      if (!result.isInProgress) {
        _lastSyncResult = result;
      }
      notifyListeners();
    });
    
    _conflictSubscription = syncManager.conflictStream.listen((conflict) {
      if (!conflict.isResolved) {
        _unresolvedConflicts.add(conflict);
        notifyListeners();
      }
    });
    
    _loadSyncStatistics();
  }
  
  Future<void> _loadSyncStatistics() async {
    _syncStatistics = await syncManager.getSyncStatistics();
    notifyListeners();
  }
  
  Future<void> startSync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    notifyListeners();
    
    final result = await syncManager.performSync();
    
    _isSyncing = false;
    _lastSyncResult = result;
    await _loadSyncStatistics();
    notifyListeners();
  }
  
  Future<void> setSyncMode(SyncMode mode) async {
    await syncManager.setSyncMode(mode);
    notifyListeners();
  }
  
  void pauseSync() {
    syncManager.pauseSync();
    _isSyncing = false;
    notifyListeners();
  }
  
  void resumeSync() {
    syncManager.resumeSync();
    notifyListeners();
  }
  
  Future<void> resolveConflict(
    SyncConflict conflict,
    ConflictResolution resolution,
    Map<String, dynamic> resolvedData,
  ) async {
    conflict.resolve(resolution, resolvedData, 'user');
    _unresolvedConflicts.removeWhere((c) => c.id == conflict.id);
    notifyListeners();
  }
  
  Future<void> forceSyncItem(String itemId, SyncPriority priority) async {
    await syncManager.forceSyncItem(itemId, priority);
  }
  
  Future<void> clearSyncQueue() async {
    await syncManager.clearSyncQueue();
    await _loadSyncStatistics();
    notifyListeners();
  }
  
  Future<void> refreshStatistics() async {
    await _loadSyncStatistics();
  }
  
  @override
  void dispose() {
    _syncStatusSubscription?.cancel();
    _conflictSubscription?.cancel();
    super.dispose();
  }
}