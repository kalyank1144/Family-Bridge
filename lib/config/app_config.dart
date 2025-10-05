import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'FamilyBridge';
  static const String appVersion = '1.0.0';
  
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  
  static const Color elderPrimaryColor = Color(0xFF4CAF50);
  static const Color elderBackgroundColor = Color(0xFFFAFAFA);
  
  static const Color caregiverPrimaryColor = Color(0xFF2196F3);
  static const Color caregiverBackgroundColor = Color(0xFFFFFFFF);
  
  static const Color youthPrimaryColor = Color(0xFF9C27B0);
  static const Color youthBackgroundColor = Color(0xFFF5F5F5);
  
  static const double elderMinimumFontSize = 18.0;
  static const double elderButtonFontSize = 24.0;
  static const double elderHeaderFontSize = 36.0;
  
  static const double elderMinimumTouchTarget = 60.0;
  
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );
}
