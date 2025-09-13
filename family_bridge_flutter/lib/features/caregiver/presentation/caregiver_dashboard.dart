import 'package:flutter/material.dart';

class CaregiverDashboard extends StatelessWidget {
  const CaregiverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caregiver Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Health Monitoring'),
          SizedBox(height: 12),
          Text('Appointments'),
          SizedBox(height: 12),
          Text('Messages'),
        ],
      ),
    );
  }
}
