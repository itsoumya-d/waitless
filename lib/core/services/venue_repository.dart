import '../../models/venue.dart';
import 'nearby_venues.dart';

/// Repository for venue data operations
class VenueRepository {
  /// Mock data for initial development
  /// TODO: Replace with Firebase Firestore queries
  
  static final List<Venue> _mockVenues = [
    const Venue(
      id: '1',
      name: 'Trader Joe\'s',
      address: '123 Market St, San Francisco, CA',
      latitude: 37.7749,
      longitude: -122.4194,
      category: 'grocery',
      currentCrowdLevel: CrowdLevel.low,
      reportCount: 24,
      averageWaitMinutes: 3,
    ),
    const Venue(
      id: '2',
      name: 'Equinox Gym',
      address: '456 Fitness Ave, San Francisco, CA',
      latitude: 37.7849,
      longitude: -122.4094,
      category: 'gym',
      currentCrowdLevel: CrowdLevel.medium,
      reportCount: 18,
      averageWaitMinutes: 0,
    ),
    const Venue(
      id: '3',
      name: 'Target',
      address: '789 Shopping Blvd, San Francisco, CA',
      latitude: 37.7649,
      longitude: -122.4294,
      category: 'retail',
      currentCrowdLevel: CrowdLevel.high,
      reportCount: 42,
      averageWaitMinutes: 12,
    ),
    const Venue(
      id: '4',
      name: 'Blue Bottle Coffee',
      address: '321 Brew Lane, San Francisco, CA',
      latitude: 37.7549,
      longitude: -122.4394,
      category: 'coffeeshop',
      currentCrowdLevel: CrowdLevel.low,
      reportCount: 15,
      averageWaitMinutes: 5,
    ),
    const Venue(
      id: '5',
      name: 'Whole Foods Market',
      address: '555 Organic Way, San Francisco, CA',
      latitude: 37.7599,
      longitude: -122.4144,
      category: 'grocery',
      currentCrowdLevel: CrowdLevel.medium,
      reportCount: 31,
      averageWaitMinutes: 7,
    ),
    const Venue(
      id: '6',
      name: 'Chase Bank',
      address: '100 Finance St, San Francisco, CA',
      latitude: 37.7699,
      longitude: -122.4044,
      category: 'bank',
      currentCrowdLevel: CrowdLevel.high,
      reportCount: 28,
      averageWaitMinutes: 15,
    ),
    const Venue(
      id: '7',
      name: 'CVS Pharmacy',
      address: '200 Health Blvd, San Francisco, CA',
      latitude: 37.7799,
      longitude: -122.3994,
      category: 'pharmacy',
      currentCrowdLevel: CrowdLevel.low,
      reportCount: 12,
      averageWaitMinutes: 4,
    ),
    const Venue(
      id: '8',
      name: 'Chipotle',
      address: '300 Burrito Ave, San Francisco, CA',
      latitude: 37.7679,
      longitude: -122.4244,
      category: 'restaurant',
      currentCrowdLevel: CrowdLevel.veryHigh,
      reportCount: 56,
      averageWaitMinutes: 18,
    ),
  ];
  
  /// Get nearby demo venues, or the demo catalog when location is unknown.
  Future<List<Venue>> getNearbyVenues({
    double? latitude,
    double? longitude,
    double radiusKm = 5.0,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return selectNearbyVenues(
      _mockVenues,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
  
  /// Get venue by ID
  Future<Venue?> getVenueById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      return _mockVenues.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Search venues by name or category
  Future<List<Venue>> searchVenues(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final lowerQuery = query.toLowerCase();
    return _mockVenues.where((v) {
      return v.name.toLowerCase().contains(lowerQuery) ||
             v.category.toLowerCase().contains(lowerQuery) ||
             v.address.toLowerCase().contains(lowerQuery);
    }).toList();
  }
  
  /// Get venues filtered by crowd level
  Future<List<Venue>> getVenuesByFilter({
    CrowdLevel? maxCrowdLevel,
    String? category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _mockVenues.where((v) {
      bool matches = true;
      
      if (maxCrowdLevel != null) {
        matches = matches && v.currentCrowdLevel.index <= maxCrowdLevel.index;
      }
      
      if (category != null) {
        matches = matches && v.category == category;
      }
      
      return matches;
    }).toList();
  }
  
  /// Submit a crowd report
  Future<bool> submitCrowdReport({
    required String venueId,
    required CrowdLevel crowdLevel,
    int? waitMinutes,
    String? comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // TODO: Save to Firestore
    // For now, just return success
    return true;
  }
  
  /// Get predictions for a venue (mock data)
  Future<List<HourlyPrediction>> getVenuePredictions(String venueId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Generate mock predictions for 24 hours
    return List.generate(24, (hour) {
      // Simulate typical patterns
      double crowdScore;
      if (hour >= 11 && hour <= 13) {
        crowdScore = 0.8; // Lunch rush
      } else if (hour >= 17 && hour <= 19) {
        crowdScore = 0.9; // Evening rush
      } else if (hour >= 9 && hour <= 11) {
        crowdScore = 0.5; // Morning moderate
      } else if (hour >= 6 && hour <= 8) {
        crowdScore = 0.3; // Early morning
      } else if (hour >= 20 && hour <= 22) {
        crowdScore = 0.4; // Late evening
      } else {
        crowdScore = 0.1; // Off hours
      }
      
      return HourlyPrediction(
        hour: hour,
        crowdScore: crowdScore,
        confidence: 0.85,
      );
    });
  }
  
  /// Get best times to visit a venue
  List<Map<String, dynamic>> getBestTimesToVisit(List<HourlyPrediction> predictions) {
    // Sort by crowd score ascending
    final sorted = List<HourlyPrediction>.from(predictions)
      ..sort((a, b) => a.crowdScore.compareTo(b.crowdScore));
    
    // Get top 3 best times
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

