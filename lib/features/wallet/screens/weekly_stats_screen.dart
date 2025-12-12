import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/social_sharing_service.dart';
import '../../../core/services/user_stats_service.dart';
import '../../../models/user_data.dart';

/// Weekly stats summary screen
class WeeklyStatsScreen extends ConsumerWidget {
  const WeeklyStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsStreamProvider);
    final stats = statsAsync.value ?? const UserStats(); // Simplified fallback for UI
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Summary'),
        backgroundColor: AppColors.backgroundLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(stats),
            const SizedBox(height: 24),
            
            // Time saved breakdown
            _buildSection('Time Saved This Week', [
              _buildDayBar('Mon', 15),
              _buildDayBar('Tue', 8),
              _buildDayBar('Wed', 22),
              _buildDayBar('Thu', 12),
              _buildDayBar('Fri', 18),
              _buildDayBar('Sat', 30),
              _buildDayBar('Sun', 25),
            ]),
            const SizedBox(height: 24),
            
            // Top venues
            _buildSection('Your Top Venues', [
              _buildVenueRow('🛒', 'Trader Joe\'s', '45 min saved', 1),
              _buildVenueRow('💪', 'LA Fitness', '32 min saved', 2),
              _buildVenueRow('☕', 'Starbucks', '28 min saved', 3),
            ]),
            const SizedBox(height: 24),
            
            // Achievements
            _buildSection('Achievements', [
              _buildAchievement('🔥', 'Week Streak', '7 days in a row!'),
              _buildAchievement('📊', 'Data Hero', '10 reports submitted'),
              _buildAchievement('⏰', 'Time Saver', '2+ hours saved'),
            ]),
            const SizedBox(height: 24),
            
            // Share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  // In a real app, this would use actual user stats
                  ref.read(socialSharingProvider).shareWeeklySummary(
                    weekRange: 'Dec 4 - Dec 10',
                    totalMinutes: 135, // 2h 15m
                    reportsCount: 12,
                    topVenue: 'Trader Joe\'s',
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Your Stats'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(UserStats stats) {
    final hours = stats.weekMinutesSaved ~/ 60;
    final mins = stats.weekMinutesSaved % 60;
    final timeString = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'This Week',
            style: AppTypography.labelMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            timeString,
            style: AppTypography.displayLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Total time saved',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Reports', '${stats.weekReports}'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildMiniStat('Venues', '${stats.weekVenuesVisited}'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildMiniStat('Rank', '#${stats.rank}'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleMedium),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDayBar(String day, int minutes) {
    final maxMinutes = 30;
    final percentage = (minutes / maxMinutes).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              day,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '${minutes}m',
              style: AppTypography.labelMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueRow(String emoji, String name, String saved, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.labelLarge),
                Text(
                  saved,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(String emoji, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelLarge),
              Text(
                desc,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
