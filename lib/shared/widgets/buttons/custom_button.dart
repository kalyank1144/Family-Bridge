import 'package:flutter/material.dart';

import 'package:family_bridge/shared/core/constants/app_constants.dart';

/// A customizable button widget with consistent styling across the app
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final ButtonVariant variant;
  final ButtonSize size;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.padding,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define button styling based on variant
    Color getBackgroundColor() {
      if (backgroundColor != null) return backgroundColor!;
      
      switch (variant) {
        case ButtonVariant.primary:
          return colorScheme.primary;
        case ButtonVariant.secondary:
          return colorScheme.secondary;
        case ButtonVariant.outline:
          return Colors.transparent;
        case ButtonVariant.text:
          return Colors.transparent;
        case ButtonVariant.danger:
          return colorScheme.error;
      }
    }

    Color getForegroundColor() {
      if (foregroundColor != null) return foregroundColor!;
      
      switch (variant) {
        case ButtonVariant.primary:
          return colorScheme.onPrimary;
        case ButtonVariant.secondary:
          return colorScheme.onSecondary;
        case ButtonVariant.outline:
          return colorScheme.primary;
        case ButtonVariant.text:
          return colorScheme.primary;
        case ButtonVariant.danger:
          return colorScheme.onError;
      }
    }

    BorderSide? getBorderSide() {
      switch (variant) {
        case ButtonVariant.outline:
          return BorderSide(color: colorScheme.primary, width: 1.5);
        case ButtonVariant.danger:
          return BorderSide(color: colorScheme.error, width: 1.5);
        default:
          return null;
      }
    }

    double getButtonHeight() {
      if (height != null) return height!;
      
      switch (size) {
        case ButtonSize.small:
          return 36.0;
        case ButtonSize.medium:
          return 48.0;
        case ButtonSize.large:
          return 56.0;
      }
    }

    EdgeInsetsGeometry getButtonPadding() {
      if (padding != null) return padding!;
      
      switch (size) {
        case ButtonSize.small:
          return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
        case ButtonSize.medium:
          return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
        case ButtonSize.large:
          return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);
      }
    }

    Widget buildButtonChild() {
      if (isLoading) {
        return SizedBox(
          width: 20.0,
          height: 20.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(getForegroundColor()),
          ),
        );
      }

      if (icon != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.0),
            const SizedBox(width: AppConstants.smallPadding),
            Text(text),
          ],
        );
      }

      return Text(text);
    }

    Widget button = SizedBox(
      width: isExpanded ? double.infinity : width,
      height: getButtonHeight(),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: getBackgroundColor(),
          foregroundColor: getForegroundColor(),
          side: getBorderSide(),
          padding: getButtonPadding(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          elevation: variant == ButtonVariant.text || variant == ButtonVariant.outline ? 0 : 2,
        ),
        child: buildButtonChild(),
      ),
    );

    return button;
  }
}

/// Button variant styles
enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
  danger,
}

/// Button size options
enum ButtonSize {
  small,
  medium,
  large,
}