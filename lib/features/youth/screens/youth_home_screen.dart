import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../chat/screens/family_chat_screen.dart' as chat;

class YouthHomeScreen extends StatefulWidget {
  const YouthHomeScreen({super.key});

  @override
  State<YouthHomeScreen> createState() => _YouthHomeScreenState();
}

class _YouthHomeScreenState extends State<YouthHomeScreen> {
  static const _prefsUserIdKey = 'youth_user_id';
  String? _userId;
  final String _familyId = 'demo-family-123';

  @override
  void initState() {
    super.initState();
    _ensureUserId();
  }

  Future<void> _ensureUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_prefsUserIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_prefsUserIdKey, id);
    }
    if (mounted) setState(() => _userId = id);
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return chat.FamilyChatScreen(
      familyId: _familyId,
      userId: _userId!,
      userType: 'youth',
    );
  }
}