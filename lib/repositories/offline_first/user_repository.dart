import 'package:hive/hive.dart';

import 'base_offline_repository.dart';
import 'package:family_bridge/models/hive/user_model.dart';

class UserRepository extends BaseOfflineRepository<HiveUserProfile> {
  UserRepository({required Box<HiveUserProfile> box})
      : super(
          table: 'users',
          box: box,
          fromMap: (m) => HiveUserProfile.fromMap(m),
          toMap: (m) => m.toMap(),
        );
}
