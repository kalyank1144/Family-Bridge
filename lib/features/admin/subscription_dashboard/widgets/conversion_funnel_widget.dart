import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ConversionFunnel extends StatelessWidget {
  final int trials;
  final int engaged;
  final int prompted;
  final int converted;

  const ConversionFunnel({super.key, required this.trials, required this.engaged, required this.prompted, required this.converted});

  @override
  Widget build(BuildContext context) {
    final maxV = trials == 0 ? 1 : trials;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conversion Funnel', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMd),
            _row(context, 'Trials', trials, maxV, AppTheme.infoColor),
            const SizedBox(height: 8),
            _row(context, 'Engaged', engaged, maxV, AppTheme.primaryColor),
            const SizedBox(height: 8),
            _row(context, 'Prompted', prompted, maxV, AppTheme.warningColor),
            const SizedBox(height: 8),
            _row(context, 'Converted', converted, maxV, AppTheme.successColor),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, int value, int maxV, Color color) {
    final pct = value / (maxV == 0 ? 1 : maxV);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)), Text(value.toString(), style: Theme.of(context).textTheme.labelLarge)]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(minHeight: 12, value: pct.clamp(0, 1), backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color)),
        ),
      ],
    );
  }
}
