import 'package:flutter/foundation.dart';
import '../storage/local_storage_manager.dart';
import '../models/sync_operation.dart';
import '../models/sync_conflict.dart';

class ConflictResolver {
  final LocalStorageManager storageManager;
  final Function(SyncConflict) onConflict;
  
  ConflictResolver({
    required this.storageManager,
    required this.onConflict,
  });
  
  Future<SyncConflict?> checkForConflict(SyncOperation operation) async {
    // Check if there's a conflict between local and remote data
    // This would typically involve comparing timestamps and checksums
    
    try {
      // Get local data
      final localData = await _getLocalData(operation);
      if (localData == null) {
        return null; // No local data, no conflict
      }
      
      // Get remote data (simulated for now)
      final remoteData = await _getRemoteData(operation);
      if (remoteData == null) {
        return null; // No remote data, no conflict
      }
      
      // Compare timestamps
      final localTimestamp = DateTime.parse(localData['timestamp'] ?? DateTime.now().toIso8601String());
      final remoteTimestamp = DateTime.parse(remoteData['timestamp'] ?? DateTime.now().toIso8601String());
      
      // Check if data differs
      if (_dataConflicts(localData, remoteData)) {
        final conflict = SyncConflict(
          itemId: operation.id,
          type: operation.type,
          localData: localData,
          remoteData: remoteData,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp,
        );
        
        return conflict;
      }
    } catch (e) {
      debugPrint('Error checking for conflict: $e');
    }
    
    return null;
  }
  
  Future<Map<String, dynamic>?> _getLocalData(SyncOperation operation) async {
    // Get local data based on operation type
    switch (operation.type) {
      case 'message':
        // Get message from local storage
        return operation.data;
      case 'health_record':
        // Get health record from local storage
        return operation.data;
      case 'medication':
        // Get medication from local storage
        return operation.data;
      case 'user_profile':
        // Get user profile from local storage
        return operation.data;
      default:
        return operation.data;
    }
  }
  
  Future<Map<String, dynamic>?> _getRemoteData(SyncOperation operation) async {
    // This would typically fetch data from the server
    // For now, we'll simulate it
    return null;
  }
  
