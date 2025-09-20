import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LargeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool filled;

  const LargeActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = AppTheme.primaryBlue,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = filled
        ? ElevatedButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size(double.infinity, 80),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 80),
            side: BorderSide(color: color, width: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: filled ? Colors.white : color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: filled ? Colors.white : color,
          ),
        ),
      ],
    );

    return filled
        ? ElevatedButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}
