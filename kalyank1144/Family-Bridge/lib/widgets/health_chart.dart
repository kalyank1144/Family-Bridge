import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HealthChart extends StatelessWidget {
  final String title;
  final List<double> values;
  final List<String> labels;

  const HealthChart({
    super.key,
    required this.title,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.monitor_heart, size: 18, color: Colors.redAccent),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                      return Text(labels[i], style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  spots: spots,
                  barWidth: 3,
                  color: Colors.blue,
                  belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.12)),
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}