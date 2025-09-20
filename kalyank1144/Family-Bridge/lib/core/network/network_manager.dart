import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

enum NetworkStatus {
  online,
  offline,
  weak,
  slow,
}

enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  bluetooth,
  none,
}

class NetworkQuality {
  final double bandwidth;
  final int latency;
  final double packetLoss;
  final NetworkStatus status;
  final String message;
  
  NetworkQuality({
    required this.bandwidth,
    required this.latency,
    required this.packetLoss,
    required this.status,
    required this.message,
  });
  
  bool get isGood => status == NetworkStatus.online && latency < 100;
  bool get isAcceptable => status != NetworkStatus.offline && latency < 500;
}

class NetworkManager {
  final Connectivity _connectivity = Connectivity();
  final Dio _dio = Dio();
  
  final _connectionController = StreamController<bool>.broadcast();
  final _statusController = StreamController<NetworkStatus>.broadcast();
  final _typeController = StreamController<ConnectionType>.broadcast();
  final _qualityController = StreamController<NetworkQuality>.broadcast();
  
  bool _isOnline = false;
  NetworkStatus _currentStatus = NetworkStatus.offline;
  ConnectionType _connectionType = ConnectionType.none;
  NetworkQuality? _networkQuality;
  
  Timer? _monitoringTimer;
  Timer? _retryTimer;
  
  static const String _testUrl = 'https://www.google.com';
  static const Duration _monitoringInterval = Duration(seconds: 30);
  static const Duration _retryInterval = Duration(seconds: 10);
  
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<NetworkStatus> get statusStream => _statusController.stream;
  Stream<ConnectionType> get typeStream => _typeController.stream;
  Stream<NetworkQuality> get qualityStream => _qualityController.stream;
  
  bool get isOnline => _isOnline;
  NetworkStatus get status => _currentStatus;
  ConnectionType get connectionType => _connectionType;
  NetworkQuality? get networkQuality => _networkQuality;
  
  Future<void> initialize() async {
    await _checkConnectivity();
    _startConnectivityMonitoring();
    _startQualityMonitoring();
  }
  
  void _startConnectivityMonitoring() {
    _connectivity.onConnectivityChanged.listen((result) {
      _handleConnectivityChange(result);
    });
  }
  
  void _startQualityMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      if (_isOnline) {
        _measureNetworkQuality();
      }
    });
  }
  
  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    if (results.isEmpty) {
      _updateConnectionStatus(false, ConnectionType.none);
      return;
    }
    
    final result = results.first;
    final connectionType = _mapConnectionType(result);
    
    // Check actual internet connectivity
    final hasInternet = await _checkInternetConnection();
    
    _updateConnectionStatus(hasInternet, connectionType);
    
    if (hasInternet) {
      await _measureNetworkQuality();
    }
  }
  
  ConnectionType _mapConnectionType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectionType.wifi;
      case ConnectivityResult.mobile:
        return ConnectionType.mobile;
      case ConnectivityResult.ethernet:
        return ConnectionType.ethernet;
      case ConnectivityResult.bluetooth:
        return ConnectionType.bluetooth;
      case ConnectivityResult.none:
      default:
        return ConnectionType.none;
    }
  }
  
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _handleConnectivityChange(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _updateConnectionStatus(false, ConnectionType.none);
    }
  }
  
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      debugPrint('Error checking internet: $e');
      return false;
    }
  }
  
  Future<void> _measureNetworkQuality() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Measure latency with a simple request
      final response = await _dio.get(
        _testUrl,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;
      
      // Estimate bandwidth based on response size and time
      final responseSize = response.data.toString().length;
      final bandwidth = (responseSize * 8) / (latency / 1000); // bits per second
      
      // Determine network quality
      NetworkStatus status;
      String message;
      
      if (latency < 50) {
        status = NetworkStatus.online;
        message = 'Excellent connection';
      } else if (latency < 150) {
        status = NetworkStatus.online;
        message = 'Good connection';
      } else if (latency < 500) {
        status = NetworkStatus.weak;
        message = 'Weak connection';
      } else {
        status = NetworkStatus.slow;
        message = 'Poor connection';
      }
      
      _networkQuality = NetworkQuality(
        bandwidth: bandwidth,
        latency: latency,
        packetLoss: 0.0, // Would need more sophisticated testing
        status: status,
        message: message,
      );
      
      _currentStatus = status;
      _statusController.add(status);
      _qualityController.add(_networkQuality!);
      
    } catch (e) {
      debugPrint('Error measuring network quality: $e');
      
      _networkQuality = NetworkQuality(
        bandwidth: 0,
        latency: 9999,
        packetLoss: 100,
        status: NetworkStatus.offline,
        message: 'Connection test failed',
      );
      
      _currentStatus = NetworkStatus.offline;
      _statusController.add(NetworkStatus.offline);
      _qualityController.add(_networkQuality!);
    }
  }
  
  void _updateConnectionStatus(bool isOnline, ConnectionType type) {
    final statusChanged = _isOnline != isOnline;
    final typeChanged = _connectionType != type;
    
    _isOnline = isOnline;
    _connectionType = type;
    
    if (statusChanged) {
      _connectionController.add(isOnline);
      
      if (isOnline) {
        debugPrint('Network connected: $type');
        _retryTimer?.cancel();
      } else {
        debugPrint('Network disconnected');
        _currentStatus = NetworkStatus.offline;
        _statusController.add(NetworkStatus.offline);
        _startRetryTimer();
      }
    }
    
    if (typeChanged) {
      _typeController.add(type);
    }
  }
  
  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (_) {
      _checkConnectivity();
    });
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
  
  Future<bool> isReachable(String url) async {
    if (!_isOnline) return false;
    
    try {
      final response = await _dio.head(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  void startMonitoring() {
    _startQualityMonitoring();
  }
  
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _retryTimer?.cancel();
  }
  
  Map<String, dynamic> getNetworkInfo() {
    return {
      'isOnline': _isOnline,
      'status': _currentStatus.toString(),
      'connectionType': _connectionType.toString(),
      'quality': _networkQuality != null ? {
        'bandwidth': '${(_networkQuality!.bandwidth / 1000000).toStringAsFixed(2)} Mbps',
        'latency': '${_networkQuality!.latency} ms',
        'packetLoss': '${_networkQuality!.packetLoss}%',
        'message': _networkQuality!.message,
      } : null,
    };
  }
  
  void dispose() {
    _monitoringTimer?.cancel();
    _retryTimer?.cancel();
    _connectionController.close();
    _statusController.close();
    _typeController.close();
    _qualityController.close();
    _dio.close();
  }
}