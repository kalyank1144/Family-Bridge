import 'package:flutter/material.dart';

class MedicationTile extends StatelessWidget {
  final String name;
  final String dosage;
  final String schedule;
  final bool taken;
  final VoidCallback? onToggle;

  const MedicationTile({
    super.key,
    required this.name,
    required this.dosage,
    required this.schedule,
    required this.taken,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: taken ? Colors.green : Colors.blue,
        child: Icon(taken ? Icons.check : Icons.medication, color: Colors.white),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$dosage • $schedule'),
      trailing: Switch(value: taken, onChanged: (_) => onToggle?.call()),
    );
  }
}