import 'package:flutter_test/flutter_test.dart';
import 'package:waitless/core/services/venue_repository.dart';

void main() {
  group('mock repository', () {
    test('respects the supplied origin and radius', () async {
      final repository = VenueRepository();
      final catalog = await repository.getNearbyVenues();
      final origin = catalog.first;
      final venues = await repository.getNearbyVenues(
        latitude: origin.latitude,
        longitude: origin.longitude,
        radiusKm: 0,
      );
      expect(venues.map((v) => v.id), [origin.id]);
      expect(venues.single.distanceKm, 0);
    });

    test('returns a catalog copy without modifying future requests', () async {
      final repository = VenueRepository();
      final catalog = await repository.getNearbyVenues();
      final count = catalog.length;
      catalog.clear();
      expect(await repository.getNearbyVenues(), hasLength(count));
    });
  });
}
