import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:family_bridge/core/utils/env.dart';

enum ConnectionQuality { none, poor, moderate, good }

class NetworkStatus {
  final bool isOnline;
  final ConnectionQuality quality;
  final ConnectivityResult connectivity;

  const NetworkStatus({
    required this.isOnline,
    required this.quality,
    required this.connectivity,
  });
}

class NetworkManager {
  NetworkManager._internal();
  static final NetworkManager instance = NetworkManager._internal();

  final _connectivity = Connectivity();
  final _controller = StreamController<NetworkStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkStatus _current = const NetworkStatus(
    isOnline: true,
    quality: ConnectionQuality.good,
    connectivity: ConnectivityResult.wifi,
  );

  Stream<NetworkStatus> get statusStream => _controller.stream;
  NetworkStatus get current => _current;

  Future<void> startMonitoring() async {
    await _emit(await _checkStatus());
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      await _emit(await _checkStatus());
    });

    // Periodic quality check
    Timer.periodic(const Duration(seconds: 30), (_) async {
      await _emit(await _checkStatus());
    });
  }

  Future<void> stopMonitoring() async {
    await _subscription?.cancel();
    await _controller.close();
  }

  Future<NetworkStatus> _checkStatus() async {
    final results = await _connectivity.checkConnectivity();
    final primary = results.isNotEmpty ? results.first : ConnectivityResult.none;
    if (primary == ConnectivityResult.none) {
      return NetworkStatus(
        isOnline: false,
        quality: ConnectionQuality.none,
        connectivity: ConnectivityResult.none,
      );
    }
    final quality = await _probeQuality();
    return NetworkStatus(
      isOnline: quality != ConnectionQuality.none,
      quality: quality,
      connectivity: primary,
    );
  }

  Future<ConnectionQuality> _probeQuality() async {
    try {
      final url = Env.supabaseUrl;
      if (url.isEmpty) return ConnectionQuality.moderate;
      // Use a HEAD request to the Supabase REST endpoint for quick check
      final uri = Uri.parse(url);
      final host = uri.host;
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(host, 443, timeout: const Duration(seconds: 3));
      socket.destroy();
      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;
      if (ms < 100) return ConnectionQuality.good;
      if (ms < 400) return ConnectionQuality.moderate;
      return ConnectionQuality.poor;
    } catch (e) {
      debugPrint('Network probe failed: $e');
      return ConnectionQuality.none;
    }
  }

  Future<void> _emit(NetworkStatus status) async {
    _current = status;
    _controller.add(status);
  }
}
