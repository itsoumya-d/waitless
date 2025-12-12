import 'package:flutter_test/flutter_test.dart';
import 'package:waitless/models/wait_activity.dart';

void main() {
  group('WaitActivity', () {
    test('creates instance with required fields', () {
      const activity = WaitActivity(
        id: 'activity-1',
        title: 'Quick Meditation',
        description: 'A 5-minute breathing exercise',
        type: ActivityType.mindfulness,
        durationSeconds: 300,
      );

      expect(activity.id, 'activity-1');
      expect(activity.title, 'Quick Meditation');
      expect(activity.type, ActivityType.mindfulness);
      expect(activity.durationSeconds, 300);
      expect(activity.isSponsored, false); // Default
      expect(activity.requiresPremium, false); // Default
    });

    test('creates instance with all optional fields', () {
      const activity = WaitActivity(
        id: 'activity-2',
        title: 'Advanced Trivia',
        description: 'Test your knowledge',
        type: ActivityType.entertainment,
        durationSeconds: 600,
        thumbnailUrl: 'https://example.com/trivia.jpg',
        isSponsored: true,
        sponsorName: 'TestCo',
        tags: ['science', 'quiz'],
        rating: 4.5,
        requiresPremium: true,
      );

      expect(activity.isSponsored, true);
      expect(activity.sponsorName, 'TestCo');
      expect(activity.tags, ['science', 'quiz']);
      expect(activity.rating, 4.5);
      expect(activity.requiresPremium, true);
    });
  });

  group('ActivityType', () {
    test('displayName returns correct values', () {
      expect(ActivityType.microLearning.displayName, 'Learn');
      expect(ActivityType.entertainment.displayName, 'Play');
      expect(ActivityType.mindfulness.displayName, 'Breathe');
      expect(ActivityType.productivity.displayName, 'Do');
    });

    test('icon returns correct emojis', () {
      expect(ActivityType.microLearning.icon, '📚');
      expect(ActivityType.entertainment.icon, '🎮');
      expect(ActivityType.mindfulness.icon, '🧘');
      expect(ActivityType.productivity.icon, '✅');
    });

    test('all types have icons and display names', () {
      for (final type in ActivityType.values) {
        expect(type.displayName, isNotEmpty);
        expect(type.icon, isNotEmpty);
      }
    });
  });

  group('ActivityCompletion', () {
    test('creates instance with required fields', () {
      final completion = ActivityCompletion(
        id: 'completion-1',
        activityId: 'activity-1',
        userId: 'user-1',
        completedAt: DateTime(2024, 1, 15, 10, 30),
      );

      expect(completion.id, 'completion-1');
      expect(completion.activityId, 'activity-1');
      expect(completion.userId, 'user-1');
      expect(completion.pointsEarned, 0); // Default
      expect(completion.watchedAd, false); // Default
    });

    test('creates instance with optional fields', () {
      final completion = ActivityCompletion(
        id: 'completion-2',
        activityId: 'activity-2',
        userId: 'user-1',
        completedAt: DateTime(2024, 1, 15, 10, 30),
        pointsEarned: 50,
        watchedAd: true,
      );

      expect(completion.pointsEarned, 50);
      expect(completion.watchedAd, true);
    });
  });
}
