import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/offline/offline_manager.dart';
import 'services/network/network_manager.dart';
import 'services/sync/data_sync_service.dart';
import 'services/sync/sync_queue.dart';
import 'services/cache/cache_manager.dart';
import 'services/background/background_sync_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Supabase configuration
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize core services
  await initializeServices();
  
  runApp(
    const ProviderScope(
      child: FamilyBridgeApp(),
    ),
  );
}

Future<void> initializeServices() async {
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    // Initialize Hive for local storage
    await Hive.initFlutter();
    
    // Initialize Offline Manager
    await OfflineManager.initialize();
    
    // Initialize Network Manager
    final networkManager = NetworkManager();
    await networkManager.initialize();
    
    // Initialize Cache Manager
    final cacheManager = CacheManager();
    await cacheManager.initialize();
    
    // Initialize Sync Queue
    final syncQueue = SyncQueue();
    final syncBox = await Hive.openBox('sync_queue_box');
    await syncQueue.initialize(syncBox);
    
    // Initialize Data Sync Service
    final dataSyncService = DataSyncService();
    await dataSyncService.initialize();
    
    // Initialize Background Sync Service
    final backgroundSync = BackgroundSyncService();
    await backgroundSync.initialize(
      supabaseUrl: supabaseUrl,
      supabaseKey: supabaseAnonKey,
    );
    
    debugPrint('All services initialized successfully');
    
  } catch (e) {
    debugPrint('Service initialization failed: $e');
  }
}

class FamilyBridgeApp extends StatelessWidget {
  const FamilyBridgeApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamilyBridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }
  
  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final session = Supabase.instance.client.auth.currentSession;
    
    if (!mounted) return;
    
    if (session != null) {
      // User is logged in, navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // User not logged in, navigate to welcome
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 100,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 20),
            Text(
              'FamilyBridge',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Connecting Generations',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.family_restroom,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to FamilyBridge',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Stay connected with your loved ones',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to login
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FamilyBridge'),
        actions: [
          StreamBuilder<bool>(
            stream: NetworkManager().connectionStream,
            builder: (context, snapshot) {
              final isOnline = snapshot.data ?? false;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  color: isOnline ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Home Screen - Implement based on user type'),
      ),
    );
  }
}