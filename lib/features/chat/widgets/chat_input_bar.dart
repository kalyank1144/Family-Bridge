import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String userType;
  final Function(String) onSendText;
  final VoidCallback onRecordVoice;
  final VoidCallback onAttachMedia;
  final VoidCallback onSendLocation;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.userType,
    required this.onSendText,
    required this.onRecordVoice,
    required this.onAttachMedia,
    required this.onSendLocation,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> with TickerProviderStateMixin {
  bool _hasText = false;
  late AnimationController _voiceButtonController;
  late AnimationController _sendButtonController;
  bool _isVoiceMode = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    
    _voiceButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Set initial voice mode for elder users
    _isVoiceMode = widget.userType == 'elder';
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
      
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _voiceButtonController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isElder = widget.userType == 'elder';
    final isCaregiver = widget.userType == 'caregiver';
    final isYouth = widget.userType == 'youth';
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isElder ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: _buildInputInterface(isElder, isCaregiver, isYouth),
      ),
    );
  }

  Widget _buildInputInterface(bool isElder, bool isCaregiver, bool isYouth) {
    if (isElder) {
      return _buildElderInterface();
    } else if (isCaregiver) {
      return _buildCaregiverInterface();
    } else if (isYouth) {
      return _buildYouthInterface();
    } else {
      return _buildDefaultInterface();
    }
  }

  Widget _buildElderInterface() {
    return Column(
      children: [
        // Quick response buttons for elders
        if (!_hasText) _buildElderQuickResponses(),
        
        const SizedBox(height: 8),
        
        // Main input row
        Row(
          children: [
            // Voice button (primary for elders)
            _buildVoiceButton(size: 64, isPrimary: true),
            
            const SizedBox(width: 12),
            
            // Text input (simplified)
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        maxLines: 3,
                        minLines: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 20),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            widget.onSendText(text);
                          }
                        },
                      ),
                    ),
                    // Large send button for elders
                    if (_hasText)
                      _buildSendButton(size: 56),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            
            // Emergency button for elders
            const SizedBox(width: 12),
            _buildEmergencyButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildCaregiverInterface() {
    return Column(
      children: [
        // Professional toolbar
        if (!_hasText) _buildCaregiverToolbar(),
        
        const SizedBox(height: 8),
        
        // Main input row
        Row(
          children: [
            // Media attachment button
            _buildIconButton(
              icon: Icons.add_circle_outline,
              onPressed: widget.onAttachMedia,
              color: _getAccentColor(),
              size: 48,
            ),
            
            const SizedBox(width: 8),
            
            // Professional text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 48,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        maxLines: 4,
                        minLines: 1,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            widget.onSendText(text);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Voice or Send button
            _hasText 
                ? _buildSendButton(size: 48)
                : _buildVoiceButton(size: 48),
          ],
        ),
      ],
    );
  }

  Widget _buildYouthInterface() {
    return Column(
      children: [
        // Modern youth toolbar
        if (!_hasText) _buildYouthToolbar(),
        
        const SizedBox(height: 8),
        
        // Main input row
        Row(
          children: [
            // Emoji button
            _buildIconButton(
              icon: Icons.emoji_emotions_outlined,
              onPressed: _showEmojiPicker,
              color: Colors.purple.shade400,
              size: 42,
            ),
            
            const SizedBox(width: 8),
            
            // Modern text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 44,
                  maxHeight: 100,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        maxLines: 3,
                        minLines: 1,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            widget.onSendText(text);
                          }
                        },
                      ),
                    ),
                    // GIF and sticker buttons
                    _buildIconButton(
                      icon: Icons.gif_box_outlined,
                      onPressed: _showGifPicker,
                      color: Colors.purple.shade300,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Voice or Send with animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _hasText
                  ? _buildSendButton(size: 44, key: const Key('send'))
                  : _buildVoiceButton(size: 44, key: const Key('voice')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultInterface() {
    return Row(
      children: [
        if (!_hasText) ...[
          _buildIconButton(
            icon: Icons.add_circle_outline,
            onPressed: widget.onAttachMedia,
            color: _getAccentColor(),
            size: 44,
          ),
          const SizedBox(width: 8),
        ],
        
        Expanded(
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 44,
              maxHeight: 100,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        _hasText 
            ? _buildSendButton(size: 44)
            : _buildVoiceButton(size: 44),
      ],
    );
  }

  Widget _buildElderQuickResponses() {
    final quickResponses = [
      "I'm okay ✅",
      "Need help 🆘",
      "Love you ❤️",
      "Thank you 🙏",
      "Call me 📞",
      "Yes ✅",
      "No ❌",
    ];

    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: quickResponses.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
              onPressed: () {
                widget.onSendText(quickResponses[index]);
                HapticFeedback.lightImpact();
              },
              child: Text(
                quickResponses[index],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCaregiverToolbar() {
    return Row(
      children: [
        _buildToolbarButton(
          icon: Icons.location_on_outlined,
          label: 'Location',
          onPressed: widget.onSendLocation,
          color: Colors.red,
        ),
        const SizedBox(width: 12),
        _buildToolbarButton(
          icon: Icons.note_add_outlined,
          label: 'Care Note',
          onPressed: _addCareNote,
          color: Colors.orange,
        ),
        const SizedBox(width: 12),
        _buildToolbarButton(
          icon: Icons.schedule_outlined,
          label: 'Schedule',
          onPressed: _scheduleMessage,
          color: Colors.blue,
        ),
        const Spacer(),
        _buildToolbarButton(
          icon: Icons.priority_high,
          label: 'Priority',
          onPressed: _setPriority,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildYouthToolbar() {
    return Row(
      children: [
        _buildToolbarButton(
          icon: Icons.photo_camera_outlined,
          label: 'Camera',
          onPressed: _takePhoto,
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        _buildToolbarButton(
          icon: Icons.photo_library_outlined,
          label: 'Gallery',
          onPressed: widget.onAttachMedia,
          color: Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildToolbarButton(
          icon: Icons.auto_stories_outlined,
          label: 'Story',
          onPressed: _shareStory,
          color: Colors.purple,
        ),
        const Spacer(),
        _buildToolbarButton(
          icon: Icons.celebration_outlined,
          label: 'Achievement',
          onPressed: _shareAchievement,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceButton({
    required double size,
    bool isPrimary = false,
    Key? key,
  }) {
    return AnimatedBuilder(
      animation: _voiceButtonController,
      builder: (context, child) {
        return Container(
          key: key,
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade700,
                    ],
                  )
                : null,
            color: isPrimary ? null : _getAccentColor().withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: isPrimary
                ? null
                : Border.all(
                    color: _getAccentColor().withOpacity(0.3),
                    width: 1,
                  ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.mic_rounded,
              color: isPrimary ? Colors.white : _getAccentColor(),
              size: size * 0.4,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.onRecordVoice();
            },
          ),
        );
      },
    );
  }

  Widget _buildSendButton({
    required double size,
    Key? key,
  }) {
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _sendButtonController, curve: Curves.elasticOut),
      ),
      child: Container(
        key: key,
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getAccentColor(),
              _getAccentColor().withOpacity(0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getAccentColor().withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.send_rounded,
            color: Colors.white,
            size: size * 0.4,
          ),
          onPressed: () {
            if (widget.controller.text.trim().isNotEmpty) {
              widget.onSendText(widget.controller.text);
              HapticFeedback.lightImpact();
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade600,
            Colors.red.shade700,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.emergency,
          color: Colors.white,
          size: 28,
        ),
        onPressed: _sendEmergencyAlert,
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: color,
          size: size * 0.4,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Color _getAccentColor() {
    switch (widget.userType) {
      case 'elder':
        return Colors.blue.shade700;
      case 'caregiver':
        return Colors.teal.shade700;
      case 'youth':
        return Colors.purple.shade700;
      default:
        return Colors.blue;
    }
  }

  // Action methods
  void _showEmojiPicker() {
    HapticFeedback.selectionClick();
    // Implement emoji picker
  }

  void _showGifPicker() {
    HapticFeedback.selectionClick();
    // Implement GIF picker
  }

  void _addCareNote() {
    HapticFeedback.selectionClick();
    // Implement care note functionality
  }

  void _scheduleMessage() {
    HapticFeedback.selectionClick();
    // Implement message scheduling
  }

  void _setPriority() {
    HapticFeedback.selectionClick();
    // Implement priority setting
  }

  void _takePhoto() {
    HapticFeedback.selectionClick();
    // Implement camera functionality
  }

  void _shareStory() {
    HapticFeedback.selectionClick();
    // Implement story sharing
  }

  void _shareAchievement() {
    HapticFeedback.selectionClick();
    // Implement achievement sharing
  }

  void _sendEmergencyAlert() {
    HapticFeedback.heavyImpact();
    widget.onSendText('🆘 EMERGENCY: I need immediate help!');
  }
}