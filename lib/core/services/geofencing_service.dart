import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'favorites_service.dart';
import '../../models/venue.dart';

/// Service to monitor user location and trigger alerts when near favorite venues
class GeofencingService {
  final Ref _ref;
  StreamSubscription<Position>? _positionSubscription;
  final Set<String> _recentlyNotifiedVenues = {};
  
  // ignore: constant_identifier_names
  static const double GEOFENCE_RADIUS_METERS = 200.0;
  // ignore: constant_identifier_names
  static const int NOTIFICATION_COOLDOWN_MINUTES = 60;

  GeofencingService(this._ref);

  /// Start monitoring location for geofencing
  Future<void> startMonitoring({required Function(Venue) onVenueEnter}) async {
    final hasPermission = await _checkPermissions();
    
    if (!hasPermission) {
      debugPrint('❌ Geofencing permission denied');
      return;
    }

    debugPrint('📍 Starting geofencing monitoring...');
    
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // Update every 50 meters
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _checkProximity(position, onVenueEnter);
    }, onError: (e) {
      debugPrint('❌ Geofencing error: $e');
    });
  }

  /// Stop monitoring
  void stopMonitoring() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    debugPrint('🛑 Stopped geofencing monitoring');
  }

  Future<bool> _checkPermissions() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;
    
    final result = await Permission.locationWhenInUse.request();
    return result.isGranted;
  }

  void _checkProximity(Position position, Function(Venue) onVenueEnter) {
    
    final favoritesAsync = _ref.read(favoriteVenuesProvider);
    final favorites = favoritesAsync.value;
    
    if (favorites == null || favorites.isEmpty) return;

    for (final venue in favorites) {
      // Skip if recently notified
      if (_recentlyNotifiedVenues.contains(venue.id)) continue;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        venue.latitude,
        venue.longitude,
      );

      if (distance <= GEOFENCE_RADIUS_METERS) {
        _triggerEntryAlert(venue, onVenueEnter);
      }
    }
  }

  void _triggerEntryAlert(Venue venue, Function(Venue) onVenueEnter) {
    debugPrint('🔔 Entering geofence for ${venue.name}');
    
    // Mark as notified
    _recentlyNotifiedVenues.add(venue.id);
    Future.delayed(const Duration(minutes: NOTIFICATION_COOLDOWN_MINUTES), () {
      _recentlyNotifiedVenues.remove(venue.id);
    });

    onVenueEnter(venue);
  }
}

final geofencingServiceProvider = Provider<GeofencingService>((ref) {
  return GeofencingService(ref);
});
