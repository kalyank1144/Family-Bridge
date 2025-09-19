import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/encryption/encryption_service.dart';
import '../../services/security/auth_security_service.dart';
import '../../services/audit/audit_logger.dart';
import '../../services/compliance/hipaa_administrative.dart';
import '../../services/compliance/hipaa_technical.dart';
import '../../services/compliance/hipaa_physical.dart';
import '../../services/compliance/compliance_reporting.dart';
import '../../services/security/privacy_manager.dart';
import '../../services/security/security_monitoring.dart';
import '../../middleware/security_middleware.dart';

/// Main Security Configuration and Initialization
class SecurityConfig {
  static SecurityConfig? _instance;
  
  // Services
  late final EncryptionService encryptionService;
  late final AuthSecurityService authService;
  late final AuditLogger auditLogger;
  late final SecurityMiddleware securityMiddleware;
  late final SecurityMonitoring securityMonitoring;
  late final PrivacyManager privacyManager;
  late final ComplianceReporting complianceReporting;
  
  // HIPAA Components
  late final HIPAAAdministrative hipaaAdmin;
  late final HIPAATechnical hipaaTech;
  late final HIPAAPhysical hipaaPhysical;
  
  // Configuration flags
  bool _initialized = false;
  bool _strictMode = true;
  bool _debugMode = false;
  
  SecurityConfig._();
  
  factory SecurityConfig() {
    _instance ??= SecurityConfig._();
    return _instance!;
  }
  
