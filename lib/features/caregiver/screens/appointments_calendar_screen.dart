import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/appointments_provider.dart';
import '../providers/family_data_provider.dart';
import '../models/appointment.dart';
import '../widgets/appointment_card.dart';

class AppointmentsCalendarScreen extends StatefulWidget {
  const AppointmentsCalendarScreen({super.key});

  @override
  State<AppointmentsCalendarScreen> createState() =>
      _AppointmentsCalendarScreenState();
}

class _AppointmentsCalendarScreenState
    extends State<AppointmentsCalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
  }

  List<Appointment> _getAppointmentsForDay(DateTime day) {
    final provider = context.read<AppointmentsProvider>();
    return provider.getAppointmentsForDate(day);
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsProvider = context.watch<AppointmentsProvider>();
    final familyProvider = context.watch<FamilyDataProvider>();
    final selectedAppointments = appointmentsProvider.getAppointmentsForDate(_selectedDay);
    final todayAppointments = appointmentsProvider.todayAppointments;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FeatherIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Appointments Calendar'),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.filter),
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: const Icon(FeatherIcons.download),
            onPressed: _exportCalendar,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendar(appointmentsProvider),
          _buildAppointmentsList(selectedAppointments, familyProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/caregiver/appointments/add'),
        icon: const Icon(FeatherIcons.plus),
        label: const Text('Add Appointment'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildCalendar(AppointmentsProvider provider) {
    return Card(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      child: TableCalendar<Appointment>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getAppointmentsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: AppTheme.textSecondary),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppTheme.accentColor,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markerSize: 6,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          formatButtonTextStyle: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 12,
          ),
          leftChevronIcon: const Icon(
            FeatherIcons.chevronLeft,
            color: AppTheme.primaryColor,
          ),
          rightChevronIcon: const Icon(
            FeatherIcons.chevronRight,
            color: AppTheme.primaryColor,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, appointments) {
            if (appointments.isEmpty) return null;
            
            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: appointments.take(3).map((appointment) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: appointment.memberColor,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(
    List<Appointment> appointments,
    FamilyDataProvider familyProvider,
  ) {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXl),
            topRight: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(_selectedDay),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${appointments.length} appointment${appointments.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (_isToday(_selectedDay))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: appointments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                      ),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        final member = familyProvider.getMemberById(
                          appointment.familyMemberId,
                        );
                        return AppointmentCard(
                          appointment: appointment,
                          member: member,
                          onEdit: () => _editAppointment(appointment),
                          onCall: () => _callDoctor(appointment),
                          onNavigate: () => _navigateToLocation(appointment),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FeatherIcons.calendar,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'No appointments scheduled',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Tap the + button to add an appointment',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Today's Appointments";
    }
    
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return "Tomorrow's Appointments";
    }
    
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Appointments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ListTile(
              leading: const Icon(FeatherIcons.users),
              title: const Text('By Family Member'),
              onTap: () {
                Navigator.pop(context);
                // Implement filter by family member
              },
            ),
            ListTile(
              leading: const Icon(FeatherIcons.activity),
              title: const Text('By Appointment Type'),
              onTap: () {
                Navigator.pop(context);
                // Implement filter by type
              },
            ),
            ListTile(
              leading: const Icon(FeatherIcons.mapPin),
              title: const Text('By Location'),
              onTap: () {
                Navigator.pop(context);
                // Implement filter by location
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calendar exported successfully'),
      ),
    );
  }

  void _editAppointment(Appointment appointment) {
    // Navigate to edit appointment screen
    context.push('/caregiver/appointments/edit/${appointment.id}');
  }

  void _callDoctor(Appointment appointment) {
    if (appointment.phoneNumber != null) {
      // Implement phone call functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling ${appointment.doctorName}...'),
        ),
      );
    }
  }

  void _navigateToLocation(Appointment appointment) {
    // Implement navigation functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to ${appointment.location}...'),
      ),
    );
  }
}