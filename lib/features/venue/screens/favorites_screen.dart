import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../home/widgets/venue_quick_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteVenuesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Favorite Places'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundLight.withValues(alpha: 0.9),
                AppColors.backgroundLight.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
        ),
        child: favoritesAsync.when(
          data: (venues) {
            if (venues.isEmpty) {
              return EmptyStateWidget.noFavorites(
                onExplore: () => context.go('/search'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
              itemCount: venues.length,
              itemBuilder: (context, index) {
                final venue = venues[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: Key(venue.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: AppColors.error,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      HapticFeedback.mediumImpact();
                      return true;
                    },
                    onDismissed: (direction) {
                      ref.read(favoritesServiceProvider).removeFavorite(venue.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${venue.name} removed from favorites'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              ref.read(favoritesServiceProvider).addFavorite(venue.id);
                            },
                          ),
                        ),
                      );
                    },
                    child: VenueQuickCard(
                      venue: venue,
                      onTap: () => context.push('/venue/${venue.id}'),
                    ),
                  ),
                )
                    .animate(delay: (index * 50).ms)
                    .fadeIn(duration: 200.ms)
                    .slideX(begin: 0.05, end: 0);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => EmptyStateWidget.error(
            message: 'Error loading favorites: $err',
            onRetry: () => ref.refresh(favoriteVenuesProvider),
          ),
        ),
      ),
    );
  }
}
