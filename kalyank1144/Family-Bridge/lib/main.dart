import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/security/security_config.dart';
import 'middleware/security_middleware.dart';
import 'services/security/auth_security_service.dart';
import 'screens/elder/elder_dashboard.dart';
import 'screens/caregiver/caregiver_dashboard.dart';
import 'screens/youth/youth_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const FamilyBridgeApp());
}

class FamilyBridgeApp extends StatelessWidget {
  const FamilyBridgeApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SecureApp(
      supabaseUrl: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://your-project.supabase.co',
      ),
      supabaseAnonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'your-anon-key',
      ),
      strictMode: true,
      debugMode: false,
      loadingWidget: const LoadingScreen(),
      errorBuilder: (error) => ErrorScreen(error: error),
      child: MaterialApp(
        title: 'FamilyBridge',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: const AuthenticationScreen(),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing Security...', style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text('Ensuring HIPAA Compliance', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final Object error;
  
  const ErrorScreen({Key? key, required this.error}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text('Security Initialization Failed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text('Exit App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({Key? key}) : super(key: key);
  
  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserType _selectedUserType = UserType.elder;
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final securityConfig = SecurityConfigProvider.of(context)?.securityConfig;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.family_restroom, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text('FamilyBridge', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('Secure Health Management', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              SegmentedButton<UserType>(
                segments: const [
                  ButtonSegment(value: UserType.elder, label: Text('Elder'), icon: Icon(Icons.elderly)),
                  ButtonSegment(value: UserType.caregiver, label: Text('Caregiver'), icon: Icon(Icons.medical_services)),
                  ButtonSegment(value: UserType.youth, label: Text('Youth'), icon: Icon(Icons.child_care)),
                ],
                selected: {_selectedUserType},
                onSelectionChanged: (s) => setState(() => _selectedUserType = s.first),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Secure Login', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _handleBiometricLogin,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Login with Biometrics'),
              ),
              const SizedBox(height: 40),
              if (securityConfig != null)
                FutureBuilder<SecurityStatus>(
                  future: securityConfig.getSecurityStatus(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final status = snapshot.data!;
                    final color = status.overallHealth == 'EXCELLENT'
                        ? Colors.green
                        : status.overallHealth == 'GOOD'
                            ? Colors.orange
                            : Colors.red;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.security, size: 16, color: color),
                        const SizedBox(width: 5),
                        Text('Security Status: ${status.overallHealth}', style: TextStyle(fontSize: 12, color: color)),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final securityConfig = SecurityConfigProvider.of(context)!.securityConfig;
      final sanitized = securityConfig.securityMiddleware.sanitizeInput({
        'email': _emailController.text,
        'password': _passwordController.text,
      });
      final user = User(
        id: 'temp_user_id',
        email: sanitized['email'],
        userType: _selectedUserType,
        role: _selectedUserType.toString().split('.').last,
      );
      securityConfig.authService.startSession(user);
      _navigateToDashboard(user);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _handleBiometricLogin() async {
    try {
      final securityConfig = SecurityConfigProvider.of(context)!.securityConfig;
      final result = await securityConfig.authService.authenticateBiometric(reason: 'Authenticate to access FamilyBridge');
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric authentication successful')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Biometric authentication failed: ${result.error}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Biometric error: $e')));
    }
  }
  
  void _navigateToDashboard(User user) {
    Widget dashboard;
    switch (user.userType) {
      case UserType.elder:
        dashboard = const ElderDashboard();
        break;
      case UserType.caregiver:
        dashboard = const CaregiverDashboard();
        break;
      case UserType.youth:
        dashboard = const YouthDashboard();
        break;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SecurityContext(
          currentUser: user,
          securityMiddleware: SecurityConfigProvider.of(context)!.securityConfig.securityMiddleware,
          child: dashboard,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}