import 'package:hive/hive.dart';

import 'base_offline_repository.dart';
import 'package:family_bridge/models/hive/health_data_model.dart';
import 'package:family_bridge/services/sync/conflict_resolver.dart';
import 'package:family_bridge/services/sync/data_sync_service.dart';

typedef Json = Map<String, dynamic>;

class HealthRepository extends BaseOfflineRepository<HiveHealthRecord> {
  HealthRepository({required Box<HiveHealthRecord> box})
      : super(
          table: 'health_records',
          box: box,
          fromMap: (m) => HiveHealthRecord.fromMap(m),
          toMap: (m) => m.toMap(),
        );

  Future<void> upsertMerge(HiveHealthRecord record) async {
    await upsertLocal(record);
    await DataSyncService.instance.upsertWithMerge(
      table: table,
      local: toMap(record),
      strategy: ConflictStrategy.merge,
      mergeArrayKeys: const ['symptoms', 'tags'],
    );
  }
}
