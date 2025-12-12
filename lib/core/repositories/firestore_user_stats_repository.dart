import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_data.dart';
import '../services/firebase_service.dart';

/// Repository for syncing user stats to Firestore
class FirestoreUserStatsRepository {
  final FirebaseService _firebaseService;

  FirestoreUserStatsRepository(this._firebaseService);

  /// Collection reference for user stats
  CollectionReference get _usersCollection => _firebaseService.firestore.collection('users');

  /// Stream valid user stats
  Stream<UserStats> streamUserStats(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('stats')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserStats.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return const UserStats();
    });
  }

  /// Sync stats to Firestore
  Future<void> syncUserStats(String userId, UserStats stats) async {
    await _usersCollection
        .doc(userId)
        .collection('stats')
        .doc('current')
        .set(stats.toMap());
  }

  /// Update a specific field atomically
  Future<void> incrementStat(String userId, String field, {int amount = 1}) async {
    await _usersCollection
        .doc(userId)
        .collection('stats')
        .doc('current')
        .set({field: FieldValue.increment(amount)}, SetOptions(merge: true));
  }
}
