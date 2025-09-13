import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router.dart';
import 'config/theme_provider.dart';

class FamilyBridgeApp extends ConsumerWidget {
  const FamilyBridgeApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'FamilyBridge',
      theme: theme,
      routerConfig: router,
    );
  }
}
