import 'dart:math';

import 'package:family_bridge/features/caregiver/models/family_member.dart';
import 'package:family_bridge/features/caregiver/models/health_data.dart';

class HealthAnomaly {
  final String memberId;
  final String title;
  final String description;
  final DateTime timestamp;
  final double severity; // 0-1

  HealthAnomaly({
    required this.memberId,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.severity,
  });
}

class HealthAnalyticsSummary {
  final double avgHeartRate;
  final String? maxBloodPressure;
  final int totalSteps;
  final double avgMedicationCompliance;

  HealthAnalyticsSummary({
    required this.avgHeartRate,
    required this.maxBloodPressure,
    required this.totalSteps,
    required this.avgMedicationCompliance,
  });
}

class HealthAnalyticsService {
  HealthAnalyticsSummary summarizeCurrent(List<FamilyMember> members) {
    final hr = <double>[];
    final bp = <List<int>>[];
    int steps = 0;
    double compliance = 0;

    for (final m in members) {
      final heartRate = _toDouble(m.vitals['heartRate']);
      if (heartRate != null) hr.add(heartRate);
      final bpStr = m.vitals['bloodPressure']?.toString();
      if (bpStr != null && bpStr.contains('/')) {
        final parts = bpStr.split('/');
        final s = int.tryParse(parts[0]);
        final d = int.tryParse(parts[1]);
        if (s != null && d != null) bp.add([s, d]);
      }
      steps += (m.vitals['steps'] as int?) ?? 0;
      compliance += m.medicationCompliance;
    }

    final avgHr = hr.isEmpty ? 0 : hr.reduce((a, b) => a + b) / hr.length;
    List<int>? maxBp;
    for (final p in bp) {
      if (maxBp == null || p[0] > maxBp[0]) maxBp = p;
    }

    final avgCompliance = members.isEmpty ? 0 : compliance / members.length;

    return HealthAnalyticsSummary(
      avgHeartRate: double.parse(avgHr.toStringAsFixed(1)),
      maxBloodPressure: maxBp != null ? '${maxBp[0]}/${maxBp[1]}' : null,
      totalSteps: steps,
      avgMedicationCompliance: avgCompliance,
    );
  }

  List<HealthAnomaly> detectAnomalies(List<FamilyMember> members) {
    final anomalies = <HealthAnomaly>[];
    for (final m in members) {
      final hr = _toDouble(m.vitals['heartRate']);
      if (hr != null && (hr < 50 || hr > 110)) {
        anomalies.add(HealthAnomaly(
          memberId: m.id,
          title: 'Abnormal Heart Rate',
          description: '${m.name}\'s heart rate is ${hr.toStringAsFixed(0)} bpm',
          timestamp: DateTime.now(),
          severity: hr > 120 ? 0.9 : 0.7,
        ));
      }
      final bpStr = m.vitals['bloodPressure']?.toString();
      if (bpStr != null && bpStr.contains('/')) {
        final s = int.tryParse(bpStr.split('/')[0]) ?? 0;
        final d = int.tryParse(bpStr.split('/')[1]) ?? 0;
        if (s >= 140 || d >= 90) {
          anomalies.add(HealthAnomaly(
            memberId: m.id,
            title: 'High Blood Pressure',
            description: '${m.name}\'s BP is $bpStr',
            timestamp: DateTime.now(),
            severity: s >= 160 || d >= 100 ? 0.95 : 0.75,
          ));
        }
      }
      if (m.medicationCompliance < 0.8) {
        anomalies.add(HealthAnomaly(
          memberId: m.id,
          title: 'Low Medication Compliance',
          description: '${m.name}\'s compliance ${(_pct(m.medicationCompliance))}%',
          timestamp: DateTime.now(),
          severity: 0.6,
        ));
      }
    }
    return anomalies;
  }

  double riskScore(FamilyMember m) {
    double score = 0.0;
    final hr = _toDouble(m.vitals['heartRate']);
    if (hr != null && (hr < 55 || hr > 105)) score += 0.25;
    final bpStr = m.vitals['bloodPressure']?.toString();
    if (bpStr != null && bpStr.contains('/')) {
      final s = int.tryParse(bpStr.split('/')[0]) ?? 0;
      final d = int.tryParse(bpStr.split('/')[1]) ?? 0;
      if (s >= 140 || d >= 90) score += 0.35;
    }
    if (m.medicationCompliance < 0.85) score += 0.25;
    if ((m.activeAlerts).isNotEmpty) score += 0.15;
    return min(1.0, score);
  }

  String trendOf(List<double> values) {
    if (values.length < 2) return 'stable';
    final first = values.first;
    final last = values.last;
    if (last > first * 1.05) return 'up';
    if (last < first * 0.95) return 'down';
    return 'stable';
  }

  int _pct(double v) => (v.clamp(0, 1) * 100).round();
  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
