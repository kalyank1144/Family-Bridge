import 'package:flutter/material.dart';

class ElderDashboard extends StatelessWidget {
  const ElderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elder Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Daily Check-In'),
          SizedBox(height: 12),
          Text('Medications'),
          SizedBox(height: 12),
          Text('Emergency Contacts'),
        ],
      ),
    );
  }
}
