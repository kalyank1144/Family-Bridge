import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/security_banner.dart';
import '../../widgets/secure_card.dart';
import '../../widgets/health_chart.dart';
import '../common/appointments_screen.dart';
import '../common/messages_screen.dart';
import '../common/patient_detail_screen.dart';
import '../../middleware/security_middleware.dart';
import '../../data/repositories/health_repository.dart';
import '../../data/repositories/caregiver_repository.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  int _tab = 0;
  late final HealthRepository _healthRepo;
  late final CaregiverRepository _careRepo;
  @override
  void initState() {
    super.initState();
    _healthRepo = HealthRepository(Supabase.instance.client);
    _careRepo = CaregiverRepository(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Home'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.shield_moon)),
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
          NavigationDestination(icon: Icon(Icons.people), label: 'Patients'),
          NavigationDestination(icon: Icon(Icons.monitor_heart), label: 'Monitoring'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Appointments'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Messages'),
        ],
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 0:
        return _patientsTab();
      case 1:
        return _monitoringTab();
      case 2:
        return const AppointmentsScreen();
      case 3:
        return const MessagesScreen(channelId: 'care_team');
      default:
        return const SizedBox();
    }
  }

  Widget _patientsTab() {
    final ctx = SecurityContext.of(context)!;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _careRepo.streamAssignedPatients(ctx.currentUser.id),
      builder: (context, snapshot) {
        final patients = snapshot.data ?? const [];
        if (patients.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No assigned patients yet'),
            ),
          );
        }
        return ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, i) {
            final p = patients[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(p['full_name'] ?? p['email'] ?? 'Elder'),
                subtitle: Text('Elder ID: ${p['elder_id']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDetailScreen(name: (p['full_name'] ?? p['email'] ?? 'Elder').toString()),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _monitoringTab() {
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
                title: 'Average Heart Rate (Week)',
                values: hr.isEmpty ? [0, 0, 0, 0, 0, 0, 0] : hr,
                labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
              ),
            ),
            const SizedBox(height: 12),
            SecureCard(
              resource: 'health_data',
              action: 'read',
              child: HealthChart(
                title: 'Average Systolic BP (Week)',
                values: sbp.isEmpty ? [0, 0, 0, 0, 0, 0, 0] : sbp,
                labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
              ),
            ),
          ],
        );
      },
    );
  }
}