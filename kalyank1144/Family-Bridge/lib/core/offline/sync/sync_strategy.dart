import 'package:flutter/foundation.dart';
import '../../network/network_manager.dart';
import '../storage/local_storage_manager.dart';

enum SyncStrategyType {
  full,      // Sync everything
  incremental, // Sync only changes since last sync
  priority,   // Sync by priority
  minimal,    // Only critical data
  adaptive,   // Based on network conditions
}

class SyncStrategy {
  final NetworkManager networkManager;
  final LocalStorageManager storageManager;
  
  SyncStrategy({
    required this.networkManager,
    required this.storageManager,
  });
  
  Future<SyncStrategyType> determineStrategy() async {
    // Check network quality
    final networkQuality = networkManager.networkQuality;
    final connectionType = networkManager.connectionType;
    
    // If no network quality data, default to minimal
    if (networkQuality == null) {
      return SyncStrategyType.minimal;
    }
    
    // Check user preferences
    final userPreference = await storageManager.getConfig('syncStrategy');
    if (userPreference != null && userPreference == 'manual') {
      return SyncStrategyType.priority;
    }
    
    // Determine based on network conditions
    if (connectionType == ConnectionType.wifi) {
      if (networkQuality.isGood) {
        return SyncStrategyType.full;
      } else {
        return SyncStrategyType.incremental;
      }
    } else if (connectionType == ConnectionType.mobile) {
      // Check data saver mode
      final dataSaverEnabled = await storageManager.getConfig('dataSaverMode') ?? false;
      
      if (dataSaverEnabled) {
        return SyncStrategyType.minimal;
      } else if (networkQuality.isGood) {
        return SyncStrategyType.priority;
      } else {
        return SyncStrategyType.minimal;
      }
    } else {
      // Other connection types (ethernet, bluetooth)
      return SyncStrategyType.incremental;
    }
  }
  
  Future<int> getBatchSize(SyncStrategyType strategy) async {
    switch (strategy) {
      case SyncStrategyType.full:
        return 100;
      case SyncStrategyType.incremental:
        return 50;
      case SyncStrategyType.priority:
        return 25;
      case SyncStrategyType.minimal:
        return 10;
      case SyncStrategyType.adaptive:
        return await _getAdaptiveBatchSize();
    }
  }
  
  Future<int> _getAdaptiveBatchSize() async {
    final networkQuality = networkManager.networkQuality;
    
    if (networkQuality == null) {
      return 10;
    }
    
    // Calculate batch size based on latency and bandwidth
    if (networkQuality.latency < 50) {
      return 100;
    } else if (networkQuality.latency < 150) {
      return 50;
    } else if (networkQuality.latency < 500) {
      return 25;
    } else {
      return 10;
    }
  }
  
  Future<Duration> getSyncInterval(SyncStrategyType strategy) async {
    switch (strategy) {
      case SyncStrategyType.full:
        return const Duration(minutes: 5);
      case SyncStrategyType.incremental:
        return const Duration(minutes: 10);
      case SyncStrategyType.priority:
        return const Duration(minutes: 15);
      case SyncStrategyType.minimal:
        return const Duration(minutes: 30);
      case SyncStrategyType.adaptive:
        return await _getAdaptiveSyncInterval();
    }
  }
  
  Future<Duration> _getAdaptiveSyncInterval() async {
    final networkQuality = networkManager.networkQuality;
    final batteryLevel = await _getBatteryLevel();
    
    if (networkQuality == null) {
      return const Duration(minutes: 30);
    }
    
    // Adjust interval based on network quality and battery
    if (networkQuality.isGood && batteryLevel > 50) {
      return const Duration(minutes: 5);
    } else if (networkQuality.isAcceptable && batteryLevel > 30) {
      return const Duration(minutes: 15);
    } else {
      return const Duration(minutes: 30);
    }
  }
  
  Future<int> _getBatteryLevel() async {
    // This would typically use a battery plugin
    // For now, return a default value
    return 75;
  }
  
  Future<bool> shouldCompressData(SyncStrategyType strategy) async {
    switch (strategy) {
      case SyncStrategyType.full:
        return false; // No compression for full sync on good connection
      case SyncStrategyType.incremental:
        return true;
      case SyncStrategyType.priority:
        return true;
      case SyncStrategyType.minimal:
        return true;
      case SyncStrategyType.adaptive:
        return networkManager.connectionType != ConnectionType.wifi;
    }
  }
  
  Future<bool> shouldUseDeltaSync(SyncStrategyType strategy) async {
    switch (strategy) {
      case SyncStrategyType.full:
        return false;
      case SyncStrategyType.incremental:
        return true;
      case SyncStrategyType.priority:
        return true;
      case SyncStrategyType.minimal:
        return true;
      case SyncStrategyType.adaptive:
        return true;
    }
  }
  
  Future<int> getMaxRetries(SyncStrategyType strategy) async {
    switch (strategy) {
      case SyncStrategyType.full:
        return 5;
      case SyncStrategyType.incremental:
        return 3;
      case SyncStrategyType.priority:
        return 3;
      case SyncStrategyType.minimal:
        return 2;
      case SyncStrategyType.adaptive:
        return networkManager.networkQuality?.isGood ?? false ? 5 : 2;
    }
  }
  
  Future<Map<String, dynamic>> getStrategyConfig(SyncStrategyType strategy) async {
    return {
      'type': strategy.toString(),
      'batchSize': await getBatchSize(strategy),
      'syncInterval': (await getSyncInterval(strategy)).inMinutes,
      'compress': await shouldCompressData(strategy),
      'deltaSync': await shouldUseDeltaSync(strategy),
      'maxRetries': await getMaxRetries(strategy),
    };
  }
}