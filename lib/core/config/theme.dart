import 'package:flutter/material.dart';

ThemeData _baseTheme(ColorScheme scheme, {double scale = 1.0}) {
  final textTheme = Typography.blackCupertino.apply(fontSizeFactor: scale);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.background,
    appBarTheme: AppBarTheme(backgroundColor: scheme.surface, foregroundColor: scheme.onSurface),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: scheme.surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary),
  );
}

ThemeData elderTheme() {
  final scheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1E88E5),
    onPrimary: Colors.white,
    secondary: Color(0xFF26A69A),
    onSecondary: Colors.white,
    error: Color(0xFFD32F2F),
    onError: Colors.white,
    background: Color(0xFFF7FAFC),
    onBackground: Color(0xFF0D1B2A),
    surface: Colors.white,
    onSurface: Color(0xFF0D1B2A),
  );
  return _baseTheme(scheme, scale: 1.2);
}

ThemeData caregiverTheme() {
  final scheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1565C0),
    onPrimary: Colors.white,
    secondary: Color(0xFF2E7D32),
    onSecondary: Colors.white,
    error: Color(0xFFC62828),
    onError: Colors.white,
    background: Color(0xFFFDFDFE),
    onBackground: Color(0xFF12263A),
    surface: Colors.white,
    onSurface: Color(0xFF12263A),
  );
  return _baseTheme(scheme, scale: 1.0);
}

ThemeData youthTheme() {
  final scheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF7C4DFF),
    onPrimary: Colors.white,
    secondary: Color(0xFFFF4081),
    onSecondary: Colors.white,
    error: Color(0xFFEF5350),
    onError: Colors.white,
    background: Color(0xFF0F1220),
    onBackground: Colors.white,
    surface: Color(0xFF15182A),
    onSurface: Colors.white,
  );
  final base = _baseTheme(scheme, scale: 1.0).copyWith(
    textTheme: Typography.whiteCupertino,
    scaffoldBackgroundColor: scheme.background,
    appBarTheme: AppBarTheme(backgroundColor: scheme.surface, foregroundColor: scheme.onSurface),
  );
  return base;
}
