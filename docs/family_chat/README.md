# FamilyBridge - Real-Time Family Communication System

A comprehensive Flutter-based real-time chat system designed for multi-generational family communication, with adaptive interfaces for elderly users, caregivers, and youth.

## 🎯 Key Features

### Real-Time Communication
- **Instant Messaging**: Real-time message delivery using Supabase
- **Presence System**: Live online/offline status tracking
- **Typing Indicators**: See when family members are typing
- **Read Receipts**: Know when messages have been read

### Message Types
- 📝 **Text Messages**: With emoji support and mentions
- 🎤 **Voice Messages**: With AI transcription for elderly users
- 📷 **Photo Sharing**: Optimized image delivery
- 🎥 **Video Sharing**: With thumbnail generation
- 📍 **Location Sharing**: Share current location
- 📋 **Care Notes**: Professional notes for caregivers
- 📢 **Announcements**: Family-wide announcements
- 🏆 **Achievements**: Youth achievement sharing

## 👥 User-Specific Adaptations

### Elder Users
- **Large Text Display**: 24px+ font sizes for better readability
- **Voice Priority**: Auto-play voice messages
- **Quick Responses**: Preset response buttons
  - "I'm okay"
  - "Need help"
  - "Love you"
  - "Call me"
- **Simplified Interface**: Essential emojis only
- **Voice Announcements**: Urgent messages spoken aloud
- **AI Transcription**: Automatic voice-to-text conversion

### Caregiver Users
- **Professional Layout**: Clean, organized interface
- **Advanced Features**:
  - Message search and filtering
  - Care notes with timestamps
  - Priority flagging system
  - Chat history export
  - Multi-select for task creation
  - @mentions for specific members
- **Grouped Notifications**: Organized by priority

### Youth Users
- **Modern Chat UI**: Contemporary design
- **Interactive Features**:
  - Message reactions (❤️, 👍, 😂, etc.)
  - GIF picker integration
  - Sticker packs
  - Message effects and animations
  - Voice filters for fun recordings
- **Smart Notifications**: Silent during school hours
- **Achievement Sharing**: Share accomplishments

## 🏗️ Architecture

### Project Structure
```
/lib/features/chat/
├── models/
│   ├── message_model.dart        # Message data structure
│   └── presence_model.dart       # Online status models
├── providers/
│   └── chat_providers.dart       # Riverpod state management
├── screens/
│   └── family_chat_screen.dart   # Main chat interface
├── services/
│   ├── chat_service.dart         # Supabase real-time logic
│   ├── media_service.dart        # Media handling
│   └── notification_service.dart # Smart notifications
└── widgets/
    ├── message_bubble.dart        # Message display
    ├── chat_input_bar.dart        # Input interface
    ├── typing_indicator.dart      # Typing status
    ├── online_status_bar.dart     # Online members
    ├── voice_recorder_overlay.dart # Voice recording
    ├── voice_message_player.dart  # Voice playback
    └── message_reactions.dart    # Reaction system
```

## 🔧 Technical Implementation

### Supabase Real-Time Setup
```dart
// Message subscription
final messageChannel = supabase
  .channel('messages:$familyId')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'messages',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'family_id',
      value: familyId,
    ),
    callback: (payload) {
      // Handle message changes
    },
  )
  .subscribe();

// Presence tracking
final presenceChannel = supabase
  .channel('family:$familyId')
  .onPresenceSync((payload) {
    // Update online status
  })
  .onBroadcast(
    event: 'typing',
    callback: (payload) {
      // Handle typing indicators
    },
  )
  .subscribe();
```

### State Management (Riverpod)
```dart
// Message stream provider
final messagesStreamProvider = StreamProvider.family<List<Message>, String>(
  (ref, familyId) {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.messagesStream;
  },
);

// Presence tracking
final presenceStreamProvider = StreamProvider.family<Map<String, FamilyMemberPresence>, String>(
  (ref, familyId) {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.presenceStream;
  },
);
```

## 📱 Smart Notifications

### Priority Levels
- **Emergency**: Critical alerts with max priority
- **Urgent**: Time-sensitive with voice announcements for elderly
- **Important**: Standard priority notifications
- **Normal**: Low priority, grouped for caregivers

### User-Specific Behavior
- **Elder**: Voice announcements for urgent messages
- **Caregiver**: Grouped by priority with summaries
- **Youth**: Silent during school hours (8 AM - 3 PM weekdays)

## 🎨 UI/UX Features

### Accessibility
- **Elder Mode**:
  - Increased touch targets
  - High contrast colors
  - Simplified navigation
  - Voice-first interactions
  
### Performance
- **Lazy Loading**: Efficient message history pagination
- **Image Optimization**: Automatic compression and caching
- **Offline Support**: Message queuing and sync on reconnection

## 🔐 Security & Privacy

- **End-to-End Encryption**: For sensitive messages
- **Message Retention**: Configurable retention policies
- **Access Control**: Family-only message visibility
- **Content Moderation**: Report and block functionality

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Supabase account

### Installation

1. Clone the repository:
```bash
git clone https://github.com/kalyank1144/Family-Bridge.git
cd family_bridge
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Supabase:
```dart
// In lib/main.dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

4. Run the app:
```bash
flutter run
```

## 📊 Database Schema

### Messages Table
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  family_id UUID NOT NULL,
  sender_id UUID NOT NULL,
  sender_name TEXT NOT NULL,
  sender_type TEXT NOT NULL,
  content TEXT,
  type TEXT NOT NULL,
  status TEXT DEFAULT 'sent',
  priority TEXT DEFAULT 'normal',
  timestamp TIMESTAMPTZ NOT NULL,
  is_edited BOOLEAN DEFAULT false,
  edited_at TIMESTAMPTZ,
  read_by TEXT[],
  reactions JSONB,
  metadata JSONB,
  is_deleted BOOLEAN DEFAULT false
);
```

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for real-time infrastructure
- Riverpod for state management
- All contributors and testers