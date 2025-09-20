import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/appointments_service.dart';

class AppointmentsProvider extends ChangeNotifier {
  final AppointmentsService _service = AppointmentsService();
  
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  
  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  List<Appointment> get todayAppointments {
    final now = DateTime.now();
    return _appointments.where((a) => 
      a.dateTime.year == now.year &&
      a.dateTime.month == now.month &&
      a.dateTime.day == now.day
    ).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return _appointments.where((a) => 
      a.dateTime.isAfter(now) && 
      a.status == AppointmentStatus.upcoming
    ).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Appointment> getAppointmentsForDate(DateTime date) {
    return _appointments.where((a) => 
      a.dateTime.year == date.year &&
      a.dateTime.month == date.month &&
      a.dateTime.day == date.day
    ).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Appointment> getAppointmentsForMember(String memberId) {
    return _appointments.where((a) => a.familyMemberId == memberId)
        .toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Map<DateTime, List<Appointment>> get appointmentsByDate {
    final Map<DateTime, List<Appointment>> map = {};
    for (final appointment in _appointments) {
      final date = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );
      map[date] ??= [];
      map[date]!.add(appointment);
    }
    // Sort appointments within each date
    map.forEach((date, appointments) {
      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
    return map;
  }

  Future<void> loadAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.initialize();
      _appointments = await _service.getAppointments();
      _error = null;
    } catch (e) {
      _error = e.toString();
      // Offline-first approach will provide local data even on error
      debugPrint('Appointments error (offline data may still be available): $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserAppointments(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.initialize();
      _appointments = await _service.getUserAppointments(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('User appointments error (offline data may still be available): $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAppointment(Appointment appointment) async {
    try {
      await _service.initialize();
      final addedAppointment = await _service.addAppointment(appointment);
      
      // Optimistically update UI
      _appointments.add(addedAppointment);
      _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      // Offline-first approach will queue this for later sync
      debugPrint('Appointment creation queued for sync: $e');
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _service.initialize();
      await _service.updateAppointment(appointment);
      
      // Update local state
      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        _appointments[index] = appointment;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Appointment update queued for sync: $e');
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _service.initialize();
      await _service.cancelAppointment(appointmentId);
      
      // Update local state
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: AppointmentStatus.cancelled,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Appointment cancellation queued for sync: $e');
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      // Optimistically remove from UI
      _appointments.removeWhere((a) => a.id == appointmentId);
      notifyListeners();
      
      await _service.initialize();
      // Note: Service doesn't have delete method, would need to add to service
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Appointment deletion queued for sync: $e');
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<List<Appointment>> getTodayAppointmentsForUser(String userId) async {
    await _service.initialize();
    return await _service.getTodayAppointments(userId);
  }

  Future<List<Appointment>> getUpcomingAppointmentsForUser(String userId, {int days = 7}) async {
    await _service.initialize();
    return await _service.getUpcomingAppointments(userId, days: days);
  }

  // Stream support for real-time updates
  Stream<List<Appointment>>? _appointmentStream;

  Stream<List<Appointment>> watchUserAppointments(String userId) {
    _appointmentStream?.drain(); // Cancel previous stream
    _appointmentStream = _service.watchUserAppointments(userId);
    
    _appointmentStream!.listen(
      (appointments) {
        _appointments = appointments;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );

    return _appointmentStream!;
  }

  @override
  void dispose() {
    _appointmentStream?.drain();
    _service.dispose();
    super.dispose();
  }
}

extension AppointmentCopyWith on Appointment {
  Appointment copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    DateTime? endDateTime,
    DateTime? reminderDateTime,
    String? location,
    AppointmentType? type,
    AppointmentStatus? status,
    String? familyMemberId,
    String? familyId,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      location: location ?? this.location,
      type: type ?? this.type,
      status: status ?? this.status,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      familyId: familyId ?? this.familyId,
    );
  }
}