import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/offline/offline_manager.dart';
import '../../../services/network/network_manager.dart';

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return OfflineManager.instance.statusStream;
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  return NetworkManager.instance.statusStream;
});

class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStatusProvider);
    final net = ref.watch(networkStatusProvider);

    final isOffline = net.asData?.value.isOnline == false || OfflineManager.instance.isOffline;

    if (isOffline) {
      return Container(
        width: double.infinity,
        color: Colors.orange.shade100,
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.wifi_off, size: 16, color: Colors.orange),
            SizedBox(width: 8),
            Text('Offline mode — messages will sync when back online'),
          ],
        ),
      );
    }

    return sync.when(
      data: (status) {
        switch (status.state) {
          case SyncState.syncing:
            return Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Syncing…'),
                ],
              ),
            );
          case SyncState.error:
            return Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.error_outline, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sync error — will retry automatically'),
                ],
              ),
            );
          case SyncState.idle:
          default:
            return const SizedBox.shrink();
        }
      },
      error: (_, __) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}
