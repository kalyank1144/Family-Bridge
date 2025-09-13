import 'package:flutter/material.dart';

final ThemeData youthTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent, brightness: Brightness.light),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(fontSize: 16, height: 1.6),
  ),
);
