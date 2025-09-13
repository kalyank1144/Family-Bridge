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
    return map;
  }

  AppointmentsProvider() {
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _service.getAppointments();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _loadMockAppointments();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadMockAppointments() {
    final now = DateTime.now();
    final memberColors = [
      const Color(0xFF6B46C1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
    ];

    _appointments = [
      Appointment(
        id: '1',
        familyMemberId: '1',
        familyMemberName: 'Walter',
        doctorName: 'Dr. Smith',
        location: 'Medical Center, Office 302',
        dateTime: DateTime(now.year, now.month, now.day, 9, 0),
        type: AppointmentType.doctorVisit,
        status: AppointmentStatus.upcoming,
        notes: 'Regular checkup',
        phoneNumber: '555-0123',
        memberColor: memberColors[0],
      ),
      Appointment(
        id: '2',
        familyMemberId: '2',
        familyMemberName: 'Eva',
        doctorName: 'Dr. Johnson',
        location: 'Lab Corp, Building B',
        dateTime: DateTime(now.year, now.month, now.day, 11, 30),
        type: AppointmentType.labWork,
        status: AppointmentStatus.upcoming,
        notes: 'Blood work for annual physical',
        phoneNumber: '555-0124',
        memberColor: memberColors[1],
        requiredDocuments: ['Insurance card', 'Lab order'],
      ),
      Appointment(
        id: '3',
        familyMemberId: '1',
        familyMemberName: 'Walter',
        doctorName: 'Dr. Lee',
        location: 'Heart & Vascular Center',
        dateTime: DateTime(now.year, now.month, now.day, 14, 0),
        type: AppointmentType.specialist,
        status: AppointmentStatus.upcoming,
        notes: 'Cardiology follow-up',
        phoneNumber: '555-0125',
        memberColor: memberColors[0],
        transportationDetails: 'Eugene will drive',
      ),
      Appointment(
        id: '4',
        familyMemberId: '2',
        familyMemberName: 'Eva',
        doctorName: 'Dr. Wilson',
        location: 'Physical Therapy Center',
        dateTime: DateTime(now.year, now.month, now.day + 1, 10, 0),
        type: AppointmentType.therapy,
        status: AppointmentStatus.upcoming,
        notes: 'Session 5 of 10',
        phoneNumber: '555-0126',
        memberColor: memberColors[1],
      ),
      Appointment(
        id: '5',
        familyMemberId: '3',
        familyMemberName: 'Eugene',
        doctorName: 'Dr. Brown',
        location: 'Dental Associates',
        dateTime: DateTime(now.year, now.month, now.day + 2, 15, 30),
        type: AppointmentType.dental,
        status: AppointmentStatus.upcoming,
        notes: 'Cleaning',
        phoneNumber: '555-0127',
        memberColor: memberColors[2],
      ),
      Appointment(
        id: '6',
        familyMemberId: '4',
        familyMemberName: 'Sophia',
        doctorName: 'Dr. Martinez',
        location: 'Pediatric Care',
        dateTime: DateTime(now.year, now.month, now.day + 3, 9, 0),
        type: AppointmentType.vaccination,
        status: AppointmentStatus.upcoming,
        notes: 'Annual flu shot',
        phoneNumber: '555-0128',
        memberColor: memberColors[3],
      ),
      Appointment(
        id: '7',
        familyMemberId: '1',
        familyMemberName: 'Walter',
        doctorName: 'Dr. Smith',
        location: 'Medical Center, Office 302',
        dateTime: DateTime(now.year, now.month, now.day - 7, 9, 0),
        type: AppointmentType.doctorVisit,
        status: AppointmentStatus.completed,
        notes: 'Follow-up visit',
        phoneNumber: '555-0123',
        memberColor: memberColors[0],
      ),
    ];
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> addAppointment(Appointment appointment) async {
    try {
      final newAppointment = await _service.addAppointment(appointment);
      _appointments.add(newAppointment);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _service.updateAppointment(appointment);
      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        _appointments[index] = appointment;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _service.cancelAppointment(appointmentId);
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = Appointment(
          id: _appointments[index].id,
          familyMemberId: _appointments[index].familyMemberId,
          familyMemberName: _appointments[index].familyMemberName,
          doctorName: _appointments[index].doctorName,
          location: _appointments[index].location,
          dateTime: _appointments[index].dateTime,
          type: _appointments[index].type,
          status: AppointmentStatus.cancelled,
          notes: _appointments[index].notes,
          hasReminder: _appointments[index].hasReminder,
          transportationDetails: _appointments[index].transportationDetails,
          requiredDocuments: _appointments[index].requiredDocuments,
          phoneNumber: _appointments[index].phoneNumber,
          memberColor: _appointments[index].memberColor,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadAppointments();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}