  bool _dataConflicts(Map<String, dynamic> local, Map<String, dynamic> remote) {
    // Check if the data actually conflicts
    // Skip metadata fields
    final skipFields = {'timestamp', 'syncVersion', 'deviceId', 'lastModified'};
    
    for (final key in local.keys) {
      if (skipFields.contains(key)) continue;
      
      if (remote.containsKey(key)) {
        if (local[key] != remote[key]) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  Future<void> autoResolve(SyncConflict conflict) async {
    ConflictResolution resolution;
    Map<String, dynamic> resolvedData;
    
    switch (conflict.type) {
      case 'message':
        // Messages: Keep both (no real conflict)
        resolution = ConflictResolution.merge;
        resolvedData = _mergeMessages(conflict.localData, conflict.remoteData);
        break;
        
      case 'health_record':
        // Health records: Use most recent
        if (conflict.localTimestamp.isAfter(conflict.remoteTimestamp)) {
          resolution = ConflictResolution.useLocal;
          resolvedData = conflict.localData;
        } else {
          resolution = ConflictResolution.useRemote;
          resolvedData = conflict.remoteData;
        }
        break;
        
      case 'medication':
        // Medications: Use most recent
        if (conflict.localTimestamp.isAfter(conflict.remoteTimestamp)) {
          resolution = ConflictResolution.useLocal;
          resolvedData = conflict.localData;
        } else {
          resolution = ConflictResolution.useRemote;
          resolvedData = conflict.remoteData;
        }
        break;
        
      case 'user_profile':
        // User profiles: Merge non-conflicting fields
        resolution = ConflictResolution.merge;
        resolvedData = _mergeData(conflict.localData, conflict.remoteData);
        break;
        
      default:
        // Default: Use most recent
        if (conflict.localTimestamp.isAfter(conflict.remoteTimestamp)) {
          resolution = ConflictResolution.useLocal;
          resolvedData = conflict.localData;
        } else {
          resolution = ConflictResolution.useRemote;
          resolvedData = conflict.remoteData;
        }
    }
    
    conflict.resolve(resolution, resolvedData, 'system');
    await _saveResolvedConflict(conflict);
  }
  
  Map<String, dynamic> _mergeMessages(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // For messages, we typically keep both
    // This is a simplified merge
    return {
      ...remote,
      ...local,
      'merged': true,
      'mergedAt': DateTime.now().toIso8601String(),
    };
  }
  
  Map<String, dynamic> _mergeData(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = <String, dynamic>{};
    
    // Start with remote data
    merged.addAll(remote);
    
    // Add local fields that don't conflict
    for (final entry in local.entries) {
      if (!remote.containsKey(entry.key) || remote[entry.key] == entry.value) {
        merged[entry.key] = entry.value;
      } else {
        // For conflicting fields, use the most recent
        final localTime = DateTime.parse(local['timestamp'] ?? '2000-01-01');
        final remoteTime = DateTime.parse(remote['timestamp'] ?? '2000-01-01');
        
        if (localTime.isAfter(remoteTime)) {
          merged[entry.key] = entry.value;
        }
      }
    }
    
    merged['merged'] = true;
    merged['mergedAt'] = DateTime.now().toIso8601String();
    
    return merged;
  }
  
  Future<void> _saveResolvedConflict(SyncConflict conflict) async {
    // Save resolved conflict to storage for audit
    final conflicts = await storageManager.getConfig('resolvedConflicts') ?? [];
    if (conflicts is List) {
      conflicts.add(conflict.toJson());
      
      // Keep only last 100 resolved conflicts
      if (conflicts.length > 100) {
        conflicts.removeRange(0, conflicts.length - 100);
      }
      
      await storageManager.saveConfig('resolvedConflicts', conflicts);
    }
  }
  
  Future<void> manualResolve(
    SyncConflict conflict,
    ConflictResolution resolution,
    Map<String, dynamic> resolvedData,
    String userId,
  ) async {
    conflict.resolve(resolution, resolvedData, userId);
    await _saveResolvedConflict(conflict);
    
    // Apply the resolution
    await _applyResolution(conflict);
  }
  
  Future<void> _applyResolution(SyncConflict conflict) async {
    if (!conflict.isResolved || conflict.resolvedData == null) {
      return;
    }
    
    // Apply the resolved data based on type
    switch (conflict.type) {
      case 'message':
        // Save resolved message
        await storageManager.saveConfig('message_${conflict.itemId}', conflict.resolvedData);
        break;
      case 'health_record':
        // Save resolved health record
        await storageManager.saveConfig('health_${conflict.itemId}', conflict.resolvedData);
        break;
      case 'medication':
        // Save resolved medication
        await storageManager.saveConfig('medication_${conflict.itemId}', conflict.resolvedData);
        break;
      case 'user_profile':
        // Save resolved user profile
        await storageManager.saveConfig('profile_${conflict.itemId}', conflict.resolvedData);
        break;
      default:
        // Save generic resolved data
        await storageManager.saveConfig('resolved_${conflict.itemId}', conflict.resolvedData);
    }
  }
  
  Future<List<SyncConflict>> getUnresolvedConflicts() async {
    final conflicts = await storageManager.getConfig('unresolvedConflicts') ?? [];
    if (conflicts is List) {
      return conflicts
          .map((c) => SyncConflict.fromJson(Map<String, dynamic>.from(c)))
          .where((c) => !c.isResolved)
          .toList();
    }
    return [];
  }
  
  Future<void> saveUnresolvedConflict(SyncConflict conflict) async {
    final conflicts = await storageManager.getConfig('unresolvedConflicts') ?? [];
    if (conflicts is List) {
      conflicts.add(conflict.toJson());
      await storageManager.saveConfig('unresolvedConflicts', conflicts);
    }
  }
}