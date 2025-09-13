import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/storage_keys.dart';

typedef SyncHandler = Future<void> Function(Map<String, dynamic> payload);

class SyncQueueService {
  final Box _box = Hive.box(StorageKeys.syncQueueBox);

  Future<void> enqueue(String type, Map<String, dynamic> payload) async {
    final entry = {
      'type': type,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
    };
    await _box.add(jsonEncode(entry));
  }

  Future<void> process(Map<String, SyncHandler> handlers) async {
    final toRemove = <int>[];
    for (int i = 0; i < _box.length; i++) {
      final raw = _box.getAt(i) as String;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type'] as String;
      final payload = (data['payload'] as Map).cast<String, dynamic>();
      final handler = handlers[type];
      if (handler != null) {
        await handler(payload);
        toRemove.add(i);
      }
    }
    // remove processed from oldest to newest accounting for shifting indices
    for (final index in toRemove.reversed) {
      await _box.deleteAt(index);
    }
  }
}
