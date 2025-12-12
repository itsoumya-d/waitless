import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/activity_repository.dart';
import '../../../models/wait_activity.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import 'activity_launch_screen.dart';

/// Provider for activity repository
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

/// Provider for featured activities
final featuredActivitiesProvider = FutureProvider<List<WaitActivity>>((ref) async {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.getFeaturedActivities();
});

/// Provider for activities by type
final activitiesByTypeProvider = FutureProvider.family<List<WaitActivity>, ActivityType>((ref, type) async {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.getActivitiesByType(type);
});

/// Activities screen for wait-time content
class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  ActivityType? _selectedType;
  
  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(featuredActivitiesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wait Activities'),
        backgroundColor: AppColors.backgroundLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detection banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Not waiting anywhere',
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Activities will appear when you\'re in a queue',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
            
            // Activity categories
            Text(
              'Browse Activities',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildCategoryCard(
                  ActivityType.microLearning,
                  '📚',
                  'Learn',
                  'Quick lessons',
                  AppColors.primary,
                ),
                _buildCategoryCard(
                  ActivityType.entertainment,
                  '🎮',
                  'Play',
                  'Mini games',
                  AppColors.accent,
                ),
                _buildCategoryCard(
                  ActivityType.mindfulness,
                  '🧘',
                  'Breathe',
                  'Calm & relax',
                  AppColors.secondary,
                ),
                _buildCategoryCard(
                  ActivityType.productivity,
                  '✅',
                  'Do',
                  'Productivity',
                  AppColors.info,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Featured activities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedType != null 
                      ? '${_selectedType!.displayName} Activities' 
                      : 'Featured',
                  style: AppTypography.titleMedium,
                ),
                if (_selectedType != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedType = null),
                    child: const Text('Clear filter'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Activity list
            _selectedType != null
                ? _buildFilteredActivities(_selectedType!)
                : _buildFeaturedActivities(featuredAsync),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilteredActivities(ActivityType type) {
    final activitiesAsync = ref.watch(activitiesByTypeProvider(type));
    
    return activitiesAsync.when(
      loading: () => ShimmerLoadingList(
        itemCount: 5,
        itemBuilder: (context, index) => const ShimmerActivityCard(),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (activities) => Column(
        children: activities.map((activity) => _buildActivityCard(activity)).toList(),
      ),
    );
  }
  
  Widget _buildFeaturedActivities(AsyncValue<List<WaitActivity>> featuredAsync) {
    return featuredAsync.when(
      loading: () => ShimmerLoadingList(
        itemCount: 4,
        itemBuilder: (context, index) => const ShimmerActivityCard(),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (activities) => Column(
        children: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          return _buildActivityCard(activity)
              .animate(delay: (index * 100).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.2, end: 0);
        }).toList(),
      ),
    );
  }
  
  Widget _buildCategoryCard(
    ActivityType type,
    String emoji,
    String title,
    String subtitle,
    Color color,
  ) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        // Navigate to specialized screens for enhanced activities
        switch (type) {
          case ActivityType.entertainment:
            context.push('/games');
            return;
          case ActivityType.mindfulness:
            context.push('/breathing');
            return;
          case ActivityType.microLearning:
            // Show vocabulary/trivia options
            _showLearningOptions();
            return;
          case ActivityType.productivity:
            // For now, just filter the list
            setState(() {
              _selectedType = _selectedType == type ? null : type;
            });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isSelected ? 1 : 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: isSelected ? Colors.white : color,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected 
                    ? Colors.white.withValues(alpha: 0.8) 
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showLearningOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Learning Type', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('📖', style: TextStyle(fontSize: 24))),
              ),
              title: const Text('Vocabulary'),
              subtitle: const Text('Learn 5 new words'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                context.push('/vocabulary');
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('❓', style: TextStyle(fontSize: 24))),
              ),
              title: const Text('Trivia Quiz'),
              subtitle: const Text('Test your knowledge'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                context.push('/trivia');
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityCard(WaitActivity activity) {
    final durationMinutes = (activity.durationSeconds / 60).ceil();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showActivityDetail(activity);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      activity.type.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activity.isSponsored)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SPONSORED',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.accent,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      Text(activity.title, style: AppTypography.titleSmall),
                      Text(
                        '$durationMinutes min • ${activity.type.displayName}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showActivityDetail(WaitActivity activity) {
    final durationMinutes = (activity.durationSeconds / 60).ceil();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppColors.textTertiaryLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              activity.type.icon,
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.title,
                                style: AppTypography.headlineSmall,
                              ),
                              Text(
                                '$durationMinutes min • ${activity.type.displayName}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Description
                    Text(
                      activity.description,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activity.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tag,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const Spacer(),
                    
                    // Start button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          HapticFeedback.mediumImpact();
                          // Navigate to full activity launch screen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ActivityLaunchScreen(activity: activity),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Activity'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Points info
                    Center(
                      child: Text(
                        '+5 points on completion',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
