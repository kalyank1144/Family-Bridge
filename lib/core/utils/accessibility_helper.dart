import 'package:flutter/material.dart';

class AccessibilityHelper {
  static const Duration _defaultDuration = Duration(milliseconds: 300);
  static const Duration _reducedDuration = Duration(milliseconds: 150);
  static const Duration _noDuration = Duration.zero;

  /// Gets the appropriate animation duration based on accessibility settings
  static Duration getAnimationDuration(
    BuildContext context, {
    Duration? customDuration,
    bool respectReducedMotion = true,
  }) {
    if (!respectReducedMotion) {
      return customDuration ?? _defaultDuration;
    }

    final mediaQuery = MediaQuery.of(context);
    
    // Check if user has reduced motion enabled
    if (mediaQuery.disableAnimations) {
      return _noDuration;
    }
    
    // Check if user prefers reduced motion
    if (mediaQuery.accessibleNavigation) {
      return _reducedDuration;
    }
    
    return customDuration ?? _defaultDuration;
  }

  /// Creates a curve that respects accessibility preferences
  static Curve getAnimationCurve(
    BuildContext context, {
    Curve? customCurve,
    bool respectReducedMotion = true,
  }) {
    if (!respectReducedMotion) {
      return customCurve ?? Curves.easeInOut;
    }

    final mediaQuery = MediaQuery.of(context);
    
    // Use linear curve for reduced motion
    if (mediaQuery.disableAnimations || mediaQuery.accessibleNavigation) {
      return Curves.linear;
    }
    
    return customCurve ?? Curves.easeInOut;
  }

  /// Determines if animations should be enabled
  static bool shouldAnimateFor(BuildContext context, {bool respectSettings = true}) {
    if (!respectSettings) return true;
    
    final mediaQuery = MediaQuery.of(context);
    return !mediaQuery.disableAnimations;
  }

  /// Gets text scale factor considering accessibility preferences
  static double getTextScaleFactor(BuildContext context, {double? customScale}) {
    final mediaQuery = MediaQuery.of(context);
    final systemScale = mediaQuery.textScaleFactor;
    
    if (customScale != null) {
      return (systemScale * customScale).clamp(0.8, 2.0);
    }
    
    return systemScale.clamp(0.8, 2.0);
  }

  /// Gets appropriate semantic properties for widgets
  static Map<String, dynamic> getSemanticProperties({
    String? label,
    String? hint,
    String? value,
    bool? isButton,
    bool? isToggled,
    VoidCallback? onTap,
  }) {
    return {
      if (label != null) 'label': label,
      if (hint != null) 'hint': hint,
      if (value != null) 'value': value,
      if (isButton == true) 'button': true,
      if (isToggled != null) 'toggled': isToggled,
      if (onTap != null) 'onTap': onTap,
    };
  }

  /// Creates accessible color contrasts
  static Color getAccessibleColor(
    BuildContext context,
    Color foreground,
    Color background, {
    double minContrastRatio = 4.5,
  }) {
    final contrast = _calculateContrastRatio(foreground, background);
    
    if (contrast >= minContrastRatio) {
      return foreground;
    }
    
    // Adjust color to meet contrast requirements
    final hsl = HSLColor.fromColor(foreground);
    
    // Try making it darker first
    for (double lightness = hsl.lightness; lightness >= 0.1; lightness -= 0.1) {
      final adjustedColor = hsl.withLightness(lightness).toColor();
      if (_calculateContrastRatio(adjustedColor, background) >= minContrastRatio) {
        return adjustedColor;
      }
    }
    
    // If that doesn't work, try making it lighter
    for (double lightness = hsl.lightness; lightness <= 0.9; lightness += 0.1) {
      final adjustedColor = hsl.withLightness(lightness).toColor();
      if (_calculateContrastRatio(adjustedColor, background) >= minContrastRatio) {
        return adjustedColor;
      }
    }
    
    // Fallback to black or white
    final blackContrast = _calculateContrastRatio(Colors.black, background);
    final whiteContrast = _calculateContrastRatio(Colors.white, background);
    
    return blackContrast > whiteContrast ? Colors.black : Colors.white;
  }

