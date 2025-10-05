import 'package:flutter/foundation.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration manager for FamilyBridge
/// 
/// This class provides typed access to environment variables and validates
/// required configurations on application startup.
class EnvConfig {
  static bool _initialized = false;

  /// Initialize environment configuration
  /// 
  /// Must be called before accessing any configuration values
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await dotenv.load(fileName: '.env');
      _initialized = true;
      _validateRequiredConfig();
    } catch (e) {
      if (kDebugMode) {
        print('Warning: .env file not found, using default values');
      }
    }
  }

  /// Validate that all required configuration values are present
  static void _validateRequiredConfig() {
    final requiredKeys = [
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
    ];

    final missingKeys = <String>[];
    for (final key in requiredKeys) {
      if (!dotenv.env.containsKey(key) || dotenv.env[key]!.isEmpty) {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty) {
      throw Exception(
        'Missing required environment variables: ${missingKeys.join(', ')}',
      );
    }
  }

  // App Configuration
  static String get appName => _getString('APP_NAME', 'FamilyBridge');
  static String get appVersion => _getString('APP_VERSION', '1.0.0');
  static bool get isDebugMode => _getBool('DEBUG_MODE', kDebugMode);
  static String get logLevel => _getString('LOG_LEVEL', 'info');

  // Supabase Configuration
  static String get supabaseUrl => _getRequiredString('SUPABASE_URL');
  static String get supabaseAnonKey => _getRequiredString('SUPABASE_ANON_KEY');
  static String get supabaseServiceRoleKey => 
      _getString('SUPABASE_SERVICE_ROLE_KEY', '');

  // Database Configuration
  static String get databaseUrl => _getString('DATABASE_URL', '');

  // Authentication
  static String get jwtSecret => _getString('JWT_SECRET', '');
  static String get jwtExpiry => _getString('JWT_EXPIRY', '7d');
  static String get refreshTokenExpiry => _getString('REFRESH_TOKEN_EXPIRY', '30d');

  // Third-party Services
  static String get weatherApiKey => _getString('WEATHER_API_KEY', '');
  static String get weatherApiUrl => 
      _getString('WEATHER_API_URL', 'https://api.openweathermap.org/data/2.5');

  // Push Notifications
  static String get fcmServerKey => _getString('FCM_SERVER_KEY', '');
  static String get fcmSenderId => _getString('FCM_SENDER_ID', '');

  // Media Storage
  static String get storageBucket => _getString('STORAGE_BUCKET', '');
  static int get maxFileSize => _getInt('MAX_FILE_SIZE', 10485760); // 10MB
  static List<String> get allowedFileTypes => 
      _getString('ALLOWED_FILE_TYPES', 'jpg,jpeg,png,gif,mp4,mp3,wav')
          .split(',')
          .map((e) => e.trim())
          .toList();

  // Email Services
  static String get smtpHost => _getString('SMTP_HOST', 'smtp.gmail.com');
  static int get smtpPort => _getInt('SMTP_PORT', 587);
  static String get smtpUser => _getString('SMTP_USER', '');
  static String get smtpPass => _getString('SMTP_PASS', '');

  // SMS Services
  static String get twilioAccountSid => _getString('TWILIO_ACCOUNT_SID', '');
  static String get twilioAuthToken => _getString('TWILIO_AUTH_TOKEN', '');
  static String get twilioPhoneNumber => _getString('TWILIO_PHONE_NUMBER', '');

  // Social Media Integration
  static String get googleClientId => _getString('GOOGLE_CLIENT_ID', '');
  static String get googleClientSecret => _getString('GOOGLE_CLIENT_SECRET', '');
  static String get appleClientId => _getString('APPLE_CLIENT_ID', '');
  static String get appleTeamId => _getString('APPLE_TEAM_ID', '');
  static String get appleKeyId => _getString('APPLE_KEY_ID', '');

  // Analytics
  static bool get analyticsEnabled => _getBool('ANALYTICS_ENABLED', true);
  static String get firebaseProjectId => _getString('FIREBASE_PROJECT_ID', '');
  static String get googleAnalyticsId => _getString('GOOGLE_ANALYTICS_ID', '');

  // Error Reporting
  static bool get crashlyticsEnabled => _getBool('CRASHLYTICS_ENABLED', true);
  static String get sentryDsn => _getString('SENTRY_DSN', '');

  // Feature Flags
  static bool get enableVoiceMessages => _getBool('ENABLE_VOICE_MESSAGES', true);
  static bool get enableVideoCalls => _getBool('ENABLE_VIDEO_CALLS', false);
  static bool get enableLocationSharing => _getBool('ENABLE_LOCATION_SHARING', true);
  static bool get enableHealthTracking => _getBool('ENABLE_HEALTH_TRACKING', true);
  static bool get enableMedicationReminders => 
      _getBool('ENABLE_MEDICATION_REMINDERS', true);
  static bool get enableEmergencyAlerts => _getBool('ENABLE_EMERGENCY_ALERTS', true);

  // Performance & Monitoring
  static bool get performanceMonitoring => _getBool('PERFORMANCE_MONITORING', true);
  static bool get logRequests => _getBool('LOG_REQUESTS', kDebugMode);
  static bool get logResponses => _getBool('LOG_RESPONSES', false);
  static String get maxLogSize => _getString('MAX_LOG_SIZE', '50MB');

  // Cache Configuration
  static int get cacheDuration => _getInt('CACHE_DURATION', 300); // 5 minutes
  static String get cacheMaxSize => _getString('CACHE_MAX_SIZE', '100MB');
  static bool get offlineModeEnabled => _getBool('OFFLINE_MODE_ENABLED', true);

  // Security
  static bool get encryptionEnabled => _getBool('ENCRYPTION_ENABLED', true);
  static bool get biometricAuthEnabled => _getBool('BIOMETRIC_AUTH_ENABLED', true);
  static int get sessionTimeout => _getInt('SESSION_TIMEOUT', 3600); // 1 hour

  // Development/Testing
  static bool get mockServices => _getBool('MOCK_SERVICES', false);
  static bool get enableFlutterDriver => _getBool('ENABLE_FLUTTER_DRIVER', false);
  static String get testUserEmail => 
      _getString('TEST_USER_EMAIL', 'test@familybridge.app');
  static String get testUserPassword => _getString('TEST_USER_PASSWORD', 'test123456');

  // Backup & Recovery
  static bool get autoBackupEnabled => _getBool('AUTO_BACKUP_ENABLED', true);
  static String get backupFrequency => _getString('BACKUP_FREQUENCY', 'daily');
  static int get backupRetentionDays => _getInt('BACKUP_RETENTION_DAYS', 30);

  // Compliance
  static bool get gdprCompliance => _getBool('GDPR_COMPLIANCE', true);
  static bool get hipaaCompliance => _getBool('HIPAA_COMPLIANCE', false);
  static int get dataRetentionDays => _getInt('DATA_RETENTION_DAYS', 365);

  // Helper methods
  static String _getString(String key, String defaultValue) {
    return dotenv.env[key] ?? defaultValue;
  }

  static String _getRequiredString(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Required environment variable $key is not set');
    }
    return value;
  }

  static bool _getBool(String key, bool defaultValue) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      return defaultValue;
    }
    return value.toLowerCase() == 'true';
  }

  static int _getInt(String key, int defaultValue) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      return defaultValue;
    }
    return int.tryParse(value) ?? defaultValue;
  }

  static double _getDouble(String key, double defaultValue) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      return defaultValue;
    }
    return double.tryParse(value) ?? defaultValue;
  }

  /// Print all configuration values (for debugging)
  /// Only works in debug mode and excludes sensitive values
  static void debugPrintConfig() {
    if (!kDebugMode) return;

    print('=== FamilyBridge Configuration ===');
    print('App Name: $appName');
    print('App Version: $appVersion');
    print('Debug Mode: $isDebugMode');
    print('Log Level: $logLevel');
    print('Supabase URL: ${supabaseUrl.replaceAll(RegExp(r'https?://'), '***')}');
    print('Analytics Enabled: $analyticsEnabled');
    print('Crashlytics Enabled: $crashlyticsEnabled');
    print('Performance Monitoring: $performanceMonitoring');
    print('Offline Mode: $offlineModeEnabled');
    print('Encryption Enabled: $encryptionEnabled');
    print('GDPR Compliance: $gdprCompliance');
    print('==================================');
  }

  /// Get environment-specific configuration as a map
  static Map<String, dynamic> toMap() {
    return {
      'app_name': appName,
      'app_version': appVersion,
      'debug_mode': isDebugMode,
      'log_level': logLevel,
      'analytics_enabled': analyticsEnabled,
      'crashlytics_enabled': crashlyticsEnabled,
      'performance_monitoring': performanceMonitoring,
      'offline_mode_enabled': offlineModeEnabled,
      'encryption_enabled': encryptionEnabled,
      'biometric_auth_enabled': biometricAuthEnabled,
      'gdpr_compliance': gdprCompliance,
      'hipaa_compliance': hipaaCompliance,
    };
  }
}