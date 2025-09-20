import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';

class VoiceNavigationWidget extends StatefulWidget {
  final String screenName;
  final Map<String, VoidCallback>? screenCommands;
  final Widget child;
  final bool showVoiceButton;
  final bool showHelpButton;

  const VoiceNavigationWidget({
    super.key,
    required this.screenName,
    required this.child,
    this.screenCommands,
    this.showVoiceButton = true,
    this.showHelpButton = true,
  });

  @override
  State<VoiceNavigationWidget> createState() => _VoiceNavigationWidgetState();
}

class _VoiceNavigationWidgetState extends State<VoiceNavigationWidget>
    with TickerProviderStateMixin {
  late VoiceService _voiceService;
  bool _isListening = false;
  bool _isInitialized = false;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVoiceService();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeVoiceService() async {
    _voiceService = context.read<VoiceService>();
    
    // Set the current screen for context-aware help
    _voiceService.setCurrentScreen(widget.screenName);
    
    // Register screen-specific commands
    widget.screenCommands?.forEach((command, callback) {
      _voiceService.registerCommand(command, callback);
    });

    setState(() => _isInitialized = true);
  }

  Future<void> _toggleVoiceListening() async {
    if (!_isInitialized) return;

    HapticFeedback.mediumImpact();

    if (_isListening) {
      await _voiceService.stopListening();
      _waveController.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _waveController.repeat();
      
      await _voiceService.speak('Listening for your command');
      await _voiceService.startListening(
        onResult: (result) {
          // Voice service handles command processing automatically
        },
        listenFor: const Duration(seconds: 10),
      );
      
      // Auto-stop after timeout
      Future.delayed(const Duration(seconds: 10), () {
        if (_isListening && mounted) {
          setState(() => _isListening = false);
          _waveController.stop();
        }
      });
    }
  }

  Future<void> _showHelp() async {
    HapticFeedback.lightImpact();
    _voiceService.registerCommand('help', () {}, isGlobal: true);
    await _voiceService.speak('Showing help for ${widget.screenName}');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      floatingActionButton: _buildFloatingActions(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Help Button
        if (widget.showHelpButton)
          FloatingActionButton(
            heroTag: 'help-${widget.screenName}',
            onPressed: _showHelp,
            backgroundColor: AppTheme.primaryBlue,
            tooltip: 'Get voice help',
            child: const Icon(
              Icons.help_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
        
        if (widget.showHelpButton) const SizedBox(height: 16),
        
        // Voice Button with animations
        if (widget.showVoiceButton)
          AnimatedBuilder(
            animation: _isListening ? _waveAnimation : _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? (1.0 + (_waveAnimation.value * 0.3)) : _pulseAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring for listening state
                    if (_isListening)
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.emergencyRed.withOpacity(0.6),
                            width: 3,
                          ),
                        ),
                      ),
                    
                    // Main voice button
                    FloatingActionButton.large(
                      heroTag: 'voice-${widget.screenName}',
                      onPressed: _isInitialized ? _toggleVoiceListening : null,
                      backgroundColor: _isListening 
                          ? AppTheme.emergencyRed 
                          : AppTheme.successGreen,
                      tooltip: _isListening ? 'Stop listening' : 'Start voice commands',
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        
        const SizedBox(height: 16),
        
        // Voice status indicator
        if (_isListening)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.emergencyRed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.graphic_eq,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Listening...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Extension method to easily wrap screens with voice navigation
extension VoiceNavigationExtension on Widget {
  Widget withVoiceNavigation({
    required String screenName,
    Map<String, VoidCallback>? screenCommands,
    bool showVoiceButton = true,
    bool showHelpButton = true,
  }) {
    return VoiceNavigationWidget(
      screenName: screenName,
      screenCommands: screenCommands,
      showVoiceButton: showVoiceButton,
      showHelpButton: showHelpButton,
      child: this,
    );
  }
}