import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/services/venue_data_provider.dart';
import '../../../core/services/user_stats_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/nearby_venues.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../models/venue.dart';
import '../widgets/time_saved_banner.dart';
import '../widgets/crowd_pulse_card.dart';
import '../widgets/venue_quick_card.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedFilter = 'All';


  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(fetchNearbyVenuesProvider);
    final currentCityAsync = ref.watch(currentCityProvider);
    final location = ref.watch(currentLocationProvider).valueOrNull;
    final hasLocation = hasValidCoordinates(location?.latitude, location?.longitude);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(fetchNearbyVenuesProvider);
          ref.invalidate(currentLocationProvider);
          await Future.wait([
            ref.read(fetchNearbyVenuesProvider.future),
            ref.read(currentCityProvider.future),
          ]);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.backgroundLight,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WaitLess',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentCityAsync.when(
                          data: (city) => city ?? 'Unknown Location',
                          loading: () => 'Locating...',
                          error: (_, __) => 'Unknown Location',
                        ),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // Navigate to debounced search screen
                  context.push('/search');
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  context.push('/notifications');
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          // Time Saved Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer(
                builder: (context, ref, child) {
                  final userData = ref.watch(userDataProvider);
                  final userStatsAsync = ref.watch(userStatsStreamProvider);
                  
                  final totalSaved = userData?.totalMinutesSaved ?? 0;
                  final weekSaved = userStatsAsync.value?.weekMinutesSaved ?? 0; // Use value or 0
                  
                  return TimeSavedBanner(
                    minutesSaved: totalSaved,
                    thisWeek: weekSaved,
                  );
                },
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
            ),
          ),
          
          // Crowd Pulse Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .fadeIn(duration: 1000.ms)
                          .then()
                          .fadeOut(duration: 1000.ms),
                      const SizedBox(width: 8),
                      Text(
                        'CROWD PULSE',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/search'); // Navigate to full list/search for now
                    },
                    child: Text(
                      'View All',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Crowd Pulse Cards (horizontal scroll)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: venuesAsync.when(
                loading: () => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 5,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: ShimmerCrowdPulseCard(),
                  ),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (venues) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: venues.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CrowdPulseCard(
                        venue: venues[index],
                        onTap: () {
                          context.push('/venue/${venues[index].id}');
                        },
                      )
                          .animate(delay: (index * 100).ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: 0.3, end: 0),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Best Time to Visit Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                '📈 Best Time to Visit',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ),
          ),
          
          // Best Time Recommendations
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildRecommendation(
                        venue: 'Target',
                        recommendation: 'Go in 47 min',
                        detail: 'Crowds drop 60%',
                        icon: Icons.trending_down,
                        color: AppColors.success,
                      ),
                      const Divider(height: 24),
                      _buildRecommendation(
                        venue: 'Equinox Gym',
                        recommendation: 'Avoid until 2pm',
                        detail: 'Peak hours now',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ),
          ),
          
          // Nearby Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      hasLocation ? '📍 Nearby (5 km)' : '📍 Browse venues',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildFilterChip('All', _selectedFilter == 'All')
                          .animate(delay: 600.ms)
                          .fadeIn()
                          .slideX(begin: 0.2, end: 0),
                      const SizedBox(width: 8),
                      _buildFilterChip('Low Crowd', _selectedFilter == 'Low Crowd')
                          .animate(delay: 700.ms)
                          .fadeIn()
                          .slideX(begin: 0.2, end: 0),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            ),
          ),
          
          // Nearby Venues List
          venuesAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ShimmerVenueQuickCard(),
                  childCount: 5,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
            data: (venues) {
              final filteredVenues = _selectedFilter == 'Low Crowd'
                  ? venues.where((v) => v.currentCrowdLevel == CrowdLevel.low).toList()
                  : venues;
              
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VenueQuickCard(
                          venue: filteredVenues[index],
                          onTap: () {
                            context.push('/venue/${filteredVenues[index].id}');
                          },
                        )
                            .animate(delay: (600 + index * 100).ms)
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: 0.2, end: 0),
                      );
                    },
                    childCount: filteredVenues.length,
                  ),
                ),
              );
            },
          ),
        ],
        ),
      ),
      
      // Chat FAB and Quick Report
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Report FAB (smaller)
          FloatingActionButton.small(
            heroTag: 'report',
            onPressed: () {
              _showQuickReportSheet(context);
            },
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_location_alt, size: 20),
          ).animate().scale(delay: 700.ms, duration: 400.ms),
          const SizedBox(height: 12),
          // AI Chat FAB (primary)
          FloatingActionButton.extended(
            heroTag: 'chat',
            onPressed: () {
              context.push('/chat');
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('AI Chat'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ).animate().scale(delay: 800.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildRecommendation({
    required String venue,
    required String recommendation,
    required String detail,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                venue,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
              ),
              Text(
                recommendation,
                style: AppTypography.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Text(
          detail,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textTertiaryLight,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  void _showQuickReportSheet(BuildContext context) {
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
              'Quick Report',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us how crowded it is here',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickReportOption('🟢', 'Empty', CrowdLevel.low),
                _buildQuickReportOption('🟡', 'Moderate', CrowdLevel.medium),
                _buildQuickReportOption('🔴', 'Busy', CrowdLevel.high),
                _buildQuickReportOption('⛔', 'Packed', CrowdLevel.veryHigh),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReportOption(String emoji, String label, CrowdLevel level) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        Navigator.pop(context);
        // Update user stats
        ref.read(userDataProvider.notifier).incrementReports();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Thanks for reporting! +10 points'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
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
          Text(
            label,
            style: AppTypography.labelMedium,
          ),
        ],
      ),
    );
  }
}

