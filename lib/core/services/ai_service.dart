import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../models/venue.dart';

/// AI Service for Gemini-powered features
/// 
/// Provides intelligent chat, content generation, and contextual suggestions
class AIService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;
  
  /// System prompt that defines the AI's personality and context
  static const String _systemPrompt = '''
You are WaitLess AI, a helpful assistant integrated into the WaitLess app - a real-time crowd intelligence and time optimization platform.

Your capabilities:
- Help users find the best times to visit venues (restaurants, stores, gyms)
- Suggest nearby activities based on location and crowd levels
- Generate vocabulary words, trivia questions, and breathing exercises
- Provide personalized recommendations based on user context

Personality traits:
- Friendly and concise
- Focused on helping users save time
- Knowledgeable about crowd patterns and venue data
- Encouraging about time-saving achievements

Always format responses to be mobile-friendly (short paragraphs, bullet points when helpful).
When suggesting venues, include crowd level context when available.
''';

  /// Initialize the AI service with API key
  Future<void> initialize(String apiKey) async {
    if (apiKey.isEmpty) {
      debugPrint('⚠️ AI Service: No API key provided');
      return;
    }
    
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1024,
        ),
        systemInstruction: Content.text(_systemPrompt),
      );
      
      _chatSession = _model!.startChat();
      _isInitialized = true;
      debugPrint('✅ AI Service initialized successfully');
    } catch (e) {
      debugPrint('❌ AI Service initialization failed: $e');
      _isInitialized = false;
    }
  }
  
  /// Check if the service is ready
  bool get isInitialized => _isInitialized;
  
  /// Send a chat message and get a response
  Future<String> chat(String message, {
    Position? userLocation,
    List<Venue>? nearbyVenues,
    String? additionalContext,
  }) async {
    if (!_isInitialized || _chatSession == null) {
      return _getFallbackResponse(message);
    }
    
    try {
      // Build context-aware prompt
      final contextualMessage = _buildContextualMessage(
        message,
        userLocation: userLocation,
        nearbyVenues: nearbyVenues,
        additionalContext: additionalContext,
      );
      
      final response = await _chatSession!.sendMessage(
        Content.text(contextualMessage),
      );
      
      return response.text ?? 'I couldn\'t generate a response. Please try again.';
    } catch (e) {
      debugPrint('AI chat error: $e');
      return _getFallbackResponse(message);
    }
  }
  
  /// Generate vocabulary words for learning
  Future<List<VocabularyWord>> generateVocabularyWords({
    String language = 'Spanish',
    String difficulty = 'beginner',
    int count = 5,
  }) async {
    if (!_isInitialized || _model == null) {
      return _getDefaultVocabularyWords();
    }
    
    try {
      final prompt = '''
Generate $count $difficulty-level $language vocabulary words.
Format each word as: word|pronunciation|meaning|example sentence
One word per line, no numbering or bullets.
''';
      
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      return text.split('\n')
          .where((line) => line.contains('|'))
          .map((line) {
            final parts = line.split('|');
            return VocabularyWord(
              word: parts.isNotEmpty ? parts[0].trim() : '',
              pronunciation: parts.length > 1 ? parts[1].trim() : '',
              meaning: parts.length > 2 ? parts[2].trim() : '',
              exampleSentence: parts.length > 3 ? parts[3].trim() : '',
            );
          })
          .where((w) => w.word.isNotEmpty)
          .take(count)
          .toList();
    } catch (e) {
      debugPrint('Vocabulary generation error: $e');
      return _getDefaultVocabularyWords();
    }
  }
  
  /// Generate a trivia question
  Future<TriviaQuestion> generateTriviaQuestion({
    String category = 'general knowledge',
  }) async {
    if (!_isInitialized || _model == null) {
      return _getDefaultTriviaQuestion();
    }
    
    try {
      final prompt = '''
Generate a $category trivia question.
Format:
Question: [the question]
A) [option 1]
B) [option 2]
C) [option 3]
D) [option 4]
Answer: [correct letter]
Explanation: [brief explanation]
''';
      
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      return _parseTriviaQuestion(text);
    } catch (e) {
      debugPrint('Trivia generation error: $e');
      return _getDefaultTriviaQuestion();
    }
  }
  
  /// Generate a personalized breathing exercise
  Future<BreathingExercise> generateBreathingExercise({
    String mood = 'stressed',
    int availableMinutes = 3,
  }) async {
    if (!_isInitialized || _model == null) {
      return _getDefaultBreathingExercise();
    }
    
    try {
      final prompt = '''
Create a breathing exercise for someone feeling $mood with $availableMinutes minutes available.
Format:
Name: [exercise name]
Pattern: [inhale seconds]-[hold seconds]-[exhale seconds]-[hold seconds]
Cycles: [number of cycles]
Description: [one sentence description]
''';
      
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      return _parseBreathingExercise(text);
    } catch (e) {
      debugPrint('Breathing exercise generation error: $e');
      return _getDefaultBreathingExercise();
    }
  }
  
  /// Generate game challenge parameters
  Future<GameChallenge> generateGameChallenge({
    required String gameType,
    int currentLevel = 1,
  }) async {
    // For games, we use predefined patterns with slight AI variations
    // This keeps gameplay consistent while adding variety
    return GameChallenge(
      difficulty: (currentLevel * 0.1).clamp(0.5, 2.0),
      timeLimit: Duration(seconds: 30 - (currentLevel * 2).clamp(0, 15)),
      targetScore: 10 + (currentLevel * 5),
      hint: 'Focus and react quickly!',
    );
  }
  
  /// Reset chat session for new conversation
  void resetChat() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }
  
  // Private helper methods
  
  String _buildContextualMessage(
    String message, {
    Position? userLocation,
    List<Venue>? nearbyVenues,
    String? additionalContext,
  }) {
    final buffer = StringBuffer();
    
    if (userLocation != null) {
      buffer.writeln('[User Location: ${userLocation.latitude.toStringAsFixed(4)}, ${userLocation.longitude.toStringAsFixed(4)}]');
    }
    
    if (nearbyVenues != null && nearbyVenues.isNotEmpty) {
      buffer.writeln('[Nearby venues:');
      for (final venue in nearbyVenues.take(5)) {
        buffer.writeln('- ${venue.name}: ${venue.currentCrowdLevel.name} crowd');
      }
      buffer.writeln(']');
    }
    
    if (additionalContext != null) {
      buffer.writeln('[$additionalContext]');
    }
    
    buffer.writeln('\nUser: $message');
    
    return buffer.toString();
  }
  
  String _getFallbackResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('crowd') || lowerMessage.contains('busy')) {
      return 'I can help you find less crowded times! Check the venue cards on the home screen - green means low crowd, yellow is moderate, and red is busy. Tap any venue for hourly predictions.';
    }
    
    if (lowerMessage.contains('activity') || lowerMessage.contains('do')) {
      return 'While you wait, try our activities! 📚 Learn something new, 🎮 Play quick games, 🧘 Practice breathing exercises, or ✅ Be productive. Each activity earns you points!';
    }
    
    if (lowerMessage.contains('point') || lowerMessage.contains('badge')) {
      return 'You earn points by reporting crowd levels, completing activities, and maintaining daily streaks. Check your Wallet tab to see your progress and unlock badges!';
    }
    
    return 'I\'m here to help you save time! Ask me about crowd levels, nearby venues, activities to do while waiting, or how to earn more points.';
  }
  
  List<VocabularyWord> _getDefaultVocabularyWords() {
    return [
      VocabularyWord(
        word: 'Hola',
        pronunciation: 'OH-lah',
        meaning: 'Hello',
        exampleSentence: '¡Hola, amigo! - Hello, friend!',
      ),
      VocabularyWord(
        word: 'Gracias',
        pronunciation: 'GRAH-see-as',
        meaning: 'Thank you',
        exampleSentence: 'Muchas gracias - Thank you very much',
      ),
      VocabularyWord(
        word: 'Por favor',
        pronunciation: 'por fah-VOR',
        meaning: 'Please',
        exampleSentence: 'Un café, por favor - A coffee, please',
      ),
      VocabularyWord(
        word: 'Buenos días',
        pronunciation: 'BWEH-nos DEE-as',
        meaning: 'Good morning',
        exampleSentence: 'Buenos días, ¿cómo estás?',
      ),
      VocabularyWord(
        word: 'Adiós',
        pronunciation: 'ah-DYOS',
        meaning: 'Goodbye',
        exampleSentence: '¡Adiós, hasta luego!',
      ),
    ];
  }
  
  TriviaQuestion _getDefaultTriviaQuestion() {
    return TriviaQuestion(
      question: 'What is the capital of France?',
      options: ['London', 'Berlin', 'Paris', 'Madrid'],
      correctIndex: 2,
      explanation: 'Paris has been the capital of France since the 10th century.',
    );
  }
  
  BreathingExercise _getDefaultBreathingExercise() {
    return BreathingExercise(
      name: 'Box Breathing',
      inhaleSeconds: 4,
      holdAfterInhale: 4,
      exhaleSeconds: 4,
      holdAfterExhale: 4,
      cycles: 4,
      description: 'A calming technique used by Navy SEALs to reduce stress.',
    );
  }
  
  TriviaQuestion _parseTriviaQuestion(String text) {
    try {
      final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
      
      String question = '';
      List<String> options = [];
      int correctIndex = 0;
      String explanation = '';
      
      for (final line in lines) {
        if (line.startsWith('Question:')) {
          question = line.substring(9).trim();
        } else if (line.startsWith('A)')) {
          options.add(line.substring(2).trim());
        } else if (line.startsWith('B)')) {
          options.add(line.substring(2).trim());
        } else if (line.startsWith('C)')) {
          options.add(line.substring(2).trim());
        } else if (line.startsWith('D)')) {
          options.add(line.substring(2).trim());
        } else if (line.startsWith('Answer:')) {
          final answer = line.substring(7).trim().toUpperCase();
          correctIndex = ['A', 'B', 'C', 'D'].indexOf(answer);
          if (correctIndex < 0) correctIndex = 0;
        } else if (line.startsWith('Explanation:')) {
          explanation = line.substring(12).trim();
        }
      }
      
      if (question.isNotEmpty && options.length >= 4) {
        return TriviaQuestion(
          question: question,
          options: options.take(4).toList(),
          correctIndex: correctIndex,
          explanation: explanation,
        );
      }
    } catch (e) {
      debugPrint('Error parsing trivia: $e');
    }
    
    return _getDefaultTriviaQuestion();
  }
  
  BreathingExercise _parseBreathingExercise(String text) {
    try {
      final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
      
      String name = 'Relaxation Breathing';
      int inhale = 4, holdIn = 4, exhale = 4, holdOut = 4, cycles = 4;
      String description = 'A gentle breathing exercise for relaxation.';
      
      for (final line in lines) {
        if (line.startsWith('Name:')) {
          name = line.substring(5).trim();
        } else if (line.startsWith('Pattern:')) {
          final pattern = line.substring(8).trim();
          final parts = pattern.split('-').map((p) => int.tryParse(p.trim()) ?? 4).toList();
          if (parts.length >= 4) {
            inhale = parts[0];
            holdIn = parts[1];
            exhale = parts[2];
            holdOut = parts[3];
          }
        } else if (line.startsWith('Cycles:')) {
          cycles = int.tryParse(line.substring(7).trim()) ?? 4;
        } else if (line.startsWith('Description:')) {
          description = line.substring(12).trim();
        }
      }
      
      return BreathingExercise(
        name: name,
        inhaleSeconds: inhale,
        holdAfterInhale: holdIn,
        exhaleSeconds: exhale,
        holdAfterExhale: holdOut,
        cycles: cycles,
        description: description,
      );
    } catch (e) {
      debugPrint('Error parsing breathing exercise: $e');
    }
    
    return _getDefaultBreathingExercise();
  }
}

