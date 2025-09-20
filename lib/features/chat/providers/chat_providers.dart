import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../models/presence_model.dart';
import '../services/chat_service.dart';
import '../services/media_service.dart';
import '../services/emergency_service.dart';
import '../../../core/services/notification_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

// Media service provider
final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});

// Emergency service provider
final emergencyServiceProvider = Provider<EmergencyService>((ref) {
  final emergencyService = EmergencyService();
  final chatService = ref.read(chatServiceProvider);
  emergencyService.setChatService(chatService);
  return emergencyService;
});

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

final messagesStreamProvider = StreamProvider.family<List<Message>, String>(
  (ref, familyId) {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.messagesStream;
  },
);

final presenceStreamProvider = StreamProvider.family<Map<String, FamilyMemberPresence>, String>(
  (ref, familyId) {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.presenceStream;
  },
);

final typingStreamProvider = StreamProvider.family<List<TypingIndicator>, String>(
  (ref, familyId) {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.typingStream;
  },
);

final isTypingProvider = StateProvider<bool>((ref) => false);

final selectedMessageProvider = StateProvider<Message?>((ref) => null);

final replyToMessageProvider = StateProvider<Message?>((ref) => null);

final chatInitializedProvider = FutureProvider.family<void, ChatInitParams>(
  (ref, params) async {
    final chatService = ref.watch(chatServiceProvider);
    await chatService.initialize(
      familyId: params.familyId,
      userId: params.userId,
      userType: params.userType,
    );
  },
);

class ChatInitParams {
  final String familyId;
  final String userId;
  final String userType;

  ChatInitParams({
    required this.familyId,
    required this.userId,
    required this.userType,
  });
}

final quickResponsesProvider = Provider.family<List<String>, String>(
  (ref, userType) {
    switch (userType) {
      case 'elder':
        return [
          "I'm okay",
          "Need help",
          "Love you",
          "Call me",
          "Thank you",
          "Yes",
          "No",
          "On my way",
        ];
      case 'caregiver':
        return [
          "Checking in",
          "On my way",
          "Medication reminder",
          "How are you feeling?",
          "Need anything?",
          "I'll handle it",
        ];
      case 'youth':
        return [
          "On my way home",
          "At school",
          "Need help with homework",
          "Can I go out?",
          "Love you too",
          "Thanks!",
        ];
      default:
        return [];
    }
  },
);

final messageSearchProvider = StateNotifierProvider<MessageSearchNotifier, List<Message>>(
  (ref) => MessageSearchNotifier(),
);

class MessageSearchNotifier extends StateNotifier<List<Message>> {
  MessageSearchNotifier() : super([]);
  
  void searchMessages(List<Message> allMessages, String query) {
    if (query.isEmpty) {
      state = [];
      return;
    }
    
    state = allMessages.where((message) {
      final content = message.content?.toLowerCase() ?? '';
      final senderName = message.senderName.toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return content.contains(searchQuery) || 
             senderName.contains(searchQuery);
    }).toList();
  }
  
  void clearSearch() {
    state = [];
  }
}