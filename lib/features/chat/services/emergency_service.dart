import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/message_model.dart';
import '../services/chat_service.dart';

class EmergencyService {
  ChatService? _chatService;
  
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();
  
  void setChatService(ChatService chatService) {
    _chatService = chatService;
  }

  /// Send emergency alert to all family members
  Future<void> sendEmergencyAlert({
    required String userId,
    required String userName,
    required String familyId,
    String? customMessage,
    bool includeLocation = true,
  }) async {
    try {
      HapticFeedback.heavyImpact();
      
      // Get current location if requested
      Position? position;
      String locationInfo = '';
      
      if (includeLocation) {
        try {
          position = await _getCurrentLocation();
          if (position != null) {
            locationInfo = '\n📍 Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          }
        } catch (e) {
          debugPrint('Failed to get location for emergency alert: $e');
        }
      }
      
      // Compose emergency message
      final emergencyMessage = customMessage ?? 
          '🆘 EMERGENCY ALERT 🆘\n\n$userName needs immediate assistance!$locationInfo\n\n⏰ Time: ${DateTime.now().toLocal().toString().substring(0, 19)}\n\nPlease respond ASAP or call emergency services if needed.';
      
      // Send high-priority message
      if (_chatService != null) {
        await _chatService!.sendMessage(
          content: emergencyMessage,
          type: MessageType.announcement,
          priority: MessagePriority.emergency,
        );
        
        // Send location if available
        if (position != null) {
          await _chatService!.sendMessage(
            content: 'Emergency location',
            type: MessageType.location,
            latitude: position.latitude,
            longitude: position.longitude,
            locationName: 'Emergency location from $userName',
            priority: MessagePriority.emergency,
          );
        }
      }
      
      debugPrint('Emergency alert sent successfully');
    } catch (e) {
      debugPrint('Failed to send emergency alert: $e');
      rethrow;
    }
  }

  /// Send help request with specific type
  Future<void> sendHelpRequest({
    required String userId,
    required String userName,
    required String familyId,
    required HelpRequestType type,
    String? additionalInfo,
  }) async {
    try {
      HapticFeedback.mediumImpact();
      
      final helpMessage = _buildHelpMessage(type, userName, additionalInfo);
      
      if (_chatService != null) {
        await _chatService!.sendMessage(
          content: helpMessage,
          type: MessageType.careNote,
          priority: type == HelpRequestType.medical 
              ? MessagePriority.urgent 
              : MessagePriority.important,
        );
      }
      
    } catch (e) {
      debugPrint('Failed to send help request: $e');
      rethrow;
    }
  }

  /// Send safety check-in
  Future<void> sendSafetyCheckIn({
    required String userId,
    required String userName,
    required String familyId,
    String status = 'safe',
  }) async {
    try {
      HapticFeedback.lightImpact();
      
      final statusEmoji = _getStatusEmoji(status);
      final checkInMessage = '$statusEmoji Safety Update: $userName is $status\n⏰ ${DateTime.now().toLocal().toString().substring(0, 19)}';
      
      if (_chatService != null) {
        await _chatService!.sendMessage(
          content: checkInMessage,
          type: MessageType.announcement,
          priority: MessagePriority.normal,
        );
      }
      
    } catch (e) {
      debugPrint('Failed to send safety check-in: $e');
      rethrow;
    }
  }

  /// Cancel emergency alert
  Future<void> cancelEmergencyAlert({
    required String userId,
    required String userName,
    required String familyId,
    String? reason,
  }) async {
    try {
      final cancelMessage = '✅ EMERGENCY CANCELLED ✅\n\n$userName has cancelled the emergency alert.\n\n${reason ?? 'False alarm - everything is okay now.'}\n\n⏰ Cancelled at: ${DateTime.now().toLocal().toString().substring(0, 19)}';
      
      if (_chatService != null) {
        await _chatService!.sendMessage(
          content: cancelMessage,
          type: MessageType.announcement,
          priority: MessagePriority.important,
        );
      }
      
    } catch (e) {
      debugPrint('Failed to cancel emergency alert: $e');
      rethrow;
    }
  }

  /// Get current location with permission handling
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Build help message based on type
  String _buildHelpMessage(HelpRequestType type, String userName, String? additionalInfo) {
    final emoji = _getHelpTypeEmoji(type);
    final typeText = _getHelpTypeText(type);
    
    String message = '$emoji HELP REQUEST: $typeText\n\n$userName needs assistance with ${typeText.toLowerCase()}.';
    
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      message += '\n\nAdditional info: $additionalInfo';
    }
    
    message += '\n\n⏰ Requested at: ${DateTime.now().toLocal().toString().substring(0, 19)}';
    
    return message;
  }

