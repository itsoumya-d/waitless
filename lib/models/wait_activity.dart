/// Wait activity content types
enum ActivityType {
  microLearning,  // Quick lessons, language, trivia
  entertainment,  // Videos, mini-games, podcasts
  productivity,   // Notes, habit tracking, reading
  mindfulness,    // Breathing, meditation, calm
}

/// Wait activity model
class WaitActivity {
  final String id;
  final String title;
  final String description;
  final ActivityType type;
  final int durationSeconds;
  final String? thumbnailUrl;
  final String? contentUrl;
  final List<String> tags;
  final bool isSponsored;
  final String? sponsorName;
  final String? sponsorLogoUrl;
  final int completionCount;
  final double rating;
  final bool requiresPremium;

  const WaitActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.durationSeconds,
    this.thumbnailUrl,
    this.contentUrl,
    this.tags = const [],
    this.isSponsored = false,
    this.sponsorName,
    this.sponsorLogoUrl,
    this.completionCount = 0,
    this.rating = 0.0,
    this.requiresPremium = false,
  });
}

/// Activity completion record
class ActivityCompletion {
  final String id;
  final String activityId;
  final String userId;
  final DateTime completedAt;
  final int pointsEarned;
  final bool watchedAd;

  const ActivityCompletion({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.completedAt,
    this.pointsEarned = 0,
    this.watchedAd = false,
  });
}

extension ActivityTypeExtension on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.microLearning: return 'Learn';
      case ActivityType.entertainment: return 'Play';
      case ActivityType.productivity: return 'Do';
      case ActivityType.mindfulness: return 'Breathe';
    }
  }
  
  String get icon {
    switch (this) {
      case ActivityType.microLearning: return '📚';
      case ActivityType.entertainment: return '🎮';
      case ActivityType.productivity: return '✅';
      case ActivityType.mindfulness: return '🧘';
    }
  }
  
  String get description {
    switch (this) {
      case ActivityType.microLearning: return 'Quick lessons & trivia';
      case ActivityType.entertainment: return 'Games & videos';
      case ActivityType.productivity: return 'Get things done';
      case ActivityType.mindfulness: return 'Relax & breathe';
    }
  }
}
