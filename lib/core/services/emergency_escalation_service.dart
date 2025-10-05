import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';
import 'package:family_bridge/features/chat/services/emergency_service.dart';

class EmergencyEscalationService {
  EmergencyEscalationService._internal();
  static final EmergencyEscalationService instance = EmergencyEscalationService._internal();
  final _supabase = Supabase.instance.client;

  final _timers = <String, Timer>{};

  Future<String> startEmergency({required String familyId, required String initiatorId, required String title, required String message, required HelpRequestType helpType, String? location}) async {
    final res = await _supabase.from('emergency_events').insert({
      'family_id': familyId,
      'initiator_id': initiatorId,
      'title': title,
      'message': message,
      'help_type': helpType.name,
      'location': location,
      'status': 'active',
    }).select('id').single();
    final eventId = res['id'] as String;
    await NotificationService.instance.sendEmergencyNotification(title: title, message: message, helpType: helpType, location: location);
    _scheduleEscalation(eventId, familyId, helpType);
    return eventId;
  }

  Future<void> acknowledge(String eventId, String userId) async {
    await _supabase.from('emergency_events').update({
      'acknowledged_by': [userId],
      'acknowledged_at': DateTime.now().toIso8601String(),
    }).eq('id', eventId);
    _timers.remove(eventId)?.cancel();
  }

  void _scheduleEscalation(String eventId, String familyId, HelpRequestType helpType) {
    _timers[eventId]?.cancel();
    _timers[eventId] = Timer(const Duration(minutes: 3), () async {
      final ev = await _supabase.from('emergency_events').select('status, acknowledged_by').eq('id', eventId).single();
      final ack = (ev['acknowledged_by'] as List?)?.isNotEmpty ?? false;
      final active = ev['status'] == 'active';
      if (active && !ack) {
        await _supabase.from('emergency_events').update({'status': 'escalated', 'escalated_at': DateTime.now().toIso8601String()}).eq('id', eventId);
        await NotificationService.instance.sendEmergencyNotification(title: 'Escalation', message: 'No response yet. Escalating emergency.', helpType: helpType);
      }
    });
  }
}
