import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/accessibility_helper.dart';

// Enhanced button with multiple styles and states
class EnhancedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? buttonStyle;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final IconData? suffixIcon;
  final Color? loadingColor;
  final Duration animationDuration;

  const EnhancedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.buttonStyle,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.suffixIcon,
    this.loadingColor,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      setState(() => _isPressed = true);
      if (AccessibilityHelper.shouldAnimateFor(context)) {
        _controller.forward();
      }
      if (AccessibilityHelper.shouldUseHapticFeedback(context)) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = !widget.isDisabled && !widget.isLoading && widget.onPressed != null;
    final shouldAnimate = AccessibilityHelper.shouldAnimateFor(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: shouldAnimate ? _scaleAnimation.value : 1.0,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: _buildButton(theme, isEnabled),
          ),
        );
      },
    );
  }

  Widget _buildButton(ThemeData theme, bool isEnabled) {
    switch (widget.type) {
      case ButtonType.primary:
        return _buildElevatedButton(theme, isEnabled);
      case ButtonType.secondary:
        return _buildOutlinedButton(theme, isEnabled);
      case ButtonType.ghost:
        return _buildTextButton(theme, isEnabled);
      case ButtonType.destructive:
        return _buildDestructiveButton(theme, isEnabled);
    }
  }

  Widget _buildElevatedButton(ThemeData theme, bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? widget.onPressed : null,
      style: widget.buttonStyle ?? _getButtonStyle(theme),
      child: _buildButtonContent(),
    );
  }

  Widget _buildOutlinedButton(ThemeData theme, bool isEnabled) {
    return OutlinedButton(
      onPressed: isEnabled ? widget.onPressed : null,
      style: widget.buttonStyle ?? _getOutlinedButtonStyle(theme),
      child: _buildButtonContent(),
    );
  }

  Widget _buildTextButton(ThemeData theme, bool isEnabled) {
    return TextButton(
      onPressed: isEnabled ? widget.onPressed : null,
      style: widget.buttonStyle ?? _getTextButtonStyle(theme),
      child: _buildButtonContent(),
    );
  }

  Widget _buildDestructiveButton(ThemeData theme, bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? widget.onPressed : null,
      style: _getDestructiveButtonStyle(theme),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    return AnimatedSwitcher(
      duration: widget.animationDuration,
      child: widget.isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.loadingColor ?? Colors.white,
              ),
            )
          : _buildButtonRow(),
    );
  }

  Widget _buildButtonRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: _getIconSize()),
          SizedBox(width: _getIconSpacing()),
        ],
        widget.child,
        if (widget.suffixIcon != null) ...[
          SizedBox(width: _getIconSpacing()),
          Icon(widget.suffixIcon, size: _getIconSize()),
        ],
      ],
    );
  }

  ButtonStyle _getButtonStyle(ThemeData theme) {
    return ElevatedButton.styleFrom(
      padding: _getButtonPadding(),
      minimumSize: _getButtonMinSize(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
    );
  }

  ButtonStyle _getOutlinedButtonStyle(ThemeData theme) {
    return OutlinedButton.styleFrom(
      padding: _getButtonPadding(),
      minimumSize: _getButtonMinSize(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide(width: 2, color: theme.primaryColor),
    );
  }

  ButtonStyle _getTextButtonStyle(ThemeData theme) {
    return TextButton.styleFrom(
      padding: _getButtonPadding(),
      minimumSize: _getButtonMinSize(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  ButtonStyle _getDestructiveButtonStyle(ThemeData theme) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.red.shade600,
      foregroundColor: Colors.white,
      padding: _getButtonPadding(),
      minimumSize: _getButtonMinSize(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
    );
  }

  EdgeInsets _getButtonPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal:20, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal:28, vertical: 16);
    }
  }

  Size _getButtonMinSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return const Size(64, 36);
      case ButtonSize.medium:
        return const Size(88, 44);
      case ButtonSize.large:
        return const Size(120, 56);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getIconSpacing() {
    switch (widget.size) {
      case ButtonSize.small:
        return 6;
      case ButtonSize.medium:
        return 8;
      case ButtonSize.large:
        return 10;
    }
  }
}

