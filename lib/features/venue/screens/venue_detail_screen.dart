import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/social_sharing_service.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/venue_data_provider.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/services/user_stats_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../models/venue.dart';
import '../widgets/interactive_prediction_chart.dart';
import '../widgets/live_crowd_reports.dart';
import '../../../core/widgets/celebration_widgets.dart';

/// Venue detail screen with predictions and reporting
class VenueDetailScreen extends ConsumerStatefulWidget {
  final String venueId;
  
  const VenueDetailScreen({
    super.key,
    required this.venueId,
  });

  @override
  ConsumerState<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends ConsumerState<VenueDetailScreen> {
  bool _showConfetti = false;

  void _triggerCelebration() {
    setState(() => _showConfetti = true);
  }

  @override
  Widget build(BuildContext context) {
    final venueAsync = ref.watch(venueByIdProvider(widget.venueId));
    final predictionsAsync = ref.watch(venuePredictionsProvider(widget.venueId));
    
    return Scaffold(
      body: Stack(
        children: [
          venueAsync.when(
        loading: () => _buildLoadingState(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (venue) {
          if (venue == null) {
            return const Center(child: Text('Venue not found'));
          }
          
          return CustomScrollView(
            slivers: [
              // Hero header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: _getCrowdGradient(venue.currentCrowdLevel),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          Text(
                            _getCategoryEmoji(venue.category),
                            style: const TextStyle(fontSize: 64),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: AppTheme.glassBoxDecoration(
                              context: context,
                              radius: 30,
                              borderColor: Colors.white.withValues(alpha: 0.3),
                            ),
                            child: Text(
                              venue.currentCrowdLevel.displayName.toUpperCase(),
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.white),
                    onPressed: () {
                      HapticService.favorite();
                      ref.read(favoriteVenueIdsProvider.notifier).toggleFavorite(venue.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Added to favorites!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref.read(socialSharingProvider).shareVenue(
                        venueName: venue.name,
                        crowdLevel: venue.currentCrowdLevel.displayName,
                        waitMinutes: venue.averageWaitMinutes.round(),
                      );
                    },
                  ),
                ],
              ),
              
              // Venue info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.name,
                        style: AppTypography.headlineMedium,
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              venue.address,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                      
                      const SizedBox(height: 20),
                      
                      // Current crowd level card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: _getCrowdGradient(venue.currentCrowdLevel),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _getCrowdGradient(venue.currentCrowdLevel).colors.first.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people_outline,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Currently ${venue.currentCrowdLevel.displayName}',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    venue.currentCrowdLevel.description,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (venue.averageWaitMinutes > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: AppTheme.glassBoxDecoration(
                                  context: context,
                                  radius: 20,
                                  borderColor: Colors.white.withValues(alpha: 0.2),
                                ),
                                child: Text(
                                  '~${venue.averageWaitMinutes.round()} min',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                      
                      const SizedBox(height: 24),
                      
                      // Predictions section
                      Text(
                        'Today\'s Forecast',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      
                      // Prediction chart with interactive tooltip
                      predictionsAsync.when(
                        loading: () => const ShimmerPredictionChart(),
                        error: (e, _) => const Text('Error loading predictions'),
                        data: (predictions) => Column(
                          children: [
                            InteractivePredictionChart(
                              predictions: predictions,
                              currentHour: DateTime.now().hour,
                            ),
                            const SizedBox(height: 8),
                            const PredictionChartLegend(),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Best times
                      Text(
                        'Best Times to Visit',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      
                      predictionsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => const SizedBox(),
                        data: (predictions) {
                          final repo = ref.read(venueRepositoryProvider);
                          final bestTimes = repo.getBestTimesToVisit(predictions);
                          return Column(
                            children: bestTimes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final time = entry.value;
                              return _buildTimeSlot(
                                time['time'] as String,
                                time['description'] as String,
                                _getColorForScore(time['crowdScore'] as double),
                              ).animate(delay: (400 + index * 100).ms).fadeIn(duration: 300.ms);
                            }).toList(),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Live reports with real-time updates
                      LiveCrowdReports(venueId: venue.id),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ConfettiCelebration(
        isActive: _showConfetti,
        onComplete: () {
          if (mounted) setState(() => _showConfetti = false);
        },
      ),
    ],
  ),
      
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              _showReportSheet(context, ref);
            },
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Report Current Crowd'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimeSlot(String time, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              time,
              style: AppTypography.labelLarge,
            ),
            const Spacer(),
            Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showReportSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiaryLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Report Crowd Level',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'How crowded is it right now?',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildReportOption(context, ref, '🟢', 'Empty', CrowdLevel.low),
                _buildReportOption(context, ref, '🟡', 'Moderate', CrowdLevel.medium),
                _buildReportOption(context, ref, '🔴', 'Busy', CrowdLevel.high),
                _buildReportOption(context, ref, '⛔', 'Packed', CrowdLevel.veryHigh),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReportOption(BuildContext context, WidgetRef ref, String emoji, String label, CrowdLevel level) {
    return GestureDetector(
      onTap: () async {
        HapticService.crowdReportSubmitted();
        Navigator.pop(context);
        
        // Optimistic UI updates
        _triggerCelebration(); 
        ref.read(userDataProvider.notifier).incrementReports();
        
        // Show success immediately
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thanks for reporting! +10 points'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Submit to backend (fire and forget for responsiveness, or handle error silently)
        try {
          // 1. Submit report to venue
          await ref.read(venueRepositoryProvider).submitCrowdReport(
            venueId: widget.venueId,
            crowdLevel: level,
          );
          
          // 2. Update user stats in Firestore
          await ref.read(userStatsServiceProvider).addReport();
        } catch (e) {
          debugPrint('Error submitting report: $e');
        }
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.textTertiaryLight.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
  
  LinearGradient _getCrowdGradient(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return AppColors.crowdLowGradient;
      case CrowdLevel.medium:
        return AppColors.crowdMediumGradient;
      case CrowdLevel.high:
      case CrowdLevel.veryHigh:
        return AppColors.crowdHighGradient;
    }
  }
  
  Color _getColorForScore(double score) {
    if (score < 0.3) return AppColors.crowdLow;
    if (score < 0.6) return AppColors.crowdMedium;
    return AppColors.crowdHigh;
  }
  
  String _getCategoryEmoji(String category) {
    final cat = VenueCategory.values.firstWhere(
      (c) => c.name == category,
      orElse: () => VenueCategory.other,
    );
    return cat.icon;
  }
  
  /// Build a shimmer loading skeleton for the venue detail screen
  Widget _buildLoadingState() {
    return const ShimmerVenueDetail();
  }
}
