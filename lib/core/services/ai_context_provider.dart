import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/venue.dart';
import 'location_service.dart';
import 'venue_data_provider.dart';
import 'places_service.dart';

/// Aggregated context for AI prompts
class AIContext {
  final Position? userPosition;
  final String? cityName;
  final String? formattedAddress;
  final List<Venue> nearbyVenues;
  final Map<PlaceCategory, List<Place>> nearbyPlaces;
  final DateTime timestamp;
  final String timeOfDay;
  final String dayOfWeek;
  final int userPoints;
  final int userStreak;
  
  const AIContext({
    this.userPosition,
    this.cityName,
    this.formattedAddress,
    this.nearbyVenues = const [],
    this.nearbyPlaces = const {},
    required this.timestamp,
    required this.timeOfDay,
    required this.dayOfWeek,
    this.userPoints = 0,
    this.userStreak = 0,
  });
  
  /// Convert to context string for AI prompts
  String toContextString() {
    final buffer = StringBuffer();
    
    // Time context
    buffer.writeln('Current time: ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} ($timeOfDay, $dayOfWeek)');
    
    // Location context
    if (formattedAddress != null) {
      buffer.writeln('User location: $formattedAddress');
    } else if (cityName != null) {
      buffer.writeln('User city: $cityName');
    }
    
    // Crowd-monitored venues
    if (nearbyVenues.isNotEmpty) {
      buffer.writeln('\nCrowd-monitored venues:');
      for (final venue in nearbyVenues.take(5)) {
        buffer.writeln('  - ${venue.name} (${venue.category}): ${venue.currentCrowdLevel.name} crowd');
      }
    }
    
    // Nearby places from Google Places API
    if (nearbyPlaces.isNotEmpty) {
      buffer.writeln('\nNearby places:');
      for (final entry in nearbyPlaces.entries) {
        if (entry.value.isNotEmpty) {
          buffer.writeln('  ${entry.key.emoji} ${entry.key.displayName}:');
          for (final place in entry.value.take(3)) {
            final rating = place.rating != null ? '⭐${place.rating}' : '';
            final dist = place.distanceFormatted;
            final status = place.isOpen == true ? '(Open)' : place.isOpen == false ? '(Closed)' : '';
            buffer.writeln('    - ${place.name} $rating $dist $status');
          }
        }
      }
    }
    
    // User context
    if (userPoints > 0) {
      buffer.writeln('\nUser stats: $userPoints points, $userStreak day streak');
    }
    
    return buffer.toString();
  }
  
  /// Get brief location summary
  String get locationSummary {
    if (formattedAddress != null) return formattedAddress!;
    if (cityName != null) return cityName!;
    return 'Unknown location';
  }
  
  /// Get total nearby places count
  int get totalPlacesCount => nearbyPlaces.values.fold(0, (sum, list) => sum + list.length);
  
  /// Get time-of-day string
  static String getTimeOfDay(int hour) {
    if (hour < 6) return 'late night';
    if (hour < 9) return 'early morning';
    if (hour < 12) return 'morning';
    if (hour < 14) return 'lunchtime';
    if (hour < 17) return 'afternoon';
    if (hour < 20) return 'evening';
    if (hour < 22) return 'night';
    return 'late night';
  }
  
  /// Get day of week string
  static String getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
  
  /// Create empty context
  factory AIContext.empty() {
    final now = DateTime.now();
    return AIContext(
      timestamp: now,
      timeOfDay: getTimeOfDay(now.hour),
      dayOfWeek: getDayOfWeek(now.weekday),
    );
  }
}

