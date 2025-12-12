import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Service for social sharing functionality
class SocialSharingService {
  /// Share time saved stats
  Future<void> shareTimeSaved({
    required int totalMinutes,
    required int reportsCount,
    required int venuesVisited,
  }) async {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final timeString = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    
    final message = '''
🎉 I've saved $timeString of waiting time with WaitLess!

📊 My stats:
• Reports submitted: $reportsCount
• Venues tracked: $venuesVisited

Join me in beating the crowds! 🚀
#WaitLess #SmartShopping
''';
    
    try {
      await Share.share(message, subject: 'My WaitLess Time Saved!');
      debugPrint('📤 Shared time saved stats');
    } catch (e) {
      debugPrint('❌ Share failed: $e');
    }
  }
  
  /// Share a specific venue
  Future<void> shareVenue({
    required String venueName,
    required String crowdLevel,
    required int waitMinutes,
  }) async {
    final message = '''
📍 $venueName is currently $crowdLevel!

⏱️ Estimated wait: ~$waitMinutes min

Tracked with WaitLess - skip the crowds! 🎯
''';
    
    try {
      await Share.share(message, subject: 'Crowd Update: $venueName');
      debugPrint('📤 Shared venue status');
    } catch (e) {
      debugPrint('❌ Share failed: $e');
    }
  }
  
  /// Share weekly summary
  Future<void> shareWeeklySummary({
    required String weekRange,
    required int totalMinutes,
    required int reportsCount,
    required String topVenue,
  }) async {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final timeString = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    
    final message = '''
📊 My WaitLess Weekly Summary ($weekRange)

⏰ Time Saved: $timeString
📝 Reports: $reportsCount
🏆 Top Venue: $topVenue

Beat the crowds smarter! 💪
#WaitLess #WeeklyWins
''';
    
    try {
      await Share.share(message, subject: 'My WaitLess Week');
      debugPrint('📤 Shared weekly summary');
    } catch (e) {
      debugPrint('❌ Share failed: $e');
    }
  }
  
  /// Share achievement
  Future<void> shareAchievement({
    required String achievementName,
    required String description,
  }) async {
    final message = '''
🏆 Achievement Unlocked in WaitLess!

$achievementName
$description

Join me in saving time! 🚀
''';
    
    try {
      await Share.share(message, subject: 'WaitLess Achievement!');
    } catch (e) {
      debugPrint('❌ Share failed: $e');
    }
  }
}

/// Provider for social sharing service
final socialSharingProvider = Provider<SocialSharingService>((ref) {
  return SocialSharingService();
});
