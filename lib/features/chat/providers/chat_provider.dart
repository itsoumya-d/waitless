import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/chat_message.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/ai_context_provider.dart';

/// Chat state for managing conversation
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final List<String> quickSuggestions;
  
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.quickSuggestions = const [],
  });
  
  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    List<String>? quickSuggestions,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      quickSuggestions: quickSuggestions ?? this.quickSuggestions,
    );
  }
}

/// Chat notifier for managing chat state and interactions
class ChatNotifier extends StateNotifier<ChatState> {
  final AIService _aiService;
  final Ref _ref;
  
  ChatNotifier(this._aiService, this._ref) : super(const ChatState()) {
    _initializeChat();
  }
  
  void _initializeChat() {
    // Add welcome message
    state = state.copyWith(
      messages: [ChatMessage.welcome()],
      quickSuggestions: [
        '🔍 What\'s nearby?',
        '⏰ Best time to visit?',
        '🎯 What should I do?',
        '📊 Today\'s crowd trends',
      ],
    );
  }
  
  /// Send a message and get AI response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    // Add user message
    final userMessage = ChatMessage.user(content);
    final loadingMessage = ChatMessage.loading();
    
    state = state.copyWith(
      messages: [...state.messages, userMessage, loadingMessage],
      isLoading: true,
    );
    
    try {
      // Get context for AI
      final context = await _ref.read(aiContextProvider.future);
      
      // Get AI response
      final response = await _aiService.chat(
        content,
        userLocation: context.userPosition,
        nearbyVenues: context.nearbyVenues,
        additionalContext: context.toContextString(),
      );
      
      // Remove loading and add AI response
      final messagesWithoutLoading = state.messages
          .where((m) => !m.isLoading)
          .toList();
      
      final aiMessage = ChatMessage.ai(response);
      
      state = state.copyWith(
        messages: [...messagesWithoutLoading, aiMessage],
        isLoading: false,
      );
      
      // Update suggestions based on response
      _updateSuggestions(content, response);
    } catch (e) {
      // Remove loading and add error message
      final messagesWithoutLoading = state.messages
          .where((m) => !m.isLoading)
          .toList();
      
      final errorMessage = ChatMessage.ai(
        'Sorry, I had trouble processing that. Please try again!',
      );
      
      state = state.copyWith(
        messages: [...messagesWithoutLoading, errorMessage],
        isLoading: false,
      );
    }
  }
  
  void _updateSuggestions(String userMessage, String aiResponse) {
    // Contextual follow-up suggestions based on conversation
    final lowerMessage = userMessage.toLowerCase();
    List<String> newSuggestions;
    
    if (lowerMessage.contains('nearby') || lowerMessage.contains('crowd')) {
      newSuggestions = [
        '📍 Show on map',
        '⏰ Best time today?',
        '🔔 Notify when less busy',
      ];
    } else if (lowerMessage.contains('activity') || lowerMessage.contains('do')) {
      newSuggestions = [
        '📚 Learn something',
        '🎮 Play a game',
        '🧘 Breathing exercise',
      ];
    } else if (lowerMessage.contains('time') || lowerMessage.contains('when')) {
      newSuggestions = [
        '📊 Show hourly trends',
        '🔄 Check other venues',
        '📱 Set reminder',
      ];
    } else {
      newSuggestions = [
        '🔍 What else is nearby?',
        '💡 Any tips for saving time?',
        '🎯 What should I do now?',
      ];
    }
    
    state = state.copyWith(quickSuggestions: newSuggestions);
  }
  
  /// Clear chat and start fresh
  void clearChat() {
    _aiService.resetChat();
    _initializeChat();
  }
  
  /// Handle quick action tap
  void handleQuickAction(String action) {
    // Remove emoji prefix and send as message
    final cleanAction = action.replaceFirst(RegExp(r'^[^\w\s]+\s*'), '');
    sendMessage(cleanAction);
  }
}

/// Provider for chat state
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return ChatNotifier(aiService, ref);
});
