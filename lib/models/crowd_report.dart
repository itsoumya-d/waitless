import 'venue.dart';

/// Crowd report submitted by a user
class CrowdReport {
  final String id;
  final String venueId;
  final String userId;
  final CrowdLevel crowdLevel;
  final DateTime reportedAt;
  final int waitMinutes;
  final String? comment;
  final int upvotes;
  final int downvotes;
  final bool isActive;

  const CrowdReport({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.crowdLevel,
    required this.reportedAt,
    this.waitMinutes = 0,
    this.comment,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isActive = true,
  });
}

/// Quick report options for faster submissions
enum QuickReportOption {
  empty,       // Almost no one here
  fewPeople,   // A few people
  moderate,    // Normal crowd
  busy,        // Pretty busy
  packed,      // Very crowded
}

extension QuickReportOptionExtension on QuickReportOption {
  CrowdLevel toCrowdLevel() {
    switch (this) {
      case QuickReportOption.empty:
      case QuickReportOption.fewPeople:
        return CrowdLevel.low;
      case QuickReportOption.moderate:
        return CrowdLevel.medium;
      case QuickReportOption.busy:
        return CrowdLevel.high;
      case QuickReportOption.packed:
        return CrowdLevel.veryHigh;
    }
  }
  
  String get displayName {
    switch (this) {
      case QuickReportOption.empty: return 'Empty';
      case QuickReportOption.fewPeople: return 'Few People';
      case QuickReportOption.moderate: return 'Moderate';
      case QuickReportOption.busy: return 'Busy';
      case QuickReportOption.packed: return 'Packed';
    }
  }
  
  String get emoji {
    switch (this) {
      case QuickReportOption.empty: return '🟢';
      case QuickReportOption.fewPeople: return '🟡';
      case QuickReportOption.moderate: return '🟠';
      case QuickReportOption.busy: return '🔴';
      case QuickReportOption.packed: return '⛔';
    }
  }
}
