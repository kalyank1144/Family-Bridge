class AppConfig {
  // App Information
  static const String appName = 'FamilyBridge';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Environment
  static const bool isDebugMode = true;
  static const bool enableLogging = true;
  
  // API Endpoints
  static const String baseUrl = 'https://api.familybridge.app';
  static const String apiVersion = 'v1';
  static String get apiUrl => '$baseUrl/$apiVersion';
  
  // Firebase Configuration
  static const String firebaseProjectId = 'familybridge-app';
  static const String firebaseStorageBucket = 'familybridge-app.appspot.com';
  static const String firebaseMessagingSenderId = '123456789';
  
  // Sentry Configuration
  static const String sentryDsn = 'https://your-sentry-dsn@sentry.io/project-id';
  
  // Sync Configuration
  static const Duration defaultSyncInterval = Duration(minutes: 15);
  static const Duration emergencySyncInterval = Duration(seconds: 30);
  static const int maxSyncRetries = 3;
  static const int maxOfflineDataDays = 30;
  
  // Cache Configuration
  static const Duration cacheValidDuration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
  static const int maxCacheItems = 1000;
  
  // Network Configuration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxConcurrentRequests = 3;
  
  // Storage Configuration
  static const int maxLocalStorageSize = 500; // MB
  static const int maxMediaFileSize = 10; // MB
  static const int maxVoiceMessageDuration = 120; // seconds
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const double borderRadius = 12.0;
  static const double elevation = 4.0;
  
  // Elder-Friendly Settings
  static const double minFontSize = 16.0;
  static const double defaultFontSize = 18.0;
  static const double largeFontSize = 24.0;
  static const double minButtonHeight = 56.0;
  static const double minTouchTarget = 48.0;
  
  // Notification Settings
  static const String notificationChannelId = 'familybridge_notifications';
  static const String notificationChannelName = 'FamilyBridge Notifications';
  static const String notificationChannelDescription = 'Notifications for family updates and reminders';
  
  // Emergency Settings
  static const Duration emergencyResponseTimeout = Duration(seconds: 10);
  static const int emergencyRetryAttempts = 5;
  static const List<String> emergencyNumbers = ['911', '112'];
  
  // Health Monitoring
  static const Duration vitalCheckInterval = Duration(hours: 4);
  static const Duration medicationReminderAdvance = Duration(minutes: 30);
  static const int criticalVitalThreshold = 3; // Number of abnormal readings
  
  // Feature Flags
  static const bool enableChat = true;
  static const bool enableVideo = true;
  static const bool enableVoiceMessages = true;
  static const bool enableLocationSharing = true;
  static const bool enableHealthMonitoring = true;
  static const bool enableMedicationReminders = true;
  static const bool enableEmergencyMode = true;
  static const bool enableOfflineMode = true;
  static const bool enableDataCompression = true;
  static const bool enableAnalytics = false; // Disabled by default for privacy
  
  // Privacy Settings
  static const bool requireConsent = true;
  static const bool enableDataEncryption = true;
  static const bool enableSecureStorage = true;
  static const int dataRetentionDays = 365;
  
  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxMessageLength = 1000;
  static const int maxNotesLength = 500;
}