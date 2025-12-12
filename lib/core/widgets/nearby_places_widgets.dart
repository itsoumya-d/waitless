import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../services/places_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Horizontal carousel showing nearby places by category
class NearbyPlacesCarousel extends ConsumerWidget {
  final PlaceCategory category;
  final EdgeInsetsGeometry padding;
  
  const NearbyPlacesCarousel({
    super.key,
    required this.category,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(nearbyPlacesProvider(category));
    
    return placesAsync.when(
      loading: () => _buildShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (places) {
        if (places.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: padding,
              child: Row(
                children: [
                  Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.displayName,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showAllPlaces(context, places),
                    child: Text(
                      'See All',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Places carousel
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: padding,
                itemCount: places.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < places.length - 1 ? 12 : 0,
                    ),
                    child: _PlaceCard(
                      place: places[index],
                      category: category,
                    ).animate(delay: Duration(milliseconds: index * 50))
                        .fadeIn()
                        .slideX(begin: 0.1, end: 0),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: padding,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAllPlaces(BuildContext context, List<Place> places) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${category.emoji} ${category.displayName}',
                      style: AppTypography.headlineSmall,
                    ),
                    const Spacer(),
                    Text(
                      '${places.length} places',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: places.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return _PlaceListTile(place: place, category: category);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Card widget for a single place
class _PlaceCard extends StatelessWidget {
  final Place place;
  final PlaceCategory category;
  
  const _PlaceCard({
    required this.place,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // Could navigate to place details or open in maps
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and status
              Row(
                children: [
                  if (place.isOpen == true)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    )
                  else if (place.isOpen == false)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (place.isOpen != null) const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      place.name,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Rating
              if (place.rating != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      place.rating!.toStringAsFixed(1),
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (place.userRatingsTotal != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${place.userRatingsTotal})',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
              ],
              // Distance and price
              Row(
                children: [
                  if (place.distanceFormatted.isNotEmpty) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      place.distanceFormatted,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                  if (place.priceLevel != null) ...[
                    const Spacer(),
                    Text(
                      place.priceLevel!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List tile for place in modal
class _PlaceListTile extends StatelessWidget {
  final Place place;
  final PlaceCategory category;
  
  const _PlaceListTile({
    required this.place,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        // Open in maps or navigate to details
      },
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                category.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (place.isOpen == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Open',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (place.rating != null) ...[
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${place.rating!.toStringAsFixed(1)} ',
                        style: AppTypography.labelSmall,
                      ),
                    ],
                    if (place.distanceFormatted.isNotEmpty) ...[
                      Text(
                        '• ${place.distanceFormatted}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                    if (place.priceLevel != null) ...[
                      Text(
                        ' • ${place.priceLevel}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Chevron
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiaryLight,
          ),
        ],
      ),
    );
  }
}

/// Grid view of all place categories
class PlaceCategoriesGrid extends ConsumerWidget {
  const PlaceCategoriesGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const categories = [
      PlaceCategory.restaurant,
      PlaceCategory.cafe,
      PlaceCategory.gym,
      PlaceCategory.pharmacy,
      PlaceCategory.supermarket,
      PlaceCategory.gasStation,
      PlaceCategory.bank,
      PlaceCategory.park,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryChip(category: category);
      },
    );
  }
}

/// Quick category chip for navigation
class _CategoryChip extends StatelessWidget {
  final PlaceCategory category;
  
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          // Navigate to category list or trigger search
          context.push('/chat?query=${category.displayName} nearby');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                category.displayName,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark 
                      ? AppColors.textSecondaryDark 
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
