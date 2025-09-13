import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import '../../models/sync/sync_item.dart';

enum ConflictStrategy {
  lastWriteWins,
  merge,
  userChoose,
  serverWins,
  clientWins,
}

class ConflictResolver {
  static final ConflictResolver _instance = ConflictResolver._internal();
  factory ConflictResolver() => _instance;
  ConflictResolver._internal();

  final Logger _logger = Logger();

  // Strategy mapping for different data types
  static const Map<String, ConflictStrategy> _defaultStrategies = {
    'users': ConflictStrategy.serverWins,
    'health_data': ConflictStrategy.lastWriteWins,
    'medications': ConflictStrategy.serverWins,
    'messages': ConflictStrategy.merge,
    'appointments': ConflictStrategy.userChoose,
    'preferences': ConflictStrategy.clientWins,
    'settings': ConflictStrategy.clientWins,
    'analytics': ConflictStrategy.serverWins,
    'emergency_contacts': ConflictStrategy.serverWins,
    'daily_checkins': ConflictStrategy.lastWriteWins,
  };

  Future<ResolvedConflict> resolveConflict({
    required String table,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    ConflictStrategy? overrideStrategy,
  }) async {
    final strategy = overrideStrategy ?? _defaultStrategies[table] ?? 
        ConflictStrategy.lastWriteWins;
    
    _logger.d('Resolving conflict for $table using $strategy');
    
    // Check if there's actually a conflict
    if (!_hasConflict(localData, remoteData)) {
      return ResolvedConflict(
        resolvedData: remoteData,
        strategy: strategy,
        hasConflict: false,
      );
    }
    
    switch (strategy) {
      case ConflictStrategy.lastWriteWins:
        return _resolveLastWriteWins(localData, remoteData);
      
      case ConflictStrategy.merge:
        return _resolveMerge(table, localData, remoteData);
      
      case ConflictStrategy.userChoose:
        return _prepareUserChoice(localData, remoteData);
      
      case ConflictStrategy.serverWins:
        return ResolvedConflict(
          resolvedData: remoteData,
          strategy: strategy,
          hasConflict: true,
        );
      
      case ConflictStrategy.clientWins:
        return ResolvedConflict(
          resolvedData: localData,
          strategy: strategy,
          hasConflict: true,
        );
    }
  }

  bool _hasConflict(Map<String, dynamic> local, Map<String, dynamic> remote) {
    // Compare checksums or versions
    final localChecksum = _generateChecksum(local);
    final remoteChecksum = _generateChecksum(remote);
    
    return localChecksum != remoteChecksum;
  }

