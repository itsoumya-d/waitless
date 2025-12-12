import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_data.dart';
import 'firebase_service.dart';
import '../repositories/firestore_user_stats_repository.dart';

/// Provider for UserStatsService
final userStatsServiceProvider = Provider<UserStatsService>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final repository = FirestoreUserStatsRepository(firebaseService);
  return UserStatsService(repository, firebaseService);
});

/// Stream provider for user stats
final userStatsStreamProvider = StreamProvider<UserStats>((ref) {
  final service = ref.watch(userStatsServiceProvider);
  return service.statsStream;
});

/// Service for tracking user statistics and gamification
class UserStatsService {
  final FirestoreUserStatsRepository _repository;
  final FirebaseService _firebaseService;
  
  // Local cache of stats
  UserStats _stats = const UserStats();
  
  UserStatsService(this._repository, this._firebaseService);

  /// Get current stats
  UserStats get stats => _stats;

  /// Initialize and listen to stats stream
  Stream<UserStats> get statsStream {
    final user = _firebaseService.currentUser;
    if (user != null) {
      return _repository.streamUserStats(user.uid).map((stats) {
        _stats = stats;
        return stats;
      });
    }
    return Stream.value(_stats);
  }
  
  /// Add minutes saved
  Future<void> addMinutesSaved(int minutes) async {
    _stats = UserStats(
      todayMinutesSaved: _stats.todayMinutesSaved + minutes,
      weekMinutesSaved: _stats.weekMinutesSaved + minutes,
      monthMinutesSaved: _stats.monthMinutesSaved + minutes,
      todayReports: _stats.todayReports,
      weekReports: _stats.weekReports,
      monthReports: _stats.monthReports,
      todayPoints: _stats.todayPoints,
      weekPoints: _stats.weekPoints,
      monthPoints: _stats.monthPoints,
      weekVenuesVisited: _stats.weekVenuesVisited,
      rank: _stats.rank,
    );
    await _syncToFirebase();
  }
  
  /// Add a report
  Future<void> addReport({int points = 10}) async {
    _stats = UserStats(
      todayMinutesSaved: _stats.todayMinutesSaved,
      weekMinutesSaved: _stats.weekMinutesSaved,
      monthMinutesSaved: _stats.monthMinutesSaved,
      todayReports: _stats.todayReports + 1,
      weekReports: _stats.weekReports + 1,
      monthReports: _stats.monthReports + 1,
      todayPoints: _stats.todayPoints + points,
      weekPoints: _stats.weekPoints + points,
      monthPoints: _stats.monthPoints + points,
      weekVenuesVisited: _stats.weekVenuesVisited,
      rank: _stats.rank,
    );
    await _syncToFirebase();
  }
  
  /// Add points (for activities, upvotes, etc.)
  Future<void> addPoints(int points) async {
    _stats = UserStats(
      todayMinutesSaved: _stats.todayMinutesSaved,
      weekMinutesSaved: _stats.weekMinutesSaved,
      monthMinutesSaved: _stats.monthMinutesSaved,
      todayReports: _stats.todayReports,
      weekReports: _stats.weekReports,
      monthReports: _stats.monthReports,
      todayPoints: _stats.todayPoints + points,
      weekPoints: _stats.weekPoints + points,
      monthPoints: _stats.monthPoints + points,
      weekVenuesVisited: _stats.weekVenuesVisited,
      rank: _stats.rank,
    );
    await _syncToFirebase();
  }
  
  /// Track a venue visit
  Future<void> trackVenueVisit() async {
    _stats = UserStats(
      todayMinutesSaved: _stats.todayMinutesSaved,
      weekMinutesSaved: _stats.weekMinutesSaved,
      monthMinutesSaved: _stats.monthMinutesSaved,
      todayReports: _stats.todayReports,
      weekReports: _stats.weekReports,
      monthReports: _stats.monthReports,
      todayPoints: _stats.todayPoints,
      weekPoints: _stats.weekPoints,
      monthPoints: _stats.monthPoints,
      weekVenuesVisited: _stats.weekVenuesVisited + 1,
      rank: _stats.rank,
    );
    await _syncToFirebase();
  }

  /// Update rank from leaderboard
  Future<void> updateRank(int newRank) async {
    _stats = UserStats(
      todayMinutesSaved: _stats.todayMinutesSaved,
      weekMinutesSaved: _stats.weekMinutesSaved,
      monthMinutesSaved: _stats.monthMinutesSaved,
      todayReports: _stats.todayReports,
      weekReports: _stats.weekReports,
      monthReports: _stats.monthReports,
      todayPoints: _stats.todayPoints,
      weekPoints: _stats.weekPoints,
      monthPoints: _stats.monthPoints,
      weekVenuesVisited: _stats.weekVenuesVisited,
      rank: newRank,
    );
    // Rank usually comes from server, so maybe no sync needed back, but consistent state is good
    await _syncToFirebase();
  }
  
  /// Reset daily stats (called at midnight)
  void resetDailyStats() {
    _stats = UserStats(
      todayMinutesSaved: 0,
      weekMinutesSaved: _stats.weekMinutesSaved,
      monthMinutesSaved: _stats.monthMinutesSaved,
      todayReports: 0,
      weekReports: _stats.weekReports,
      monthReports: _stats.monthReports,
      todayPoints: 0,
      weekPoints: _stats.weekPoints,
      monthPoints: _stats.monthPoints,
      weekVenuesVisited: _stats.weekVenuesVisited,
      rank: _stats.rank,
    );
    _syncToFirebase();
  }
  
  /// Reset weekly stats (called on Monday)
  void resetWeeklyStats() {
    _stats = UserStats(
      todayMinutesSaved: _stats.todayMinutesSaved,
      weekMinutesSaved: 0,
      monthMinutesSaved: _stats.monthMinutesSaved,
      todayReports: _stats.todayReports,
      weekReports: 0,
      monthReports: _stats.monthReports,
      todayPoints: _stats.todayPoints,
      weekPoints: 0,
      monthPoints: _stats.monthPoints,
      weekVenuesVisited: 0,
      rank: _stats.rank,
    );
    _syncToFirebase();
  }
  
  /// Sync to Firebase
  Future<void> _syncToFirebase() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      await _repository.syncUserStats(user.uid, _stats);
    }
  }

  /// Calculate streak continuation
  Future<int> updateStreak({
    required DateTime lastActiveDate,
    required int currentStreak,
  }) async {
    final now = DateTime.now();
    final difference = now.difference(lastActiveDate).inDays;
    
    if (difference == 0) {
      // Same day, no change
      return currentStreak;
    } else if (difference == 1) {
      // Next day, increment streak
      return currentStreak + 1;
    } else {
      // Streak broken
      return 1;
    }
  }
  
  // Mock data removed to force real Firestore usage
  static UserStats getMockStats() {
    return const UserStats(); // Return empty defaults if called fallback
  }
}

