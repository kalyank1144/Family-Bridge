import 'package:hive/hive.dart';

import '../../models/hive/emergency_contact_model.dart';
import 'base_offline_repository.dart';

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