  /// Initialize all security services
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
    bool strictMode = true,
    bool debugMode = false,
  }) async {
    if (_initialized) return;
    
    try {
      _strictMode = strictMode;
      _debugMode = debugMode;
      
      // Initialize Supabase
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );
      
      // Initialize core services
      encryptionService = EncryptionService();
      authService = AuthSecurityService();
      auditLogger = AuditLogger();
      securityMiddleware = SecurityMiddleware();
      
      // Initialize monitoring
      securityMonitoring = SecurityMonitoring();
      
      // Initialize privacy management
      privacyManager = PrivacyManager();
      
      // Initialize HIPAA compliance
      hipaaAdmin = HIPAAAdministrative();
      hipaaTech = HIPAATechnical();
      hipaaPhysical = HIPAAPhysical();
      
      // Initialize compliance reporting
      complianceReporting = ComplianceReporting();
      
      // Setup security configurations
      await _setupSecurityConfigurations();
      
      // Perform initial security checks
      await _performInitialSecurityChecks();
      
      // Start monitoring services
      _startMonitoringServices();
      
      _initialized = true;
      
      if (_debugMode) {
        print('Security services initialized successfully');
      }
      
    } catch (e) {
      throw SecurityInitException('Failed to initialize security: $e');
    }
  }
  
  /// Setup security configurations
  Future<void> _setupSecurityConfigurations() async {
    // Configure TLS
    hipaaTech.accessControl.setupTransportEncryption();
    
    // Setup data retention policies
    privacyManager.dataRetention.scheduleRetentionEnforcement();
    
    // Configure audit log retention
    Timer.periodic(const Duration(days: 1), (_) {
      auditLogger.cleanOldLogs();
    });
    
    // Setup compliance monitoring
    complianceReporting.scheduleComplianceChecks();
  }
  
  /// Perform initial security checks
  Future<void> _performInitialSecurityChecks() async {
    try {
      // Check device security
      final deviceManager = hipaaPhysical.deviceManager;
      final isEncrypted = await deviceManager.isDeviceEncrypted();
      
      if (!isEncrypted && _strictMode) {
        throw SecurityException('Device encryption required');
      }
      
      // Check for jailbreak/root
      final deviceCompliance = await deviceManager.checkDeviceCompliance('system');
      if (deviceCompliance.isJailbroken && _strictMode) {
        throw SecurityException('Jailbroken/rooted devices not allowed');
      }
      
      // Verify encryption service
      final encryptionEnabled = await encryptionService.isEnabled();
      if (!encryptionEnabled) {
        throw SecurityException('Encryption service not configured');
      }
      
      // Log security check
      await auditLogger.logSecurityEvent(
        userId: 'system',
        event: 'SECURITY_CHECK_PASSED',
        details: {
          'device_encrypted': isEncrypted,
          'device_compliant': deviceCompliance.isCompliant,
          'encryption_enabled': encryptionEnabled,
        },
      );
      
    } catch (e) {
      await auditLogger.logSecurityEvent(
        userId: 'system',
        event: 'SECURITY_CHECK_FAILED',
        details: {'error': e.toString()},
      );
      
      if (_strictMode) {
        rethrow;
      }
    }
  }
  
  /// Start monitoring services
  void _startMonitoringServices() {
    // Monitoring is automatically started in SecurityMonitoring constructor
    
    // Additional monitoring setup
    Timer.periodic(const Duration(minutes: 5), (_) async {
      await _performPeriodicSecurityChecks();
    });
  }
  
  /// Perform periodic security checks
  Future<void> _performPeriodicSecurityChecks() async {
    try {
      // Check for suspicious activities
      // This would analyze recent audit logs for patterns
      
      // Check system health
      await _checkSystemHealth();
      
      // Update threat indicators
      // This would fetch latest threat intelligence
      
    } catch (e) {
      await auditLogger.logSecurityEvent(
        userId: 'system',
        event: 'PERIODIC_CHECK_ERROR',
        details: {'error': e.toString()},
      );
    }
  }
  
  /// Check system health
  Future<void> _checkSystemHealth() async {
    // Check database connectivity
    try {
      await Supabase.instance.client.from('health_check').select().limit(1);
    } catch (e) {
      await auditLogger.logSecurityEvent(
        userId: 'system',
        event: 'DATABASE_HEALTH_CHECK_FAILED',
        details: {'error': e.toString()},
      );
    }
  }
  
  /// Get current security status
  Future<SecurityStatus> getSecurityStatus() async {
    final status = SecurityStatus();
    
    try {
      // Check encryption
      status.encryptionEnabled = await encryptionService.isEnabled();
      
      // Check session
      status.sessionActive = authService.isSessionActive();
      
      // Check device compliance
      final deviceCompliance = await hipaaPhysical.deviceManager
          .checkDeviceCompliance('current_device');
      status.deviceCompliant = deviceCompliance.isCompliant;
      
      // Check monitoring
      status.monitoringActive = true; // Always true if initialized
      
      // Get recent security events
      final recentEvents = await auditLogger.queryLogs(
        category: 'SECURITY',
        startDate: DateTime.now().subtract(const Duration(hours: 1)),
        limit: 10,
      );
      status.recentSecurityEvents = recentEvents.length;
      
      // Calculate overall health
      status.overallHealth = _calculateOverallHealth(status);
      
    } catch (e) {
      status.errors.add(e.toString());
    }
    
    return status;
  }
  
  String _calculateOverallHealth(SecurityStatus status) {
    int score = 0;
    
    if (status.encryptionEnabled) score += 25;
    if (status.sessionActive) score += 25;
    if (status.deviceCompliant) score += 25;
    if (status.monitoringActive) score += 25;
    
    if (status.recentSecurityEvents > 10) score -= 10;
    if (status.errors.isNotEmpty) score -= 20;
    
    if (score >= 90) return 'EXCELLENT';
    if (score >= 70) return 'GOOD';
    if (score >= 50) return 'FAIR';
    return 'POOR';
  }
  
  /// Handle app lifecycle changes
  void handleAppLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App moved to background
        _handleAppBackground();
        break;
      case AppLifecycleState.resumed:
        // App moved to foreground
        _handleAppForeground();
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        break;
      case AppLifecycleState.detached:
        // App is detached
        _cleanup();
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }
  
  void _handleAppBackground() {
    // Lock sensitive data
    // Clear memory caches
    // Pause monitoring
  }
  
  void _handleAppForeground() {
    // Re-authenticate if needed
    // Resume monitoring
    // Check for security updates
  }
  
  /// Cleanup resources
  void _cleanup() {
    complianceReporting.dispose();
    // Clean other resources
  }
  
  /// Get singleton instance
  static SecurityConfig get instance {
    if (_instance == null) {
      throw SecurityInitException('Security not initialized');
    }
    return _instance!;
  }
  
  /// Check if security is initialized
  bool get isInitialized => _initialized;
  
  /// Get strict mode status
  bool get isStrictMode => _strictMode;
  
  /// Get debug mode status
  bool get isDebugMode => _debugMode;
}

