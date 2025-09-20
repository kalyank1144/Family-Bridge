import 'package:hive/hive.dart';

import '../../core/models/message_model.dart';
import 'base_offline_repository.dart';

class ChatRepository extends BaseOfflineRepository<Message> {
  ChatRepository({required Box<Message> box})
      : super(
          table: 'messages',
          box: box,
          fromMap: (m) => Message.fromMap(m),
          toMap: (m) => m.toMap(),
        );

  Stream<List<Message>> watchFamilyMessages(String familyId) {
    return box.watch().map((_) => _familyMessages(familyId));
  }

  List<Message> getFamilyMessages(String familyId) => _familyMessages(familyId);

  List<Message> _familyMessages(String familyId) {
    final list = box.values.where((m) => m.familyId == familyId).toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }
}
