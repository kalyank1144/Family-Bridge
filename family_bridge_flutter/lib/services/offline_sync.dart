import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/local_storage.dart';
import '../services/supabase_client.dart';

class SyncOperation {
  final String table;
  final String action; // insert | update | delete | upsert
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  SyncOperation({required this.table, required this.action, required this.payload, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'table': table,
        'action': action,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  static SyncOperation fromJson(Map<dynamic, dynamic> json) => SyncOperation(
        table: json['table'] as String,
        action: json['action'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class SyncService {
  static Future<void> enqueue(SyncOperation op) async {
    final box = LocalStorage.syncQueue;
    await box.add(jsonEncode(op.toJson()));
  }

  static Future<void> processQueue() async {
    final box = LocalStorage.syncQueue;
    final client = SupabaseService.client;

    final toRemove = <int>[];
    for (final key in box.keys) {
      final raw = box.get(key) as String;
      final op = SyncOperation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      try {
        final table = client.from(op.table);
        switch (op.action) {
          case 'insert':
            await table.insert(op.payload);
            break;
          case 'update':
            await table.upsert(op.payload);
            break;
          case 'upsert':
            await table.upsert(op.payload);
            break;
          case 'delete':
            final id = op.payload['id'];
            await table.delete().eq('id', id);
            break;
          default:
            break;
        }
        toRemove.add(key as int);
      } on PostgrestException {
        // Leave in queue; likely conflict or server issue.
      } catch (_) {
        // network or other; keep in queue
      }
    }

    for (final key in toRemove) {
      await box.delete(key);
    }
  }
}
