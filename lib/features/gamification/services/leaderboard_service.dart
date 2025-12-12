import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/venue_data_provider.dart';
import '../../../models/user_data.dart';

class LeaderboardEntry {
  final String id;
  final String name;
  final String avatarUrl;
  final int points;
  final int rank;
  final String badge;

  LeaderboardEntry({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.points,
    required this.rank,
    required this.badge,
  });
}

class LeaderboardService {
  final FirebaseFirestore? _firestore;
  final DataSourceMode _mode;

  LeaderboardService(this._firestore, this._mode);

  Future<List<LeaderboardEntry>> getGlobalLeaderboard() async {
    if (_mode == DataSourceMode.mock || _firestore == null) {
      return _getMockLeaderboard();
    }

    try {
      final snapshot = await _firestore!
          .collection('users')
          .orderBy('contributionPoints', descending: true)
          .limit(50)
          .get();

      final entries = <LeaderboardEntry>[];
      int rank = 1;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final points = data['contributionPoints'] as int? ?? 0;
        final badgeIndex = data['badgeLevel'] as int? ?? 0;
        final badge = BadgeLevel.values[badgeIndex].displayName;
        
        entries.add(LeaderboardEntry(
          id: doc.id,
          name: data['displayName'] as String? ?? 'Anonymous',
          avatarUrl: data['photoUrl'] as String? ?? 'https://i.pravatar.cc/150?u=${doc.id}',
          points: points,
          rank: rank++,
          badge: badge,
        ));
      }
      
      return entries;
    } catch (e) {
      // Fallback to mock on error or if collection is empty/permission denied
      return _getMockLeaderboard();
    }
  }

  Future<List<LeaderboardEntry>> _getMockLeaderboard() async {
    // Mock network delay
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      LeaderboardEntry(
        id: '1',
        name: 'Sarah Connor',
        avatarUrl: 'https://i.pravatar.cc/150?u=1',
        points: 12500,
        rank: 1,
        badge: '👑 Legend',
      ),
      LeaderboardEntry(
        id: '2',
        name: 'Mike Ross',
        avatarUrl: 'https://i.pravatar.cc/150?u=2',
        points: 9800,
        rank: 2,
        badge: '🛡️ Guardian',
      ),
      LeaderboardEntry(
        id: '3',
        name: 'Jessica Pearson',
        avatarUrl: 'https://i.pravatar.cc/150?u=3',
        points: 8450,
        rank: 3,
        badge: '⭐ Expert',
      ),
      LeaderboardEntry(
        id: '4',
        name: 'Harvey Specter',
        avatarUrl: 'https://i.pravatar.cc/150?u=4',
        points: 7200,
        rank: 4,
        badge: '⭐ Expert',
      ),
      LeaderboardEntry(
        id: '5',
        name: 'Louis Litt',
        avatarUrl: 'https://i.pravatar.cc/150?u=5',
        points: 6100,
        rank: 5,
        badge: '🤝 Trusted',
      ),
       LeaderboardEntry(
        id: '6',
        name: 'Rachel Zane',
        avatarUrl: 'https://i.pravatar.cc/150?u=6',
        points: 5400,
        rank: 6,
        badge: '🤝 Trusted',
      ),
      LeaderboardEntry(
        id: '7',
        name: 'Donna Paulsen',
        avatarUrl: 'https://i.pravatar.cc/150?u=7',
        points: 4300,
        rank: 7,
        badge: '👶 Contributor',
      ),
    ];
  }
}

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  final mode = ref.watch(dataSourceModeProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  
  return LeaderboardService(
    firebaseService.isInitialized ? firebaseService.firestore : null,
    mode,
  );
});

final globalLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getGlobalLeaderboard();
});
