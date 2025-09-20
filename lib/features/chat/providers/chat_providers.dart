import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/message_model.dart';
import '../models/presence_model.dart';
import '../services/chat_service.dart';
import '../services/media_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService.instance;
});

final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});

final messagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, familyId) {
  final service = ref.watch(chatServiceProvider);
  return service.messagesStream;
});

final presenceStreamProvider = StreamProvider.family<Map<String, FamilyMemberPresence>, String>((ref, familyId) {
  final service = ref.watch(chatServiceProvider);
  return service.presenceStream;
});

final typingStreamProvider = StreamProvider.family<List<TypingIndicator>, String>((ref, familyId) {
  final service = ref.watch(chatServiceProvider);
  return service.typingStream;
});

final quickResponsesProvider = Provider.family<List<String>, String>((ref, userType) {
  switch (userType) {
    case 'elder':
      return const [
        "I'm okay ✅",
        "Need help 🆘",
        "Love you ❤️",
        "Thank you 🙏",
        "Call me 📞",
        "Yes ✅",
        "No ❌",
      ];
    case 'caregiver':
      return const [
        'On my way',
        'Let\'s schedule a call',
        'How are you feeling?',
        'Took your meds?',
        'I\'ll check in tonight',
      ];
    case 'youth':
      return const [
        'lol 😆',
        'brb',
        'omw 🛵',
        'gg 🎮',
        'nice! 💯',
      ];
    default:
      return const [];
  }
});

final replyToMessageProvider = StateProvider<Message?>((ref) => null);
