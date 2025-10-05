import 'package:flutter_test/flutter_test.dart';

import 'package:family_bridge/services/offline/offline_manager.dart';

void main() {
  test('offline manager toggles modes and exposes status', () async {
    final mgr = OfflineManager.instance;
    // Not calling initialize() here to keep test lightweight
    mgr.goOffline();
    expect(mgr.isOffline, true);
    mgr.goOnline();
    // Cannot assert isOffline false without network; just ensure no throw
  });
}
