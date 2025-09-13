import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

enum ConnectionQuality {
  offline,
  poor,      // < 150 kbps
  fair,      // 150-500 kbps
  good,      // 500-2000 kbps
  excellent, // > 2000 kbps
}

enum NetworkType {
  none,
  mobile,
  wifi,
  ethernet,
  bluetooth,
  vpn,
  other,
}

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  final Connectivity _connectivity = Connectivity();
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();
  final StreamController<ConnectionQuality> _qualityController = 
      StreamController<ConnectionQuality>.broadcast();
  final StreamController<NetworkStatus> _statusController = 
      StreamController<NetworkStatus>.broadcast();
  
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<ConnectionQuality> get qualityStream => _qualityController.stream;
  Stream<NetworkStatus> get statusStream => _statusController.stream;
  
  bool _isOnline = false;
  ConnectionQuality _currentQuality = ConnectionQuality.offline;
  NetworkType _currentType = NetworkType.none;
  double _currentBandwidth = 0.0;
  DateTime? _lastConnectionTime;
  DateTime? _lastDisconnectionTime;
  
  Timer? _connectionCheckTimer;
  Timer? _bandwidthCheckTimer;
  
  bool get isOnline => _isOnline;
  ConnectionQuality get connectionQuality => _currentQuality;
  NetworkType get networkType => _currentType;
  double get bandwidth => _currentBandwidth;
  
  Future<void> initialize() async {
    // Check initial connection
    await _checkConnection();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Start periodic connection checks
    _startPeriodicChecks();
    
    _logger.i('NetworkManager initialized');
  }
  
  void _startPeriodicChecks() {
    // Check real connection every 30 seconds
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnection();
    });
    
    // Check bandwidth every 2 minutes when online
    _bandwidthCheckTimer?.cancel();
    _bandwidthCheckTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_isOnline) {
        _measureBandwidth();
      }
    });
  }
  
  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    _logger.d('Connectivity changed: $results');
    
    // Map connectivity result to network type
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _currentType = NetworkType.none;
    } else if (results.contains(ConnectivityResult.wifi)) {
      _currentType = NetworkType.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _currentType = NetworkType.mobile;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      _currentType = NetworkType.ethernet;
    } else if (results.contains(ConnectivityResult.bluetooth)) {
      _currentType = NetworkType.bluetooth;
    } else if (results.contains(ConnectivityResult.vpn)) {
      _currentType = NetworkType.vpn;
    } else {
      _currentType = NetworkType.other;
    }
    
    // Check real connection
    await _checkConnection();
  }
  
  Future<void> _checkConnection() async {
    try {
      // Try to reach multiple endpoints for reliability
      final endpoints = [
        'https://www.google.com',
        'https://connectivity-check.ubuntu.com',
        'https://www.cloudflare.com',
      ];
      
      bool connected = false;
      
      for (final endpoint in endpoints) {
        try {
          final response = await _dio.head(
            endpoint,
            options: Options(
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          );
          
          if (response.statusCode == 200 || response.statusCode == 204) {
            connected = true;
            break;
          }
        } catch (e) {
          // Try next endpoint
          continue;
        }
      }
      
      _updateConnectionStatus(connected);
      
      if (connected) {
        // Measure bandwidth if just connected
        if (!_isOnline) {
          await _measureBandwidth();
        }
      }
      
    } catch (e) {
      _logger.e('Connection check failed', error: e);
      _updateConnectionStatus(false);
    }
  }
  
  void _updateConnectionStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      
      if (isOnline) {
        _lastConnectionTime = DateTime.now();
        _logger.i('Connected to network');
      } else {
        _lastDisconnectionTime = DateTime.now();
        _currentQuality = ConnectionQuality.offline;
        _currentBandwidth = 0.0;
        _logger.w('Disconnected from network');
      }
      
      _connectionController.add(isOnline);
      _qualityController.add(_currentQuality);
      _updateStatus();
    }
  }
  
  Future<void> _measureBandwidth() async {
    if (!_isOnline) return;
    
    try {
      // Download a small file to measure bandwidth
      const testUrl = 'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png';
      const expectedSize = 13504; // bytes
      
      final stopwatch = Stopwatch()..start();
      
      final response = await _dio.get(
        testUrl,
        options: Options(
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      stopwatch.stop();
      
      if (response.data != null) {
        final bytes = (response.data as List<int>).length;
        final seconds = stopwatch.elapsedMilliseconds / 1000;
        final bitsPerSecond = (bytes * 8) / seconds;
        final kbps = bitsPerSecond / 1000;
        
        _currentBandwidth = kbps;
        _updateConnectionQuality(kbps);
        
        _logger.d('Bandwidth measured: ${kbps.toStringAsFixed(2)} kbps');
      }
      
    } catch (e) {
      _logger.e('Bandwidth measurement failed', error: e);
      // Assume poor connection if measurement fails
      _currentQuality = ConnectionQuality.poor;
      _qualityController.add(_currentQuality);
    }
  }
  
  void _updateConnectionQuality(double kbps) {
    ConnectionQuality newQuality;
    
    if (kbps < 150) {
      newQuality = ConnectionQuality.poor;
    } else if (kbps < 500) {
      newQuality = ConnectionQuality.fair;
    } else if (kbps < 2000) {
      newQuality = ConnectionQuality.good;
    } else {
      newQuality = ConnectionQuality.excellent;
    }
    
    if (_currentQuality != newQuality) {
      _currentQuality = newQuality;
      _qualityController.add(newQuality);
      _updateStatus();
    }
  }
  
  void _updateStatus() {
    final status = NetworkStatus(
      isOnline: _isOnline,
      quality: _currentQuality,
      type: _currentType,
      bandwidth: _currentBandwidth,
      lastConnectionTime: _lastConnectionTime,
      lastDisconnectionTime: _lastDisconnectionTime,
    );
    
    _statusController.add(status);
  }
  
  Future<bool> hasInternetConnection() async {
    await _checkConnection();
    return _isOnline;
  }
  
  Future<double> measureCurrentBandwidth() async {
    await _measureBandwidth();
    return _currentBandwidth;
  }
  
  bool shouldSyncMedia() {
    // Only sync media on good connections
    return _currentQuality == ConnectionQuality.good || 
           _currentQuality == ConnectionQuality.excellent;
  }
  
  bool shouldCompressData() {
    // Compress data on poor connections
    return _currentQuality == ConnectionQuality.poor || 
           _currentQuality == ConnectionQuality.fair;
  }
  
  int getSyncBatchSize() {
    // Adjust batch size based on connection quality
    switch (_currentQuality) {
      case ConnectionQuality.offline:
        return 0;
      case ConnectionQuality.poor:
        return 5;
      case ConnectionQuality.fair:
        return 10;
      case ConnectionQuality.good:
        return 25;
      case ConnectionQuality.excellent:
        return 50;
    }
  }
  
  Duration getSyncInterval() {
    // Adjust sync interval based on connection quality
    switch (_currentQuality) {
      case ConnectionQuality.offline:
        return const Duration(hours: 1); // Won't sync anyway
      case ConnectionQuality.poor:
        return const Duration(minutes: 30);
      case ConnectionQuality.fair:
        return const Duration(minutes: 15);
      case ConnectionQuality.good:
        return const Duration(minutes: 5);
      case ConnectionQuality.excellent:
        return const Duration(minutes: 2);
    }
  }
  
  Future<bool> waitForConnection({Duration? timeout}) async {
    if (_isOnline) return true;
    
    final completer = Completer<bool>();
    StreamSubscription? subscription;
    Timer? timeoutTimer;
    
    subscription = connectionStream.listen((isOnline) {
      if (isOnline) {
        completer.complete(true);
        subscription?.cancel();
        timeoutTimer?.cancel();
      }
    });
    
    if (timeout != null) {
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(false);
          subscription?.cancel();
        }
      });
    }
    
    return completer.future;
  }
  
  Map<String, dynamic> getStatistics() {
    final uptime = _lastConnectionTime != null
        ? DateTime.now().difference(_lastConnectionTime!)
        : Duration.zero;
    
    final downtime = _lastDisconnectionTime != null && !_isOnline
        ? DateTime.now().difference(_lastDisconnectionTime!)
        : Duration.zero;
    
    return {
      'isOnline': _isOnline,
      'connectionQuality': _currentQuality.toString(),
      'networkType': _currentType.toString(),
      'bandwidth': '${_currentBandwidth.toStringAsFixed(2)} kbps',
      'uptime': _formatDuration(uptime),
      'downtime': _formatDuration(downtime),
      'lastConnectionTime': _lastConnectionTime?.toIso8601String(),
      'lastDisconnectionTime': _lastDisconnectionTime?.toIso8601String(),
    };
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }
  
  void dispose() {
    _connectionCheckTimer?.cancel();
    _bandwidthCheckTimer?.cancel();
    _connectionController.close();
    _qualityController.close();
    _statusController.close();
  }
}

