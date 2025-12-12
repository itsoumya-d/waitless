import 'package:flutter_test/flutter_test.dart';
import 'package:waitless/models/user_data.dart';

void main() {
  group('UserData', () {
    test('creates instance with required fields', () {
      final user = UserData(
        id: 'test-id',
        displayName: 'Test User',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user.id, 'test-id');
      expect(user.displayName, 'Test User');
      expect(user.email, isNull);
      expect(user.totalReports, 0);
      expect(user.badgeLevel, BadgeLevel.newcomer);
    });

    test('copyWith creates new instance with updated fields', () {
      final user = UserData(
        id: 'test-id',
        displayName: 'Test User',
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = user.copyWith(
        displayName: 'Updated Name',
        totalReports: 50,
      );

      expect(updated.id, 'test-id'); // Unchanged
      expect(updated.displayName, 'Updated Name');
      expect(updated.totalReports, 50);
    });

    test('toMap serializes correctly', () {
      final user = UserData(
        id: 'test-id',
        displayName: 'Test User',
        email: 'test@example.com',
        createdAt: DateTime(2024, 1, 1),
        totalReports: 25,
        totalMinutesSaved: 120,
      );

      final map = user.toMap();

      expect(map['id'], 'test-id');
      expect(map['displayName'], 'Test User');
      expect(map['email'], 'test@example.com');
      expect(map['totalReports'], 25);
      expect(map['totalMinutesSaved'], 120);
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'displayName': 'Test User',
        'email': 'test@example.com',
        'createdAt': '2024-01-01T00:00:00.000',
        'totalReports': 25,
        'totalMinutesSaved': 120,
        'badgeLevel': 1, // contributor
      };

      final user = UserData.fromMap(map, 'test-id');

      expect(user.id, 'test-id');
      expect(user.displayName, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.totalReports, 25);
      expect(user.badgeLevel, BadgeLevel.contributor);
    });

    test('fromMap handles missing fields gracefully', () {
      final map = <String, dynamic>{};

      final user = UserData.fromMap(map, 'test-id');

      expect(user.id, 'test-id');
      expect(user.displayName, '');
      expect(user.totalReports, 0);
      expect(user.badgeLevel, BadgeLevel.newcomer);
    });
  });

  group('UserStats', () {
    test('creates instance with default values', () {
      const stats = UserStats();

      expect(stats.todayMinutesSaved, 0);
      expect(stats.weekMinutesSaved, 0);
      expect(stats.rank, 0);
    });

    test('toMap serializes correctly', () {
      const stats = UserStats(
        todayMinutesSaved: 30,
        weekMinutesSaved: 150,
        todayReports: 5,
        rank: 42,
      );

      final map = stats.toMap();

      expect(map['todayMinutesSaved'], 30);
      expect(map['weekMinutesSaved'], 150);
      expect(map['todayReports'], 5);
      expect(map['rank'], 42);
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'todayMinutesSaved': 45,
        'weekMinutesSaved': 200,
        'monthMinutesSaved': 800,
        'rank': 10,
      };

      final stats = UserStats.fromMap(map);

      expect(stats.todayMinutesSaved, 45);
      expect(stats.weekMinutesSaved, 200);
      expect(stats.monthMinutesSaved, 800);
      expect(stats.rank, 10);
    });
  });

  group('BadgeLevel', () {
    test('displayName returns correct values', () {
      expect(BadgeLevel.newcomer.displayName, 'Newcomer');
      expect(BadgeLevel.contributor.displayName, 'Contributor');
      expect(BadgeLevel.legend.displayName, 'WaitLess Legend');
    });

    test('icon returns correct emojis', () {
      expect(BadgeLevel.newcomer.icon, '🌱');
      expect(BadgeLevel.guardian.icon, '🛡️');
      expect(BadgeLevel.legend.icon, '👑');
    });

    test('minReports returns correct thresholds', () {
      expect(BadgeLevel.newcomer.minReports, 0);
      expect(BadgeLevel.contributor.minReports, 11);
      expect(BadgeLevel.trusted.minReports, 51);
      expect(BadgeLevel.legend.minReports, 1001);
    });
  });
}
