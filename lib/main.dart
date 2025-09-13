import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app.dart';
import 'core/config/router.dart';
import 'services/hive_service.dart';
import 'services/supabase_client.dart';
import 'services/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await initializeSupabase();
  await NotificationsService.initialize(onSelect: (payload) {
    if (payload != null) {
      rootNavigatorKey.currentContext?.go(payload);
    }
  });
  runApp(const ProviderScope(child: FamilyBridgeApp()));
}
