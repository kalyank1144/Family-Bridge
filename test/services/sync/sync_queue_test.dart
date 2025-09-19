import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:family_bridge/services/sync/sync_queue.dart';

void main() {
  setUpAll(() async {
    final dir = Directory(p.join(Directory.systemTemp.path, 'hive_test_sync'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    Hive.init(dir.path);
    Hive.registerAdapter(SyncOperationAdapter());
    await SyncQueue.instance.initialize();
  });

  test('enqueue and retrieve in FIFO order', () async {
    final id1 = const Uuid().v4();
    final id2 = const Uuid().v4();

    await SyncQueue.instance.enqueue(SyncOperation(
      id: id1,
      box: 'messages',
      table: 'messages',
      type: SyncOpType.create,
      payload: {'id': id1},
    ));
    await Future.delayed(const Duration(milliseconds: 2));
    await SyncQueue.instance.enqueue(SyncOperation(
      id: id2,
      box: 'messages',
      table: 'messages',
      type: SyncOpType.update,
      payload: {'id': id2},
    ));

    final ops = SyncQueue.instance.getAll();
    expect(ops.first.id, id1);
    expect(ops.last.id, id2);
  });
}
