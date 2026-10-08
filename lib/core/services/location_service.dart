import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Location service for handling GPS and permissions
class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
  
  /// Get current location permission status
  Future<LocationPermission> getPermissionStatus() async {
    return await Geolocator.checkPermission();
  }
  
  /// Get current position
  Future<Position?> getCurrentPosition({bool requestPermission = true}) async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }
      
      // Check permission
      var permission = await Geolocator.checkPermission();
      if (!requestPermission &&
          permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }
      
      // Get position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 100, // Update every 100 meters
        ),
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Get current city name from coordinates
  Future<String?> getCurrentCity() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;
      
      return getCityForPosition(position);
    } catch (e) {
      return null;
    }
  }

  /// Resolve a city from an already obtained position, without another GPS read.
  Future<String?> getCityForPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        return placemarks.first.locality;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Calculate distance between two points (in km)
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }
  
  /// Stream position updates
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    );
  }
  
  /// Check if user is at a specific venue (within threshold)
  bool isAtVenue({
    required Position userPosition,
    required double venueLatitude,
    required double venueLongitude,
    double thresholdMeters = 50,
  }) {
    final distance = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      venueLatitude,
      venueLongitude,
    );
    return distance <= thresholdMeters;
  }
  
  /// Get nearby venues sorted by distance
  List<T> sortByDistance<T>({
    required Position userPosition,
    required List<T> items,
    required double Function(T) getLatitude,
    required double Function(T) getLongitude,
  }) {
    return List<T>.from(items)
      ..sort((a, b) {
        final distA = calculateDistance(
          userPosition.latitude,
          userPosition.longitude,
          getLatitude(a),
          getLongitude(a),
        );
        final distB = calculateDistance(
          userPosition.latitude,
          userPosition.longitude,
          getLatitude(b),
          getLongitude(b),
        );
        return distA.compareTo(distB);
      });
  }
}

/// Provider for location service
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for current position (auto-updates)
final currentPositionProvider = StreamProvider<Position?>((ref) async* {
  final locationService = ref.watch(locationServiceProvider);
  
  // First yield current position
  final initial = await locationService.getCurrentPosition();
  yield initial;
  
  // Then stream updates
  await for (final position in locationService.getPositionStream()) {
    yield position;
  }
});

/// Shared one-shot location for venue discovery and the city label.
/// Reads only with existing permission; discovery never opens a permission
/// prompt. Explicit permission-request entry points are unchanged.
final currentLocationProvider = FutureProvider<Position?>((ref) async {
  try {
    return await ref.watch(locationServiceProvider).getCurrentPosition(
      requestPermission: false,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
  } catch (_) {
    return null;
  }
});

/// Provider for current city name
final currentCityProvider = FutureProvider<String?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  final position = await ref.watch(currentLocationProvider.future);
  if (position == null) return null;
  return locationService.getCityForPosition(position);
});

