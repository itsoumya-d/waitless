import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waitless/core/services/firestore_venue_repository.dart';

class _Document extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic> fields;
  _Document(this.id, this.fields);
  @override
  Map<String, dynamic> data() => fields;
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  _Snapshot(this.docs);
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final QuerySnapshot<Map<String, dynamic>> snapshot;
  int reads = 0;
  _Collection(this.snapshot);
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    reads++;
    return snapshot;
  }
}

class _Firestore extends Fake implements FirebaseFirestore {
  final _Collection venues;
  _Firestore(this.venues);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, 'venues');
    return venues;
  }
}

void main() {
  group('Firestore nearby discovery with in-memory snapshots', () {
    late _Collection collection;
    late FirestoreVenueRepository repository;
    setUp(() {
      collection = _Collection(
        _Snapshot([
          _Document('far', {'latitude': 0, 'longitude': 0.04}),
          _Document('missing', {}),
          _Document('partial', {'latitude': 0}),
          _Document('malformed', {'latitude': '0', 'longitude': 0}),
          _Document('invalid', {'latitude': 91, 'longitude': 0}),
          _Document('nonfinite', {'latitude': double.nan, 'longitude': 0}),
          _Document('outside', {'latitude': 0, 'longitude': 1}),
          _Document('zero', {'latitude': 0, 'longitude': 0}),
          _Document('near', {'latitude': 0, 'longitude': 0.01}),
        ]),
      );
      repository = FirestoreVenueRepository(_Firestore(collection));
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
        expect(collection.reads, 1);
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
      expect(collection.reads, 0);
    });
  });
}
