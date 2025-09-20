import 'package:flutter/material.dart';

enum AppointmentType { 
  doctorVisit, 
  labWork, 
  therapy, 
  checkup, 
  vaccination, 
  dental, 
  specialist,
  other 
}

enum AppointmentStatus { 
  upcoming, 
  inProgress, 
  completed, 
  cancelled, 
  missed 
}

class Appointment {
  final String id;
  final String familyMemberId;
  final String familyMemberName;
  final String doctorName;
  final String location;
  final DateTime dateTime;
  final AppointmentType type;
  final AppointmentStatus status;
  final String? notes;
  final bool hasReminder;
  final String? transportationDetails;
  final List<String> requiredDocuments;
  final String? phoneNumber;
  final Color memberColor;

  Appointment({
    required this.id,
    required this.familyMemberId,
    required this.familyMemberName,
    required this.doctorName,
    required this.location,
    required this.dateTime,
    required this.type,
    this.status = AppointmentStatus.upcoming,
    this.notes,
    this.hasReminder = true,
    this.transportationDetails,
    this.requiredDocuments = const [],
    this.phoneNumber,
    required this.memberColor,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      familyMemberId: json['family_member_id'] as String,
      familyMemberName: json['family_member_name'] as String,
      doctorName: json['doctor_name'] as String,
      location: json['location'] as String,
      dateTime: DateTime.parse(json['date_time'] as String),
      type: AppointmentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AppointmentType.other,
      ),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AppointmentStatus.upcoming,
      ),
      notes: json['notes'] as String?,
      hasReminder: json['has_reminder'] as bool? ?? true,
      transportationDetails: json['transportation_details'] as String?,
      requiredDocuments: List<String>.from(json['required_documents'] ?? []),
      phoneNumber: json['phone_number'] as String?,
      memberColor: Color(json['member_color'] as int? ?? 0xFF6B46C1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_member_id': familyMemberId,
      'family_member_name': familyMemberName,
      'doctor_name': doctorName,
      'location': location,
      'date_time': dateTime.toIso8601String(),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'notes': notes,
      'has_reminder': hasReminder,
      'transportation_details': transportationDetails,
      'required_documents': requiredDocuments,
      'phone_number': phoneNumber,
      'member_color': memberColor.value,
    };
  }

  String get typeLabel {
    switch (type) {
      case AppointmentType.doctorVisit:
        return 'Doctor Visit';
      case AppointmentType.labWork:
        return 'Lab Work';
      case AppointmentType.therapy:
        return 'Therapy';
      case AppointmentType.checkup:
        return 'Check-up';
      case AppointmentType.vaccination:
        return 'Vaccination';
      case AppointmentType.dental:
        return 'Dental';
      case AppointmentType.specialist:
        return 'Specialist';
      case AppointmentType.other:
        return 'Other';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case AppointmentType.doctorVisit:
        return Icons.medical_services;
      case AppointmentType.labWork:
        return Icons.biotech;
      case AppointmentType.therapy:
        return Icons.psychology;
      case AppointmentType.checkup:
        return Icons.health_and_safety;
      case AppointmentType.vaccination:
        return Icons.vaccines;
      case AppointmentType.dental:
        return Icons.medical_information;
      case AppointmentType.specialist:
        return Icons.person_search;
      case AppointmentType.other:
        return Icons.event_note;
    }
  }

  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  bool get isPast => dateTime.isBefore(DateTime.now());

  String get timeFormatted {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}