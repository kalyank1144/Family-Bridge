import 'dart:async';
import 'package:flutter/foundation.dart';
import '../network/network_manager.dart';

class NetworkStateProvider extends ChangeNotifier {
  final NetworkManager networkManager;
  
  bool _isOnline = false;
  NetworkStatus _status = NetworkStatus.offline;
  ConnectionType _connectionType = ConnectionType.none;
  NetworkQuality? _networkQuality;
  Map<String, dynamic> _networkInfo = {};
  
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _typeSubscription;
  StreamSubscription? _qualitySubscription;
  
  bool get isOnline => _isOnline;
  NetworkStatus get status => _status;
  ConnectionType get connectionType => _connectionType;
  NetworkQuality? get networkQuality => _networkQuality;
  Map<String, dynamic> get networkInfo => _networkInfo;
  
  bool get isWifi => _connectionType == ConnectionType.wifi;
  bool get isMobile => _connectionType == ConnectionType.mobile;
  bool get hasGoodConnection => _networkQuality?.isGood ?? false;
  bool get hasAcceptableConnection => _networkQuality?.isAcceptable ?? false;
  
  NetworkStateProvider({required this.networkManager}) {
    _initialize();
  }
  
  void _initialize() {
    _isOnline = networkManager.isOnline;
    _status = networkManager.status;
    _connectionType = networkManager.connectionType;
    _networkQuality = networkManager.networkQuality;
    _networkInfo = networkManager.getNetworkInfo();
    
    _connectionSubscription = networkManager.connectionStream.listen((isOnline) {
      _isOnline = isOnline;
      _networkInfo = networkManager.getNetworkInfo();
      notifyListeners();
    });
    
    _statusSubscription = networkManager.statusStream.listen((status) {
      _status = status;
      _networkInfo = networkManager.getNetworkInfo();
      notifyListeners();
    });
    
    _typeSubscription = networkManager.typeStream.listen((type) {
      _connectionType = type;
      _networkInfo = networkManager.getNetworkInfo();
      notifyListeners();
    });
    
    _qualitySubscription = networkManager.qualityStream.listen((quality) {
      _networkQuality = quality;
      _networkInfo = networkManager.getNetworkInfo();
      notifyListeners();
    });
  }
  
  Future<bool> waitForConnection({Duration? timeout}) async {
    return await networkManager.waitForConnection(timeout: timeout);
  }
  
  Future<bool> isReachable(String url) async {
    return await networkManager.isReachable(url);
  }
  
  void refreshNetworkInfo() {
    _networkInfo = networkManager.getNetworkInfo();
    notifyListeners();
  }
  
  String getConnectionMessage() {
    if (!_isOnline) {
      return 'No internet connection';
    }
    
    switch (_status) {
      case NetworkStatus.online:
        return 'Connected';
      case NetworkStatus.weak:
        return 'Weak connection';
      case NetworkStatus.slow:
        return 'Slow connection';
      case NetworkStatus.offline:
        return 'Offline';
    }
  }
  
  String getConnectionTypeString() {
    switch (_connectionType) {
      case ConnectionType.wifi:
        return 'Wi-Fi';
      case ConnectionType.mobile:
        return 'Mobile Data';
      case ConnectionType.ethernet:
        return 'Ethernet';
      case ConnectionType.bluetooth:
        return 'Bluetooth';
      case ConnectionType.none:
        return 'None';
    }
  }
  
  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _statusSubscription?.cancel();
    _typeSubscription?.cancel();
    _qualitySubscription?.cancel();
    super.dispose();
  }
}