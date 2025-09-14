import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Existing global palette (used by Caregiver and shared UI)
  static const Color primaryColor = Color(0xFF6B46C1);
  static const Color secondaryColor = Color(0xFF9333EA);
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF3B82F6);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  static const Color healthGreen = Color(0xFF10B981);
  static const Color healthYellow = Color(0xFFF59E0B);
  static const Color healthRed = Color(0xFFEF4444);

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Default light theme (existing)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: backgroundColor,
      surface: surfaceColor,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: textPrimary),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  // Default dark theme (existing)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF111827),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: Color(0xFF111827),
      surface: Color(0xFF1F2937),
    ),
  );

  // Elder-focused theme with WCAG AAA sizing/contrast
  static ThemeData get elderTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1E3A8A),
        onPrimary: Colors.white,
        secondary: Color(0xFF059669),
        onSecondary: Colors.white,
        error: Color(0xFFDC2626),
        onError: Colors.white,
        background: Color(0xFFF9FAFB),
        onBackground: Color(0xFF111827),
        surface: Colors.white,
        onSurface: Color(0xFF111827),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.openSans(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF111827),
          height: 1.2,
        ),
        displayMedium: GoogleFonts.openSans(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF111827),
          height: 1.2,
        ),
        displaySmall: GoogleFonts.openSans(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
          height: 1.3,
        ),
        headlineLarge: GoogleFonts.openSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF111827),
          height: 1.3,
        ),
        headlineMedium: GoogleFonts.openSans(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.openSans(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.openSans(
          fontSize: 20,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF374151),
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.openSans(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF374151),
          height: 1.6,
        ),
        labelLarge: GoogleFonts.openSans(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
          height: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 80),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          textStyle: GoogleFonts.openSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 80),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(width: 3),
          textStyle: GoogleFonts.openSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(8),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        titleTextStyle: GoogleFonts.openSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF111827),
        ),
        iconTheme: const IconThemeData(
          size: 32,
          color: Color(0xFF111827),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            width: 2,
            color: Colors.grey.shade400,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(width: 3, color: Color(0xFF1E3A8A)),
        ),
        labelStyle: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.openSans(fontSize: 18, color: Colors.black54),
      ),
      iconTheme: const IconThemeData(size: 32, color: Color(0xFF374151)),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w500),
        selectedIconTheme: const IconThemeData(size: 36),
        unselectedIconTheme: const IconThemeData(size: 32),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Elder-accessible color shortcuts
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color successGreen = Color(0xFF059669);
  static const Color emergencyRed = Color(0xFFDC2626);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color neutralGray = Color(0xFF6B7280);
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color darkText = Color(0xFF111827);
}