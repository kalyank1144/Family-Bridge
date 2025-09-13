import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';

enum AppTheme { elder, caregiver, youth }

class ThemeController extends StateNotifier<ThemeData> {
  ThemeController() : super(caregiverTheme());

  void setTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.elder:
        state = elderTheme();
        break;
      case AppTheme.caregiver:
        state = caregiverTheme();
        break;
      case AppTheme.youth:
        state = youthTheme();
        break;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeController, ThemeData>((ref) => ThemeController());
