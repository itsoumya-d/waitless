import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';


/// Represents a place from Google Places API
class Place {
  final String id;
  final String name;
  final String? formattedAddress;
  final double latitude;
  final double longitude;
  final double? rating;
  final int? userRatingsTotal;
  final String? priceLevel;
  final bool? isOpen;
  final List<String> types;
  final String? photoReference;
  final double? distanceMeters;

  const Place({
    required this.id,
    required this.name,
    this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.userRatingsTotal,
    this.priceLevel,
    this.isOpen,
    this.types = const [],
    this.photoReference,
    this.distanceMeters,
  });

  factory Place.fromJson(Map<String, dynamic> json, {Position? userPosition}) {
    final location = json['location'] ?? json['geometry']?['location'];
    final lat = location?['latitude'] ?? location?['lat'] ?? 0.0;
    final lng = location?['longitude'] ?? location?['lng'] ?? 0.0;
    
    double? distance;
    if (userPosition != null) {
      distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        lat.toDouble(),
        lng.toDouble(),
      );
    }

    // Parse opening hours
    bool? isOpen;
    final openingHours = json['currentOpeningHours'] ?? json['opening_hours'];
    if (openingHours != null) {
      isOpen = openingHours['openNow'] ?? openingHours['open_now'];
    }

    // Get photo reference
    String? photoRef;
    final photos = json['photos'] as List?;
    if (photos != null && photos.isNotEmpty) {
      photoRef = photos.first['name'] ?? photos.first['photo_reference'];
    }

    return Place(
      id: json['id'] ?? json['place_id'] ?? '',
      name: json['displayName']?['text'] ?? json['name'] ?? 'Unknown',
      formattedAddress: json['formattedAddress'] ?? json['formatted_address'] ?? json['vicinity'],
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['userRatingsTotal'] ?? json['user_ratings_total'],
      priceLevel: _parsePriceLevel(json['priceLevel'] ?? json['price_level']),
      isOpen: isOpen,
      types: List<String>.from(json['types'] ?? []),
      photoReference: photoRef,
      distanceMeters: distance,
    );
  }

  static String? _parsePriceLevel(dynamic level) {
    if (level == null) return null;
    if (level is String) {
      switch (level) {
        case 'PRICE_LEVEL_FREE': return 'Free';
        case 'PRICE_LEVEL_INEXPENSIVE': return '\$';
        case 'PRICE_LEVEL_MODERATE': return '\$\$';
        case 'PRICE_LEVEL_EXPENSIVE': return '\$\$\$';
        case 'PRICE_LEVEL_VERY_EXPENSIVE': return '\$\$\$\$';
        default: return level;
      }
    }
    if (level is int) {
      return '\$' * level;
    }
    return null;
  }

  String get distanceFormatted {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()}m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)}km';
  }

  String get primaryType {
    if (types.isEmpty) return 'Place';
    // Map common types to friendly names
    final typeMap = {
      'restaurant': 'Restaurant',
      'cafe': 'Café',
      'gym': 'Gym',
      'pharmacy': 'Pharmacy',
      'hospital': 'Hospital',
      'bank': 'Bank',
      'atm': 'ATM',
      'gas_station': 'Gas Station',
      'supermarket': 'Supermarket',
      'grocery_store': 'Grocery',
      'shopping_mall': 'Mall',
      'park': 'Park',
      'airport': 'Airport',
      'train_station': 'Train Station',
      'bus_station': 'Bus Station',
      'bar': 'Bar',
      'movie_theater': 'Cinema',
      'museum': 'Museum',
      'library': 'Library',
      'school': 'School',
      'university': 'University',
      'lodging': 'Hotel',
      'spa': 'Spa',
      'beauty_salon': 'Salon',
    };
    
    for (final type in types) {
      if (typeMap.containsKey(type)) {
        return typeMap[type]!;
      }
    }
    return types.first.replaceAll('_', ' ').split(' ').map((w) => 
      w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : ''
    ).join(' ');
  }
}

/// Place categories for nearby search
enum PlaceCategory {
  restaurant('restaurant', 'Restaurants', '🍽️'),
  cafe('cafe', 'Cafés', '☕'),
  gym('gym', 'Gyms', '💪'),
  pharmacy('pharmacy', 'Pharmacies', '💊'),
  hospital('hospital', 'Hospitals', '🏥'),
  bank('bank', 'Banks', '🏦'),
  atm('atm', 'ATMs', '💳'),
  gasStation('gas_station', 'Gas Stations', '⛽'),
  supermarket('supermarket', 'Supermarkets', '🛒'),
  shoppingMall('shopping_mall', 'Malls', '🛍️'),
  park('park', 'Parks', '🌳'),
  airport('airport', 'Airports', '✈️'),
  trainStation('train_station', 'Train Stations', '🚆'),
  bar('bar', 'Bars', '🍺'),
  movieTheater('movie_theater', 'Cinemas', '🎬'),
  hotel('lodging', 'Hotels', '🏨');

  final String type;
  final String displayName;
  final String emoji;
  
  const PlaceCategory(this.type, this.displayName, this.emoji);
}

