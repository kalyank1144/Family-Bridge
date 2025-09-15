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

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isElder = widget.userType == 'elder';
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isElder ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!_hasText) ...[
              _buildIconButton(
                icon: Icons.add_circle_outline,
                onPressed: widget.onAttachMedia,
                color: _getAccentColor(),
              ),
              if (widget.userType == 'caregiver')
                _buildIconButton(
                  icon: Icons.location_on_outlined,
                  onPressed: widget.onSendLocation,
                  color: Colors.red,
                ),
            ],
            Expanded(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: isElder ? 56 : 48,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(isElder ? 28 : 24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.userType == 'youth' && !_hasText)
                      _buildIconButton(
                        icon: Icons.emoji_emotions_outlined,
                        onPressed: _showEmojiPicker,
                        size: isElder ? 28 : 24,
                      ),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: isElder ? 18 : 15,
                        ),
                        decoration: InputDecoration(
                          hintText: isElder ? 'Type or record message...' : 'Message',
                          hintStyle: TextStyle(
                            fontSize: isElder ? 18 : 15,
                            color: Colors.grey.shade500,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isElder ? 20 : 16,
                            vertical: isElder ? 16 : 12,
                          ),
                        ),
                        onSubmitted: _hasText ? widget.onSendText : null,
                      ),
                    ),
                    if (widget.userType == 'caregiver' && !_hasText)
                      _buildIconButton(
                        icon: Icons.mic_none,
                        onPressed: widget.onRecordVoice,
                        size: isElder ? 28 : 24,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    double? size,
  }) {
    final isElder = widget.userType == 'elder';
    
    return IconButton(
      icon: Icon(icon),
      iconSize: size ?? (isElder ? 32 : 24),
      color: color ?? Colors.grey.shade600,
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
    );
  }

  Widget _buildSendButton() {
    final isElder = widget.userType == 'elder';
    final color = _getAccentColor();
    
    if (_hasText) {
      return Container(
        width: isElder ? 56 : 48,
        height: isElder ? 56 : 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.send),
          iconSize: isElder ? 28 : 22,
          color: Colors.white,
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onSendText(widget.controller.text);
          },
        ),
      );
    } else {
      return Container(
        width: isElder ? 56 : 48,
        height: isElder ? 56 : 48,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.mic),
          iconSize: isElder ? 32 : 24,
          color: Colors.white,
          onPressed: () {
            HapticFeedback.heavyImpact();
            widget.onRecordVoice();
          },
        ),
      );
    }
  }

  Color _getAccentColor() {
    switch (widget.userType) {
      case 'elder':
        return Colors.blue;
      case 'caregiver':
        return Colors.teal;
      case 'youth':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select Emoji',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      widget.controller.text += _emojis[index];
                      Navigator.pop(context);
                    },
                    child: Center(
                      child: Text(
                        _emojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  final List<String> _emojis = [
    '😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊',
    '😇', '🙂', '😉', '😌', '😍', '🥰', '😘', '😗',
    '😙', '😚', '☺️', '🙃', '🤗', '🤩', '🤔', '🤨',
    '😐', '😑', '😶', '🙄', '😏', '😣', '😥', '😮',
    '🤐', '😯', '😪', '😫', '😴', '😌', '😛', '😜',
    '😝', '🤤', '😒', '😓', '😔', '😕', '🙁', '☹️',
    '😖', '😞', '😟', '😤', '😢', '😭', '😦', '😧',
    '😨', '😩', '🤯', '😬', '😰', '😱', '🥵', '🥶',
    '😳', '🤪', '😵', '😡', '😠', '🤬', '😷', '🤒',
    '🤕', '🤢', '🤮', '🤧', '😇', '🤠', '🤥', '🤫',
    '🤭', '🧐', '🤓', '😈', '👿', '🤡', '👻', '💀',
    '☠️', '👽', '👾', '🤖', '💩', '😺', '😸', '😹',
    '😻', '😼', '😽', '🙀', '😿', '😾', '❤️', '🧡',
    '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
    '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝',
    '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙',
    '👈', '👉', '👆', '👇', '☝️', '✋', '🤚', '🖐',
    '🖖', '👋', '🤙', '💪', '🙏', '👏', '🤝', '👐',
  ];

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }
}