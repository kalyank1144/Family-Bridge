import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ElderTheme {
  static const minFontSize = 18.0;
  static const minTouchSize = 48.0;

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1E3A8A),
      secondary: Color(0xFF059669),
      error: Color(0xFFDC2626),
      background: Color(0xFFF9FAFB),
      surface: Colors.white,
    ),
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.openSans(fontSize: 20, height: 1.5),
      bodyMedium: GoogleFonts.openSans(fontSize: 18, height: 1.5),
      titleLarge: GoogleFonts.openSans(fontSize: 24, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.openSans(fontSize: 28, fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 64),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
