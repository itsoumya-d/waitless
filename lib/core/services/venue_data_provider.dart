import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/venue.dart';
import '../../models/crowd_report.dart';
import 'venue_repository.dart';
import 'firestore_venue_repository.dart';
import 'auth_service.dart';
import 'location_service.dart';

/// Configuration for which data source to use
enum DataSourceMode {
  /// Use local mock data (development/offline)
  mock,
  /// Use Firebase Firestore (production)
  firestore,
}

/// Provider for current data source mode
/// Set to [DataSourceMode.mock] for development without Firebase config
/// Set to [DataSourceMode.firestore] when Firebase is properly configured
final dataSourceModeProvider = Provider<DataSourceMode>((ref) {
  // Always use Firestore in production
  return DataSourceMode.firestore;
});

/// Abstract venue repository interface
abstract class IVenueRepository {
  Future<List<Venue>> getNearbyVenues({
    double? latitude,
    double? longitude,
    double radiusKm = 5.0,
  });
  
  Future<Venue?> getVenueById(String id);
  
  Future<List<Venue>> searchVenues(String query);
  
  Future<List<Venue>> getVenuesByFilter({
    CrowdLevel? maxCrowdLevel,
    String? category,
  });
  
  Future<bool> submitCrowdReport({
    required String venueId,
    required CrowdLevel crowdLevel,
    int? waitMinutes,
    String? comment,
  });
  
  Future<List<HourlyPrediction>> getVenuePredictions(String venueId);
  
  List<Map<String, dynamic>> getBestTimesToVisit(List<HourlyPrediction> predictions);
}

/// Unified venue repository provider that auto-selects mock or Firestore
final venueRepositoryProvider = Provider<IVenueRepository>((ref) {
  final mode = ref.watch(dataSourceModeProvider);
  
  switch (mode) {
    case DataSourceMode.firestore:
      debugPrint('📡 Using Firestore venue repository');
      return _FirestoreVenueAdapter(
        ref.watch(firestoreVenueRepositoryProvider),
        ref.watch(authServiceProvider),
      );
    case DataSourceMode.mock:
      debugPrint('🧪 Using mock venue repository');
      return _MockVenueAdapter(VenueRepository());
  }
});

/// Adapter to make VenueRepository implement IVenueRepository
class _MockVenueAdapter implements IVenueRepository {
  final VenueRepository _repo;
  
  _MockVenueAdapter(this._repo);
  
  @override
  Future<List<Venue>> getNearbyVenues({
    double? latitude,
    double? longitude,
    double radiusKm = 5.0,
  }) => _repo.getNearbyVenues(
    latitude: latitude,
    longitude: longitude,
    radiusKm: radiusKm,
  );
  
  @override
  Future<Venue?> getVenueById(String id) => _repo.getVenueById(id);
  
  @override
  Future<List<Venue>> searchVenues(String query) => _repo.searchVenues(query);
  
  @override
  Future<List<Venue>> getVenuesByFilter({
    CrowdLevel? maxCrowdLevel,
    String? category,
  }) => _repo.getVenuesByFilter(
    maxCrowdLevel: maxCrowdLevel,
    category: category,
  );
  
  @override
  Future<bool> submitCrowdReport({
    required String venueId,
    required CrowdLevel crowdLevel,
    int? waitMinutes,
    String? comment,
  }) => _repo.submitCrowdReport(
    venueId: venueId,
    crowdLevel: crowdLevel,
    waitMinutes: waitMinutes,
    comment: comment,
  );
  
  @override
  Future<List<HourlyPrediction>> getVenuePredictions(String venueId) =>
      _repo.getVenuePredictions(venueId);
  
  @override
  List<Map<String, dynamic>> getBestTimesToVisit(List<HourlyPrediction> predictions) =>
      _repo.getBestTimesToVisit(predictions);
}

/// Adapter to make FirestoreVenueRepository implement IVenueRepository
class _FirestoreVenueAdapter implements IVenueRepository {
  final FirestoreVenueRepository _repo;
  final AuthService _authService;
  
  _FirestoreVenueAdapter(this._repo, this._authService);
  
  @override
  Future<List<Venue>> getNearbyVenues({
    double? latitude,
    double? longitude,
    double radiusKm = 5.0,
  }) => _repo.getNearbyVenues(
    latitude: latitude,
    longitude: longitude,
    radiusKm: radiusKm,
  );
  
