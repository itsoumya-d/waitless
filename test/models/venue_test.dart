import 'package:flutter_test/flutter_test.dart';
import 'package:waitless/models/venue.dart';

void main() {
  group('Venue', () {
    test('creates instance with required fields', () {
      final venue = Venue(
        id: 'venue-1',
        name: 'Test Venue',
        address: '123 Main St',
        latitude: 37.7749,
        longitude: -122.4194,
        category: 'restaurant',
      );

      expect(venue.id, 'venue-1');
      expect(venue.name, 'Test Venue');
      expect(venue.currentCrowdLevel, CrowdLevel.medium); // Default
      expect(venue.isFavorite, false); // Default
    });

    test('copyWith creates new instance with updated fields', () {
      final venue = Venue(
        id: 'venue-1',
        name: 'Test Venue',
        address: '123 Main St',
        latitude: 37.7749,
        longitude: -122.4194,
        category: 'restaurant',
      );

      final updated = venue.copyWith(
        currentCrowdLevel: CrowdLevel.high,
        isFavorite: true,
        reportCount: 10,
      );

      expect(updated.id, 'venue-1'); // Unchanged
      expect(updated.name, 'Test Venue'); // Unchanged
      expect(updated.currentCrowdLevel, CrowdLevel.high);
      expect(updated.isFavorite, true);
      expect(updated.reportCount, 10);
    });

    test('copyWith preserves unmodified fields', () {
      final venue = Venue(
        id: 'venue-1',
        name: 'Test Venue',
        address: '123 Main St',
        latitude: 37.7749,
        longitude: -122.4194,
        category: 'restaurant',
        imageUrl: 'https://example.com/image.jpg',
        averageWaitMinutes: 15.5,
      );

      final updated = venue.copyWith(name: 'New Name');

      expect(updated.imageUrl, 'https://example.com/image.jpg');
      expect(updated.averageWaitMinutes, 15.5);
      expect(updated.latitude, 37.7749);
    });
  });

  group('HourlyPrediction', () {
    test('creates instance with required fields', () {
      const prediction = HourlyPrediction(
        hour: 14,
        crowdScore: 0.75,
        confidence: 0.85,
      );

      expect(prediction.hour, 14);
      expect(prediction.crowdScore, 0.75);
      expect(prediction.confidence, 0.85);
    });
  });

  group('CrowdLevel', () {
    test('displayName returns correct values', () {
      expect(CrowdLevel.low.displayName, 'Low');
      expect(CrowdLevel.medium.displayName, 'Medium');
      expect(CrowdLevel.high.displayName, 'High');
      expect(CrowdLevel.veryHigh.displayName, 'Very High');
    });

    test('description returns correct messages', () {
      expect(CrowdLevel.low.description, 'Great time to visit!');
      expect(CrowdLevel.veryHigh.description, 'Very crowded');
    });

    test('color returns non-null colors', () {
      expect(CrowdLevel.low.color, isNotNull);
      expect(CrowdLevel.medium.color, isNotNull);
      expect(CrowdLevel.high.color, isNotNull);
      expect(CrowdLevel.veryHigh.color, isNotNull);
    });
  });

  group('VenueCategory', () {
    test('displayName returns correct values', () {
      expect(VenueCategory.grocery.displayName, 'Grocery');
      expect(VenueCategory.restaurant.displayName, 'Restaurant');
      expect(VenueCategory.coffeeshop.displayName, 'Coffee Shop');
    });

    test('icon returns correct emojis', () {
      expect(VenueCategory.grocery.icon, '🛒');
      expect(VenueCategory.restaurant.icon, '🍽️');
      expect(VenueCategory.gym.icon, '💪');
      expect(VenueCategory.coffeeshop.icon, '☕');
    });

    test('all categories have icons and display names', () {
      for (final category in VenueCategory.values) {
        expect(category.displayName, isNotEmpty);
        expect(category.icon, isNotEmpty);
      }
    });
  });
}
