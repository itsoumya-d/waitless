import 'package:equatable/equatable.dart';

import 'venue.dart';

/// Chat message types for different content
enum ChatMessageType {
  text,
  venueCard,
  activitySuggestion,
  quickActions,
  loading,
}

/// Chat message sender
enum ChatSender {
  user,
  ai,
  system,
}

/// Chat message model
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final ChatMessageType type;
  final ChatSender sender;
  final DateTime timestamp;
  final Venue? venue;
  final List<String>? suggestions;
  final bool isLoading;
  
  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.sender,
    required this.timestamp,
    this.venue,
    this.suggestions,
    this.isLoading = false,
  });
  
  /// Create a user text message
  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: ChatMessageType.text,
      sender: ChatSender.user,
      timestamp: DateTime.now(),
    );
  }
  
  /// Create an AI text message
  factory ChatMessage.ai(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: ChatMessageType.text,
      sender: ChatSender.ai,
      timestamp: DateTime.now(),
    );
  }
  
  /// Create a loading indicator message
  factory ChatMessage.loading() {
    return ChatMessage(
      id: 'loading',
      content: '',
      type: ChatMessageType.loading,
      sender: ChatSender.ai,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }
  
  /// Create a venue card message
  factory ChatMessage.venueCard(Venue venue, String description) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: description,
      type: ChatMessageType.venueCard,
      sender: ChatSender.ai,
      timestamp: DateTime.now(),
      venue: venue,
    );
  }
  
  /// Create a system message with quick action suggestions
  factory ChatMessage.quickActions(List<String> actions) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'Here are some things you can ask:',
      type: ChatMessageType.quickActions,
      sender: ChatSender.system,
      timestamp: DateTime.now(),
      suggestions: actions,
    );
  }
  
  /// Create welcome message
  factory ChatMessage.welcome() {
    return ChatMessage(
      id: 'welcome',
      content: 'Hi! I\'m your WaitLess assistant 👋\n\nI can help you find the best times to visit places, suggest activities while you wait, and answer questions about crowd levels.\n\nWhat would you like to know?',
      type: ChatMessageType.text,
      sender: ChatSender.ai,
      timestamp: DateTime.now(),
    );
  }
  
  @override
  List<Object?> get props => [id, content, type, sender, timestamp];
}
