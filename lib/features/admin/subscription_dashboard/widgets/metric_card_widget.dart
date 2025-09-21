import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final double? trend;
  final IconData icon;
  final Color color;

  const MetricCard({super.key, required this.title, required this.value, this.subtitle, this.trend, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final trendColor = (trend ?? 0) >= 0 ? AppTheme.successColor : AppTheme.errorColor;
    final trendIcon = (trend ?? 0) >= 0 ? Icons.arrow_upward : Icons.arrow_downward;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.bodySmall)),
                if (trend != null)
                  Row(children: [Icon(trendIcon, size: 14, color: trendColor), const SizedBox(width: 4), Text('${(trend!.abs() * 100).toStringAsFixed(1)}%', style: TextStyle(color: trendColor, fontWeight: FontWeight.bold, fontSize: 12))]),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
