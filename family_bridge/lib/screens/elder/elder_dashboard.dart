import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../middleware/security_middleware.dart';
import '../../widgets/security_banner.dart';
import '../../widgets/secure_card.dart';
import '../../widgets/health_chart.dart';
import '../../widgets/medication_tile.dart';
import '../common/messages_screen.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/health_repository.dart';

class ElderDashboard extends StatefulWidget {
  const ElderDashboard({super.key});

  @override
  State<ElderDashboard> createState() => _ElderDashboardState();
}

class _ElderDashboardState extends State<ElderDashboard> {
  int _tab = 0;
  late final MedicationsRepository _medRepo;
  late final HealthRepository _healthRepo;
  bool _checkinSubmitted = false;
  bool _pain = false;
  bool _medicationTaken = false;
  String _mood = 'Good';

  @override
  void initState() {
    super.initState();
    _medRepo = MedicationsRepository(Supabase.instance.client);
    _healthRepo = HealthRepository(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elder Home'),
        actions: [
          IconButton(
            onPressed: _exportData,
            icon: const Icon(Icons.download_lock),
            tooltip: 'Export My Data',
          ),
          IconButton(
            onPressed: _emergencyAccess,
            icon: const Icon(Icons.emergency),
            tooltip: 'Emergency',
          ),
        ],
      ),
      body: Column(
        children: [
          const SecurityBanner(),
          Expanded(child: _buildTab()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.vaccines), label: 'Meds'),
          NavigationDestination(icon: Icon(Icons.check_circle), label: 'Check-in'),
          NavigationDestination(icon: Icon(Icons.contacts), label: 'Contacts'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Messages'),
        ],
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 0:
        return _homeTab();
      case 1:
        return _medicationsTab();
      case 2:
        return _checkinTab();
      case 3:
        return _contactsTab();
      case 4:
        return const MessagesScreen(channelId: 'family');
      default:
        return const SizedBox();
    }
  }

  Widget _homeTab() {
    final ctx = SecurityContext.of(context)!;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _healthRepo.watchRecent(ctx.currentUser.id, days: 7),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const [];
        final hr = _healthRepo.toDailyAverages(rows, 'heart_rate');
        final sbp = _healthRepo.toDailyAverages(rows, 'systolic');
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            SecureCard(
              resource: 'health_data',
              action: 'read',
              child: HealthChart(
                title: 'Heart Rate',
                values: hr.isEmpty ? [0, 0, 0, 0, 0, 0, 0] : hr,
                labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
              ),
            ),
            const SizedBox(height: 12),
            SecureCard(
              resource: 'health_data',
              action: 'read',
              child: HealthChart(
                title: 'Blood Pressure (Sys)',
                values: sbp.isEmpty ? [0, 0, 0, 0, 0, 0, 0] : sbp,
                labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _medicationsTab() {
    final ctx = SecurityContext.of(context)!;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _medRepo.watchMyMedications(ctx.currentUser.id),
      builder: (context, snapshot) {
        final meds = snapshot.data ?? const [];
        return ListView(
          children: [
            for (final m in meds)
              MedicationTile(
                name: m['name'] ?? '',
                dosage: m['dosage'] ?? '',
                schedule: m['schedule'] ?? '',
                taken: (m['taken'] ?? false) as bool,
                onToggle: () => _toggleMedication(m['id'] as String, !(m['taken'] ?? false)),
              ),
          ],
        );
      },
    );
  }

  Future<void> _toggleMedication(String id, bool taken) async {
    final ctx = SecurityContext.of(context)!;
    await ctx.securityMiddleware.secureApiCall(
      user: ctx.currentUser,
      resource: 'medications',
      action: 'update',
      requiresConsent: true,
      consentType: 'health_data',
      apiCall: () async {
        await _medRepo.toggleTaken(id, taken);
        return true;
      },
    );
  }

  Widget _checkinTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Check-in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _mood,
            decoration: const InputDecoration(labelText: 'Mood'),
            items: const [
              DropdownMenuItem(value: 'Good', child: Text('Good')),
              DropdownMenuItem(value: 'Okay', child: Text('Okay')),
              DropdownMenuItem(value: 'Bad', child: Text('Bad')),
            ],
            onChanged: (v) => setState(() => _mood = v ?? 'Good'),
          ),
          SwitchListTile(
            value: _pain,
            onChanged: (v) => setState(() => _pain = v),
            title: const Text('Pain today'),
          ),
          SwitchListTile(
            value: _medicationTaken,
            onChanged: (v) => setState(() => _medicationTaken = v),
            title: const Text('Took medication'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _checkinSubmitted ? null : _submitCheckin,
              child: Text(_checkinSubmitted ? 'Submitted' : 'Submit'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCheckin() async {
    final ctx = SecurityContext.of(context)!;
    await ctx.securityMiddleware.secureApiCall(
      user: ctx.currentUser,
      resource: 'health_data',
      action: 'create',
      requiresConsent: true,
      consentType: 'health_data',
      apiCall: () async {
        await _healthRepo.addCheckIn(ctx.currentUser.id, {
          'mood': _mood,
          'pain': _pain,
          'medication_taken': _medicationTaken,
        });
        setState(() => _checkinSubmitted = true);
        return true;
      },
    );
  }

  Widget _contactsTab() {
    final contacts = [
      {'name': 'Alice', 'relation': 'Daughter', 'phone': '555-0100'},
      {'name': 'Bob', 'relation': 'Son', 'phone': '555-0111'},
      {'name': 'Dr. Smith', 'relation': 'Physician', 'phone': '555-0122'},
    ];
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, i) {
        final c = contacts[i];
        return ListTile(
          leading: const Icon(Icons.contact_page),
          title: Text(c['name']!),
          subtitle: Text(c['relation']!),
          trailing: IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
        );
      },
    );
  }

  Future<void> _exportData() async {
    final ctx = SecurityContext.of(context)!;
    final ok = await ctx.securityMiddleware.requireMFA(user: ctx.currentUser, action: 'export_data');
    if (!ok) return;
    await ctx.securityMiddleware.secureApiCall(
      user: ctx.currentUser,
      resource: 'health_data',
      action: 'export',
      apiCall: () async => true,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export requested')));
  }

  Future<void> _emergencyAccess() async {
    final ctx = SecurityContext.of(context)!;
    await ctx.securityMiddleware.handleEmergencyAccess(
      requestingUser: ctx.currentUser,
      patientId: ctx.currentUser.id,
      reason: 'Emergency button tapped',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency team notified')));
  }
}