import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:waitless/core/services/auth_service.dart';
import 'package:waitless/core/services/firestore_venue_repository.dart';
import 'package:waitless/core/services/location_service.dart';
import 'package:waitless/core/services/venue_data_provider.dart';
import 'package:waitless/models/venue.dart';

Position position(double latitude, double longitude) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime(2026),
  accuracy: 1,
  altitude: 0,
  altitudeAccuracy: 1,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);

class _LocationService extends Fake implements LocationService {
  Position? location;
  int reads = 0;
  final permissionRequests = <bool>[];
  bool fail = false;
  bool hang = false;
  @override
  Future<Position?> getCurrentPosition({bool requestPermission = true}) async {
    reads++;
    permissionRequests.add(requestPermission);
    if (fail) throw StateError('Location unavailable');
    if (hang) return Completer<Position?>().future;
    return location;
  }

  @override
  Future<String?> getCityForPosition(Position position) async => 'Fixture city';
}

class _Repository extends Fake implements IVenueRepository {
  final calls = <(double?, double?, double)>[];
  @override
  Future<List<Venue>> getNearbyVenues({
    double? latitude,
    double? longitude,
    double radiusKm = 5,
  }) async {
    calls.add((latitude, longitude, radiusKm));
    return [];
  }
}

class _FirestoreRepository extends Fake implements FirestoreVenueRepository {
  final calls = <(double?, double?, double)>[];
  @override
  Future<List<Venue>> getNearbyVenues({
    double? latitude,
    double? longitude,
    double radiusKm = 5,
  }) async {
    calls.add((latitude, longitude, radiusKm));
    return [];
  }
}

class _AuthService extends Fake implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final permission in [
    LocationPermission.denied,
    LocationPermission.deniedForever,
    LocationPermission.unableToDetermine,
  ]) {
    test(
      'discovery does not request permission or read GPS for $permission',
      () async {
        const channel = MethodChannel('flutter.baseflow.com/geolocator');
        final calls = <String>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'isLocationServiceEnabled') return true;
          if (call.method == 'checkPermission') return permission.index;
          throw StateError('Unexpected native call: ${call.method}');
        });
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
        final repository = _Repository();
        final container = ProviderContainer(
          overrides: [venueRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);
        await container.read(fetchNearbyVenuesProvider.future);
        expect(calls, ['isLocationServiceEnabled', 'checkPermission']);
        expect(repository.calls, [(null, null, 5.0)]);
      },
    );
  }

  test(
    'discovery and city share one lookup, and refresh uses new coordinates',
    () async {
      final location = _LocationService()..location = position(0, 0);
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(location),
          venueRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(fetchNearbyVenuesProvider.future);
      expect(await container.read(currentCityProvider.future), 'Fixture city');
      expect(repository.calls, [(0.0, 0.0, 5.0)]);
      expect(location.reads, 1);

      location.location = position(1, 2);
      container.invalidate(currentLocationProvider);
      await container.read(fetchNearbyVenuesProvider.future);
      expect(await container.read(currentCityProvider.future), 'Fixture city');
      expect(repository.calls.last, (1.0, 2.0, 5.0));
      expect(location.reads, 2);
      expect(location.permissionRequests, [false, false]);
    },
  );

  testWidgets('unresponsive location lookup falls back after ten seconds', (
    tester,
  ) async {
    final location = _LocationService()..hang = true;
    final repository = _Repository();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(location),
        venueRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final result = container.read(fetchNearbyVenuesProvider.future);
    await tester.pump();
    expect(repository.calls, isEmpty);
    await tester.pump(const Duration(seconds: 10));
    expect(await result, isEmpty);
    expect(repository.calls, [(null, null, 5.0)]);
  });

  for (final failure in [false, true]) {
    test('missing location falls back to browsing (error: $failure)', () async {
      final location = _LocationService()..fail = failure;
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(location),
          venueRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(fetchNearbyVenuesProvider.future);
      expect(await container.read(currentCityProvider.future), isNull);
      expect(repository.calls, [(null, null, 5.0)]);
      expect(location.reads, 1);
    });
  }

  test(
    'Firestore adapter preserves absent origin instead of substituting zero',
    () async {
      final repository = _FirestoreRepository();
      final container = ProviderContainer(
        overrides: [
          dataSourceModeProvider.overrideWithValue(DataSourceMode.firestore),
          firestoreVenueRepositoryProvider.overrideWithValue(repository),
          authServiceProvider.overrideWithValue(_AuthService()),
        ],
      );
      addTearDown(container.dispose);
      final adapter = container.read(venueRepositoryProvider);
      await adapter.getNearbyVenues();
      await adapter.getNearbyVenues(latitude: 0, longitude: 0, radiusKm: 2);
      expect(repository.calls, [(null, null, 5.0), (0.0, 0.0, 2.0)]);
    },
  );
}
