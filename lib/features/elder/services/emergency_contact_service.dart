import 'package:flutter/foundation.dart';

import 'package:uuid/uuid.dart';

import 'package:family_bridge/features/elder/models/emergency_contact_model.dart';
import 'package:family_bridge/models/hive/emergency_contact_model.dart';
import 'package:family_bridge/repositories/offline_first/emergency_contact_repository.dart';
import 'package:family_bridge/services/sync/data_sync_service.dart';

class EmergencyContactService {
  final _uuid = const Uuid();
  
  late EmergencyContactRepository _repo;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await DataSyncService.instance.initialize();
    _repo = EmergencyContactRepository(box: DataSyncService.instance.emergencyContactsBox);
    _initialized = true;
  }

  Future<List<EmergencyContact>> getUserContacts(String userId) async {
    await initialize();
    
    try {
      final hiveContacts = _repo.getUserContacts(userId);
      return hiveContacts.map(_fromHiveContact).toList();
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');
      return [];
    }
  }

  Stream<List<EmergencyContact>> watchUserContacts(String userId) async* {
    await initialize();
    
    await for (final hiveContacts in _repo.watchUserContacts(userId)) {
      yield hiveContacts.map(_fromHiveContact).toList();
    }
  }

  Future<EmergencyContact> addContact(EmergencyContact contact, String userId) async {
    await initialize();
    
    final id = contact.id.isNotEmpty ? contact.id : _uuid.v4();
    final hiveContact = _toHiveContact(contact, id, userId);
    
    await _repo.create(hiveContact);
    
    return contact.copyWith(id: id);
  }

  Future<void> updateContact(EmergencyContact contact, String userId) async {
    await initialize();
    
    final hiveContact = _toHiveContact(contact, contact.id, userId);
    await _repo.upsert(hiveContact);
  }

  Future<void> deleteContact(String contactId) async {
    await initialize();
    
    await _repo.delete(contactId);
  }

  Future<void> reorderContacts(String userId, List<String> contactIds) async {
    await initialize();
    
    // Update priorities based on new order
    for (int i = 0; i < contactIds.length; i++) {
      final contact = _repo.box.get(contactIds[i]);
      if (contact != null) {
        contact.priority = i + 1;
        contact.updatedAt = DateTime.now();
        await _repo.upsert(contact);
      }
    }
  }

  void dispose() {
    // Nothing to dispose for offline-first approach
  }

  // Conversion helpers
  HiveEmergencyContact _toHiveContact(EmergencyContact contact, String id, String userId) {
    return HiveEmergencyContact(
      id: id,
      userId: userId,
      familyId: 'default', // Should come from context
      name: contact.name,
      relationship: contact.relationship,
      phone: contact.phone,
      photoUrl: contact.photoUrl,
      priority: contact.priority,
      createdAt: contact.createdAt,
    );
  }

  EmergencyContact _fromHiveContact(HiveEmergencyContact hiveContact) {
    return EmergencyContact(
      id: hiveContact.id,
      name: hiveContact.name,
      relationship: hiveContact.relationship,
      phone: hiveContact.phone,
      photoUrl: hiveContact.photoUrl,
      priority: hiveContact.priority,
      createdAt: hiveContact.createdAt,
    );
  }
}

extension EmergencyContactCopyWith on EmergencyContact {
  EmergencyContact copyWith({String? id}) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name,
      relationship: relationship,
      phone: phone,
      photoUrl: photoUrl,
      priority: priority,
      createdAt: createdAt,
    );
  }
}