import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const cacheBox = 'cache';
  static const syncQueueBox = 'sync_queue';

  static Future<void> openCoreBoxes() async {
    await Hive.openBox(cacheBox);
    await Hive.openBox(syncQueueBox);
  }

  static Box get cache => Hive.box(cacheBox);
  static Box get syncQueue => Hive.box(syncQueueBox);
}