  /// Calculates color contrast ratio between two colors
  static double _calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = _getRelativeLuminance(foreground);
    final bgLuminance = _getRelativeLuminance(background);
    
    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Gets relative luminance of a color
  static double _getRelativeLuminance(Color color) {
    double r = color.red / 255.0;
    double g = color.green / 255.0;
    double b = color.blue / 255.0;
    
    r = r <= 0.03928 ? r / 12.92 : Math.pow((r + 0.055) / 1.055, 2.4);
    g = g <= 0.03928 ? g / 12.92 : Math.pow((g + 0.055) / 1.055, 2.4);
    b = b <= 0.03928 ? b / 12.92 : Math.pow((b + 0.055) / 1.055, 2.4);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Creates accessible announcement for screen readers
  static void announceForAccessibility(BuildContext context, String message) {
    if (message.isNotEmpty) {
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  /// Determines if haptic feedback should be enabled
  static bool shouldUseHapticFeedback(BuildContext context) {
    // Check if haptic feedback is available and enabled
    return true; // Default to true, could be made configurable
  }

  /// Gets appropriate focus node properties
  static Map<String, dynamic> getFocusProperties({
    bool autofocus = false,
    bool skipTraversal = false,
    String? debugLabel,
  }) {
    return {
      'autofocus': autofocus,
      'skipTraversal': skipTraversal,
      if (debugLabel != null) 'debugLabel': debugLabel,
    };
  }

  /// Creates accessible button style based on context
  static ButtonStyle getAccessibleButtonStyle(
    BuildContext context, {
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    EdgeInsets? padding,
  }) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    // Increase padding for easier touch targets
    final accessiblePadding = padding ?? const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    );
    
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.all(
        backgroundColor ?? theme.primaryColor,
      ),
      foregroundColor: MaterialStateProperty.all(
        getAccessibleColor(
          context,
          foregroundColor ?? Colors.white,
          backgroundColor ?? theme.primaryColor,
        ),
      ),
      elevation: MaterialStateProperty.all(elevation ?? 2),
      padding: MaterialStateProperty.all(accessiblePadding),
      minimumSize: MaterialStateProperty.all(const Size(88, 48)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Import for math functions
import 'dart:math' as Math;

/// Accessibility-aware animation widget
class AccessibleAnimatedWidget extends StatelessWidget {
  final Widget child;
  final Duration? duration;
  final Curve? curve;
  final bool respectReducedMotion;

  const AccessibleAnimatedWidget({
    super.key,
    required this.child,
    this.duration,
    this.curve,
    this.respectReducedMotion = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = AccessibilityHelper.getAnimationDuration(
      context,
      customDuration: duration,
      respectReducedMotion: respectReducedMotion,
    );
    
    final effectiveCurve = AccessibilityHelper.getAnimationCurve(
      context,
      customCurve: curve,
      respectReducedMotion: respectReducedMotion,
    );

    if (!AccessibilityHelper.shouldAnimateFor(context)) {
      return child;
    }

    return AnimatedSwitcher(
      duration: effectiveDuration,
      switchInCurve: effectiveCurve,
      switchOutCurve: effectiveCurve,
      child: child,
    );
  }
}

/// Accessibility-aware fade transition
class AccessibleFadeTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> opacity;
  final bool respectReducedMotion;

  const AccessibleFadeTransition({
    super.key,
    required this.child,
    required this.opacity,
    this.respectReducedMotion = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!AccessibilityHelper.shouldAnimateFor(context) && respectReducedMotion) {
      return child;
    }

    return FadeTransition(
      opacity: opacity,
      child: child,
    );
  }
}

/// Accessibility-aware slide transition
class AccessibleSlideTransition extends StatelessWidget {
  final Widget child;
  final Animation<Offset> position;
  final bool respectReducedMotion;

  const AccessibleSlideTransition({
    super.key,
    required this.child,
    required this.position,
    this.respectReducedMotion = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!AccessibilityHelper.shouldAnimateFor(context) && respectReducedMotion) {
      return child;
    }

    return SlideTransition(
      position: position,
      child: child,
    );
  }
}

/// Accessibility-aware scale transition
class AccessibleScaleTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> scale;
  final bool respectReducedMotion;

  const AccessibleScaleTransition({
    super.key,
    required this.child,
    required this.scale,
    this.respectReducedMotion = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!AccessibilityHelper.shouldAnimateFor(context) && respectReducedMotion) {
      return child;
    }

    return ScaleTransition(
      scale: scale,
      child: child,
    );
  }
}