import 'package:flutter/foundation.dart';
import '../offline/offline_manager.dart';
import '../offline/storage/local_storage_manager.dart';
import '../models/user.dart';

class AppStateProvider extends ChangeNotifier {
  final OfflineManager offlineManager;
  final LocalStorageManager storageManager;
  
  User? _currentUser;
  List<User> _familyMembers = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _appState = {};
  
  User? get currentUser => _currentUser;
  List<User> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get appState => _appState;
  
  AppStateProvider({
    required this.offlineManager,
    required this.storageManager,
  }) {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await loadCurrentUser();
    await loadFamilyMembers();
  }
  
  Future<void> loadCurrentUser() async {
    _setLoading(true);
    try {
      final userId = await storageManager.getConfig('currentUserId');
      if (userId != null) {
        _currentUser = await storageManager.getUser(userId);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load user: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> loadFamilyMembers() async {
    _setLoading(true);
    try {
      _familyMembers = await storageManager.getAllUsers();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load family members: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> setCurrentUser(User user) async {
    _currentUser = user;
    await storageManager.saveUser(user);
    await storageManager.saveConfig('currentUserId', user.id);
    notifyListeners();
  }
  
  Future<void> addFamilyMember(User user) async {
    await storageManager.saveUser(user);
    _familyMembers.add(user);
    notifyListeners();
  }
  
  Future<void> updateFamilyMember(User user) async {
    await storageManager.saveUser(user);
    final index = _familyMembers.indexWhere((m) => m.id == user.id);
    if (index != -1) {
      _familyMembers[index] = user;
      notifyListeners();
    }
  }
  
  Future<void> removeFamilyMember(String userId) async {
    _familyMembers.removeWhere((m) => m.id == userId);
    notifyListeners();
  }
  
  void updateAppState(String key, dynamic value) {
    _appState[key] = value;
    notifyListeners();
  }
  
  dynamic getAppState(String key) {
    return _appState[key];
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    debugPrint(error);
    notifyListeners();
  }
  
  Future<void> signOut() async {
    _currentUser = null;
    _familyMembers.clear();
    _appState.clear();
    await storageManager.saveConfig('currentUserId', null);
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}