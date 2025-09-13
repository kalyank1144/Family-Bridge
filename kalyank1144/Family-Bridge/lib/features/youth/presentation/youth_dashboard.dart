import 'package:flutter/material.dart';

class YouthDashboard extends StatelessWidget {
  const YouthDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Youth Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Stories'),
          SizedBox(height: 12),
          Text('Care Points'),
          SizedBox(height: 12),
          Text('Messages'),
        ],
      ),
    );
  }
}
