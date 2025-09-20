import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../repositories/offline_first/appointment_repository.dart';
import '../../../services/sync/data_sync_service.dart';
import '../../../models/hive/appointment_model.dart';
import '../models/appointment.dart';
import '../../../core/services/notification_service.dart';

class AppointmentsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  
  late AppointmentRepository _repo;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await DataSyncService.instance.initialize();
    _repo = AppointmentRepository(box: DataSyncService.instance.appointmentsBox);
    _initialized = true;
  }

  Future<List<Appointment>> getAppointments() async {
    await initialize();
    
    try {
      final hiveAppointments = _repo.box.values.toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      
      return hiveAppointments.map(_fromHiveAppointment).toList();
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      return [];
    }
  }

  Future<List<Appointment>> getUserAppointments(String userId) async {
    await initialize();
    
    try {
      final hiveAppointments = _repo.getUserAppointments(userId);
      return hiveAppointments.map(_fromHiveAppointment).toList();
    } catch (e) {
      debugPrint('Error loading user appointments: $e');
      return [];
    }
  }

  Stream<List<Appointment>> watchUserAppointments(String userId) async* {
    await initialize();
    
    await for (final hiveAppointments in _repo.watchUserAppointments(userId)) {
      yield hiveAppointments.map(_fromHiveAppointment).toList();
    }
  }

  Future<Appointment> addAppointment(Appointment appointment) async {
    await initialize();
    
    final id = appointment.id.isNotEmpty ? appointment.id : _uuid.v4();
    final hiveAppointment = _toHiveAppointment(appointment, id);
    
    await _repo.create(hiveAppointment);
    if (appointment.reminderDateTime != null) {
      await NotificationService.instance.scheduleAppointmentReminder(
        title: 'Appointment Reminder',
        message: appointment.title,
        scheduledTime: appointment.reminderDateTime!,
        appointmentId: id,
      );
    }
    
    return appointment.copyWith(id: id);
  }

  Future<void> updateAppointment(Appointment appointment) async {
    await initialize();
    
    final hiveAppointment = _toHiveAppointment(appointment, appointment.id);
    await _repo.upsert(hiveAppointment);
    if (appointment.reminderDateTime != null) {
      await NotificationService.instance.scheduleAppointmentReminder(
        title: 'Appointment Reminder',
        message: appointment.title,
        scheduledTime: appointment.reminderDateTime!,
        appointmentId: appointment.id,
      );
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await initialize();
    
    final existing = _repo.box.get(appointmentId);
    if (existing != null) {
      existing.status = 'cancelled';
      existing.updatedAt = DateTime.now();
      await _repo.upsert(existing);
    }
  }

  Future<List<Appointment>> getUpcomingAppointments(String userId, {int days = 7}) async {
    await initialize();
    
    final hiveAppointments = _repo.getUpcomingAppointments(userId, days: days);
    return hiveAppointments.map(_fromHiveAppointment).toList();
  }

  Future<List<Appointment>> getTodayAppointments(String userId) async {
    await initialize();
    
    final hiveAppointments = _repo.getTodayAppointments(userId);
    return hiveAppointments.map(_fromHiveAppointment).toList();
  }

  void dispose() {
    // Nothing to dispose for offline-first approach
  }

  // Conversion helpers
  HiveAppointment _toHiveAppointment(Appointment appointment, String id) {
    return HiveAppointment(
      id: id,
      userId: appointment.memberId ?? 'default',
      familyId: appointment.familyId ?? 'default',
      title: appointment.title,
      description: appointment.description,
      startAt: appointment.dateTime,
      endAt: appointment.endDateTime,
      reminderAt: appointment.reminderDateTime,
      status: appointment.status ?? 'scheduled',
    );
  }

  Appointment _fromHiveAppointment(HiveAppointment hiveAppointment) {
    return Appointment(
      id: hiveAppointment.id,
      title: hiveAppointment.title,
      description: hiveAppointment.description,
      dateTime: hiveAppointment.startAt,
      endDateTime: hiveAppointment.endAt,
      reminderDateTime: hiveAppointment.reminderAt,
      location: '', // Not stored in Hive model, could extend
      memberId: hiveAppointment.userId,
      familyId: hiveAppointment.familyId,
      status: hiveAppointment.status,
      type: AppointmentType.medical, // Default, could be stored in metadata
    );
  }
}