  /// Get emoji for help request type
  String _getHelpTypeEmoji(HelpRequestType type) {
    switch (type) {
      case HelpRequestType.medical:
        return '🏥';
      case HelpRequestType.mobility:
        return '♿';
      case HelpRequestType.technology:
        return '💻';
      case HelpRequestType.household:
        return '🏠';
      case HelpRequestType.transportation:
        return '🚗';
      case HelpRequestType.shopping:
        return '🛒';
      case HelpRequestType.social:
        return '👥';
      case HelpRequestType.other:
        return '❓';
    }
  }

  /// Get text description for help request type
  String _getHelpTypeText(HelpRequestType type) {
    switch (type) {
      case HelpRequestType.medical:
        return 'Medical assistance';
      case HelpRequestType.mobility:
        return 'Mobility support';
      case HelpRequestType.technology:
        return 'Technology help';
      case HelpRequestType.household:
        return 'Household tasks';
      case HelpRequestType.transportation:
        return 'Transportation';
      case HelpRequestType.shopping:
        return 'Shopping assistance';
      case HelpRequestType.social:
        return 'Social support';
      case HelpRequestType.other:
        return 'General assistance';
    }
  }

  /// Get emoji for safety status
  String _getStatusEmoji(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return '✅';
      case 'home':
        return '🏠';
      case 'out':
        return '🚶';
      case 'travel':
        return '✈️';
      case 'work':
        return '💼';
      case 'hospital':
        return '🏥';
      case 'emergency':
        return '🆘';
      default:
        return '📍';
    }
  }

  /// Check if user is in emergency mode
  bool isEmergencyActive(String userId) {
    // This would typically check a database or cache
    // For now, return false as placeholder
    return false;
  }

  /// Get emergency contacts for family
  Future<List<EmergencyContact>> getEmergencyContacts(String familyId) async {
    try {
      // This would fetch from database
      // Placeholder implementation
      return [
        EmergencyContact(
          id: '1',
          name: 'Emergency Services',
          phone: '911',
          type: EmergencyContactType.emergency,
        ),
        EmergencyContact(
          id: '2',
          name: 'Family Doctor',
          phone: '555-0123',
          type: EmergencyContactType.medical,
        ),
      ];
    } catch (e) {
      debugPrint('Failed to get emergency contacts: $e');
      return [];
    }
  }

  /// Auto-trigger emergency alert based on device sensors
  Future<void> checkForAutoEmergency(String userId, String familyId) async {
    // This would integrate with device sensors to detect falls, 
    // prolonged inactivity, etc. Placeholder for now.
    
    // Example: Check for fall detection, heart rate anomalies, etc.
    // if (fallDetected || heartRateAbnormal) {
    //   await sendEmergencyAlert(...);
    // }
  }
}

/// Types of help requests
enum HelpRequestType {
  medical,
  mobility,
  technology,
  household,
  transportation,
  shopping,
  social,
  other,
}

/// Emergency contact model
class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final EmergencyContactType type;
  final String? relationship;
  final bool isPrimary;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.relationship,
    this.isPrimary = false,
  });
}

/// Emergency contact types
enum EmergencyContactType {
  emergency,
  medical,
  family,
  caregiver,
  neighbor,
  other,
}

// Emergency service provider is defined in chat_providers.dart