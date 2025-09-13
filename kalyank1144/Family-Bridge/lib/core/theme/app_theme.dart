import 'package:flutter/material.dart';
import '../constants/roles.dart';
import 'themes_elder.dart';
import 'themes_caregiver.dart';
import 'themes_youth.dart';

class AppTheme {
  static ThemeData forUser(UserType? type) {
    switch (type) {
      case UserType.elder:
        return elderTheme;
      case UserType.caregiver:
        return caregiverTheme;
      case UserType.youth:
        return youthTheme;
      default:
        return caregiverTheme;
    }
  }
}
