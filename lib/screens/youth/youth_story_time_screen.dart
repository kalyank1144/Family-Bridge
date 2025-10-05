import 'package:flutter/material.dart';
import 'package:family_bridge/config/app_config.dart';

class YouthStoryTimeScreen extends StatefulWidget {
  const YouthStoryTimeScreen({super.key});

  @override
  State<YouthStoryTimeScreen> createState() => _YouthStoryTimeScreenState();
}

class _YouthStoryTimeScreenState extends State<YouthStoryTimeScreen> {
  bool _isRecording = false;
  int _recordingDuration = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.youthBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppConfig.youthPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Record a Story',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              
              Text(
                'Share your story with family',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Record a voice message or type your story',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isRecording
                              ? [
                                  AppConfig.errorColor,
                                  AppConfig.youthPrimaryColor,
                                ]
                              : [
                                  AppConfig.youthPrimaryColor,
                                  AppConfig.primaryColor,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording 
                                    ? AppConfig.errorColor 
                                    : AppConfig.youthPrimaryColor)
                                .withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isRecording = !_isRecording;
                              if (!_isRecording) {
                                _recordingDuration = 0;
                              }
                            });
                          },
                          customBorder: const CircleBorder(),
                          child: Center(
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    if (_isRecording)
                      Column(
                        children: [
                          Text(
                            'Recording...',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppConfig.errorColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDuration(_recordingDuration),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppConfig.youthPrimaryColor,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Tap to start recording',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppConfig.youthPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConfig.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates,
                          color: AppConfig.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Story Prompts',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppConfig.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPromptChip('Tell about your day'),
                    const SizedBox(height: 8),
                    _buildPromptChip('Share a fun memory'),
                    const SizedBox(height: 8),
                    _buildPromptChip('What made you smile today?'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                      label: const Text('Type Story'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: AppConfig.youthPrimaryColor,
                        ),
                        foregroundColor: AppConfig.youthPrimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isRecording
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      icon: const Icon(Icons.send),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppConfig.youthPrimaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptChip(String text) {
    return InkWell(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
