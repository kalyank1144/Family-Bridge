/// Application-wide constants for FamilyBridge
/// 
/// This file contains all constant values used throughout the application
/// to ensure consistency and maintainability.
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  /// Application Information
  static const String appName = 'FamilyBridge';
  static const String appTagline = 'Connecting Generations with Care';
  static const String appDescription = 
      'A comprehensive multi-generational family care coordination platform';
  
  /// Version Information
  static const String versionNumber = '1.0.0';
  static const int versionCode = 1;
  
  /// Network Configuration
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(minutes: 2);
  static const int maxRetryAttempts = 3;
  
  /// Cache Configuration
  static const Duration cacheExpiry = Duration(hours: 1);
  static const Duration shortCacheExpiry = Duration(minutes: 15);
  static const Duration longCacheExpiry = Duration(days: 1);
  static const int maxCacheSize = 100; // MB
  
  /// Database Configuration
  static const String dbName = 'family_bridge.db';
  static const int dbVersion = 1;
  static const int connectionPoolSize = 10;
  
  /// File Upload Limits
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB
  static const int maxAudioSize = 25 * 1024 * 1024; // 25MB
  static const int maxDocumentSize = 50 * 1024 * 1024; // 50MB
  
  /// Supported File Types
  static const List<String> supportedImageTypes = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'
  ];
  static const List<String> supportedVideoTypes = [
    'mp4', 'mov', 'avi', 'mkv', 'wmv'
  ];
  static const List<String> supportedAudioTypes = [
    'mp3', 'wav', 'aac', 'm4a', 'ogg'
  ];
  static const List<String> supportedDocumentTypes = [
    'pdf', 'doc', 'docx', 'txt', 'rtf'
  ];
  
  /// Chat Configuration
  static const int maxMessageLength = 1000;
  static const int maxVoiceMessageDuration = 300; // 5 minutes in seconds
  static const Duration typingIndicatorTimeout = Duration(seconds: 3);
  static const int messagesPerPage = 50;
  
  /// Health Monitoring
  static const Duration healthCheckInterval = Duration(hours: 1);
  static const int maxVitalReadings = 100;
  static const Duration medicationReminderWindow = Duration(minutes: 30);
  
  /// Emergency Contacts
  static const int maxEmergencyContacts = 10;
  static const Duration emergencyResponseTimeout = Duration(minutes: 5);
  
  /// Notification Configuration
  static const Duration notificationDelay = Duration(seconds: 2);
  static const int maxNotificationsPerHour = 50;
  static const Duration quietHoursStart = Duration(hours: 22); // 10 PM
  static const Duration quietHoursEnd = Duration(hours: 7); // 7 AM
  
  /// Security Configuration
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration passwordResetExpiry = Duration(hours: 1);
  static const int maxLoginAttempts = 5;
  static const Duration loginLockoutDuration = Duration(minutes: 15);
  static const int minPasswordLength = 8;
  
  /// Biometric Authentication
  static const Duration biometricTimeout = Duration(seconds: 30);
  static const String biometricReason = 'Please verify your identity';
  
  /// Location Services
  static const double locationAccuracyRadius = 100.0; // meters
  static const Duration locationUpdateInterval = Duration(minutes: 15);
  static const Duration maxLocationAge = Duration(hours: 1);
  
  /// Voice Services
  static const Duration maxRecordingDuration = Duration(minutes: 5);
  static const Duration minRecordingDuration = Duration(seconds: 1);
  static const String defaultLanguageCode = 'en-US';
  
  /// Animation Configuration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  /// UI Configuration
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  /// Grid Configuration
  static const int defaultGridCrossAxisCount = 2;
  static const double defaultGridSpacing = 16.0;
  static const double defaultGridAspectRatio = 1.0;
  
  /// List Configuration
  static const int defaultListPageSize = 20;
  static const double defaultListItemHeight = 80.0;
  
  /// Error Messages
  static const String genericErrorMessage = 
      'Something went wrong. Please try again.';
  static const String networkErrorMessage = 
      'Please check your internet connection and try again.';
  static const String timeoutErrorMessage = 
      'Request timed out. Please try again.';
  static const String unauthorizedErrorMessage = 
      'You are not authorized to perform this action.';
  static const String notFoundErrorMessage = 
      'The requested resource was not found.';
  
  /// Success Messages
  static const String dataUpdatedMessage = 'Data updated successfully';
  static const String dataSavedMessage = 'Data saved successfully';
  static const String messageDeliveredMessage = 'Message delivered';
  static const String settingsUpdatedMessage = 'Settings updated';
  
  /// User Types
  static const String elderUserType = 'elder';
  static const String caregiverUserType = 'caregiver';
  static const String youthUserType = 'youth';
  
  /// Chat Message Types
  static const String textMessageType = 'text';
  static const String imageMessageType = 'image';
  static const String videoMessageType = 'video';
  static const String audioMessageType = 'audio';
  static const String documentMessageType = 'document';
  static const String locationMessageType = 'location';
  
  /// Health Data Types
  static const String bloodPressureType = 'blood_pressure';
  static const String heartRateType = 'heart_rate';
  static const String temperatureType = 'temperature';
  static const String weightType = 'weight';
  static const String glucoseType = 'glucose';
  static const String oxygenSaturationTypes = 'oxygen_saturation';
  
  /// Alert Types
  static const String medicationAlertType = 'medication';
  static const String appointmentAlertType = 'appointment';
  static const String healthAlertType = 'health';
  static const String emergencyAlertType = 'emergency';
  static const String generalAlertType = 'general';
  
  /// Appointment Types
  static const String doctorAppointmentType = 'doctor';
  static const String dentistAppointmentType = 'dentist';
  static const String therapyAppointmentType = 'therapy';
  static const String testAppointmentType = 'test';
  static const String generalAppointmentType = 'general';
  
  /// Storage Keys (for local storage)
  static const String userPreferencesKey = 'user_preferences';
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String cacheKey = 'app_cache';
  static const String settingsKey = 'app_settings';
  
  /// Analytics Event Names
  static const String loginEventName = 'login';
  static const String logoutEventName = 'logout';
  static const String messageEventName = 'send_message';
  static const String appointmentEventName = 'create_appointment';
  static const String healthDataEventName = 'add_health_data';
  static const String emergencyEventName = 'emergency_alert';
  
  /// Remote Config Keys
  static const String maintenanceModeKey = 'maintenance_mode';
  static const String forceUpdateKey = 'force_update';
  static const String minVersionKey = 'min_version';
  static const String maxFileSizeKey = 'max_file_size';
  static const String featureFlagsKey = 'feature_flags';
  
  /// Deep Link Routes
  static const String chatDeepLink = '/chat';
  static const String appointmentDeepLink = '/appointment';
  static const String healthDeepLink = '/health';
  static const String emergencyDeepLink = '/emergency';
  static const String profileDeepLink = '/profile';
  
  /// API Endpoints (relative paths)
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String messagesEndpoint = '/messages';
  static const String appointmentsEndpoint = '/appointments';
  static const String healthDataEndpoint = '/health-data';
  static const String emergencyEndpoint = '/emergency';
  
  /// Regular Expressions
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$',
  );
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );
  
  /// Date & Time Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM d, yyyy';
  static const String displayTimeFormat = 'h:mm a';
  static const String displayDateTimeFormat = 'MMM d, yyyy h:mm a';
  
  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int infiniteScrollThreshold = 5;
  
  /// Theme Configuration
  static const String lightThemeKey = 'light';
  static const String darkThemeKey = 'dark';
  static const String systemThemeKey = 'system';
  
  /// Asset Paths
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';
  static const String fontsPath = 'assets/fonts/';
  static const String soundsPath = 'assets/sounds/';
  
  /// Default Values
  static const String defaultAvatarImage = '${imagesPath}default_avatar.png';
  static const String defaultCoverImage = '${imagesPath}default_cover.png';
  static const String appLogoImage = '${imagesPath}app_logo.png';
  
  /// Platform Identifiers
  static const String androidPlatform = 'android';
  static const String iosPlatform = 'ios';
  static const String webPlatform = 'web';
  
  /// Environment Identifiers
  static const String developmentEnv = 'development';
  static const String stagingEnv = 'staging';
  static const String productionEnv = 'production';
}