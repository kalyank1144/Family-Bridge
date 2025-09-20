import 'package:flutter/material.dart';

class TechHelpProvider extends ChangeNotifier {
  List<HelpRequest> _activeRequests = [];
  List<HelpGuide> _helpGuides = [];
  
  List<HelpRequest> get activeRequests => List.unmodifiable(_activeRequests);
  List<HelpGuide> get helpGuides => List.unmodifiable(_helpGuides);
  
  Future<void> loadActiveRequests() async {
    // Simulate loading help requests
    await Future.delayed(const Duration(milliseconds: 300));
    
    _activeRequests = [
      HelpRequest(
        id: '1',
        fromName: 'Grandma Rose',
        fromId: 'grandma-rose',
        title: 'Can\'t find my photos',
        description: 'I took some pictures yesterday but I can\'t find them anywhere. Can you help me locate them?',
        priority: 'medium',
        timeAgo: '5 minutes ago',
        requestedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      HelpRequest(
        id: '2',
        fromName: 'Grandpa Joe',
        fromId: 'grandpa-joe',
        title: 'Video call not working',
        description: 'The video call keeps disconnecting when I try to call you. The screen goes black.',
        priority: 'high',
        timeAgo: '15 minutes ago',
        requestedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];
    
    _helpGuides = [
      HelpGuide(
        id: '1',
        title: 'Making Video Calls',
        description: 'Step-by-step guide to start and manage video calls',
        icon: Icons.video_call,
        steps: 6,
        colors: [const Color(0xFF10B981), const Color(0xFF059669)],
        category: 'Communication',
      ),
      HelpGuide(
        id: '2',
        title: 'Finding Photos',
        description: 'How to locate and organize your photos',
        icon: Icons.photo_library,
        steps: 4,
        colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
        category: 'Media',
      ),
      HelpGuide(
        id: '3',
        title: 'Sending Messages',
        description: 'Learn to send text and voice messages',
        icon: Icons.message,
        steps: 5,
        colors: [const Color(0xFFEC4899), const Color(0xBE185D)],
        category: 'Communication',
      ),
      HelpGuide(
        id: '4',
        title: 'Adjusting Settings',
        description: 'Customize your app preferences',
        icon: Icons.settings,
        steps: 8,
        colors: [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
        category: 'Settings',
      ),
      HelpGuide(
        id: '5',
        title: 'Taking Photos',
        description: 'How to take and share photos with family',
        icon: Icons.camera_alt,
        steps: 7,
        colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        category: 'Media',
      ),
      HelpGuide(
        id: '6',
        title: 'Emergency Features',
        description: 'Using emergency contacts and alerts',
        icon: Icons.emergency,
        steps: 3,
        colors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        category: 'Safety',
      ),
    ];
    
    notifyListeners();
  }
  
  Future<void> markRequestAsResolved(String requestId) async {
    _activeRequests.removeWhere((request) => request.id == requestId);
    notifyListeners();
  }
  
  Future<void> startRemoteAssistance(String requestId) async {
    // Simulate starting remote assistance
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would initiate a screen sharing session
  }
  
  Future<void> sendGuide(String requestId, String guideId) async {
    // Simulate sending a guide to the family member
    await Future.delayed(const Duration(milliseconds: 300));
    // In a real app, this would send the guide through the chat system
  }
  
  void addHelpRequest(HelpRequest request) {
    _activeRequests.insert(0, request);
    notifyListeners();
  }
  
  void removeHelpRequest(String requestId) {
    _activeRequests.removeWhere((request) => request.id == requestId);
    notifyListeners();
  }
}

class HelpRequest {
  final String id;
  final String fromName;
  final String fromId;
  final String title;
  final String description;
  final String priority; // low, medium, high, urgent
  final String timeAgo;
  final DateTime requestedAt;
  
  HelpRequest({
    required this.id,
    required this.fromName,
    required this.fromId,
    required this.title,
    required this.description,
    required this.priority,
    required this.timeAgo,
    required this.requestedAt,
  });
}

class HelpGuide {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int steps;
  final List<Color> colors;
  final String category;
  
  HelpGuide({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.steps,
    required this.colors,
    required this.category,
  });
}