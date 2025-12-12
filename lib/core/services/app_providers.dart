import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import '../../models/venue.dart';
import '../../models/user_data.dart';

/// Global key for ScaffoldMessenger to show snackbars from anywhere
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Global key for Navigator to allow navigation from services
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shared preferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

/// User onboarding status provider
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('hasCompletedOnboarding') ?? false;
});

/// Set onboarding complete
Future<void> setOnboardingComplete(WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setBool('hasCompletedOnboarding', true);
}

/// Current user location provider
final userLocationProvider = FutureProvider<Position?>((ref) async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;
    
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  } catch (e) {
    return null;
  }
});

/// User data state notifier
class UserDataNotifier extends StateNotifier<UserData?> {
  UserDataNotifier() : super(null);
  
  void setUser(UserData user) => state = user;
  void clearUser() => state = null;
  
  void addMinutesSaved(int minutes) {
    if (state != null) {
      state = UserData(
        id: state!.id,
        displayName: state!.displayName,
        email: state!.email,
        photoUrl: state!.photoUrl,
        createdAt: state!.createdAt,
        totalReports: state!.totalReports,
        reportAccuracy: state!.reportAccuracy,
        totalMinutesSaved: state!.totalMinutesSaved + minutes,
        currentStreak: state!.currentStreak,
        longestStreak: state!.longestStreak,
        contributionPoints: state!.contributionPoints,
        favoriteVenueIds: state!.favoriteVenueIds,
        interests: state!.interests,
        badgeLevel: state!.badgeLevel,
        lastActiveAt: DateTime.now(),
        hasCompletedOnboarding: state!.hasCompletedOnboarding,
        notificationsEnabled: state!.notificationsEnabled,
        locationSharingEnabled: state!.locationSharingEnabled,
      );
    }
  }
  
  void incrementReports() {
    if (state != null) {
      final newTotalReports = state!.totalReports + 1;
      final newPoints = state!.contributionPoints + 10;
      
      // Calculate new badge level
      BadgeLevel newBadge = state!.badgeLevel;
      if (newTotalReports >= 1001) {
        newBadge = BadgeLevel.legend;
      } else if (newTotalReports >= 501) {
        newBadge = BadgeLevel.guardian;
      } else if (newTotalReports >= 201) {
        newBadge = BadgeLevel.expert;
      } else if (newTotalReports >= 51) {
        newBadge = BadgeLevel.trusted;
      } else if (newTotalReports >= 11) {
        newBadge = BadgeLevel.contributor;
      }
      
      state = UserData(
        id: state!.id,
        displayName: state!.displayName,
        email: state!.email,
        photoUrl: state!.photoUrl,
        createdAt: state!.createdAt,
        totalReports: newTotalReports,
        reportAccuracy: state!.reportAccuracy,
        totalMinutesSaved: state!.totalMinutesSaved,
        currentStreak: state!.currentStreak,
        longestStreak: state!.longestStreak,
        contributionPoints: newPoints,
        favoriteVenueIds: state!.favoriteVenueIds,
        interests: state!.interests,
        badgeLevel: newBadge,
        lastActiveAt: DateTime.now(),
        hasCompletedOnboarding: state!.hasCompletedOnboarding,
        notificationsEnabled: state!.notificationsEnabled,
        locationSharingEnabled: state!.locationSharingEnabled,
      );
    }
  }
  void clear() {
    state = null;
  }
}

final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData?>((ref) {
  return UserDataNotifier();
});

/// Nearby venues provider
class NearbyVenuesNotifier extends StateNotifier<AsyncValue<List<Venue>>> {
  NearbyVenuesNotifier() : super(const AsyncValue.loading());
  
  void setVenues(List<Venue> venues) {
    state = AsyncValue.data(venues);
  }
  
  void setLoading() {
    state = const AsyncValue.loading();
  }
  
  void setError(Object error, StackTrace stackTrace) {
    state = AsyncValue.error(error, stackTrace);
  }
  
  void updateVenueCrowdLevel(String venueId, CrowdLevel newLevel) {
    state.whenData((venues) {
      final updatedVenues = venues.map((v) {
        if (v.id == venueId) {
          return v.copyWith(
            currentCrowdLevel: newLevel,
            lastReportedAt: DateTime.now(),
            reportCount: v.reportCount + 1,
          );
        }
        return v;
      }).toList();
      state = AsyncValue.data(updatedVenues);
    });
  }
}

final nearbyVenuesProvider = StateNotifierProvider<NearbyVenuesNotifier, AsyncValue<List<Venue>>>((ref) {
  return NearbyVenuesNotifier();
});

/// Favorite venues provider
final favoriteVenueIdsProvider = StateNotifierProvider<FavoriteVenueIdsNotifier, List<String>>((ref) {
  return FavoriteVenueIdsNotifier();
});

class FavoriteVenueIdsNotifier extends StateNotifier<List<String>> {
  FavoriteVenueIdsNotifier() : super([]);
  
  void toggleFavorite(String venueId) {
    if (state.contains(venueId)) {
      state = state.where((id) => id != venueId).toList();
    } else {
      state = [...state, venueId];
    }
  }
  
  bool isFavorite(String venueId) => state.contains(venueId);
}

/// Selected interests provider (for onboarding and content personalization)
final selectedInterestsProvider = StateNotifierProvider<SelectedInterestsNotifier, List<String>>((ref) {
  return SelectedInterestsNotifier();
});

class SelectedInterestsNotifier extends StateNotifier<List<String>> {
  SelectedInterestsNotifier() : super([]);
  
  void toggleInterest(String interest) {
    if (state.contains(interest)) {
      state = state.where((i) => i != interest).toList();
    } else {
      state = [...state, interest];
    }
  }
  
  void setInterests(List<String> interests) {
    state = interests;
  }
}

/// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  ThemeModeNotifier(this._prefs) : super(_prefs.getBool('isDarkMode') ?? false);

  void toggle() {
    state = !state;
    _prefs.setBool('isDarkMode', state);
  }
  
  @override
  set state(bool value) {
    super.state = value;
    _prefs.setBool('isDarkMode', value);
  }
}

/// Notifications enabled provider
final notificationsEnabledProvider = StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationsEnabledNotifier(prefs);
});

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  NotificationsEnabledNotifier(this._prefs) : super(_prefs.getBool('notificationsEnabled') ?? true);
  
  @override
  set state(bool value) {
    super.state = value;
    _prefs.setBool('notificationsEnabled', value);
  }
}

/// Location sharing enabled provider
final locationSharingEnabledProvider = StateNotifierProvider<LocationSharingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocationSharingNotifier(prefs);
});

class LocationSharingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  LocationSharingNotifier(this._prefs) : super(_prefs.getBool('locationSharingEnabled') ?? true);
  
  @override
  set state(bool value) {
    super.state = value;
    _prefs.setBool('locationSharingEnabled', value);
  }
}
