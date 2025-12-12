import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/celebration_widgets.dart';

/// Shows a celebratory dialog when user levels up
class LevelUpDialog extends StatefulWidget {
  final String previousLevel;
  final String newLevel;
  final String levelIcon;
  final int pointsEarned;
  final VoidCallback? onDismiss;

  const LevelUpDialog({
    super.key,
    required this.previousLevel,
    required this.newLevel,
    required this.levelIcon,
    this.pointsEarned = 0,
    this.onDismiss,
  });

  /// Shows the level up dialog as a modal
  static Future<void> show(
    BuildContext context, {
    required String previousLevel,
    required String newLevel,
    required String levelIcon,
    int pointsEarned = 0,
  }) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Level Up',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return LevelUpDialog(
          previousLevel: previousLevel,
          newLevel: newLevel,
          levelIcon: levelIcon,
          pointsEarned: pointsEarned,
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: child,
        );
      },
    );
  }

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog> {
  bool _showConfetti = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti overlay
        ConfettiCelebration(
          isActive: _showConfetti,
          onComplete: () {
            setState(() => _showConfetti = false);
          },
        ),
        
        // Dialog content
        Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Level icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.levelIcon,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 1000.ms,
                    ),
                
                const SizedBox(height: 24),
                
                // Congratulations text
                Text(
                  '🎉 Level Up! 🎉',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: 12),
                
                // Level transition
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.previousLevel,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      widget.newLevel,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 400.ms),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'You\'ve reached a new milestone!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 500.ms),
                
                if (widget.pointsEarned > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.pointsEarned} bonus points',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms)
                      .scale(delay: 600.ms),
                ],
                
                const SizedBox(height: 24),
                
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated streak display with fire animation
class StreakDisplay extends StatelessWidget {
  final int streakDays;
  final bool animate;

  const StreakDisplay({
    super.key,
    required this.streakDays,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fire emoji with animation
        Text(
          '🔥',
          style: const TextStyle(fontSize: 24),
        )
            .animate(onPlay: animate ? (c) => c.repeat(reverse: true) : null)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.2, 1.2),
              duration: 600.ms,
            )
            .shake(hz: 2, delay: 300.ms),
        
        const SizedBox(width: 8),
        
        // Streak count
        if (animate)
          AnimatedCounter(
            value: streakDays,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
            suffix: ' day streak',
          )
        else
          Text(
            '$streakDays day streak',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
