import 'dart:async';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../../services/network/network_manager.dart';
import '../../services/sync/sync_queue.dart';
import '../../services/sync/data_sync_service.dart';
import '../../models/sync/sync_item.dart';

abstract class BaseOfflineRepository<T> {
  final Logger _logger = Logger();
  final NetworkManager _networkManager = NetworkManager();
  final SyncQueue _syncQueue = SyncQueue();
  final DataSyncService _dataSyncService = DataSyncService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  late Box<T> _localBox;
  final String tableName;
  final String boxName;
  
  final StreamController<List<T>> _dataController = 
      StreamController<List<T>>.broadcast();
  
  Stream<List<T>> get dataStream => _dataController.stream;
  
  BaseOfflineRepository({
    required this.tableName,
    required this.boxName,
  });
  
  Future<void> initialize() async {
    _localBox = await Hive.openBox<T>(boxName);
    
    // Listen to network changes
    _networkManager.connectionStream.listen((isOnline) {
      if (isOnline) {
        _syncWithRemote();
      }
    });
    
    _logger.i('Repository initialized: $tableName');
  }
  
  // Abstract methods to be implemented by subclasses
  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T item);
  String getId(T item);
  DateTime? getUpdatedAt(T item);
  T updateSyncStatus(T item, {required bool isSynced, DateTime? lastSynced});
  
  // Offline-first read strategy
  Stream<List<T>> getData({
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async* {
    try {
      // 1. Always read from local first
      List<T> localData = await _getLocalData(
        filters: filters,
        orderBy: orderBy,
        ascending: ascending,
        limit: limit,
      );
      
      // 2. Return local data immediately
      yield localData;
      _dataController.add(localData);
      
      // 3. Fetch remote in background if online
      if (_networkManager.isOnline) {
        final remoteData = await _fetchRemoteData(
          filters: filters,
          orderBy: orderBy,
          ascending: ascending,
          limit: limit,
        );
        
        if (remoteData != null && remoteData.isNotEmpty) {
          // Update local storage
          await _updateLocalData(remoteData);
          
          // Re-read local data with updates
          localData = await _getLocalData(
            filters: filters,
            orderBy: orderBy,
            ascending: ascending,
            limit: limit,
          );
          
          // Yield updated data
          yield localData;
          _dataController.add(localData);
        }
      }
    } catch (e) {
      _logger.e('Error getting data from $tableName', error: e);
      yield [];
    }
  }
  
  // Offline-first write strategy
  Future<T?> saveData(T item) async {
    try {
      // 1. Save locally first
      final id = getId(item);
      await _localBox.put(id, item);
      
      // 2. Add to sync queue
      await _syncQueue.addItem(SyncItem(
        operation: SyncOperation.create,
        tableName: tableName,
        data: toJson(item),
        priority: _getPriority(),
        userId: _supabase.auth.currentUser?.id,
        recordId: id,
      ));
      
      // 3. Attempt immediate sync if online
      if (_networkManager.isOnline) {
        await _syncQueue.processQueue();
      }
      
      // 4. Notify listeners
      _notifyListeners();
      
      return item;
      
    } catch (e) {
      _logger.e('Error saving data to $tableName', error: e);
      return null;
    }
  }
  
  // Update data
  Future<T?> updateData(T item) async {
    try {
      // 1. Update locally first
      final id = getId(item);
      await _localBox.put(id, item);
      
      // 2. Add to sync queue
      await _syncQueue.addItem(SyncItem(
        operation: SyncOperation.update,
        tableName: tableName,
        data: toJson(item),
        priority: _getPriority(),
        userId: _supabase.auth.currentUser?.id,
        recordId: id,
      ));
      
      // 3. Attempt immediate sync if online
      if (_networkManager.isOnline) {
        await _syncQueue.processQueue();
      }
      
      // 4. Notify listeners
      _notifyListeners();
      
      return item;
      
    } catch (e) {
      _logger.e('Error updating data in $tableName', error: e);
      return null;
    }
  }
  
  // Delete data
  Future<bool> deleteData(String id) async {
    try {
      // 1. Mark as deleted locally (soft delete)
      final item = _localBox.get(id);
      if (item != null) {
        // Could mark with a deleted flag instead of removing
        await _localBox.delete(id);
      }
      
      // 2. Add to sync queue
      await _syncQueue.addItem(SyncItem(
        operation: SyncOperation.delete,
        tableName: tableName,
        data: {'id': id},
        priority: _getPriority(),
        userId: _supabase.auth.currentUser?.id,
        recordId: id,
      ));
      
      // 3. Attempt immediate sync if online
      if (_networkManager.isOnline) {
        await _syncQueue.processQueue();
      }
      
      // 4. Notify listeners
      _notifyListeners();
      
      return true;
      
    } catch (e) {
      _logger.e('Error deleting data from $tableName', error: e);
      return false;
    }
  }
  
  // Get single item
  Future<T?> getById(String id) async {
    try {
      // Try local first
      T? item = _localBox.get(id);
      
      // If not found locally and online, try remote
      if (item == null && _networkManager.isOnline) {
        final remoteData = await _supabase
            .from(tableName)
            .select()
            .eq('id', id)
            .single();
        
        if (remoteData != null) {
          item = fromJson(remoteData);
          // Cache locally
          await _localBox.put(id, item);
        }
      }
      
      return item;
      
    } catch (e) {
      _logger.e('Error getting item by id from $tableName', error: e);
      return null;
    }
  }
  
  // Batch operations
  Future<void> saveBatch(List<T> items) async {
    try {
      // Save all locally
      final Map<String, T> itemMap = {
        for (var item in items) getId(item): item
      };
      await _localBox.putAll(itemMap);
      
      // Add to sync queue
      final syncItems = items.map((item) => SyncItem(
        operation: SyncOperation.create,
        tableName: tableName,
        data: toJson(item),
        priority: _getPriority(),
        userId: _supabase.auth.currentUser?.id,
        recordId: getId(item),
      )).toList();
      
      await _syncQueue.addBatch(syncItems);
      
      // Attempt sync if online
      if (_networkManager.isOnline) {
        await _syncQueue.processQueue();
      }
      
      _notifyListeners();
      
    } catch (e) {
      _logger.e('Error saving batch to $tableName', error: e);
    }
  }
  
  // Private helper methods
  Future<List<T>> _getLocalData({
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    List<T> data = _localBox.values.toList();
    
    // Apply filters
    if (filters != null && filters.isNotEmpty) {
      data = _applyFilters(data, filters);
    }
    
    // Apply sorting
    if (orderBy != null) {
      data = _applySorting(data, orderBy, ascending);
    }
    
    // Apply limit
    if (limit != null && data.length > limit) {
      data = data.take(limit).toList();
    }
    
    return data;
  }
  
  Future<List<T>?> _fetchRemoteData({
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      var query = _supabase.from(tableName).select();
      
      // Apply filters
      filters?.forEach((key, value) {
        query = query.eq(key, value);
      });
      
      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }
      
      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final response = await query;
      
      if (response != null) {
        return (response as List)
            .map((json) => fromJson(json))
            .toList();
      }
      
      return null;
      
    } catch (e) {
      _logger.e('Error fetching remote data from $tableName', error: e);
      return null;
    }
  }
  
  Future<void> _updateLocalData(List<T> remoteData) async {
    for (final item in remoteData) {
      final id = getId(item);
      final localItem = _localBox.get(id);
      
      // Update if remote is newer or doesn't exist locally
      if (localItem == null) {
        await _localBox.put(id, item);
      } else {
        final localUpdatedAt = getUpdatedAt(localItem);
        final remoteUpdatedAt = getUpdatedAt(item);
        
        if (localUpdatedAt != null && remoteUpdatedAt != null) {
          if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
            await _localBox.put(id, item);
          }
        }
      }
    }
  }
  
  List<T> _applyFilters(List<T> data, Map<String, dynamic> filters) {
    // This would be implemented based on specific model properties
    // For now, returning unfiltered data
    return data;
  }
  
  List<T> _applySorting(List<T> data, String orderBy, bool ascending) {
    // This would be implemented based on specific model properties
    // For now, returning unsorted data
    return data;
  }
  
  SyncPriority _getPriority() {
    // Get priority based on table name
    return _dataSyncService.getPriorityForTable(tableName);
  }
  
  void _notifyListeners() {
    final data = _localBox.values.toList();
    _dataController.add(data);
  }
  
  Future<void> _syncWithRemote() async {
    try {
      _logger.d('Syncing $tableName with remote');
      
      // Get all local unsynced items
      final unsyncedItems = _localBox.values
          .where((item) {
            // Check if item needs syncing (implementation specific)
            return true;
          })
          .toList();
      
      if (unsyncedItems.isNotEmpty) {
        // Add to sync queue
        final syncItems = unsyncedItems.map((item) => SyncItem(
          operation: SyncOperation.update,
          tableName: tableName,
          data: toJson(item),
          priority: _getPriority(),
          userId: _supabase.auth.currentUser?.id,
          recordId: getId(item),
        )).toList();
        
        await _syncQueue.addBatch(syncItems);
        await _syncQueue.processQueue();
      }
      
    } catch (e) {
      _logger.e('Error syncing $tableName', error: e);
    }
  }
  
  // Cleanup and disposal
  Future<void> clearLocal() async {
    await _localBox.clear();
    _notifyListeners();
  }
  
  Future<void> dispose() async {
    await _dataController.close();
  }
  
  // Statistics and debugging
  Map<String, dynamic> getStatistics() {
    return {
      'tableName': tableName,
      'localCount': _localBox.length,
      'boxName': boxName,
      'isOpen': _localBox.isOpen,
    };
  }
}