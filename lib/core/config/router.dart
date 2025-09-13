import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/user_type_selection_screen.dart';
import '../../features/auth/screens/elder_registration_screen.dart';
import '../../features/auth/screens/caregiver_registration_screen.dart';
import '../../features/auth/screens/youth_registration_screen.dart';
import '../../features/elder/presentation/dashboard_screen.dart' as elder;
import '../../features/caregiver/presentation/dashboard_screen.dart' as caregiver;
import '../../features/youth/presentation/dashboard_screen.dart' as youth;
import '../constants/roles.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  final role = ref.watch(userRoleProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/welcome',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const _Splash()),
      GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/onboarding/select-role', builder: (c, s) => const UserTypeSelectionScreen()),
      GoRoute(path: '/onboarding/register-elder', builder: (c, s) => const ElderRegistrationScreen()),
      GoRoute(path: '/onboarding/register-caregiver', builder: (c, s) => const CaregiverRegistrationScreen()),
      GoRoute(path: '/onboarding/register-youth', builder: (c, s) => const YouthRegistrationScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/elder', builder: (c, s) => const elder.DashboardScreen()),
      GoRoute(path: '/caregiver', builder: (c, s) => const caregiver.DashboardScreen()),
      GoRoute(path: '/youth', builder: (c, s) => const youth.DashboardScreen()),
    ],
    redirect: (context, state) {
      final isLoggedIn = auth.asData?.value != null;
      final loggingIn = state.subloc == '/login' || state.subloc == '/register' || state.subloc == '/welcome' || state.subloc.startsWith('/onboarding');
      if (!isLoggedIn && !loggingIn) return '/welcome';
      if (isLoggedIn && (state.subloc == '/' || loggingIn)) {
        if (role == UserType.elder) return '/elder';
        if (role == UserType.caregiver) return '/caregiver';
        if (role == UserType.youth) return '/youth';
        return null;
      }
      return null;
    },
    debugLogDiagnostics: true,
  );
});

class _Splash extends StatelessWidget {
  const _Splash({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
