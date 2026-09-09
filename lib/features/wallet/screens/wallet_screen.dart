import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/user_stats_service.dart';




/// Time Reclaim Wallet screen
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsStreamProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Wallet'),
        backgroundColor: AppColors.backgroundLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () {
              context.go('/wallet/leaderboard');
            },
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading stats: $e')),
        data: (stats) {
          // Format time saved
          final totalMinutes = stats.monthMinutesSaved;
          final hours = totalMinutes ~/ 60;
          final minutes = totalMinutes % 60;
          final timeString = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time saved hero card
                GestureDetector(
                  onTap: () {
                    context.go('/wallet/weekly');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.access_time_filled,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          timeString,
                          style: AppTypography.timeSaved.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total Time Reclaimed',
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 12),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('${stats.weekMinutesSaved}m', 'This Week'),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            _buildStat('7', 'Day Streak 🔥'), // TODO: Real streak
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            _buildStat('#${stats.rank}', 'City Rank'),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 24),
                
                // Points section
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        value: '${stats.monthPoints}',
                        label: 'Points',
                        color: AppColors.secondary,
                        icon: Icons.stars_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        value: '${stats.monthReports}',
                        label: 'Reports',
                        color: AppColors.accent,
                        icon: Icons.fact_check_outlined,
                      ),
                    ),
                  ],
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 400.ms),
                
                const SizedBox(height: 24),
                
                // Badge section
                Text(
                  'Your Badge',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildBadgeCard()
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 400.ms),
                
                const SizedBox(height: 24),
                
                // Achievements
                Text(
                  'Achievements',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildAchievementsRow()
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 400.ms),
                
                const SizedBox(height: 24),
                
                // Recent activity
                Text(
                  'Recent Activity',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 12),
                
                ..._buildRecentActivities(),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.statValue.copyWith(
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBadgeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('⭐', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contributor',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Submit 4 more reports to reach Trusted',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.86,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAchievementsRow() {
    final achievements = [
      {'icon': '🌟', 'name': 'First Report', 'unlocked': true},
      {'icon': '🔥', 'name': '7-Day Streak', 'unlocked': true},
      {'icon': '📍', 'name': '10 Venues', 'unlocked': true},
      {'icon': '👑', 'name': 'Top 100', 'unlocked': false},
      {'icon': '🎯', 'name': '100 Reports', 'unlocked': false},
    ];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: achievements.map((a) {
          final unlocked = a['unlocked'] as bool;
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: unlocked 
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.textTertiaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: unlocked 
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      a['icon'] as String,
                      style: TextStyle(
                        fontSize: 28,
                        color: unlocked ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  a['name'] as String,
                  style: AppTypography.labelSmall.copyWith(
                    color: unlocked 
                        ? AppColors.textPrimaryLight 
                        : AppColors.textTertiaryLight,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  List<Widget> _buildRecentActivities() {
    final activities = [
      {'icon': Icons.add_location, 'title': 'Reported at Trader Joe\'s', 'value': '+10 points', 'time': '2 min ago'},
      {'icon': Icons.access_time, 'title': 'Saved 12 min at Target', 'value': '+12 min saved', 'time': '1 hour ago'},
      {'icon': Icons.thumb_up, 'title': 'Report upvoted 3 times', 'value': '+15 points', 'time': '3 hours ago'},
      {'icon': Icons.emoji_events, 'title': 'Unlocked "7-Day Streak"', 'value': '+50 points', 'time': 'Yesterday'},
    ];
    
    return activities.asMap().entries.map((entry) {
      final index = entry.key;
      final a = entry.value;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(a['icon'] as IconData, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['title'] as String, style: AppTypography.labelMedium),
                  Text(
                    a['time'] as String,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              a['value'] as String,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.success,
              ),
            ),
          ],
        ),
      )
          .animate(delay: (500 + index * 100).ms)
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.1, end: 0);
    }).toList();
  }
  

}
