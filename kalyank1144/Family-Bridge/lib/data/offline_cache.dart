import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OfflineCache {
  final String namespace;
  OfflineCache(this.namespace);

  Future<File> _file(String key) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/cache_${namespace}_$key.json';
    return File(path);
  }

  Future<List<Map<String, dynamic>>> readList(String key) async {
    try {
      final f = await _file(key);
      if (!await f.exists()) return [];
      final txt = await f.readAsString();
      final data = jsonDecode(txt) as List;
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> data) async {
    final f = await _file(key);
    await f.writeAsString(jsonEncode(data));
  }
}