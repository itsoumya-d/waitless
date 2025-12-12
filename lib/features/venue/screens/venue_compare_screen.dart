import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/services/venue_data_provider.dart';
import '../../../models/venue.dart';

/// Venue comparison screen
class VenueCompareScreen extends ConsumerStatefulWidget {
  const VenueCompareScreen({super.key});

  @override
  ConsumerState<VenueCompareScreen> createState() => _VenueCompareScreenState();
}

class _VenueCompareScreenState extends ConsumerState<VenueCompareScreen> {
  Venue? _venue1;
  Venue? _venue2;

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(fetchNearbyVenuesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Venues'),
        backgroundColor: AppColors.backgroundLight,
      ),
      body: venuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (venues) => _buildContent(venues),
      ),
    );
  }

  Widget _buildContent(List<Venue> venues) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Venue selectors
          Row(
            children: [
              Expanded(child: _buildVenueSelector(1, _venue1, venues)),
              const SizedBox(width: 16),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.compare_arrows, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildVenueSelector(2, _venue2, venues)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Comparison
          if (_venue1 != null && _venue2 != null) ...[
            _buildComparisonTable(),
            const SizedBox(height: 24),
            _buildRecommendation(),
          ] else ...[
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildVenueSelector(int index, Venue? selected, List<Venue> venues) {
    return GestureDetector(
      onTap: () => _showVenuePicker(index, venues),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected != null ? Colors.white : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected != null 
                ? AppColors.primary.withValues(alpha: 0.3) 
                : AppColors.textTertiaryLight.withValues(alpha: 0.3),
          ),
          boxShadow: selected != null
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]
              : null,
        ),
        child: Column(
          children: [
            if (selected != null) ...[
              Text(
                _getCategoryEmoji(selected),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                selected.name,
                style: AppTypography.labelLarge,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _buildCrowdBadge(selected.currentCrowdLevel, compact: true),
            ] else ...[
              const Icon(
                Icons.add_circle_outline,
                size: 32,
                color: AppColors.textTertiaryLight,
              ),
              const SizedBox(height: 8),
              Text(
                'Select Venue $index',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    final v1 = _venue1!;
    final v2 = _venue2!;
    
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildCompareRow('Crowd Level', v1.currentCrowdLevel.displayName, v2.currentCrowdLevel.displayName, 
            v1Win: v1.currentCrowdLevel.index < v2.currentCrowdLevel.index),
          const Divider(height: 1),
          _buildCompareRow('Wait Time', '${v1.averageWaitMinutes.round()} min', '${v2.averageWaitMinutes.round()} min',
            v1Win: v1.averageWaitMinutes < v2.averageWaitMinutes),
          const Divider(height: 1),
          _buildCompareRow('Reports', '${v1.reportCount}', '${v2.reportCount}',
            v1Win: v1.reportCount > v2.reportCount),
          const Divider(height: 1),
          _buildCompareRow('Distance', '${v1.distanceKm.toStringAsFixed(1)} km', 
            '${v2.distanceKm.toStringAsFixed(1)} km',
            v1Win: v1.distanceKm < v2.distanceKm),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCompareRow(String label, String v1Value, String v2Value, {bool? v1Win}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: v1Win == true ? AppColors.success.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (v1Win == true)
                    const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const Spacer(),
                  Text(
                    v1Value,
                    style: AppTypography.labelMedium.copyWith(
                      color: v1Win == true ? AppColors.success : null,
                      fontWeight: v1Win == true ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 100,
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: v1Win == false ? AppColors.success.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    v2Value,
                    style: AppTypography.labelMedium.copyWith(
                      color: v1Win == false ? AppColors.success : null,
                      fontWeight: v1Win == false ? FontWeight.bold : null,
                    ),
                  ),
                  const Spacer(),
                  if (v1Win == false)
                    const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation() {
    final v1 = _venue1!;
    final v2 = _venue2!;
    
    // Simple scoring
    int v1Score = 0;
    int v2Score = 0;
    
    if (v1.currentCrowdLevel.index < v2.currentCrowdLevel.index) {
      v1Score++; 
    } else if (v1.currentCrowdLevel.index > v2.currentCrowdLevel.index) {
      v2Score++;
    }
    
    if (v1.averageWaitMinutes < v2.averageWaitMinutes) {
      v1Score++; 
    } else if (v1.averageWaitMinutes > v2.averageWaitMinutes) {
      v2Score++;
    }
    
    if (v1.distanceKm < v2.distanceKm) {
      v1Score++; 
    } else if (v1.distanceKm > v2.distanceKm) {
      v2Score++;
    }
    
    final winner = v1Score > v2Score ? v1 : (v2Score > v1Score ? v2 : v1); // Default to v1 on tie

    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
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
            child: const Icon(Icons.stars, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommendation',
                  style: AppTypography.labelMedium.copyWith(color: Colors.white70),
                ),
                Text(
                  'Go to ${winner.name}',
                  style: AppTypography.titleMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/venue/${winner.id}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('View'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.compare_arrows,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Select two venues to compare',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'See crowd levels, wait times, and get recommendations',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCrowdBadge(CrowdLevel level, {bool compact = false}) {
    final color = _getLevelColor(level);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: compact ? 2 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            level.displayName,
            style: (compact ? AppTypography.labelSmall : AppTypography.labelMedium).copyWith(color: color),
          ),
        ],
      ),
    );
  }

  void _showVenuePicker(int index, List<Venue> venues) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.textTertiaryLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select Venue $index', style: AppTypography.titleMedium),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: venues.length,
                itemBuilder: (context, i) {
                  final venue = venues[i];
                  final isSelected = (index == 1 ? _venue1 : _venue2)?.id == venue.id;
                  final isOther = (index == 1 ? _venue2 : _venue1)?.id == venue.id;
                  
                  return ListTile(
                    enabled: !isOther,
                    leading: Text(_getCategoryEmoji(venue), style: const TextStyle(fontSize: 24)),
                    title: Text(venue.name),
                    subtitle: Text(venue.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : _buildCrowdBadge(venue.currentCrowdLevel, compact: true),
                    onTap: () {
                      setState(() {
                        if (index == 1) {
                          _venue1 = venue;
                        } else {
                          _venue2 = venue;
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low: return AppColors.crowdLow;
      case CrowdLevel.medium: return AppColors.crowdMedium;
      case CrowdLevel.high: return AppColors.crowdHigh;
      case CrowdLevel.veryHigh: return AppColors.crowdVeryHigh;
    }
  }

  String _getCategoryEmoji(Venue venue) {
    final category = VenueCategory.values.firstWhere(
      (c) => c.name == venue.category,
      orElse: () => VenueCategory.other,
    );
    return category.icon;
  }
}
