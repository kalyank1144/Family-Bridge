import 'package:flutter/material.dart';

final ThemeData elderTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
  visualDensity: VisualDensity.standard,
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 18, height: 1.4),
    bodyMedium: TextStyle(fontSize: 18, height: 1.4),
    labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 56),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
  ),
  checkboxTheme: const CheckboxThemeData(visualDensity: VisualDensity.comfortable),
  iconTheme: const IconThemeData(size: 28),
);
