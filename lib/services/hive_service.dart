import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/storage_keys.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(StorageKeys.authBox);
    await Hive.openBox(StorageKeys.profileBox);
    await Hive.openBox(StorageKeys.syncQueueBox);
    await Hive.openBox(StorageKeys.themeBox);
  }
}
