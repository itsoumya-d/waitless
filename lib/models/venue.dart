import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Crowd level enumeration
enum CrowdLevel {
  low,      // 0-30% capacity
  medium,   // 30-60% capacity
  high,     // 60-85% capacity
  veryHigh, // 85-100% capacity
}

/// Venue model representing a place that can be monitored for crowd levels
class Venue {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String category;
  final String? imageUrl;
  final String? placeId;
  final CrowdLevel currentCrowdLevel;
  final int reportCount;
  final DateTime? lastReportedAt;
  final double averageWaitMinutes;
  final List<HourlyPrediction> predictions;
  final bool isFavorite;
  final double distanceKm;

  const Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.imageUrl,
    this.placeId,
    this.currentCrowdLevel = CrowdLevel.medium,
    this.reportCount = 0,
    this.lastReportedAt,
    this.averageWaitMinutes = 0.0,
    this.predictions = const [],
    this.isFavorite = false,
    this.distanceKm = 0.0,
  });

  Venue copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? category,
    String? imageUrl,
    String? placeId,
    CrowdLevel? currentCrowdLevel,
    int? reportCount,
    DateTime? lastReportedAt,
    double? averageWaitMinutes,
    List<HourlyPrediction>? predictions,
    bool? isFavorite,
    double? distanceKm,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      placeId: placeId ?? this.placeId,
      currentCrowdLevel: currentCrowdLevel ?? this.currentCrowdLevel,
      reportCount: reportCount ?? this.reportCount,
      lastReportedAt: lastReportedAt ?? this.lastReportedAt,
      averageWaitMinutes: averageWaitMinutes ?? this.averageWaitMinutes,
      predictions: predictions ?? this.predictions,
      isFavorite: isFavorite ?? this.isFavorite,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

/// Hourly crowd prediction
class HourlyPrediction {
  final int hour;          // 0-23
  final double crowdScore; // 0.0-1.0
  final double confidence; // 0.0-1.0

  const HourlyPrediction({
    required this.hour,
    required this.crowdScore,
    required this.confidence,
  });
}

/// Venue category for filtering
enum VenueCategory {
  grocery,
  restaurant,
  gym,
  retail,
  pharmacy,
  bank,
  postOffice,
  dmv,
  hospital,
  airport,
  transit,
  entertainment,
  coffeeshop,
  other,
}

/// Extension to get display names and icons
extension VenueCategoryExtension on VenueCategory {
  String get displayName {
    switch (this) {
      case VenueCategory.grocery: return 'Grocery';
      case VenueCategory.restaurant: return 'Restaurant';
      case VenueCategory.gym: return 'Gym & Fitness';
      case VenueCategory.retail: return 'Retail Store';
      case VenueCategory.pharmacy: return 'Pharmacy';
      case VenueCategory.bank: return 'Bank';
      case VenueCategory.postOffice: return 'Post Office';
      case VenueCategory.dmv: return 'DMV';
      case VenueCategory.hospital: return 'Hospital';
      case VenueCategory.airport: return 'Airport';
      case VenueCategory.transit: return 'Transit';
      case VenueCategory.entertainment: return 'Entertainment';
      case VenueCategory.coffeeshop: return 'Coffee Shop';
      case VenueCategory.other: return 'Other';
    }
  }
  
  String get icon {
    switch (this) {
      case VenueCategory.grocery: return '🛒';
      case VenueCategory.restaurant: return '🍽️';
      case VenueCategory.gym: return '💪';
      case VenueCategory.retail: return '🛍️';
      case VenueCategory.pharmacy: return '💊';
      case VenueCategory.bank: return '🏦';
      case VenueCategory.postOffice: return '📮';
      case VenueCategory.dmv: return '🚗';
      case VenueCategory.hospital: return '🏥';
      case VenueCategory.airport: return '✈️';
      case VenueCategory.transit: return '🚇';
      case VenueCategory.entertainment: return '🎭';
      case VenueCategory.coffeeshop: return '☕';
      case VenueCategory.other: return '📍';
    }
  }
}

/// Extension to get crowd level details
extension CrowdLevelExtension on CrowdLevel {
  String get displayName {
    switch (this) {
      case CrowdLevel.low: return 'Low';
      case CrowdLevel.medium: return 'Medium';
      case CrowdLevel.high: return 'High';
      case CrowdLevel.veryHigh: return 'Very High';
    }
  }
  
  String get description {
    switch (this) {
      case CrowdLevel.low: return 'Great time to visit!';
      case CrowdLevel.medium: return 'Moderate activity';
      case CrowdLevel.high: return 'Busy right now';
      case CrowdLevel.veryHigh: return 'Very crowded';
    }
  }

  Color get color {
    switch (this) {
      case CrowdLevel.low: return AppColors.crowdLow;
      case CrowdLevel.medium: return AppColors.crowdMedium;
      case CrowdLevel.high: return AppColors.crowdHigh;
      case CrowdLevel.veryHigh: return AppColors.crowdVeryHigh;
    }
  }
}
