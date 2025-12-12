/// User data model for profile and statistics
class UserData {
  final String id;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final String? bio; // New field
  final DateTime createdAt;
  final int totalReports;
  final int reportAccuracy;
  final int totalMinutesSaved;
  final int currentStreak;
  final int longestStreak;
  final int contributionPoints;
  final List<String> favoriteVenueIds;
  final List<String> interests;
  final BadgeLevel badgeLevel;
  final DateTime? lastActiveAt;
  final bool hasCompletedOnboarding;
  final bool notificationsEnabled;
  final bool locationSharingEnabled;

  const UserData({
    required this.id,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.bio,
    required this.createdAt,
    this.totalReports = 0,
    this.reportAccuracy = 0,
    this.totalMinutesSaved = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.contributionPoints = 0,
    this.favoriteVenueIds = const [],
    this.interests = const [],
    this.badgeLevel = BadgeLevel.newcomer,
    this.lastActiveAt,
    this.hasCompletedOnboarding = false,
    this.notificationsEnabled = true,
    this.locationSharingEnabled = true,
  });

  UserData copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    String? bio,
    DateTime? createdAt,
    int? totalReports,
    int? reportAccuracy,
    int? totalMinutesSaved,
    int? currentStreak,
    int? longestStreak,
    int? contributionPoints,
    List<String>? favoriteVenueIds,
    List<String>? interests,
    BadgeLevel? badgeLevel,
    DateTime? lastActiveAt,
    bool? hasCompletedOnboarding,
    bool? notificationsEnabled,
    bool? locationSharingEnabled,
  }) {
    return UserData(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      totalReports: totalReports ?? this.totalReports,
      reportAccuracy: reportAccuracy ?? this.reportAccuracy,
      totalMinutesSaved: totalMinutesSaved ?? this.totalMinutesSaved,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      contributionPoints: contributionPoints ?? this.contributionPoints,
      favoriteVenueIds: favoriteVenueIds ?? this.favoriteVenueIds,
      interests: interests ?? this.interests,
      badgeLevel: badgeLevel ?? this.badgeLevel,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'totalReports': totalReports,
      'reportAccuracy': reportAccuracy,
      'totalMinutesSaved': totalMinutesSaved,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'contributionPoints': contributionPoints,
      'favoriteVenueIds': favoriteVenueIds,
      'interests': interests,
      'badgeLevel': badgeLevel.index,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'notificationsEnabled': notificationsEnabled,
      'locationSharingEnabled': locationSharingEnabled,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map, String id) {
    return UserData(
      id: id,
      displayName: map['displayName'] ?? '',
      email: map['email'],
      photoUrl: map['photoUrl'],
      bio: map['bio'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      totalReports: map['totalReports'] ?? 0,
      reportAccuracy: map['reportAccuracy'] ?? 0,
      totalMinutesSaved: map['totalMinutesSaved'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      contributionPoints: map['contributionPoints'] ?? 0,
      favoriteVenueIds: List<String>.from(map['favoriteVenueIds'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      badgeLevel: BadgeLevel.values[map['badgeLevel'] ?? 0],
      lastActiveAt: map['lastActiveAt'] != null 
          ? DateTime.tryParse(map['lastActiveAt']) 
          : null,
      hasCompletedOnboarding: map['hasCompletedOnboarding'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      locationSharingEnabled: map['locationSharingEnabled'] ?? true,
    );
  }
}

/// User badge levels based on contribution
enum BadgeLevel {
  newcomer,      // 0-10 reports
  contributor,   // 11-50 reports
  trusted,       // 51-200 reports
  expert,        // 201-500 reports
  guardian,      // 501-1000 reports
  legend,        // 1000+ reports
}

extension BadgeLevelExtension on BadgeLevel {
  String get displayName {
    switch (this) {
      case BadgeLevel.newcomer: return 'Newcomer';
      case BadgeLevel.contributor: return 'Contributor';
      case BadgeLevel.trusted: return 'Trusted Reporter';
      case BadgeLevel.expert: return 'Crowd Expert';
      case BadgeLevel.guardian: return 'Time Guardian';
      case BadgeLevel.legend: return 'WaitLess Legend';
    }
  }
  
  String get icon {
    switch (this) {
      case BadgeLevel.newcomer: return '🌱';
      case BadgeLevel.contributor: return '⭐';
      case BadgeLevel.trusted: return '🏅';
      case BadgeLevel.expert: return '🎖️';
      case BadgeLevel.guardian: return '🛡️';
      case BadgeLevel.legend: return '👑';
    }
  }
  
  int get minReports {
    switch (this) {
      case BadgeLevel.newcomer: return 0;
      case BadgeLevel.contributor: return 11;
      case BadgeLevel.trusted: return 51;
      case BadgeLevel.expert: return 201;
      case BadgeLevel.guardian: return 501;
      case BadgeLevel.legend: return 1001;
    }
  }
}

/// User statistics for the Time Reclaim Wallet
class UserStats {
  final int todayMinutesSaved;
  final int weekMinutesSaved;
  final int monthMinutesSaved;
  final int todayReports;
  final int weekReports;
  final int monthReports;
  final int todayPoints;
  final int weekPoints;
  final int monthPoints;
  final int weekVenuesVisited;
  final int rank;

  const UserStats({
    this.todayMinutesSaved = 0,
    this.weekMinutesSaved = 0,
    this.monthMinutesSaved = 0,
    this.todayReports = 0,
    this.weekReports = 0,
    this.monthReports = 0,
    this.todayPoints = 0,
    this.weekPoints = 0,
    this.monthPoints = 0,
    this.weekVenuesVisited = 0,
    this.rank = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'todayMinutesSaved': todayMinutesSaved,
      'weekMinutesSaved': weekMinutesSaved,
      'monthMinutesSaved': monthMinutesSaved,
      'todayReports': todayReports,
      'weekReports': weekReports,
      'monthReports': monthReports,
      'todayPoints': todayPoints,
      'weekPoints': weekPoints,
      'monthPoints': monthPoints,
      'weekVenuesVisited': weekVenuesVisited,
      'rank': rank,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      todayMinutesSaved: map['todayMinutesSaved'] ?? 0,
      weekMinutesSaved: map['weekMinutesSaved'] ?? 0,
      monthMinutesSaved: map['monthMinutesSaved'] ?? 0,
      todayReports: map['todayReports'] ?? 0,
      weekReports: map['weekReports'] ?? 0,
      monthReports: map['monthReports'] ?? 0,
      todayPoints: map['todayPoints'] ?? 0,
      weekPoints: map['weekPoints'] ?? 0,
      monthPoints: map['monthPoints'] ?? 0,
      weekVenuesVisited: map['weekVenuesVisited'] ?? 0,
      rank: map['rank'] ?? 0,
    );
  }
}
