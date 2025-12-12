import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/venue_data_provider.dart';
import '../../../models/venue.dart';
import 'widgets/venue_quick_card.dart';


/// Search delegate for venue search
class VenueSearchDelegate extends SearchDelegate<String?> {
  final WidgetRef ref;
  
  VenueSearchDelegate({required this.ref});

  @override
  String get searchFieldLabel => 'Search venues...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.textTertiaryLight,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear)
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches(context);
    }
    return _buildSearchResults(context);
  }

  Widget _buildRecentSearches(BuildContext context) {
    final recentSearches = ['Trader Joe\'s', 'Gym', 'Coffee', 'Target'];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Popular Searches',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recentSearches.map((search) {
            return ActionChip(
              label: Text(search),
              onPressed: () {
                query = search;
                showResults(context);
              },
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              labelStyle: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
              side: BorderSide.none,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Quick Categories',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VenueCategory.values.take(8).map((category) {
            return ActionChip(
              avatar: Text(category.icon, style: const TextStyle(fontSize: 16)),
              label: Text(category.displayName),
              onPressed: () {
                query = category.displayName.toLowerCase();
                showResults(context);
              },
              backgroundColor: Colors.white,
              side: BorderSide(color: AppColors.textTertiaryLight.withValues(alpha: 0.3)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return FutureBuilder<List<Venue>>(
      future: ref.read(venueRepositoryProvider).searchVenues(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        final venues = snapshot.data ?? [];
        
        if (venues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textTertiaryLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No venues found for "$query"',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: venues.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: VenueQuickCard(
                venue: venues[index],
                onTap: () {
                  close(context, venues[index].id);
                },
              ).animate(delay: (index * 50).ms).fadeIn(duration: 200.ms),
            );
          },
        );
      },
    );
  }
}
