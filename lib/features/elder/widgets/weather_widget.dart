import 'package:flutter/material.dart';

import 'package:family_bridge/core/theme/app_theme.dart';

class WeatherWidget extends StatelessWidget {
  final double temperature;
  final String description;
  final String icon;

  const WeatherWidget({
    super.key,
    required this.temperature,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${temperature.round()}°F',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutralGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}