enum ButtonType { primary, secondary, ghost, destructive }
enum ButtonSize { small, medium, large }

// Enhanced card with hover effects and interactive states
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final bool enableHoverEffect;
  final bool enableRipple;
  final double? elevation;
  final Duration animationDuration;

  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 12,
    this.enableHoverEffect = true,
    this.enableRipple = true,
    this.elevation,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 1,
      end: (widget.elevation ?? 1) + 4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHoverEnter() {
    if (widget.enableHoverEffect && (widget.onTap != null || widget.onLongPress != null)) {
      setState(() => _isHovering = true);
      if (AccessibilityHelper.shouldAnimateFor(context)) {
        _controller.forward();
      }
    }
  }

  void _handleHoverExit() {
    if (widget.enableHoverEffect) {
      setState(() => _isHovering = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = AccessibilityHelper.shouldAnimateFor(context);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: shouldAnimate ? _scaleAnimation.value : 1.0,
          child: MouseRegion(
            onEnter: (_) => _handleHoverEnter(),
            onExit: (_) => _handleHoverExit(),
            child: Card(
              color: widget.backgroundColor,
              elevation: _elevationAnimation.value,
              margin: widget.margin,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: widget.enableRipple && (widget.onTap != null || widget.onLongPress != null)
                  ? InkWell(
                      onTap: widget.onTap,
                      onLongPress: widget.onLongPress,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: _buildCardContent(),
                    )
                  : GestureDetector(
                      onTap: widget.onTap,
                      onLongPress: widget.onLongPress,
                      child: _buildCardContent(),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: widget.child,
    );
  }
}

// Enhanced dialog with animations
class EnhancedDialog extends StatefulWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool barrierDismissible;
  final EdgeInsets? padding;
  final double borderRadius;

  const EnhancedDialog({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.barrierDismissible = true,
    this.padding,
    this.borderRadius = 16,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    List<Widget>? actions,
    bool barrierDismissible = true,
    EdgeInsets? padding,
    double borderRadius = 16,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return EnhancedDialog(
          title: title,
          actions: actions,
          barrierDismissible: barrierDismissible,
          padding: padding,
          borderRadius: borderRadius,
          child: child,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<EnhancedDialog> createState() => _EnhancedDialogState();
}

class _EnhancedDialogState extends State<EnhancedDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title != null ? Text(widget.title!) : null,
      content: widget.child,
      actions: widget.actions,
      contentPadding: widget.padding ?? const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );
  }
}

// Floating Action Button with tooltip and animation
class EnhancedFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool mini;
  final bool extended;
  final String? label;
  final Duration animationDuration;

  const EnhancedFAB({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.mini = false,
    this.extended = false,
    this.label,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<EnhancedFAB> createState() => _EnhancedFABState();
}

class _EnhancedFABState extends State<EnhancedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: widget.extended && widget.label != null
                ? FloatingActionButton.extended(
                    onPressed: _handleTap,
                    icon: widget.child,
                    label: Text(widget.label!),
                    tooltip: widget.tooltip,
                    backgroundColor: widget.backgroundColor,
                    foregroundColor: widget.foregroundColor,
                    elevation: widget.elevation,
                  )
                : FloatingActionButton(
                    onPressed: _handleTap,
                    tooltip: widget.tooltip,
                    backgroundColor: widget.backgroundColor,
                    foregroundColor: widget.foregroundColor,
                    elevation: widget.elevation,
                    mini: widget.mini,
                    child: widget.child,
                  ),
          ),
        );
      },
    );
  }
}

// Enhanced text field with floating label animation
class EnhancedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? maxLength;

  const EnhancedTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<EnhancedTextField> createState() => _EnhancedTextFieldState();
}

class _EnhancedTextFieldState extends State<EnhancedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _labelAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _labelAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
    
    if (widget.controller != null) {
      _hasText = widget.controller!.text.isNotEmpty;
      widget.controller!.addListener(_onTextChanged);
    }
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused || _hasText) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _onTextChanged() {
    final hasText = widget.controller!.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    widget.controller?.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      validator: widget.validator,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: widget.suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}