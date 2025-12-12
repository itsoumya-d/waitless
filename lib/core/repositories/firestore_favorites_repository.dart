import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

/// Repository for managing user favorites in Firestore
class FirestoreFavoritesRepository {
  final FirebaseService _firebaseService;

  FirestoreFavoritesRepository(this._firebaseService);

  CollectionReference get _usersCollection => _firebaseService.firestore.collection('users');

  /// Stream list of favorite venue IDs
  Stream<List<String>> streamFavorites(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  /// Add a venue to favorites
  Future<void> addFavorite(String userId, String venueId) async {
    await _usersCollection
        .doc(userId)
        .collection('favorites')
        .doc(venueId)
        .set({'addedAt': FieldValue.serverTimestamp()});
  }

  /// Remove a venue from favorites
  Future<void> removeFavorite(String userId, String venueId) async {
    await _usersCollection
        .doc(userId)
        .collection('favorites')
        .doc(venueId)
        .delete();
  }
}
