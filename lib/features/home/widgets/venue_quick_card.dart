import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/favorites_service.dart';
import '../../../models/venue.dart';

/// Quick venue card for list view
class VenueQuickCard extends ConsumerWidget {
  final Venue venue;
  final VoidCallback? onTap;
  
  const VenueQuickCard({
    super.key,
    required this.venue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(venue.id));
    
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: '${venue.name}, ${venue.address}. Crowd level is ${venue.currentCrowdLevel.displayName}. ${venue.reportCount} reports.',
        hint: 'Double tap to view details',
        button: true,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _getCrowdColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _getCategoryEmoji(),
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Venue details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            venue.name,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Favorite button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(favoriteIdsProvider.notifier).toggle(venue.id);
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey(isFavorite),
                              color: isFavorite ? AppColors.error : AppColors.textTertiaryLight,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      venue.address,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Crowd level indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildCrowdBadge(),
                  const SizedBox(height: 4),
                  Text(
                    '${venue.reportCount} reports',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCrowdBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getCrowdColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getCrowdColor().withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getCrowdColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            venue.currentCrowdLevel.displayName,
            style: AppTypography.crowdLevel.copyWith(
              color: _getCrowdColor(),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getCrowdColor() {
    switch (venue.currentCrowdLevel) {
      case CrowdLevel.low:
        return AppColors.crowdLow;
      case CrowdLevel.medium:
        return AppColors.crowdMedium;
      case CrowdLevel.high:
        return AppColors.crowdHigh;
      case CrowdLevel.veryHigh:
        return AppColors.crowdVeryHigh;
    }
  }
  
  String _getCategoryEmoji() {
    final category = VenueCategory.values.firstWhere(
      (c) => c.name == venue.category,
      orElse: () => VenueCategory.other,
    );
    return category.icon;
  }
}
