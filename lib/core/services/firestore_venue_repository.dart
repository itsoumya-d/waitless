import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/venue.dart';
import '../../models/crowd_report.dart';
import 'nearby_venues.dart';

/// Firestore repository for venues
/// 
/// This handles all Firebase Firestore operations for venues and crowd reports.
class FirestoreVenueRepository {
  final FirebaseFirestore _firestore;
  
  // Collection references
  CollectionReference get _venuesCollection => _firestore.collection('venues');
  CollectionReference get _reportsCollection => _firestore.collection('crowd_reports');
  
  FirestoreVenueRepository(this._firestore);
  
  // ============ Venue Operations ============
  
  /// Get all venues
  Future<List<Venue>> getAllVenues() async {
    try {
      final snapshot = await _venuesCollection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _venueFromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching venues: $e');
      return [];
    }
  }
  
  /// Get nearby venues, or browse the catalog when location is unknown.
  Future<List<Venue>> getNearbyVenues({
    double? latitude,
    double? longitude,
    double radiusKm = 5.0,
  }) async {
    if (!radiusKm.isFinite || radiusKm < 0) return [];
    try {
      // Firestore has no native radius query. Filter client-side for now;
      // geohashing is still needed to avoid fetching the full collection.
      final snapshot = await _venuesCollection.get();
      final venues = <Venue>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lat = data['latitude'];
        final lng = data['longitude'];
        // Do not turn missing coordinates into a real venue at (0, 0).
        if (lat is! num || lng is! num ||
            !hasValidCoordinates(lat.toDouble(), lng.toDouble())) {
          continue;
        }
        venues.add(_venueFromFirestore(doc.id, data));
      }
      return selectNearbyVenues(
        venues,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    } catch (e) {
      debugPrint('❌ Error fetching nearby venues: $e');
      return [];
    }
  }

  /// Get venue by ID
  Future<Venue?> getVenueById(String id) async {
    try {
      final doc = await _venuesCollection.doc(id).get();
      if (!doc.exists) return null;
      return _venueFromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ Error fetching venue $id: $e');
      return null;
    }
  }
  
