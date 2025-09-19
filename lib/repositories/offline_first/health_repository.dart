import 'package:hive/hive.dart';

import '../../models/hive/health_data_model.dart';
import '../../services/sync/conflict_resolver.dart';
import '../../services/sync/data_sync_service.dart';
import 'base_offline_repository.dart';

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
