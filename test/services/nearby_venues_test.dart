import 'package:flutter_test/flutter_test.dart';
import 'package:waitless/core/services/nearby_venues.dart';
import 'package:waitless/models/venue.dart';

Venue venue(String id, double latitude, double longitude) => Venue(
  id: id,
  name: id,
  address: 'Synthetic fixture',
  latitude: latitude,
  longitude: longitude,
  category: 'other',
  distanceKm: 999,
);

void main() {
  test('filters inside/outside radius and sorts nearest first', () {
    final results = selectNearbyVenues(
      [venue('far', 0, 0.04), venue('outside', 0, 0.1), venue('near', 0, 0.01)],
      latitude: 0,
      longitude: 0,
    );
    expect(results.map((v) => v.id), ['near', 'far']);
    expect(results.first.distanceKm, closeTo(1.1119492664, 0.000001));
  });

  test('includes exact boundary and excludes just outside it', () {
    final fixture = venue('boundary', 0, 1);
    final distance = selectNearbyVenues(
      [fixture],
      latitude: 0,
      longitude: 0,
      radiusKm: 200,
    ).single.distanceKm;
    expect(distance, closeTo(111.1949266, 0.000001));
    expect(
      selectNearbyVenues(
        [fixture],
        latitude: 0,
        longitude: 0,
        radiusKm: distance,
      ).single.id,
      'boundary',
    );
    expect(
      selectNearbyVenues(
        [fixture],
        latitude: 0,
        longitude: 0,
        radiusKm: distance - 0.000001,
      ),
      isEmpty,
    );
  });

  test('zero radius keeps only colocated venues, including (0, 0)', () {
    expect(
      selectNearbyVenues(
        [venue('zero', 0, 0), venue('away', 0, 0.001)],
        latitude: 0,
        longitude: 0,
        radiusKm: 0,
      ).map((v) => v.id),
      ['zero'],
    );
  });

  test(
    'zero radius recognizes equivalent antimeridian and pole coordinates',
    () {
      for (final fixture in <(double, double, double, double)>[
        (0, 180, 0, -180),
        (90, 0, 90, 90),
        (-90, 180, -90, -90),
      ]) {
        expect(
          selectNearbyVenues(
            [venue('same', fixture.$3, fixture.$4)],
            latitude: fixture.$1,
            longitude: fixture.$2,
            radiusKm: 0,
          ).single.distanceKm,
          0,
        );
      }
    },
  );

  test('equal distance sorting preserves source order without mutation', () {
    final source = [venue('z', 0, 0.01), venue('a', 0, 0.01)];
    final results = selectNearbyVenues(source, latitude: 0, longitude: 0);
    expect(results.map((v) => v.id), ['z', 'a']);
    expect(source.every((v) => v.distanceKm == 999), isTrue);
    expect(identical(results.first, source.first), isFalse);
    results.clear();
    expect(source, hasLength(2));
  });

  test(
    'missing or invalid origin preserves catalog and existing distances',
    () {
      final source = [venue('far', 30, 50), venue('near', 0, 0)];
      for (final origin in <(double?, double?)>[
        (null, null),
        (null, 0),
        (0, null),
        (double.nan, 0),
        (0, double.infinity),
        (91, 0),
        (0, -181),
      ]) {
        final result = selectNearbyVenues(
          source,
          latitude: origin.$1,
          longitude: origin.$2,
        );
        expect(result, orderedEquals(source));
        expect(identical(result, source), isFalse);
        expect(result.first.distanceKm, 999);
      }
    },
  );

  test('invalid radii return no results even without an origin', () {
    for (final radius in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        selectNearbyVenues(
          [venue('zero', 0, 0)],
          latitude: 0,
          longitude: 0,
          radiusKm: radius,
        ),
        isEmpty,
      );
      expect(
        selectNearbyVenues([venue('zero', 0, 0)], radiusKm: radius),
        isEmpty,
      );
    }
  });

  test('invalid venue coordinates are skipped for a known origin', () {
    final result = selectNearbyVenues(
      [
        venue('nan', double.nan, 0),
        venue('infinity', 0, double.infinity),
        venue('latitude', -91, 0),
        venue('longitude', 0, 181),
        venue('valid', 0, 0),
      ],
      latitude: 0,
      longitude: 0,
      radiusKm: 21000,
    );
    expect(result.map((v) => v.id), ['valid']);
  });

  test('distance crosses the antimeridian using the shorter arc', () {
    final result = selectNearbyVenues(
      [venue('across', 0, -179.99)],
      latitude: 0,
      longitude: 179.99,
      radiusKm: 3,
    );
    expect(result.single.distanceKm, closeTo(2.2238985, 0.000001));
  });

  test('antipodal and polar coordinates remain finite', () {
    final antipode = selectNearbyVenues(
      [venue('antipode', 0, 180)],
      latitude: 0,
      longitude: 0,
      radiusKm: 21000,
    ).single;
    expect(antipode.distanceKm, closeTo(20015.0868, 0.001));
    final polar = selectNearbyVenues(
      [venue('polar', 89.99, -179.99)],
      latitude: 89.99,
      longitude: 179.99,
    ).single;
    expect(polar.distanceKm.isFinite, isTrue);
    expect(polar.distanceKm, lessThan(0.001));
  });

  test('empty input stays empty', () {
    expect(selectNearbyVenues([], latitude: 0, longitude: 0), isEmpty);
    expect(selectNearbyVenues([]), isEmpty);
  });
}