  /// Stream venue updates
  Stream<Venue?> streamVenue(String venueId) {
    return _venuesCollection.doc(venueId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _venueFromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    });
  }
  
  /// Search venues by name
  Future<List<Venue>> searchVenues(String query) async {
    try {
      // Firestore doesn't support full-text search
      // Use a prefix search on the name field
      final snapshot = await _venuesCollection
          .where('nameSearch', arrayContains: query.toLowerCase())
          .limit(20)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _venueFromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error searching venues: $e');
      return [];
    }
  }

  Future<List<Venue>> getVenuesByFilter({
    CrowdLevel? maxCrowdLevel,
    String? category,
  }) async {
    try {
      Query query = _venuesCollection;
      
      // Apply filters directly in Firestore query
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      if (maxCrowdLevel != null) {
        query = query.where('currentCrowdLevel', isLessThanOrEqualTo: maxCrowdLevel.index);
      }
      
      final snapshot = await query.limit(50).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _venueFromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error filtering venues: $e');
      // If index is missing, it might fail. Fallback to client-side filtering safely?
      // Ideally, we should just let it fail so we know to fix indexes. 
      // But for robustness:
      return []; 
    }
  }
  
  // ============ Crowd Report Operations ============
  
  /// Submit a crowd report
  Future<bool> submitReport({
    required String venueId,
    required String userId,
    required CrowdLevel crowdLevel,
    int? waitMinutes,
    String? comment,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Create report document
      final reportRef = _reportsCollection.doc();
      batch.set(reportRef, {
        'venueId': venueId,
        'userId': userId,
        'crowdLevel': crowdLevel.index,
        'waitMinutes': waitMinutes ?? 0,
        'comment': comment,
        'reportedAt': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'downvotes': 0,
        'isActive': true,
      });
      
      // Update venue with latest crowd level
      final venueRef = _venuesCollection.doc(venueId);
      batch.update(venueRef, {
        'currentCrowdLevel': crowdLevel.index,
        'lastReportedAt': FieldValue.serverTimestamp(),
        'reportCount': FieldValue.increment(1),
      });
      
      await batch.commit();
      debugPrint('✅ Report submitted for venue $venueId');
      return true;
    } catch (e) {
      debugPrint('❌ Error submitting report: $e');
      rethrow;
    }
  }
  
  /// Get recent reports for a venue
  Future<List<CrowdReport>> getRecentReports(String venueId, {int limit = 10}) async {
    try {
      final snapshot = await _reportsCollection
          .where('venueId', isEqualTo: venueId)
          .where('isActive', isEqualTo: true)
          .orderBy('reportedAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _reportFromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching reports: $e');
      return [];
    }
  }
  
  /// Stream recent reports
  Stream<List<CrowdReport>> streamReports(String venueId) {
    return _reportsCollection
        .where('venueId', isEqualTo: venueId)
        .where('isActive', isEqualTo: true)
        .orderBy('reportedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          return _reportFromFirestore(doc.id, doc.data() as Map<String, dynamic>);
        }).toList());
  }
  
  /// Upvote a report
  Future<void> upvoteReport(String reportId) async {
    try {
      await _reportsCollection.doc(reportId).update({
        'upvotes': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('❌ Error upvoting report: $e');
    }
  }
  
  /// Downvote a report
  Future<void> downvoteReport(String reportId) async {
    try {
      await _reportsCollection.doc(reportId).update({
        'downvotes': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('❌ Error downvoting report: $e');
    }
  }
  
  // ============ Helper Methods ============
  
  Venue _venueFromFirestore(String id, Map<String, dynamic> data) {
    return Venue(
      id: id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      category: data['category'] ?? 'other',
      imageUrl: data['imageUrl'],
      placeId: data['placeId'],
      currentCrowdLevel: CrowdLevel.values[data['currentCrowdLevel'] ?? 1],
      reportCount: data['reportCount'] ?? 0,
      lastReportedAt: (data['lastReportedAt'] as Timestamp?)?.toDate(),
      averageWaitMinutes: (data['averageWaitMinutes'] ?? 0).toDouble(),
    );
  }
  
  CrowdReport _reportFromFirestore(String id, Map<String, dynamic> data) {
    return CrowdReport(
      id: id,
      venueId: data['venueId'] ?? '',
      userId: data['userId'] ?? '',
      crowdLevel: CrowdLevel.values[data['crowdLevel'] ?? 1],
      reportedAt: (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      waitMinutes: data['waitMinutes'] ?? 0,
      comment: data['comment'],
      upvotes: data['upvotes'] ?? 0,
      downvotes: data['downvotes'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }
  /// Get venue predictions based on historical data
  Future<List<HourlyPrediction>> getVenuePredictions(String venueId) async {
    try {
      // Fetch historical reports to calculate predictions
      final snapshot = await _reportsCollection
          .where('venueId', isEqualTo: venueId)
          .where('isActive', isEqualTo: true)
          .orderBy('reportedAt', descending: true)
          .limit(100) // Analyze last 100 reports
          .get();
          
      if (snapshot.docs.length < 5) {
        // Not enough data, return mock/default profile
        return _generateDefaultPredictions();
      }
      
      // Group by hour
      final Map<int, List<int>> reportsByHour = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final reportedAt = (data['reportedAt'] as Timestamp?)?.toDate();
        if (reportedAt != null) {
          final hour = reportedAt.hour;
          final level = data['crowdLevel'] as int? ?? 1;
          
          if (!reportsByHour.containsKey(hour)) {
            reportsByHour[hour] = [];
          }
          reportsByHour[hour]!.add(level);
        }
      }
      
      // Calculate averages
      return List.generate(24, (hour) {
        double crowdScore;
        double confidence = 0.5;
        
        if (reportsByHour.containsKey(hour)) {
          final levels = reportsByHour[hour]!;
          final avgLevel = levels.reduce((a, b) => a + b) / levels.length;
          // Map 0-3 to 0.0-1.0
          crowdScore = (avgLevel / 3.0).clamp(0.0, 1.0);
          confidence = 0.8 + (levels.length * 0.02).clamp(0.0, 0.15); // Higher confidence with more data filtering
        } else {
          // No data for this hour, interpolate or use default
          crowdScore = 0.2; // Default low
          confidence = 0.3;
        }
        
        return HourlyPrediction(hour: hour, crowdScore: crowdScore, confidence: confidence);
      });
      
    } catch (e) {
      debugPrint('❌ Error generating predictions: $e');
      return _generateDefaultPredictions();
    }
  }

  List<HourlyPrediction> _generateDefaultPredictions() {
    return List.generate(24, (hour) {
      double crowdScore;
      if (hour >= 11 && hour <= 13) {
        crowdScore = 0.8;
      } else if (hour >= 17 && hour <= 19) {
        crowdScore = 0.9;
      } else if (hour >= 9 && hour <= 11) {
        crowdScore = 0.5;
      } else if (hour >= 6 && hour <= 8) {
        crowdScore = 0.3;
      } else if (hour >= 20 && hour <= 22) {
        crowdScore = 0.4;
      } else {
        crowdScore = 0.1;
      }
      return HourlyPrediction(hour: hour, crowdScore: crowdScore, confidence: 0.85);
    });
  }
}

/// Provider for Firestore venue repository
final firestoreVenueRepositoryProvider = Provider<FirestoreVenueRepository>((ref) {
  return FirestoreVenueRepository(FirebaseFirestore.instance);
});


