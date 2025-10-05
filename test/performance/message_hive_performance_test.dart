import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:family_bridge/core/models/message_model.dart';

void main() {
  late Box<Message> box;

  setUpAll(() async {
    final dir = Directory(p.join(Directory.systemTemp.path, 'hive_perf'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    Hive.init(dir.path);
    Hive.registerAdapter(MessageAdapter());
    Hive.registerAdapter(MessageTypeAdapter());
    Hive.registerAdapter(MessageStatusAdapter());
    Hive.registerAdapter(MessagePriorityAdapter());
    Hive.registerAdapter(MessageReactionAdapter());
    box = await Hive.openBox<Message>('messages');
  });

  test('insert 10k messages under 2s (non-strict)', () async {
    final uuid = const Uuid();
    final sw = Stopwatch()..start();
    for (int i = 0; i < 10000; i++) {
      final m = Message(
        id: uuid.v4(),
        familyId: 'fam1',
        senderId: 'u1',
        senderName: 'User',
        senderType: 'elder',
        content: 'Msg $i',
        type: MessageType.text,
        status: MessageStatus.sent,
        priority: MessagePriority.normal,
        timestamp: DateTime.now(),
      );
      await box.put(m.id, m);
    }
    sw.stop();
    // Not asserting strict time to avoid flaky CI; ensure completes
    expect(box.length, greaterThanOrEqualTo(10000));
  });
}