/// Vocabulary word data class
class VocabularyWord {
  final String word;
  final String pronunciation;
  final String meaning;
  final String exampleSentence;
  
  const VocabularyWord({
    required this.word,
    required this.pronunciation,
    required this.meaning,
    required this.exampleSentence,
  });
}

/// Trivia question data class
class TriviaQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  
  const TriviaQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
  
  String get correctAnswer => options[correctIndex];
}

/// Breathing exercise data class
class BreathingExercise {
  final String name;
  final int inhaleSeconds;
  final int holdAfterInhale;
  final int exhaleSeconds;
  final int holdAfterExhale;
  final int cycles;
  final String description;
  
  const BreathingExercise({
    required this.name,
    required this.inhaleSeconds,
    required this.holdAfterInhale,
    required this.exhaleSeconds,
    required this.holdAfterExhale,
    required this.cycles,
    required this.description,
  });
  
  int get totalDurationSeconds => 
      (inhaleSeconds + holdAfterInhale + exhaleSeconds + holdAfterExhale) * cycles;
}

/// Game challenge data class
class GameChallenge {
  final double difficulty;
  final Duration timeLimit;
  final int targetScore;
  final String hint;
  
  const GameChallenge({
    required this.difficulty,
    required this.timeLimit,
    required this.targetScore,
    required this.hint,
  });
}

// Providers

/// Provider for AI service singleton
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

/// Provider for initializing AI with API key
final aiInitializationProvider = FutureProvider<bool>((ref) async {
  final aiService = ref.watch(aiServiceProvider);
  
  // API key should be provided via environment or secure storage
  // For now, we'll check for a development key
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  
  if (apiKey.isNotEmpty) {
    await aiService.initialize(apiKey);
    return aiService.isInitialized;
  }
  
  debugPrint('⚠️ GEMINI_API_KEY not set. AI features will use fallback responses.');
  return false;
});
