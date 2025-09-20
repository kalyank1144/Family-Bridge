import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserType { elder, caregiver, youth }

extension UserTypeX on UserType {
  String get key => switch (this) {
        UserType.elder => 'elder',
        UserType.caregiver => 'caregiver',
        UserType.youth => 'youth',
      };

  static UserType? fromKey(String? value) {
    switch (value) {
      case 'elder':
        return UserType.elder;
      case 'caregiver':
        return UserType.caregiver;
      case 'youth':
        return UserType.youth;
      default:
        return null;
    }
  }
}

class UserTypeProvider extends ChangeNotifier {
  static const _prefsKey = 'selected_user_type';

  UserType? _userType;
  bool _initialized = false;

  UserType? get userType => _userType;
  bool get isInitialized => _initialized;
  bool get isSelected => _userType != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsKey);
    _userType = UserTypeX.fromKey(value);
    _initialized = true;
    notifyListeners();
  }

  Future<void> setUserType(UserType type, {bool persist = true}) async {
    _userType = type;
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, type.key);
    }
    notifyListeners();
  }

  Future<void> switchUserType(UserType type) async {
    await setUserType(type, persist: true);
  }

  Future<void> clear() async {
    _userType = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }
}