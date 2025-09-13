import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/family_data_provider.dart';
import '../providers/appointments_provider.dart';
import '../models/appointment.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _selectedMemberId;
  AppointmentType _selectedType = AppointmentType.doctorVisit;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyDataProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: const Text('Add Appointment'),
        leading: IconButton(
          icon: const Icon(FeatherIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMemberSelector(familyProvider),
              const SizedBox(height: AppTheme.spacingMd),
              _buildTypeSelector(),
              const SizedBox(height: AppTheme.spacingMd),
              _buildDateTimePicker(context),
              const SizedBox(height: AppTheme.spacingMd),
              _buildTextFields(),
              const SizedBox(height: AppTheme.spacingLg),
              _buildSaveButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberSelector(FamilyDataProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Family Member',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            DropdownButtonFormField<String>(
              value: _selectedMemberId,
              decoration: const InputDecoration(
                prefixIcon: Icon(FeatherIcons.user),
                hintText: 'Choose a family member',
              ),
              items: provider.familyMembers.map((member) {
                return DropdownMenuItem(
                  value: member.id,
                  child: Text(member.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMemberId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a family member';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Wrap(
              spacing: 8,
              children: AppointmentType.values.map((type) {
                return ChoiceChip(
                  label: Text(_getTypeLabel(type)),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = type;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date & Time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(FeatherIcons.calendar),
                    title: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(FeatherIcons.clock),
                    title: Text(_selectedTime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            TextFormField(
              controller: _doctorNameController,
              decoration: const InputDecoration(
                labelText: 'Doctor Name',
                prefixIcon: Icon(FeatherIcons.user),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter doctor name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(FeatherIcons.mapPin),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
                prefixIcon: Icon(FeatherIcons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(FeatherIcons.fileText),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _saveAppointment(context),
        child: const Padding(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          child: Text('Save Appointment'),
        ),
      ),
    );
  }

  String _getTypeLabel(AppointmentType type) {
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

  void _saveAppointment(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<AppointmentsProvider>();
      final familyProvider = context.read<FamilyDataProvider>();
      final member = familyProvider.getMemberById(_selectedMemberId!);
      
      final appointment = Appointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        familyMemberId: _selectedMemberId!,
        familyMemberName: member?.name ?? '',
        doctorName: _doctorNameController.text,
        location: _locationController.text,
        dateTime: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        type: _selectedType,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
        memberColor: const Color(0xFF6B46C1),
      );
      
      provider.addAppointment(appointment);
      context.pop();
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
