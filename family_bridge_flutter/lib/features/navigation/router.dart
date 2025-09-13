import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/roles.dart';
import '../auth/providers/auth_providers.dart';
import '../auth/presentation/login_page.dart';
import '../elder/presentation/elder_dashboard.dart';
import '../caregiver/presentation/caregiver_dashboard.dart';
import '../youth/presentation/youth_dashboard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authUserProvider);
  final userType = ref.watch(userTypeProvider).maybeWhen(data: (d) => d, orElse: () => null);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authStateChangesProvider.stream),
    ),
    redirect: (context, state) {
      final isAuthRoute = state.fullPath == '/auth';
      if (auth == null) return isAuthRoute ? null : '/auth';
      if (isAuthRoute) {
        switch (userType) {
          case UserType.elder:
            return '/elder';
          case UserType.caregiver:
            return '/caregiver';
          case UserType.youth:
            return '/youth';
          default:
            return '/caregiver';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (c, s) => const LoginPage()),
      GoRoute(path: '/elder', builder: (c, s) => const ElderDashboard()),
      GoRoute(path: '/caregiver', builder: (c, s) => const CaregiverDashboard()),
      GoRoute(path: '/youth', builder: (c, s) => const YouthDashboard()),
      GoRoute(
        path: '/notification/:type',
        builder: (c, s) {
          final type = s.pathParameters['type'];
          return Scaffold(
            appBar: AppBar(title: const Text('Notification')),
            body: Center(child: Text('Opened from notification: ${type ?? 'unknown'}')),
          );
        },
      ),
      GoRoute(
        path: '/',
        builder: (c, s) => const _Splash(),
      ),
    ],
  );
});

class _Splash extends ConsumerWidget {
  const _Splash({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
