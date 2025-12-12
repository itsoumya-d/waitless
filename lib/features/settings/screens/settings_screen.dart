import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/services/favorites_service.dart';

/// Settings and profile screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final locationEnabled = ref.watch(locationSharingEnabledProvider);
    
    final user = ref.watch(userDataProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.backgroundLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            GestureDetector(
              onTap: () => context.go('/profile/edit'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Hero(
                      tag: 'profile_avatar',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (user != null && user.displayName.isNotEmpty)
                                ? user.displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? 'User',
                      style: AppTypography.titleLarge,
                    ),
                    Text(
                      user?.email ?? 'No email',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Settings sections
            _buildSection('Preferences', [
              _buildSettingTile(
                Icons.notifications_outlined,
                'Notifications',
                'Crowd alerts & updates',
                trailing: Switch(
                  value: notificationsEnabled,
                  onChanged: (value) {
                    ref.read(notificationsEnabledProvider.notifier).state = value;
                  },
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.all(AppColors.primary),
                ),
              ),
              _buildSettingTile(
                Icons.location_on_outlined,
                'Location Sharing',
                'Help improve predictions',
                trailing: Switch(
                  value: locationEnabled,
                  onChanged: (value) {
                    ref.read(locationSharingEnabledProvider.notifier).state = value;
                  },
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.all(AppColors.primary),
                ),
              ),
              _buildSettingTile(
                Icons.dark_mode_outlined,
                'Dark Mode',
                'Toggle app theme',
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).state = value;
                  },
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.all(AppColors.primary),
                ),
              ),
            ]),
            
            const SizedBox(height: 16),
            
            _buildSection('Account', [
              _buildSettingTile(
                Icons.favorite_outline,
                'Favorite Places',
                '${ref.watch(favoriteIdsProvider).length} places saved',
                onTap: () => context.push('/favorites'),
              ),
              _buildSettingTile(
                Icons.history,
                'Report History',
                'View your contributions',
                onTap: () => context.push('/profile/history'),
              ),
              _buildSettingTile(
                Icons.star_outline,
                'Interests',
                'Update your preferences',
                onTap: () => context.push('/profile/interests'),
              ),
            ]),
            
            const SizedBox(height: 16),
            
            _buildSection('Support', [
              _buildSettingTile(
                Icons.help_outline,
                'Help Center',
                'FAQs and guides',
              ),
              _buildSettingTile(
                Icons.feedback_outlined,
                'Send Feedback',
                'Help us improve',
              ),
            _buildSettingTile(
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                null,
                onTap: () => context.push('/privacy-policy'),
              ),
              _buildSettingTile(
                Icons.description_outlined,
                'Terms of Service',
                null,
                onTap: () => context.push('/terms-of-service'),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            Text(
              'WaitLess v1.0.0',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
  
  Widget _buildSettingTile(
    IconData icon,
    String title,
    String? subtitle, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: AppTypography.labelLarge),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textTertiaryLight),
      onTap: onTap ?? (trailing == null ? () {} : null),
    );
  }
}
