import 'package:hive/hive.dart';

import 'package:family_bridge/services/offline/offline_manager.dart';
import 'package:family_bridge/services/sync/sync_queue.dart';

typedef Json = Map<String, dynamic>;

typedef FromMap<T> = T Function(Json);

typedef ToMap<T> = Json Function(T);

abstract class BaseOfflineRepository<T> {
  final String table;
  final Box<T> box;
  final FromMap<T> fromMap;
  final ToMap<T> toMap;

  const BaseOfflineRepository({
    required this.table,
    required this.box,
    required this.fromMap,
    required this.toMap,
  });

  Future<List<T>> getAll() async => box.values.toList();

  Future<T?> getById(String id) async => box.get(id);

  Stream<List<T>> watchAll() => box.watch().map((_) => box.values.toList());

  Future<void> upsertLocal(T model, {String? id}) async {
    final key = id ?? toMap(model)['id'] as String;
    await box.put(key, model);
  }

  Future<void> deleteLocal(String id) async => box.delete(id);

  Future<void> upsert(T model) async {
    await upsertLocal(model);
    await OfflineManager.instance.executeOrQueue(
      table: table,
      payload: toMap(model),
      type: SyncOpType.update,
    );
  }

  Future<void> create(T model) async {
    await upsertLocal(model);
    await OfflineManager.instance.executeOrQueue(
      table: table,
      payload: toMap(model),
      type: SyncOpType.create,
    );
  }

  Future<void> delete(String id) async {
    await deleteLocal(id);
    await OfflineManager.instance.executeOrQueue(
      table: table,
      payload: {'id': id},
      type: SyncOpType.delete,
    );
  }
}
