import 'package:flutter/foundation.dart';

class FamilyMemberPresence {
  final String userId;
  final String userName;
  final String userType;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime lastSeen;
  final bool isTyping;
  final String? currentActivity;

  FamilyMemberPresence({
    required this.userId,
    required this.userName,
    required this.userType,
    this.avatarUrl,
    required this.isOnline,
    required this.lastSeen,
    this.isTyping = false,
    this.currentActivity,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_name': userName,
    'user_type': userType,
    'avatar_url': avatarUrl,
    'is_online': isOnline,
    'last_seen': lastSeen.toIso8601String(),
    'is_typing': isTyping,
    'current_activity': currentActivity,
  };

  factory FamilyMemberPresence.fromJson(Map<String, dynamic> json) {
    return FamilyMemberPresence(
      userId: json['user_id'],
      userName: json['user_name'],
      userType: json['user_type'],
      avatarUrl: json['avatar_url'],
      isOnline: json['is_online'] ?? false,
      lastSeen: DateTime.parse(json['last_seen']),
      isTyping: json['is_typing'] ?? false,
      currentActivity: json['current_activity'],
    );
  }

  FamilyMemberPresence copyWith({
    String? userId,
    String? userName,
    String? userType,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isTyping,
    String? currentActivity,
  }) {
    return FamilyMemberPresence(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userType: userType ?? this.userType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
      currentActivity: currentActivity ?? this.currentActivity,
    );
  }
}

class TypingIndicator {
  final String userId;
  final String userName;
  final DateTime startedAt;

  TypingIndicator({
    required this.userId,
    required this.userName,
    required this.startedAt,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_name': userName,
    'started_at': startedAt.toIso8601String(),
  };

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      userId: json['user_id'],
      userName: json['user_name'],
      startedAt: DateTime.parse(json['started_at']),
    );
  }
}