/// Google Places API service for nearby POI discovery
class PlacesService {
  final Dio _dio;
  final SharedPreferences _prefs;
  
  // Cache settings
  static const _cachePrefix = 'places_cache_';
  static const _cacheDuration = Duration(minutes: 15);
  
  // API configuration - Uses environment variable or falls back to empty
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );
  
  // API endpoints
  static const String _nearbySearchUrl = 
      'https://places.googleapis.com/v1/places:searchNearby';
  static const String _textSearchUrl = 
      'https://places.googleapis.com/v1/places:searchText';
  static const String _placeDetailsUrl = 
      'https://places.googleapis.com/v1/places';

  PlacesService(this._prefs) : _dio = Dio();

  /// Check if Places API is configured
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Search for nearby places by category
  Future<List<Place>> searchNearby({
    required double latitude,
    required double longitude,
    required PlaceCategory category,
    double radiusMeters = 5000,
    int maxResults = 20,
  }) async {
    if (!isConfigured) {
      debugPrint('⚠️ PlacesService: API key not configured');
      return _getMockPlaces(category, latitude, longitude);
    }

    // Check cache first
    final cacheKey = '$_cachePrefix${category.type}_${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
    final cached = _getCachedPlaces(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await _dio.post(
        _nearbySearchUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,'
                'places.location,places.rating,places.userRatingsTotal,'
                'places.priceLevel,places.currentOpeningHours,places.types,places.photos',
          },
        ),
        data: {
          'includedTypes': [category.type],
          'maxResultCount': maxResults,
          'locationRestriction': {
            'circle': {
              'center': {
                'latitude': latitude,
                'longitude': longitude,
              },
              'radius': radiusMeters,
            },
          },
          'rankPreference': 'DISTANCE',
        },
      );

      final places = _parsePlacesResponse(
        response.data,
        Position(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );

      // Cache results
      _cachePlaces(cacheKey, places);

      return places;
    } catch (e) {
      debugPrint('❌ PlacesService nearby search error: $e');
      return _getMockPlaces(category, latitude, longitude);
    }
  }

  /// Search for places by text query
  Future<List<Place>> searchByText({
    required String query,
    double? latitude,
    double? longitude,
    double radiusMeters = 10000,
    int maxResults = 10,
  }) async {
    if (!isConfigured) {
      debugPrint('⚠️ PlacesService: API key not configured');
      return [];
    }

    try {
      final data = <String, dynamic>{
        'textQuery': query,
        'maxResultCount': maxResults,
      };

      if (latitude != null && longitude != null) {
        data['locationBias'] = {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': radiusMeters,
          },
        };
      }

      final response = await _dio.post(
        _textSearchUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,'
                'places.location,places.rating,places.userRatingsTotal,'
                'places.priceLevel,places.currentOpeningHours,places.types,places.photos',
          },
        ),
        data: data,
      );

      Position? userPos;
      if (latitude != null && longitude != null) {
        userPos = Position(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      return _parsePlacesResponse(response.data, userPos);
    } catch (e) {
      debugPrint('❌ PlacesService text search error: $e');
      return [];
    }
  }

  /// Get details for a specific place
  Future<Place?> getPlaceDetails(String placeId) async {
    if (!isConfigured) return null;

    try {
      final response = await _dio.get(
        '$_placeDetailsUrl/$placeId',
        options: Options(
          headers: {
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask': 'id,displayName,formattedAddress,location,'
                'rating,userRatingsTotal,priceLevel,currentOpeningHours,types,photos',
          },
        ),
      );

      return Place.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ PlacesService details error: $e');
      return null;
    }
  }

  /// Get nearby places for multiple categories at once
  Future<Map<PlaceCategory, List<Place>>> searchMultipleCategories({
    required double latitude,
    required double longitude,
    required List<PlaceCategory> categories,
    double radiusMeters = 3000,
    int maxResultsPerCategory = 5,
  }) async {
    final results = <PlaceCategory, List<Place>>{};
    
    // Execute searches in parallel
    await Future.wait(
      categories.map((category) async {
        final places = await searchNearby(
          latitude: latitude,
          longitude: longitude,
          category: category,
          radiusMeters: radiusMeters,
          maxResults: maxResultsPerCategory,
        );
        results[category] = places;
      }),
    );

    return results;
  }

  // Helper methods

  List<Place> _parsePlacesResponse(Map<String, dynamic> data, Position? userPos) {
    final places = data['places'] as List? ?? [];
    return places
        .map((p) => Place.fromJson(p as Map<String, dynamic>, userPosition: userPos))
        .toList();
  }

  List<Place>? _getCachedPlaces(String key) {
    final cached = _prefs.getString(key);
    if (cached == null) return null;

    try {
      final data = json.decode(cached) as Map<String, dynamic>;
      final timestamp = DateTime.parse(data['timestamp'] as String);
      
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        _prefs.remove(key);
        return null;
      }

      return (data['places'] as List)
          .map((p) => Place.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _prefs.remove(key);
      return null;
    }
  }

  void _cachePlaces(String key, List<Place> places) {
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'places': places.map((p) => {
        'id': p.id,
        'name': p.name,
        'formattedAddress': p.formattedAddress,
        'location': {'latitude': p.latitude, 'longitude': p.longitude},
        'rating': p.rating,
        'userRatingsTotal': p.userRatingsTotal,
        'priceLevel': p.priceLevel,
        'types': p.types,
      }).toList(),
    };
    _prefs.setString(key, json.encode(data));
  }

  /// Generate mock places for development/offline mode
  List<Place> _getMockPlaces(PlaceCategory category, double lat, double lng) {
    final mockData = <String, List<Map<String, dynamic>>>{
      'restaurant': [
        {'name': 'The Local Kitchen', 'rating': 4.5, 'priceLevel': '\$\$'},
        {'name': 'Fusion Bistro', 'rating': 4.2, 'priceLevel': '\$\$\$'},
        {'name': 'Quick Bites Diner', 'rating': 4.0, 'priceLevel': '\$'},
      ],
      'cafe': [
        {'name': 'Morning Brew', 'rating': 4.7, 'priceLevel': '\$'},
        {'name': 'Artisan Coffee Co', 'rating': 4.4, 'priceLevel': '\$\$'},
        {'name': 'The Daily Grind', 'rating': 4.1, 'priceLevel': '\$'},
      ],
      'gym': [
        {'name': 'FitLife Gym', 'rating': 4.3, 'priceLevel': '\$\$'},
        {'name': 'PowerHouse Fitness', 'rating': 4.5, 'priceLevel': '\$\$\$'},
        {'name': 'Community Wellness Center', 'rating': 4.0, 'priceLevel': '\$'},
      ],
      'pharmacy': [
        {'name': 'HealthMart Pharmacy', 'rating': 4.2, 'priceLevel': '\$'},
        {'name': '24hr MedStop', 'rating': 4.0, 'priceLevel': '\$\$'},
      ],
      'supermarket': [
        {'name': 'Fresh Foods Market', 'rating': 4.4, 'priceLevel': '\$\$'},
        {'name': 'ValueMart', 'rating': 3.9, 'priceLevel': '\$'},
        {'name': 'Organic Grocer', 'rating': 4.6, 'priceLevel': '\$\$\$'},
      ],
    };

    final items = mockData[category.type] ?? [
      {'name': '${category.displayName} Place 1', 'rating': 4.2, 'priceLevel': '\$\$'},
      {'name': '${category.displayName} Place 2', 'rating': 4.0, 'priceLevel': '\$'},
    ];

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      // Offset each mock place slightly from user location
      final offsetLat = lat + (index * 0.002);
      final offsetLng = lng + (index * 0.003);
      final distance = Geolocator.distanceBetween(lat, lng, offsetLat, offsetLng);
      
      return Place(
        id: 'mock_${category.type}_$index',
        name: item['name'] as String,
        formattedAddress: '${(distance / 1000).toStringAsFixed(1)}km away',
        latitude: offsetLat,
        longitude: offsetLng,
        rating: item['rating'] as double,
        userRatingsTotal: (50 + index * 20),
        priceLevel: item['priceLevel'] as String,
        isOpen: true,
        types: [category.type],
        distanceMeters: distance,
      );
    }).toList();
  }

  /// Clear all cached places
  Future<void> clearCache() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}

