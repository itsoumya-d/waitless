import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';
import '../../models/venue.dart';
import 'venue_data_provider.dart';

import 'firebase_service.dart';
import '../repositories/firestore_favorites_repository.dart';

/// Provider for favorites service
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  final repository = FirestoreFavoritesRepository(firebaseService);
  return FavoritesService(prefs, repository, firebaseService);
});

/// Provider for favorite venue IDs (reactive)
final favoriteIdsProvider = StateNotifierProvider<FavoriteIdsNotifier, List<String>>((ref) {
  final service = ref.watch(favoritesServiceProvider);
  return FavoriteIdsNotifier(service);
});

/// StateNotifier for managing favorite IDs reactively
class FavoriteIdsNotifier extends StateNotifier<List<String>> {
  final FavoritesService _service;
  
  FavoriteIdsNotifier(this._service) : super(_service.getFavoriteIds()) {
    _initStream();
  }
  
  void _initStream() {
    _service.favoritesStream.listen((favorites) {
      if (mounted) state = favorites;
    });
  }

  /// Check if venue is favorited
  bool isFavorite(String venueId) => state.contains(venueId);
  
  /// Toggle favorite status
  Future<void> toggle(String venueId) async {
    // Optimistic update
    final isCurrentlyFav = state.contains(venueId);
    if (isCurrentlyFav) {
      state = state.where((id) => id != venueId).toList();
    } else {
      state = [...state, venueId];
    }
    
    await _service.toggleFavorite(venueId);
  }
  
  /// Refresh from storage
  void refresh() {
    state = _service.getFavoriteIds();
  }
}

/// Service for managing favorite venues with persistence
class FavoritesService {
  static const _favoritesKey = 'favorite_venues';
  
  final SharedPreferences _prefs;
  final FirestoreFavoritesRepository _repository;
  final FirebaseService _firebaseService;
  
  FavoritesService(this._prefs, this._repository, this._firebaseService);
  
  /// Get list of favorite venue IDs (local cache)
  List<String> getFavoriteIds() {
    return _prefs.getStringList(_favoritesKey) ?? [];
  }
  
  /// Stream of favorite IDs from Firestore
  Stream<List<String>> get favoritesStream {
    final user = _firebaseService.currentUser;
    if (user != null) {
      return _repository.streamFavorites(user.uid).map((remoteFavorites) {
        // Sync remote to local
        _prefs.setStringList(_favoritesKey, remoteFavorites);
        return remoteFavorites;
      });
    }
    // If not logged in, just return local stream (simulated)
    return Stream.value(getFavoriteIds());
  }
  
  /// Check if a venue is favorited
  bool isFavorite(String venueId) {
    return getFavoriteIds().contains(venueId);
  }
  
  /// Add venue to favorites
  Future<bool> addFavorite(String venueId) async {
    // Optimistic local update
    final favorites = getFavoriteIds();
    if (!favorites.contains(venueId)) {
      favorites.add(venueId);
      await _prefs.setStringList(_favoritesKey, favorites);
      debugPrint('❤️ Added venue $venueId to favorites (local)');
      
      // Sync to cloud
      final user = _firebaseService.currentUser;
      if (user != null) {
        await _repository.addFavorite(user.uid, venueId);
        debugPrint('☁️ Added venue $venueId to favorites (cloud)');
      }
      return true;
    }
    return false;
  }
  
  /// Remove venue from favorites
  Future<bool> removeFavorite(String venueId) async {
    final favorites = getFavoriteIds();
    if (favorites.contains(venueId)) {
      favorites.remove(venueId);
      await _prefs.setStringList(_favoritesKey, favorites);
      debugPrint('💔 Removed venue $venueId from favorites (local)');
      
      // Sync to cloud
      final user = _firebaseService.currentUser;
      if (user != null) {
        await _repository.removeFavorite(user.uid, venueId);
        debugPrint('☁️ Removed venue $venueId from favorites (cloud)');
      }
      return true;
    }
    return false;
  }
  
  /// Toggle favorite status
  Future<bool> toggleFavorite(String venueId) async {
    if (isFavorite(venueId)) {
      await removeFavorite(venueId);
      return false;
    } else {
      await addFavorite(venueId);
      return true;
    }
  }
  
  /// Clear all favorites
  Future<void> clearFavorites() async {
    await _prefs.remove(_favoritesKey);
    debugPrint('🗑️ Cleared all favorites');
  }
  
  /// Get count of favorites
  int get favoriteCount => getFavoriteIds().length;
}

/// Provider for favorite venues (full venue objects)
final favoriteVenuesProvider = FutureProvider<List<Venue>>((ref) async {
  final favoriteIds = ref.watch(favoriteIdsProvider);
  final repo = ref.watch(venueRepositoryProvider);
  
  final venues = <Venue>[];
  for (final id in favoriteIds) {
    final venue = await repo.getVenueById(id);
    if (venue != null) {
      venues.add(venue);
    }
  }
  return venues;
});

/// Provider to check if specific venue is favorite
final isFavoriteProvider = Provider.family<bool, String>((ref, venueId) {
  final favoriteIds = ref.watch(favoriteIdsProvider);
  return favoriteIds.contains(venueId);
});
