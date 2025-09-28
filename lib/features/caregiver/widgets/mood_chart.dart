import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:family_bridge/core/theme/app_theme.dart';

class MoodChart extends StatelessWidget {
  final List<int> moodData;

  const MoodChart({
    super.key,
    required this.moodData,
  });

  @override
  Widget build(BuildContext context) {
    if (moodData.isEmpty) {
      return Card(
        child: Container(
          height: 250,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mood_bad,
                  size: 48,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'No mood data available',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '7-Day Mood Trend',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildMoodLegend(context),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          );
                        },
                        reservedSize: 20,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 22,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (moodData.length - 1).toDouble(),
                  minY: 0,
                  maxY: 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: moodData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: _getMoodColor(moodData.last),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: _getMoodColor(spot.y.toInt()),
                            strokeWidth: 0,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            _getMoodColor(moodData.last).withOpacity(0.3),
                            _getMoodColor(moodData.last).withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildMoodEmojis(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodLegend(BuildContext context) {
    return Row(
      children: [
        _buildLegendItem(context, 'Poor', AppTheme.errorColor),
        const SizedBox(width: 12),
        _buildLegendItem(context, 'Good', AppTheme.successColor),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodEmojis(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMoodEmoji('😔', 'Very Bad', 1),
        _buildMoodEmoji('😟', 'Bad', 2),
        _buildMoodEmoji('😐', 'Neutral', 3),
        _buildMoodEmoji('🙂', 'Good', 4),
        _buildMoodEmoji('😊', 'Very Good', 5),
      ],
    );
  }

  Widget _buildMoodEmoji(String emoji, String label, int value) {
    final isRecent = moodData.isNotEmpty && moodData.last == value;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isRecent
                ? _getMoodColor(value).withOpacity(0.2)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: isRecent
                ? Border.all(color: _getMoodColor(value), width: 2)
                : null,
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isRecent ? _getMoodColor(value) : AppTheme.textTertiary,
            fontWeight: isRecent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Color _getMoodColor(int mood) {
    if (mood >= 4) return AppTheme.successColor;
    if (mood >= 3) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}