class NetworkStatus {
  final bool isOnline;
  final ConnectionQuality quality;
  final NetworkType type;
  final double bandwidth;
  final DateTime? lastConnectionTime;
  final DateTime? lastDisconnectionTime;
  
  NetworkStatus({
    required this.isOnline,
    required this.quality,
    required this.type,
    required this.bandwidth,
    this.lastConnectionTime,
    this.lastDisconnectionTime,
  });
  
  String get displayStatus {
    if (!isOnline) return 'Offline';
    
    switch (quality) {
      case ConnectionQuality.offline:
        return 'Offline';
      case ConnectionQuality.poor:
        return 'Poor Connection';
      case ConnectionQuality.fair:
        return 'Fair Connection';
      case ConnectionQuality.good:
        return 'Good Connection';
      case ConnectionQuality.excellent:
        return 'Excellent Connection';
    }
  }
  
  String get displayType {
    switch (type) {
      case NetworkType.none:
        return 'No Network';
      case NetworkType.mobile:
        return 'Mobile Data';
      case NetworkType.wifi:
        return 'Wi-Fi';
      case NetworkType.ethernet:
        return 'Ethernet';
      case NetworkType.bluetooth:
        return 'Bluetooth';
      case NetworkType.vpn:
        return 'VPN';
      case NetworkType.other:
        return 'Other';
    }
  }
}