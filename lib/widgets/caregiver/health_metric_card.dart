import 'package:flutter/material.dart';

class HealthMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final String trend;

  const HealthMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              _buildTrendIcon(),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 4),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIcon() {
    IconData trendIcon;
    Color trendColor;
    
    switch (trend.toLowerCase()) {
      case 'up':
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        break;
      case 'down':
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        break;
      case 'stable':
      default:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.grey;
        break;
    }
    
    return Icon(
      trendIcon,
      color: trendColor,
      size: 20,
    );
  }
}
