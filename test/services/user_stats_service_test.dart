import 'package:flutter_test/flutter_test.dart';
import 'package:waitless/core/services/user_stats_service.dart';
import 'package:waitless/models/user_data.dart';

void main() {
  group('UserStatsService', () {
    test('getMockStats returns valid UserStats', () {
      final stats = UserStatsService.getMockStats();

      expect(stats, isNotNull);
      expect(stats.todayMinutesSaved, isNonNegative);
      expect(stats.weekMinutesSaved, isNonNegative);
      expect(stats.monthMinutesSaved, isNonNegative);
    });

    test('getMockStats returns consistent structure', () {
      final stats = UserStatsService.getMockStats();

      // Week should be >= today
      expect(stats.weekMinutesSaved, greaterThanOrEqualTo(stats.todayMinutesSaved));
      // Month should be >= week
      expect(stats.monthMinutesSaved, greaterThanOrEqualTo(stats.weekMinutesSaved));
    });

    test('UserStats toMap contains all expected keys', () {
      final stats = UserStatsService.getMockStats();
      final map = stats.toMap();

      expect(map.containsKey('todayMinutesSaved'), true);
      expect(map.containsKey('weekMinutesSaved'), true);
      expect(map.containsKey('monthMinutesSaved'), true);
      expect(map.containsKey('todayReports'), true);
      expect(map.containsKey('weekReports'), true);
      expect(map.containsKey('monthReports'), true);
      expect(map.containsKey('rank'), true);
    });
  });

  group('UserStats roundtrip', () {
    test('toMap and fromMap are symmetric', () {
      const original = UserStats(
        todayMinutesSaved: 30,
        weekMinutesSaved: 150,
        monthMinutesSaved: 500,
        todayReports: 3,
        weekReports: 15,
        monthReports: 45,
        todayPoints: 100,
        weekPoints: 500,
        monthPoints: 1500,
        weekVenuesVisited: 7,
        rank: 42,
      );

      final map = original.toMap();
      final restored = UserStats.fromMap(map);

      expect(restored.todayMinutesSaved, original.todayMinutesSaved);
      expect(restored.weekMinutesSaved, original.weekMinutesSaved);
      expect(restored.monthMinutesSaved, original.monthMinutesSaved);
      expect(restored.todayReports, original.todayReports);
      expect(restored.rank, original.rank);
    });
  });
}