/// Security Status Model
class SecurityStatus {
  bool encryptionEnabled = false;
  bool sessionActive = false;
  bool deviceCompliant = false;
  bool monitoringActive = false;
  int recentSecurityEvents = 0;
  String overallHealth = 'UNKNOWN';
  List<String> errors = [];
  
  Map<String, dynamic> toJson() {
    return {
      'encryption_enabled': encryptionEnabled,
      'session_active': sessionActive,
      'device_compliant': deviceCompliant,
      'monitoring_active': monitoringActive,
      'recent_security_events': recentSecurityEvents,
      'overall_health': overallHealth,
      'errors': errors,
    };
  }
}

/// Security Initialization Exception
class SecurityInitException implements Exception {
  final String message;
  
  SecurityInitException(this.message);
  
  @override
  String toString() => 'SecurityInitException: $message';
}

/// Security Configuration Widget
class SecurityConfigProvider extends InheritedWidget {
  final SecurityConfig securityConfig;
  
  const SecurityConfigProvider({
    Key? key,
    required this.securityConfig,
    required Widget child,
  }) : super(key: key, child: child);
  
  static SecurityConfigProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SecurityConfigProvider>();
  }
  
  @override
  bool updateShouldNotify(SecurityConfigProvider oldWidget) {
    return securityConfig != oldWidget.securityConfig;
  }
}

/// App lifecycle observer for security
class SecurityLifecycleObserver extends WidgetsBindingObserver {
  final SecurityConfig securityConfig;
  
  SecurityLifecycleObserver(this.securityConfig);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    securityConfig.handleAppLifecycle(state);
  }
}

/// Security initialization widget
class SecureApp extends StatefulWidget {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final Widget child;
  final bool strictMode;
  final bool debugMode;
  final Widget loadingWidget;
  final Widget Function(Object error)? errorBuilder;
  
  const SecureApp({
    Key? key,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.child,
    this.strictMode = true,
    this.debugMode = false,
    this.loadingWidget = const CircularProgressIndicator(),
    this.errorBuilder,
  }) : super(key: key);
  
  @override
  State<SecureApp> createState() => _SecureAppState();
}

class _SecureAppState extends State<SecureApp> with WidgetsBindingObserver {
  late SecurityConfig _securityConfig;
  bool _initialized = false;
  Object? _error;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSecurity();
  }
  
  Future<void> _initializeSecurity() async {
    try {
      _securityConfig = SecurityConfig();
      await _securityConfig.initialize(
        supabaseUrl: widget.supabaseUrl,
        supabaseAnonKey: widget.supabaseAnonKey,
        strictMode: widget.strictMode,
        debugMode: widget.debugMode,
      );
      
      setState(() => _initialized = true);
    } catch (e) {
      setState(() => _error = e);
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_initialized) {
      _securityConfig.handleAppLifecycle(state);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? 
             MaterialApp(
               home: Scaffold(
                 body: Center(
                   child: Text('Security initialization failed: $_error'),
                 ),
               ),
             );
    }
    
    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: widget.loadingWidget),
        ),
      );
    }
    
    return SecurityConfigProvider(
      securityConfig: _securityConfig,
      child: widget.child,
    );
  }
}