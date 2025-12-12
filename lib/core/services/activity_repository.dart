import '../../models/wait_activity.dart';

/// Repository for wait activities content
class ActivityRepository {
  
  static final List<WaitActivity> _mockActivities = [
    // Micro Learning
    const WaitActivity(
      id: 'learn-1',
      title: 'Learn 5 Spanish Words',
      description: 'Quick vocabulary lesson for beginners',
      type: ActivityType.microLearning,
      durationSeconds: 180,
      tags: ['language', 'spanish', 'vocabulary'],
    ),
    const WaitActivity(
      id: 'learn-2',
      title: 'World Capitals Quiz',
      description: 'Test your geography knowledge',
      type: ActivityType.microLearning,
      durationSeconds: 120,
      tags: ['geography', 'trivia', 'quiz'],
    ),
    const WaitActivity(
      id: 'learn-3',
      title: 'Daily Word: Ephemeral',
      description: 'Expand your vocabulary with a new word',
      type: ActivityType.microLearning,
      durationSeconds: 60,
      tags: ['vocabulary', 'english', 'word'],
    ),
    
    // Entertainment
    const WaitActivity(
      id: 'play-1',
      title: 'Quick Trivia Challenge',
      description: 'Answer 5 random trivia questions',
      type: ActivityType.entertainment,
      durationSeconds: 120,
      isSponsored: true,
      sponsorName: 'BrainGames',
      tags: ['trivia', 'quiz', 'fun'],
    ),
    const WaitActivity(
      id: 'play-2',
      title: 'Pattern Match',
      description: 'Find matching patterns in this visual game',
      type: ActivityType.entertainment,
      durationSeconds: 180,
      tags: ['game', 'visual', 'puzzle'],
    ),
    const WaitActivity(
      id: 'play-3',
      title: 'Word Scramble',
      description: 'Unscramble the letters to form words',
      type: ActivityType.entertainment,
      durationSeconds: 150,
      tags: ['word', 'puzzle', 'game'],
    ),
    
    // Productivity
    const WaitActivity(
      id: 'do-1',
      title: 'Quick Gratitude Journal',
      description: 'Write 3 things you\'re grateful for',
      type: ActivityType.productivity,
      durationSeconds: 120,
      tags: ['journal', 'gratitude', 'mental health'],
    ),
    const WaitActivity(
      id: 'do-2',
      title: 'Weekly Goal Check-In',
      description: 'Review your progress on weekly goals',
      type: ActivityType.productivity,
      durationSeconds: 180,
      tags: ['goals', 'planning', 'productivity'],
    ),
    const WaitActivity(
      id: 'do-3',
      title: 'Quick To-Do Review',
      description: 'Organize your tasks for the day',
      type: ActivityType.productivity,
      durationSeconds: 90,
      tags: ['tasks', 'organize', 'planning'],
    ),
    
    // Mindfulness
    const WaitActivity(
      id: 'breathe-1',
      title: 'Box Breathing Exercise',
      description: '4-4-4-4 breathing pattern for calm',
      type: ActivityType.mindfulness,
      durationSeconds: 240,
      tags: ['breathing', 'calm', 'stress relief'],
    ),
    const WaitActivity(
      id: 'breathe-2',
      title: '1-Minute Body Scan',
      description: 'Quick relaxation for tense muscles',
      type: ActivityType.mindfulness,
      durationSeconds: 60,
      tags: ['relaxation', 'body', 'stress relief'],
    ),
    const WaitActivity(
      id: 'breathe-3',
      title: 'Mindful Moment',
      description: 'Focus on the present moment',
      type: ActivityType.mindfulness,
      durationSeconds: 120,
      tags: ['mindfulness', 'meditation', 'present'],
    ),
  ];
  
  /// Get all activities
  Future<List<WaitActivity>> getAllActivities() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockActivities;
  }
  
  /// Get activities by type
  Future<List<WaitActivity>> getActivitiesByType(ActivityType type) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockActivities.where((a) => a.type == type).toList();
  }
  
  /// Get activities matching wait duration
  Future<List<WaitActivity>> getActivitiesForDuration(int waitSeconds) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Return activities that fit within the wait time (with some buffer)
    return _mockActivities.where((a) {
      return a.durationSeconds <= waitSeconds + 30;
    }).toList()
      ..sort((a, b) {
        // Prioritize activities closest to but not exceeding wait time
        final aDiff = (waitSeconds - a.durationSeconds).abs();
        final bDiff = (waitSeconds - b.durationSeconds).abs();
        return aDiff.compareTo(bDiff);
      });
  }
  
  /// Get personalized activities based on interests
  Future<List<WaitActivity>> getPersonalizedActivities(List<String> interests) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (interests.isEmpty) {
      return _mockActivities.take(6).toList();
    }
    
    // Score activities based on matching tags
    final scored = _mockActivities.map((activity) {
      int score = 0;
      for (final interest in interests) {
        if (activity.tags.contains(interest.toLowerCase())) {
          score += 2;
        }
        // Partial match on activity type
        if (activity.type.name.toLowerCase().contains(interest.toLowerCase())) {
          score += 1;
        }
      }
      return {'activity': activity, 'score': score};
    }).toList()
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    
    return scored
        .take(8)
        .map((s) => s['activity'] as WaitActivity)
        .toList();
  }
  
  /// Get featured activities (including sponsored)
  Future<List<WaitActivity>> getFeaturedActivities() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Put sponsored first, then shuffle others
    final sponsored = _mockActivities.where((a) => a.isSponsored).toList();
    final regular = _mockActivities.where((a) => !a.isSponsored).toList()..shuffle();
    
    return [...sponsored, ...regular.take(5)];
  }
  
  /// Record activity completion
  Future<int> recordCompletion({
    required String activityId,
    required String userId,
    bool watchedAd = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Calculate points
    int points = 5; // Base points
    if (watchedAd) points += 10; // Bonus for ad
    
    // TODO: Save to Firestore
    return points;
  }
}
