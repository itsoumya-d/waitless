import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waitless/core/services/firestore_venue_repository.dart';

class _Firestore extends Fake implements FirebaseFirestore {}

class _Repository extends FirestoreVenueRepository {
  final List<({String id, Map<String, dynamic> data})> records;
  int reads = 0;
  _Repository(this.records) : super(_Firestore());

  @override
  Future<List<({String id, Map<String, dynamic> data})>>
  loadVenueRecords() async {
    reads++;
    return records;
  }
}

void main() {
  group('Firestore nearby discovery with in-memory records', () {
    late _Repository repository;
    setUp(() {
      repository = _Repository([
        (id: 'far', data: {'latitude': 0, 'longitude': 0.04}),
        (id: 'missing', data: {}),
        (id: 'partial', data: {'latitude': 0}),
        (id: 'malformed', data: {'latitude': '0', 'longitude': 0}),
        (id: 'invalid', data: {'latitude': 91, 'longitude': 0}),
        (id: 'nonfinite', data: {'latitude': double.nan, 'longitude': 0}),
        (id: 'outside', data: {'latitude': 0, 'longitude': 1}),
        (id: 'zero', data: {'latitude': 0, 'longitude': 0}),
        (id: 'near', data: {'latitude': 0, 'longitude': 0.01}),
      ]);
    });

    test(
      'filters and sorts, excluding missing/malformed coordinates',
      () async {
        final venues = await repository.getNearbyVenues(
          latitude: 0,
          longitude: 0,
        );
        expect(venues.map((v) => v.id), ['zero', 'near', 'far']);
        expect(venues[1].distanceKm, closeTo(1.1119492664, 0.000001));
        expect(repository.reads, 1);
      },
    );

    test('unknown origin browses valid records in collection order', () async {
      final venues = await repository.getNearbyVenues();
      expect(venues.map((v) => v.id), ['far', 'outside', 'zero', 'near']);
      expect(venues.every((v) => v.distanceKm == 0), isTrue);
    });

    test('zero radius does not turn missing coordinates into (0, 0)', () async {
      final venues = await repository.getNearbyVenues(
        latitude: 0,
        longitude: 0,
        radiusKm: 0,
      );
      expect(venues.map((v) => v.id), ['zero']);
    });

    test('invalid radius performs no database read', () async {
      expect(await repository.getNearbyVenues(radiusKm: double.nan), isEmpty);
      expect(repository.reads, 0);
    });
  });
}