  @override
  Future<Venue?> getVenueById(String id) => _repo.getVenueById(id);
  
  @override
  Future<List<Venue>> searchVenues(String query) => _repo.searchVenues(query);
  
  @override
  Future<List<Venue>> getVenuesByFilter({
    CrowdLevel? maxCrowdLevel,
    String? category,
  }) {
    return _repo.getVenuesByFilter(
      maxCrowdLevel: maxCrowdLevel,
      category: category,
    );
  }
  
  @override
  Future<bool> submitCrowdReport({
    required String venueId,
    required CrowdLevel crowdLevel,
    int? waitMinutes,
    String? comment,
  }) async {
    try {
      final userId = _authService.currentUserId ?? 'anonymous';
      
      return await _repo.submitReport(
        venueId: venueId,
        userId: userId,
        crowdLevel: crowdLevel,
        waitMinutes: waitMinutes,
        comment: comment,
      );
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<List<HourlyPrediction>> getVenuePredictions(String venueId) {
    return _repo.getVenuePredictions(venueId);
  }
  
  @override
  List<Map<String, dynamic>> getBestTimesToVisit(List<HourlyPrediction> predictions) {
    final sorted = List<HourlyPrediction>.from(predictions)
      ..sort((a, b) => a.crowdScore.compareTo(b.crowdScore));
    
    return sorted.take(3).map((p) {
      String period;
      if (p.hour < 12) {
        period = '${p.hour == 0 ? 12 : p.hour}:00 AM';
      } else if (p.hour == 12) {
        period = '12:00 PM';
      } else {
        period = '${p.hour - 12}:00 PM';
      }
      
      return {
        'time': period,
        'crowdScore': p.crowdScore,
        'description': p.crowdScore < 0.3 
            ? 'Usually quiet' 
            : p.crowdScore < 0.5 
                ? 'Low to moderate' 
                : 'Moderate activity',
      };
    }).toList();
  }
}

/// Provider for fetching nearby venues (uses unified interface)
final fetchNearbyVenuesProvider = FutureProvider<List<Venue>>((ref) async {
  final repo = ref.watch(venueRepositoryProvider);
  final location = await ref.watch(currentLocationProvider.future);
  return repo.getNearbyVenues(
    latitude: location?.latitude,
    longitude: location?.longitude,
  );
});

/// Provider for fetching venue by ID
final venueByIdProvider = FutureProvider.family<Venue?, String>((ref, id) async {
  final repo = ref.watch(venueRepositoryProvider);
  return repo.getVenueById(id);
});

/// Provider for venue predictions
final venuePredictionsProvider = FutureProvider.family<List<HourlyPrediction>, String>((ref, venueId) async {
  final repo = ref.watch(venueRepositoryProvider);
  return repo.getVenuePredictions(venueId);
});

/// Provider for searching venues
final searchVenuesProvider = FutureProvider.family<List<Venue>, String>((ref, query) async {
  final repo = ref.watch(venueRepositoryProvider);
  return repo.searchVenues(query);
});

// ============ Real-Time Stream Providers ============

/// Stream provider for real-time venue updates (Firestore only)
final venueStreamProvider = StreamProvider.family<Venue?, String>((ref, venueId) {
  final mode = ref.watch(dataSourceModeProvider);
  
  if (mode == DataSourceMode.firestore) {
    final firestoreRepo = ref.watch(firestoreVenueRepositoryProvider);
    return firestoreRepo.streamVenue(venueId);
  }
  
  // For mock mode, return a single-value stream
  return Stream.fromFuture(
    ref.watch(venueRepositoryProvider).getVenueById(venueId)
  );
});

/// Stream provider for real-time crowd reports (Firestore only)
final crowdReportsStreamProvider = StreamProvider.family<List<CrowdReport>, String>((ref, venueId) {
  final mode = ref.watch(dataSourceModeProvider);
  
  if (mode == DataSourceMode.firestore) {
    final firestoreRepo = ref.watch(firestoreVenueRepositoryProvider);
    return firestoreRepo.streamReports(venueId);
  }
  
  // For mock mode, return empty stream
  return Stream.value(<CrowdReport>[]);
});


