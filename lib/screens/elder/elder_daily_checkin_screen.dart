import 'package:flutter/material.dart';
import 'package:family_bridge/config/app_config.dart';

class ElderDailyCheckinScreen extends StatefulWidget {
  const ElderDailyCheckinScreen({super.key});

  @override
  State<ElderDailyCheckinScreen> createState() => _ElderDailyCheckinScreenState();
}

class _ElderDailyCheckinScreenState extends State<ElderDailyCheckinScreen> {
  String? _selectedMood;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.elderBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppConfig.elderPrimaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Daily Check-in',
          style: TextStyle(
            fontSize: AppConfig.elderButtonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              
              Text(
                'How are you feeling today?',
                style: TextStyle(
                  fontSize: AppConfig.elderButtonFontSize + 4,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MoodButton(
                          emoji: '😊',
                          label: 'Happy',
                          isSelected: _selectedMood == 'happy',
                          onTap: () {
                            setState(() {
                              _selectedMood = 'happy';
                            });
                          },
                        ),
                        
                        _MoodButton(
                          emoji: '😐',
                          label: 'Okay',
                          isSelected: _selectedMood == 'okay',
                          onTap: () {
                            setState(() {
                              _selectedMood = 'okay';
                            });
                          },
                        ),
                        
                        _MoodButton(
                          emoji: '😢',
                          label: 'Sad',
                          isSelected: _selectedMood == 'sad',
                          onTap: () {
                            setState(() {
                              _selectedMood = 'sad';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: AppConfig.elderMinimumTouchTarget,
                child: ElevatedButton(
                  onPressed: _selectedMood != null
                      ? () {
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.elderPrimaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "I'm OK",
                    style: TextStyle(
                      fontSize: AppConfig.elderButtonFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: isSelected 
              ? AppConfig.elderPrimaryColor.withOpacity(0.2) 
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppConfig.elderPrimaryColor 
                : Colors.grey[300]!,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: AppConfig.elderMinimumFontSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? AppConfig.elderPrimaryColor 
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