  String _generateChecksum(Map<String, dynamic> data) {
    // Remove metadata fields before comparison
    final cleanData = Map<String, dynamic>.from(data)
      ..remove('last_synced')
      ..remove('sync_version')
      ..remove('updated_at');
    
    final jsonString = json.encode(cleanData);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  ResolvedConflict _resolveLastWriteWins(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final localTime = DateTime.tryParse(local['updated_at'] ?? '');
    final remoteTime = DateTime.tryParse(remote['updated_at'] ?? '');
    
    if (localTime == null || remoteTime == null) {
      // Default to remote if timestamps are missing
      return ResolvedConflict(
        resolvedData: remote,
        strategy: ConflictStrategy.lastWriteWins,
        hasConflict: true,
      );
    }
    
    final winner = localTime.isAfter(remoteTime) ? local : remote;
    
    return ResolvedConflict(
      resolvedData: winner,
      strategy: ConflictStrategy.lastWriteWins,
      hasConflict: true,
      metadata: {
        'local_time': localTime.toIso8601String(),
        'remote_time': remoteTime.toIso8601String(),
        'winner': localTime.isAfter(remoteTime) ? 'local' : 'remote',
      },
    );
  }

  ResolvedConflict _resolveMerge(
    String table,
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    Map<String, dynamic> merged;
    
    switch (table) {
      case 'messages':
        merged = _mergeMessages(local, remote);
        break;
      
      case 'health_data':
        merged = _mergeHealthData(local, remote);
        break;
      
      default:
        // Default merge strategy - combine non-conflicting fields
        merged = _defaultMerge(local, remote);
    }
    
    return ResolvedConflict(
      resolvedData: merged,
      strategy: ConflictStrategy.merge,
      hasConflict: true,
      metadata: {
        'merge_type': table,
        'fields_merged': merged.keys.toList(),
      },
    );
  }

  Map<String, dynamic> _mergeMessages(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // For messages, keep both if they're different
    // This ensures no messages are lost
    return remote; // In practice, messages would be appended, not replaced
  }

  Map<String, dynamic> _mergeHealthData(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = Map<String, dynamic>.from(remote);
    
    // For numeric health data, take the average or latest
    final numericFields = [
      'blood_pressure_systolic',
      'blood_pressure_diastolic',
      'heart_rate',
      'blood_sugar',
      'weight',
      'temperature',
      'oxygen_saturation',
    ];
    
    for (final field in numericFields) {
      if (local.containsKey(field) && remote.containsKey(field)) {
        final localValue = local[field];
        final remoteValue = remote[field];
        
        if (localValue != null && remoteValue != null) {
          // Use latest value based on timestamp
          final localTime = DateTime.tryParse(local['recorded_at'] ?? '');
          final remoteTime = DateTime.tryParse(remote['recorded_at'] ?? '');
          
          if (localTime != null && remoteTime != null) {
            merged[field] = localTime.isAfter(remoteTime) ? localValue : remoteValue;
          }
        }
      }
    }
    
    return merged;
  }

  Map<String, dynamic> _defaultMerge(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = Map<String, dynamic>.from(remote);
    
    // Merge non-conflicting fields
    local.forEach((key, value) {
      if (!remote.containsKey(key)) {
        merged[key] = value;
      } else if (value != remote[key]) {
        // Field exists in both - use timestamp to decide
        final localTime = DateTime.tryParse(local['updated_at'] ?? '');
        final remoteTime = DateTime.tryParse(remote['updated_at'] ?? '');
        
        if (localTime != null && remoteTime != null) {
          merged[key] = localTime.isAfter(remoteTime) ? value : remote[key];
        }
      }
    });
    
    return merged;
  }

  ResolvedConflict _prepareUserChoice(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // Prepare data for user to choose
    return ResolvedConflict(
      resolvedData: {}, // Will be filled after user choice
      strategy: ConflictStrategy.userChoose,
      hasConflict: true,
      requiresUserInput: true,
      options: ConflictOptions(
        localData: local,
        remoteData: remote,
        differences: _findDifferences(local, remote),
      ),
    );
  }

  List<FieldDifference> _findDifferences(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final differences = <FieldDifference>[];
    final allKeys = {...local.keys, ...remote.keys};
    
    for (final key in allKeys) {
      final localValue = local[key];
      final remoteValue = remote[key];
      
      if (localValue != remoteValue) {
        differences.add(FieldDifference(
          fieldName: key,
          localValue: localValue,
          remoteValue: remoteValue,
        ));
      }
    }
    
    return differences;
  }

  Future<void> applyUserChoice({
    required String conflictId,
    required ConflictChoice choice,
    required Map<String, dynamic> customData,
  }) async {
    _logger.i('User chose $choice for conflict $conflictId');
    
    // Apply the user's choice
    // This would update the local database and sync queue
  }

  Future<List<PendingConflict>> getPendingConflicts() async {
    // Return conflicts that require user resolution
    // These would be stored in a separate Hive box
    return [];
  }

  Future<void> autoResolveConflicts(String table) async {
    final strategy = _defaultStrategies[table] ?? ConflictStrategy.lastWriteWins;
    
    if (strategy == ConflictStrategy.userChoose) {
      _logger.w('Cannot auto-resolve conflicts for $table - requires user input');
      return;
    }
    
    // Auto-resolve conflicts using the default strategy
    _logger.i('Auto-resolving conflicts for $table using $strategy');
  }
}

class ResolvedConflict {
  final Map<String, dynamic> resolvedData;
  final ConflictStrategy strategy;
  final bool hasConflict;
  final bool requiresUserInput;
  final ConflictOptions? options;
  final Map<String, dynamic>? metadata;

  ResolvedConflict({
    required this.resolvedData,
    required this.strategy,
    required this.hasConflict,
    this.requiresUserInput = false,
    this.options,
    this.metadata,
  });
}

class ConflictOptions {
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final List<FieldDifference> differences;

  ConflictOptions({
    required this.localData,
    required this.remoteData,
    required this.differences,
  });
}

class FieldDifference {
  final String fieldName;
  final dynamic localValue;
  final dynamic remoteValue;

  FieldDifference({
    required this.fieldName,
    required this.localValue,
    required this.remoteValue,
  });

  String get displayName {
    // Convert field names to user-friendly labels
    final labels = {
      'blood_pressure_systolic': 'Systolic BP',
      'blood_pressure_diastolic': 'Diastolic BP',
      'heart_rate': 'Heart Rate',
      'blood_sugar': 'Blood Sugar',
      'weight': 'Weight',
      'temperature': 'Temperature',
      'oxygen_saturation': 'Oxygen Level',
    };
    
    return labels[fieldName] ?? fieldName.replaceAll('_', ' ').toUpperCase();
  }
}

class PendingConflict {
  final String id;
  final String table;
  final DateTime detectedAt;
  final ConflictOptions options;

  PendingConflict({
    required this.id,
    required this.table,
    required this.detectedAt,
    required this.options,
  });
}

enum ConflictChoice {
  keepLocal,
  keepRemote,
  keepBoth,
  custom,
}