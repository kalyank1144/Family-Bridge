import 'package:hive/hive.dart';

import 'base_offline_repository.dart';
import 'package:family_bridge/models/hive/emergency_contact_model.dart';

class EmergencyContactRepository extends BaseOfflineRepository<HiveEmergencyContact> {
  EmergencyContactRepository({required Box<HiveEmergencyContact> box})
      : super(
          table: 'emergency_contacts',
          box: box,
          fromMap: (m) => HiveEmergencyContact.fromMap(m),
          toMap: (m) => m.toMap(),
        );

  List<HiveEmergencyContact> getUserContacts(String userId) {
    return box.values
        .where((contact) => contact.userId == userId)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  Stream<List<HiveEmergencyContact>> watchUserContacts(String userId) {
    return box.watch().map((_) => getUserContacts(userId));
  }
}