/// Provider for aggregated AI context
final aiContextProvider = FutureProvider<AIContext>((ref) async {
  final now = DateTime.now();
  
  // Get location
  Position? position;
  String? cityName;
  try {
    final locationService = ref.watch(locationServiceProvider);
    position = await locationService.getCurrentPosition();
    cityName = await locationService.getCurrentCity();
  } catch (e) {
    // Location not available
  }
  
  // Get nearby venues
  List<Venue> nearbyVenues = [];
  try {
    final venuesAsync = ref.watch(fetchNearbyVenuesProvider);
    venuesAsync.whenData((venues) {
      nearbyVenues = venues;
      
      // Sort by distance if we have position
      if (position != null) {
        final pos = position; // Local non-null copy
        nearbyVenues = List.from(venues)..sort((a, b) {
          final distA = Geolocator.distanceBetween(
            pos.latitude, pos.longitude,
            a.latitude, a.longitude,
          );
          final distB = Geolocator.distanceBetween(
            pos.latitude, pos.longitude,
            b.latitude, b.longitude,
          );
          return distA.compareTo(distB);
        });
      }
    });
  } catch (e) {
    // Venues not available
  }
  
  return AIContext(
    userPosition: position,
    cityName: cityName,
    nearbyVenues: nearbyVenues.take(10).toList(),
    timestamp: now,
    timeOfDay: AIContext.getTimeOfDay(now.hour),
    dayOfWeek: AIContext.getDayOfWeek(now.weekday),
  );
});

/// Provider for quick location-based suggestions
final locationSuggestionsProvider = FutureProvider<List<String>>((ref) async {
  final context = await ref.watch(aiContextProvider.future);
  
  final suggestions = <String>[];
  
  // Add time-based suggestions
  switch (context.timeOfDay) {
    case 'early morning':
    case 'morning':
      suggestions.add('☕ Find a quiet coffee shop');
      suggestions.add('🏋️ Best time for gym?');
      break;
    case 'lunchtime':
      suggestions.add('🍽️ Lunch spot with no wait');
      suggestions.add('🛒 When to shop?');
      break;
    case 'afternoon':
      suggestions.add('☕ Coffee break nearby');
      suggestions.add('🛒 Best time to shop');
      break;
    case 'evening':
      suggestions.add('🍕 Dinner recommendations');
      suggestions.add('🎬 Entertainment nearby');
      break;
    case 'night':
    case 'late night':
      suggestions.add('🌙 Late night spots');
      suggestions.add('🏠 Plan for tomorrow');
      break;
    default:
      suggestions.add('🔍 What\'s nearby?');
  }
  
  // Add venue-based suggestions if available
  if (context.nearbyVenues.isNotEmpty) {
    final lowCrowdVenue = context.nearbyVenues
        .where((v) => v.currentCrowdLevel == CrowdLevel.low)
        .take(1)
        .toList();
    
    if (lowCrowdVenue.isNotEmpty) {
      suggestions.add('🟢 ${lowCrowdVenue.first.name} is not busy!');
    }
  }
  
  // Add places-based suggestions
  if (context.nearbyPlaces.isNotEmpty) {
    // Find top-rated nearby place
    for (final places in context.nearbyPlaces.values) {
      final topRated = places.where((p) => (p.rating ?? 0) >= 4.5).take(1).toList();
      if (topRated.isNotEmpty) {
        suggestions.add('⭐ Top rated: ${topRated.first.name}');
        break;
      }
    }
  }
  
  return suggestions;
});

/// Provider for nearby places with caching
final enhancedNearbyPlacesProvider = FutureProvider<Map<PlaceCategory, List<Place>>>((ref) async {
  final placesService = ref.watch(placesServiceProvider);
  final locationService = ref.watch(locationServiceProvider);
  
  final position = await locationService.getCurrentPosition();
  if (position == null) return {};
  
  return placesService.searchMultipleCategories(
    latitude: position.latitude,
    longitude: position.longitude,
    categories: [
      PlaceCategory.restaurant,
      PlaceCategory.cafe,
      PlaceCategory.gym,
      PlaceCategory.pharmacy,
      PlaceCategory.supermarket,
      PlaceCategory.gasStation,
    ],
    maxResultsPerCategory: 5,
  );
});

