import 'dart:math' as math;

import '../../models/venue.dart';

/// Whether both coordinates describe a finite point on Earth.
bool hasValidCoordinates(double? latitude, double? longitude) =>
    latitude != null &&
    longitude != null &&
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;

/// Select venues within an inclusive great-circle radius in kilometres.
///
/// Results are nearest first, preserving source order for equal distances. The
/// source list and venues are never mutated. Without a valid origin, return a
/// catalog copy in source order without inventing distances. Invalid radii
/// (negative or non-finite) produce no results; zero includes colocated venues.
List<Venue> selectNearbyVenues(
  Iterable<Venue> venues, {
  double? latitude,
  double? longitude,
  double radiusKm = 5.0,
}) {
  if (!radiusKm.isFinite || radiusKm < 0) return [];
  if (!hasValidCoordinates(latitude, longitude)) return List.of(venues);

  final nearby = <({Venue venue, int index})>[];
  var index = 0;
  for (final venue in venues) {
    final sourceIndex = index++;
    if (!hasValidCoordinates(venue.latitude, venue.longitude)) continue;
    final distance = _distanceKm(
      latitude!,
      longitude!,
      venue.latitude,
      venue.longitude,
    );
    if (distance <= radiusKm) {
      nearby.add((
        venue: venue.copyWith(distanceKm: distance),
        index: sourceIndex,
      ));
    }
  }
  nearby.sort((a, b) {
    final comparison = a.venue.distanceKm.compareTo(b.venue.distanceKm);
    return comparison != 0 ? comparison : a.index.compareTo(b.index);
  });
  return nearby.map((entry) => entry.venue).toList();
}

double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
  // Longitude wraps at the antimeridian and is immaterial at either pole.
  if (lat1 == lat2 &&
      (lng1 == lng2 || (lng1 - lng2).abs() == 360 || lat1.abs() == 90)) {
    return 0;
  }
  const radiansPerDegree = math.pi / 180;
  final latitudeDelta = (lat2 - lat1) * radiansPerDegree;
  final longitudeDelta = (lng2 - lng1) * radiansPerDegree;
  final latitudeTerm = math.sin(latitudeDelta / 2);
  final longitudeTerm = math.sin(longitudeDelta / 2);
  final haversine =
      (latitudeTerm * latitudeTerm +
              math.cos(lat1 * radiansPerDegree) *
                  math.cos(lat2 * radiansPerDegree) *
                  longitudeTerm *
                  longitudeTerm)
          .clamp(0.0, 1.0);
  // Mean Earth radius. Clamping avoids rounding errors near antipodal points.
  return 6371.0 *
      2 *
      math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
}
