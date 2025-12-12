import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/app_providers.dart';

class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  // Available interests mapping to typical categories or custom tags
  final List<String> _availableInterests = [
    'Coffee Shop', 'Gym', 'Grocery Store', 'Library', 'Restaurant', 
    'Bar', 'Park', 'Museum', 'Coworking', 'Beach'
  ];

  @override
  Widget build(BuildContext context) {
    // Get currently selected interests from user provider (or local interest provider)
    // We'll use the one in app_providers
    final selectedInterests = ref.watch(selectedInterestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Interests'),
        backgroundColor: AppColors.backgroundLight,
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Done'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What do you like?',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Select categories to get personalized recommendations.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableInterests.map((interest) {
                final isSelected = selectedInterests.contains(interest);
                return _buildInterestChip(interest, isSelected);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        HapticFeedback.selectionClick();
        ref.read(selectedInterestsProvider.notifier).toggleInterest(label);
        
        // Also update main user object persistence if needed
        // For now, selectedInterestsProvider is ephemeral but we plan to persist it
        // In a full implementation, we'd save this to Firestore/SharedPreferences here.
        final currentUser = ref.read(userDataProvider);
        if (currentUser != null) {
          // Update user object logic here if we were syncing
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.textTertiaryLight.withValues(alpha: 0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    );
  }
}
