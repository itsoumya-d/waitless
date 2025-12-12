import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Banner showing total time saved with animations
class TimeSavedBanner extends StatelessWidget {
  final int minutesSaved;
  final int thisWeek;
  
  const TimeSavedBanner({
    super.key,
    required this.minutesSaved,
    required this.thisWeek,
  });

  @override
  Widget build(BuildContext context) {
    final hours = minutesSaved ~/ 60;
    final mins = minutesSaved % 60;
    
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Reclaimed',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      _AnimatedTimeDisplay(
                        hours: hours,
                        minutes: mins,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 14,
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .slideY(begin: 0, end: -0.1, duration: 600.ms),
                        const SizedBox(width: 4),
                        Text(
                          '+${thisWeek}m this week',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideX(begin: -0.1, end: 0),
                ],
              ),
            ),
            
            // Animated time icon with ripple effect
            _AnimatedTimeIcon(),
          ],
        ),
      ),
    );
  }
}

/// Animated display for time values
class _AnimatedTimeDisplay extends StatelessWidget {
  final int hours;
  final int minutes;

  const _AnimatedTimeDisplay({
    required this.hours,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final displayHours = (hours * value).round();
        final displayMins = (minutes * value).round();
        return Text(
          displayHours > 0 ? '${displayHours}h ${displayMins}m' : '${displayMins}m',
          style: AppTypography.timeSaved.copyWith(
            color: Colors.white,
          ),
        );
      },
    );
  }
}

/// Animated time icon with pulsing rings
class _AnimatedTimeIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ripple
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
              duration: 2000.ms,
              curve: Curves.easeOut,
            )
            .fadeOut(duration: 2000.ms),
        
        // Inner ring
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.access_time_filled,
            color: Colors.white,
            size: 32,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 1000.ms,
            ),
      ],
    );
  }
}
