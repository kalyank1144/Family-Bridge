typedef Json = Map<String, dynamic>;

enum ConflictStrategy { lastWriteWins, merge }

class ConflictResolver {
  static Json resolve({
    required Json local,
    required Json remote,
    required ConflictStrategy strategy,
    List<String> mergeArrayKeys = const [],
    List<String> overrideRemoteKeys = const [],
  }) {
    switch (strategy) {
      case ConflictStrategy.lastWriteWins:
        final localUpdated = DateTime.tryParse(local['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final remoteUpdated = DateTime.tryParse(remote['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return localUpdated.isAfter(remoteUpdated) ? local : remote;
      case ConflictStrategy.merge:
        final merged = <String, dynamic>{}..addAll(remote)..addAll(local);
        // Merge arrays uniquely for specified keys
        for (final key in mergeArrayKeys) {
          final l = (local[key] as List?) ?? const [];
          final r = (remote[key] as List?) ?? const [];
          merged[key] = {
            for (final e in [...r, ...l]) e: true,
          }.keys.toList();
        }
        for (final key in overrideRemoteKeys) {
          merged[key] = local[key];
        }
        merged['updated_at'] = DateTime.now().toIso8601String();
        return merged;
    }
  }
}
