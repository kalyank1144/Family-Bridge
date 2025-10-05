import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkManager {
  final Connectivity _connectivity = Connectivity();
  final _connectionController = StreamController<bool>.broadcast();
  
  bool _isOnline = false;
  
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isOnline => _isOnline;
  
  Future<void> initialize() async {
    await _checkConnectivity();
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }
  
  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _handleConnectivityChange(results);
  }
  
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isConnected = results.isNotEmpty && 
                       results.first != ConnectivityResult.none;
    
    if (_isOnline != isConnected) {
      _isOnline = isConnected;
      _connectionController.add(isConnected);
    }
  }
  
  void dispose() {
    _connectionController.close();
  }
}