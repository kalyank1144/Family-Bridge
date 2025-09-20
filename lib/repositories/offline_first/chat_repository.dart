import 'package:hive/hive.dart';

import '../../models/hive/message_model.dart';
import 'base_offline_repository.dart';

class ChatRepository extends BaseOfflineRepository<HiveChatMessage> {
  ChatRepository({required Box<HiveChatMessage> box})
      : super(
          table: 'messages',
          box: box,
          fromMap: (m) => HiveChatMessage.fromMap(m),
          toMap: (m) => m.toMap(),
        );

  Stream<List<HiveChatMessage>> watchFamilyMessages(String familyId) {
    return box.watch().map((_) => _familyMessages(familyId));
  }

  List<HiveChatMessage> getFamilyMessages(String familyId) => _familyMessages(familyId);

  List<HiveChatMessage> _familyMessages(String familyId) {
    final list = box.values.where((m) => m.familyId == familyId).toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }
}
