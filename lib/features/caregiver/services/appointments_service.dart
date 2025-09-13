import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';

class AppointmentsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Appointment>> getAppointments() async {
    try {
      final response = await _supabase
          .from('appointments')
          .select()
          .order('date_time', ascending: true);
      
      return (response as List)
          .map((json) => Appointment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load appointments: $e');
    }
  }

  Future<Appointment> addAppointment(Appointment appointment) async {
    try {
      final response = await _supabase
          .from('appointments')
          .insert(appointment.toJson())
          .select()
          .single();
      
      return Appointment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add appointment: $e');
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _supabase
          .from('appointments')
          .update(appointment.toJson())
          .eq('id', appointment.id);
    } catch (e) {
      throw Exception('Failed to update appointment: $e');
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId);
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  void dispose() {}
}