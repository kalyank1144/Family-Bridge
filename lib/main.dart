import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app.dart';
import 'services/hive_service.dart';
import 'services/supabase_client.dart';
import 'services/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await initializeSupabase();
  await NotificationsService.initialize();
  runApp(const ProviderScope(child: FamilyBridgeApp()));
}
