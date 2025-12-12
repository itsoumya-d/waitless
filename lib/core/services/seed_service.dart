import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/venue.dart';
import '../services/venue_repository.dart';

class SeedService {
  final FirebaseFirestore _firestore;
  
  SeedService(this._firestore);
  
  Future<void> seedVenuesIfNeeded() async {
    try {
      final collection = _firestore.collection('venues');
      final snapshot = await collection.limit(1).get();
      
      if (snapshot.docs.isNotEmpty) {
        debugPrint('📦 Firestore already has data, skipping seed.');
        return;
      }
      
      debugPrint('🌱 Seeding Firestore with initial venue data...');
      
      // Access private mock venues via a temporary public accessor if needed, 
      // or just copy the list here. For simplicity/robustness, I'll copy a subset 
      // or use a public getter if available.
      // VenueRepository() is the mock repo.
      final mockRepo = VenueRepository(); 
      // We need to access getNearbyVenues which returns the mock list effectively.
      final venues = await mockRepo.getNearbyVenues(radiusKm: 10000);
      
      final batch = _firestore.batch();
      
      for (final venue in venues) {
        final docRef = collection.doc(venue.id);
        batch.set(docRef, {
          'name': venue.name,
          'address': venue.address,
          'latitude': venue.latitude,
          'longitude': venue.longitude,
          'category': venue.category,
          'imageUrl': venue.imageUrl,
          'placeId': venue.placeId,
          'currentCrowdLevel': venue.currentCrowdLevel.index,
          'reportCount': venue.reportCount,
          'averageWaitMinutes': venue.averageWaitMinutes,
          'lastReportedAt': venue.lastReportedAt != null 
              ? Timestamp.fromDate(venue.lastReportedAt!) 
              : null,
          'nameSearch': _generateSearchKeywords(venue.name),
        });
      }
      
      await batch.commit();
      debugPrint('✅ Successfully seeded ${venues.length} venues to Firestore');
      
    } catch (e) {
      debugPrint('❌ Error seeding data: $e');
    }
  }
  
  List<String> _generateSearchKeywords(String name) {
    final nameLower = name.toLowerCase();
    final keywords = <String>[];
    String current = '';
    for (int i = 0; i < nameLower.length; i++) {
      current += nameLower[i];
      keywords.add(current);
    }
    // Add words
    final words = nameLower.split(' ');
    for (var word in words) {
        current = '';
        for (int i = 0; i < word.length; i++) {
            current += word[i];
            keywords.add(current);
        }
    }
    return keywords.toSet().toList(); // Unique
  }
}
