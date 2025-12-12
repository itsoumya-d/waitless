import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for now
    final notifications = [
      {
        'title': 'Crowd Alert: Target',
        'body': 'Crowd levels at Target have dropped to Low. Good time to go!',
        'time': '2 min ago',
        'icon': '🟢',
        'color': AppColors.success,
      },
      {
        'title': 'Points Earned',
        'body': 'You earned 10 points for your report!',
        'time': '1 hour ago',
        'icon': '🏆',
        'color': AppColors.accent,
      },
      {
        'title': 'New Feature',
        'body': 'Try out our new "Smart Wait" activities.',
        'time': '1 day ago',
        'icon': '✨',
        'color': AppColors.primary,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Notifications', style: AppTypography.titleMedium),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: notifications.isEmpty
          ? EmptyStateWidget.noNotifications()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (notif['color'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              notif['icon'] as String,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif['title'] as String,
                                style: AppTypography.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif['body'] as String,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notif['time'] as String,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: (index * 100).ms).fadeIn().slideX(),
                );
              },
            ),
    );
  }
}
