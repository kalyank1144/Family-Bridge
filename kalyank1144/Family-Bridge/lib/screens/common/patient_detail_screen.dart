import 'package:flutter/material.dart';
import '../../widgets/secure_card.dart';
import '../../widgets/health_chart.dart';

class PatientDetailScreen extends StatelessWidget {
  final String name;
  const PatientDetailScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          SecureCard(
            resource: 'health_data',
            action: 'read',
            child: HealthChart(
              title: 'Heart Rate',
              values: [68, 72, 70, 75, 71, 69, 73],
              labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
            ),
          ),
          SizedBox(height: 12),
          SecureCard(
            resource: 'health_data',
            action: 'read',
            child: HealthChart(
              title: 'Systolic BP',
              values: [118, 122, 121, 125, 119, 117, 120],
              labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
            ),
          ),
        ],
      ),
    );
  }
}