// Providers

/// Provider for PlacesService
final placesServiceProvider = Provider<PlacesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PlacesService(prefs);
});

// Note: sharedPreferencesProvider is imported from app_providers.dart
// Note: locationServiceProvider is imported from location_service.dart

/// Provider for nearby places by category
final nearbyPlacesProvider = FutureProvider.family<List<Place>, PlaceCategory>((ref, category) async {
  final placesService = ref.watch(placesServiceProvider);
  final positionAsync = ref.watch(userLocationProvider);
  
  final position = positionAsync.valueOrNull;
  if (position == null) return [];
  
  return placesService.searchNearby(
    latitude: position.latitude,
    longitude: position.longitude,
    category: category,
  );
});

/// Provider for all nearby places (multiple categories)
final allNearbyPlacesProvider = FutureProvider<Map<PlaceCategory, List<Place>>>((ref) async {
  final placesService = ref.watch(placesServiceProvider);
  final positionAsync = ref.watch(userLocationProvider);
  
  final position = positionAsync.valueOrNull;
  if (position == null) return {};
  
  return placesService.searchMultipleCategories(
    latitude: position.latitude,
    longitude: position.longitude,
    categories: [
      PlaceCategory.restaurant,
      PlaceCategory.cafe,
      PlaceCategory.gym,
      PlaceCategory.supermarket,
    ],
  );
});

/// Provider for text search results
final placesSearchProvider = FutureProvider.family<List<Place>, String>((ref, query) async {
  if (query.isEmpty) return [];
  
  final placesService = ref.watch(placesServiceProvider);
  final positionAsync = ref.watch(userLocationProvider);
  
  final position = positionAsync.valueOrNull;
  
  return placesService.searchByText(
    query: query,
    latitude: position?.latitude,
    longitude: position?.longitude,
  );
});

