import 'dart:async';

import 'package:family_bridge/core/models/message_model.dart';
import 'package:family_bridge/core/models/notification_preferences.dart';

class NotificationRouteDecision {
  final bool deliverNow;
  final Duration? delay;
  const NotificationRouteDecision({required this.deliverNow, this.delay});
}

class NotificationRouter {
  NotificationRouter._internal();
  static final NotificationRouter instance = NotificationRouter._internal();

  final _batchQueues = <String, List<_BatchItem>>{};
  final _batchTimers = <String, Timer?>{};

  NotificationRouteDecision decide({
    required String userType,
    required NotificationPreferences prefs,
    required MessagePriority priority,
    required String category,
  }) {
    if (priority == MessagePriority.emergency) {
      return const NotificationRouteDecision(deliverNow: true);
    }
    if (prefs.quietHours.enabled) {
      final now = DateTime.now();
      final h = now.hour;
      final s = prefs.quietHours.startHour;
      final e = prefs.quietHours.endHour;
      final inQuiet = s < e ? (h >= s && h < e) : (h >= s || h < e);
      if (inQuiet) {
        return NotificationRouteDecision(deliverNow: false, delay: Duration(hours: _hoursUntil(e)));
      }
    }
    if (category == 'chat' && priority == MessagePriority.normal) {
      return const NotificationRouteDecision(deliverNow: false, delay: Duration(minutes: 2));
    }
    return const NotificationRouteDecision(deliverNow: true);
  }

  void enqueueBatch({required String key, required Function(List<_BatchItem>) onFlush, required _BatchItem item, Duration window = const Duration(minutes: 2)}) {
    _batchQueues.putIfAbsent(key, () => []);
    _batchQueues[key]!.add(item);
    _batchTimers[key]?.cancel();
    _batchTimers[key] = Timer(window, () {
      final items = List<_BatchItem>.from(_batchQueues[key] ?? const []);
      _batchQueues[key] = [];
      onFlush(items);
    });
  }
}

int _hoursUntil(int targetHour) {
  final now = DateTime.now();
  int h = (targetHour - now.hour) % 24;
  if (h <= 0) h += 24;
  return h;
}

class _BatchItem {
  final String title;
  final String body;
  final MessagePriority priority;
  final Map<String, String?> payload;
  _BatchItem(this.title, this.body, this.priority, this.payload);
}
