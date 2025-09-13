import 'package:hive/hive.dart';
import '../../models/hive/health_data_model.dart';
import 'base_offline_repository.dart';
import '../../services/sync/sync_queue.dart';
import '../../models/sync/sync_item.dart';

class HealthRepository extends BaseOfflineRepository<HealthDataModel> {
  static final HealthRepository _instance = HealthRepository._internal();
  factory HealthRepository() => _instance;
  
  HealthRepository._internal() : super(
    tableName: 'health_data',
    boxName: 'health_data_box',
  );
  
  @override
  HealthDataModel fromJson(Map<String, dynamic> json) {
    return HealthDataModel.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(HealthDataModel item) {
    return item.toJson();
  }
  
  @override
  String getId(HealthDataModel item) {
    return item.id;
  }
  
  @override
  DateTime? getUpdatedAt(HealthDataModel item) {
    return item.recordedAt;
  }
  
  @override
  HealthDataModel updateSyncStatus(
    HealthDataModel item, {
    required bool isSynced,
    DateTime? lastSynced,
  }) {
    item.isSynced = isSynced;
    item.lastSynced = lastSynced;
    return item;
  }
  
  // Health-specific methods
  Future<List<HealthDataModel>> getRecentReadings({
    required String userId,
    int days = 7,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    await for (final data in getData(
      filters: {'userId': userId},
      orderBy: 'recordedAt',
      ascending: false,
    )) {
      return data.where((item) => 
        item.recordedAt.isAfter(cutoffDate)
      ).toList();
    }
    
    return [];
  }
  
  Future<HealthDataModel?> getLatestReading(String userId) async {
    await for (final data in getData(
      filters: {'userId': userId},
      orderBy: 'recordedAt',
      ascending: false,
      limit: 1,
    )) {
      return data.isNotEmpty ? data.first : null;
    }
    
    return null;
  }
  
  Future<Map<String, List<double>>> getHealthTrends({
    required String userId,
    required int days,
  }) async {
    final readings = await getRecentReadings(userId: userId, days: days);
    
    final trends = <String, List<double>>{
      'bloodPressureSystolic': [],
      'bloodPressureDiastolic': [],
      'heartRate': [],
      'bloodSugar': [],
      'weight': [],
      'temperature': [],
      'oxygenSaturation': [],
    };
    
    for (final reading in readings) {
      if (reading.bloodPressureSystolic != null) {
        trends['bloodPressureSystolic']!.add(reading.bloodPressureSystolic!);
      }
      if (reading.bloodPressureDiastolic != null) {
        trends['bloodPressureDiastolic']!.add(reading.bloodPressureDiastolic!);
      }
      if (reading.heartRate != null) {
        trends['heartRate']!.add(reading.heartRate!);
      }
      if (reading.bloodSugar != null) {
        trends['bloodSugar']!.add(reading.bloodSugar!);
      }
      if (reading.weight != null) {
        trends['weight']!.add(reading.weight!);
      }
      if (reading.temperature != null) {
        trends['temperature']!.add(reading.temperature!);
      }
      if (reading.oxygenSaturation != null) {
        trends['oxygenSaturation']!.add(reading.oxygenSaturation!);
      }
    }
    
    return trends;
  }
  
  Future<bool> hasAbnormalReadings(String userId) async {
    final latest = await getLatestReading(userId);
    if (latest == null) return false;
    
    // Check for abnormal values
    if (latest.bloodPressureSystolic != null) {
      if (latest.bloodPressureSystolic! > 140 || 
          latest.bloodPressureSystolic! < 90) {
        return true;
      }
    }
    
    if (latest.bloodPressureDiastolic != null) {
      if (latest.bloodPressureDiastolic! > 90 || 
          latest.bloodPressureDiastolic! < 60) {
        return true;
      }
    }
    
    if (latest.heartRate != null) {
      if (latest.heartRate! > 100 || latest.heartRate! < 60) {
        return true;
      }
    }
    
    if (latest.bloodSugar != null) {
      if (latest.bloodSugar! > 180 || latest.bloodSugar! < 70) {
        return true;
      }
    }
    
    if (latest.temperature != null) {
      if (latest.temperature! > 38 || latest.temperature! < 36) {
        return true;
      }
    }
    
    if (latest.oxygenSaturation != null) {
      if (latest.oxygenSaturation! < 95) {
        return true;
      }
    }
    
    return false;
  }
  
  Future<HealthDataModel?> recordHealthData({
    required String userId,
    double? bloodPressureSystolic,
    double? bloodPressureDiastolic,
    double? heartRate,
    double? bloodSugar,
    double? weight,
    double? temperature,
    int? steps,
    double? oxygenSaturation,
    String? notes,
  }) async {
    final healthData = HealthDataModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      recordedAt: DateTime.now(),
      bloodPressureSystolic: bloodPressureSystolic,
      bloodPressureDiastolic: bloodPressureDiastolic,
      heartRate: heartRate,
      bloodSugar: bloodSugar,
      weight: weight,
      temperature: temperature,
      steps: steps,
      oxygenSaturation: oxygenSaturation,
      notes: notes,
      source: 'manual',
    );
    
    // Check for critical values that need immediate sync
    bool isCritical = false;
    
    if (bloodPressureSystolic != null && 
        (bloodPressureSystolic > 180 || bloodPressureSystolic < 70)) {
      isCritical = true;
    }
    
    if (heartRate != null && 
        (heartRate > 120 || heartRate < 40)) {
      isCritical = true;
    }
    
    if (bloodSugar != null && 
        (bloodSugar > 250 || bloodSugar < 50)) {
      isCritical = true;
    }
    
    if (oxygenSaturation != null && oxygenSaturation < 90) {
      isCritical = true;
    }
    
    // Save with appropriate priority
    if (isCritical) {
      // Add to sync queue with critical priority
      await SyncQueue().addItem(SyncItem(
        operation: SyncOperation.create,
        tableName: tableName,
        data: toJson(healthData),
        priority: SyncPriority.critical,
        userId: userId,
        recordId: healthData.id,
      ));
    }
    
    return await saveData(healthData);
  }
  
  Future<Map<String, dynamic>> getHealthSummary({
    required String userId,
    required int days,
  }) async {
    final readings = await getRecentReadings(userId: userId, days: days);
    
    if (readings.isEmpty) {
      return {
        'hasData': false,
        'message': 'No health data available',
      };
    }
    
    // Calculate averages
    double avgSystolic = 0, avgDiastolic = 0, avgHeartRate = 0;
    double avgSugar = 0, avgWeight = 0, avgTemp = 0, avgOxygen = 0;
    int countSystolic = 0, countDiastolic = 0, countHeartRate = 0;
    int countSugar = 0, countWeight = 0, countTemp = 0, countOxygen = 0;
    
    for (final reading in readings) {
      if (reading.bloodPressureSystolic != null) {
        avgSystolic += reading.bloodPressureSystolic!;
        countSystolic++;
      }
      if (reading.bloodPressureDiastolic != null) {
        avgDiastolic += reading.bloodPressureDiastolic!;
        countDiastolic++;
      }
      if (reading.heartRate != null) {
        avgHeartRate += reading.heartRate!;
        countHeartRate++;
      }
      if (reading.bloodSugar != null) {
        avgSugar += reading.bloodSugar!;
        countSugar++;
      }
      if (reading.weight != null) {
        avgWeight += reading.weight!;
        countWeight++;
      }
      if (reading.temperature != null) {
        avgTemp += reading.temperature!;
        countTemp++;
      }
      if (reading.oxygenSaturation != null) {
        avgOxygen += reading.oxygenSaturation!;
        countOxygen++;
      }
    }
    
    return {
      'hasData': true,
      'totalReadings': readings.length,
      'averages': {
        'bloodPressure': countSystolic > 0 
            ? '${(avgSystolic / countSystolic).toStringAsFixed(0)}/${(avgDiastolic / countDiastolic).toStringAsFixed(0)}'
            : null,
        'heartRate': countHeartRate > 0 
            ? (avgHeartRate / countHeartRate).toStringAsFixed(0)
            : null,
        'bloodSugar': countSugar > 0 
            ? (avgSugar / countSugar).toStringAsFixed(1)
            : null,
        'weight': countWeight > 0 
            ? (avgWeight / countWeight).toStringAsFixed(1)
            : null,
        'temperature': countTemp > 0 
            ? (avgTemp / countTemp).toStringAsFixed(1)
            : null,
        'oxygenSaturation': countOxygen > 0 
            ? (avgOxygen / countOxygen).toStringAsFixed(1)
            : null,
      },
      'latestReading': readings.first.toJson(),
      'hasAbnormalValues': await hasAbnormalReadings(userId),
    };
  }
}