import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'sync_item.g.dart';

enum SyncOperation { create, update, delete }
enum SyncStatus { pending, syncing, failed, completed }
enum SyncPriority { critical, high, normal, low }

@HiveType(typeId: 10)
class SyncItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String operation;

  @HiveField(2)
  late String tableName;

  @HiveField(3)
  late Map<String, dynamic> data;

  @HiveField(4)
  late DateTime timestamp;

  @HiveField(5)
  int retryCount = 0;

  @HiveField(6)
  late String status;

  @HiveField(7)
  String? errorMessage;

  @HiveField(8)
  late String priority;

  @HiveField(9)
  String? userId;

  @HiveField(10)
  String? recordId;

  @HiveField(11)
  int? version;

  @HiveField(12)
  Map<String, dynamic>? conflictData;

  SyncItem({
    String? id,
    required SyncOperation operation,
    required String tableName,
    required Map<String, dynamic> data,
    DateTime? timestamp,
    this.retryCount = 0,
    SyncStatus status = SyncStatus.pending,
    this.errorMessage,
    SyncPriority priority = SyncPriority.normal,
    this.userId,
    this.recordId,
    this.version,
    this.conflictData,
  })  : id = id ?? const Uuid().v4(),
        operation = operation.toString().split('.').last,
        this.tableName = tableName,
        this.data = data,
        timestamp = timestamp ?? DateTime.now(),
        status = status.toString().split('.').last,
        priority = priority.toString().split('.').last;

  SyncOperation get syncOperation =>
      SyncOperation.values.firstWhere((e) => e.toString().split('.').last == operation);

  SyncStatus get syncStatus =>
      SyncStatus.values.firstWhere((e) => e.toString().split('.').last == status);

  SyncPriority get syncPriority =>
      SyncPriority.values.firstWhere((e) => e.toString().split('.').last == priority);

  bool get canRetry => retryCount < 3 && syncStatus == SyncStatus.failed;

  void incrementRetry() {
    retryCount++;
    if (retryCount >= 3) {
      status = SyncStatus.failed.toString().split('.').last;
    }
  }

  void markAsSyncing() {
    status = SyncStatus.syncing.toString().split('.').last;
  }

  void markAsCompleted() {
    status = SyncStatus.completed.toString().split('.').last;
  }

  void markAsFailed(String error) {
    status = SyncStatus.failed.toString().split('.').last;
    errorMessage = error;
    incrementRetry();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation,
      'tableName': tableName,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'status': status,
      'errorMessage': errorMessage,
      'priority': priority,
      'userId': userId,
      'recordId': recordId,
      'version': version,
      'conflictData': conflictData,
    };
  }

  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json['id'],
      operation: SyncOperation.values.firstWhere(
          (e) => e.toString().split('.').last == json['operation']),
      tableName: json['tableName'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
      status: SyncStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status']),
      errorMessage: json['errorMessage'],
      priority: SyncPriority.values.firstWhere(
          (e) => e.toString().split('.').last == json['priority']),
      userId: json['userId'],
      recordId: json['recordId'],
      version: json['version'],
      conflictData: json['conflictData'],
    );
  }
}