import 'package:hive/hive.dart';

import '../../models/hive/appointment_model.dart';
import 'base_offline_repository.dart';

class AppointmentRepository extends BaseOfflineRepository<HiveAppointment> {
  AppointmentRepository({required Box<HiveAppointment> box})
      : super(
          table: 'appointments',
          box: box,
          fromMap: (m) => HiveAppointment.fromMap(m),
          toMap: (m) => m.toMap(),
        );

  List<HiveAppointment> getUserAppointments(String userId) {
    return box.values
        .where((appointment) => appointment.userId == userId)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  Stream<List<HiveAppointment>> watchUserAppointments(String userId) {
    return box.watch().map((_) => getUserAppointments(userId));
  }

  List<HiveAppointment> getFamilyAppointments(String familyId) {
    return box.values
        .where((appointment) => appointment.familyId == familyId)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  List<HiveAppointment> getUpcomingAppointments(String userId, {int days = 7}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    
    return box.values
        .where((appointment) => 
            appointment.userId == userId &&
            appointment.startAt.isAfter(now) &&
            appointment.startAt.isBefore(future) &&
            appointment.status != 'cancelled')
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  List<HiveAppointment> getTodayAppointments(String userId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return box.values
        .where((appointment) => 
            appointment.userId == userId &&
            appointment.startAt.isAfter(todayStart) &&
            appointment.startAt.isBefore(todayEnd) &&
            appointment.status != 'cancelled')
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }
}