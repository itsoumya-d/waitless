import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reusable empty state widget with illustration, title, description and action
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                icon,
                size: 56,
                color: color,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.2, end: 0),
            
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(actionLabel!),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms)
                  .scale(delay: 400.ms, duration: 300.ms),
            ],
          ],
        ),
      ),
    );
  }

  // Factory constructors for common empty states
  factory EmptyStateWidget.noVenues({VoidCallback? onRefresh}) {
    return EmptyStateWidget(
      icon: Icons.location_off_outlined,
      title: 'No Venues Nearby',
      description: 'We couldn\'t find any venues in your area. Try expanding your search or check back later.',
      actionLabel: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
      iconColor: AppColors.primary,
    );
  }

  factory EmptyStateWidget.noFavorites({VoidCallback? onExplore}) {
    return EmptyStateWidget(
      icon: Icons.favorite_border,
      title: 'No Favorites Yet',
      description: 'Save your favorite venues to quickly check their crowd levels anytime.',
      actionLabel: onExplore != null ? 'Explore Venues' : null,
      onAction: onExplore,
      iconColor: AppColors.accent,
    );
  }

  factory EmptyStateWidget.noActivities() {
    return const EmptyStateWidget(
      icon: Icons.hourglass_empty,
      title: 'No Activities Available',
      description: 'Activities will appear when you\'re waiting in a queue. Check back later!',
      iconColor: AppColors.secondary,
    );
  }

  factory EmptyStateWidget.noNotifications() {
    return const EmptyStateWidget(
      icon: Icons.notifications_off_outlined,
      title: 'All Caught Up!',
      description: 'You have no new notifications. We\'ll let you know when something happens.',
      iconColor: AppColors.info,
    );
  }

  factory EmptyStateWidget.error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'Something Went Wrong',
      description: message ?? 'We encountered an error. Please try again.',
      actionLabel: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
      iconColor: AppColors.error,
    );
  }

  factory EmptyStateWidget.noConnection({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.wifi_off,
      title: 'No Connection',
      description: 'Please check your internet connection and try again.',
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
      iconColor: AppColors.warning,
    );
  }
}
