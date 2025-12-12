import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/venue.dart';

/// Compact card showing venue with current crowd level
class CrowdPulseCard extends StatefulWidget {
  final Venue venue;
  final VoidCallback? onTap;
  
  const CrowdPulseCard({
    super.key,
    required this.venue,
    this.onTap,
  });

  @override
  State<CrowdPulseCard> createState() => _CrowdPulseCardState();
}

class _CrowdPulseCardState extends State<CrowdPulseCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: Semantics(
        label: '${widget.venue.name} is currently ${widget.venue.currentCrowdLevel.displayName}. ${widget.venue.averageWaitMinutes > 0 ? "${widget.venue.averageWaitMinutes} minute wait." : ""}',
        hint: 'Double tap to view details',
        button: true,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24), // Softer corners
              boxShadow: [
                BoxShadow(
                  color: _getCrowdColor().withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8), // Softer, deeper shadow
                ),
              ],
              border: Border.all(
                color: Colors.white,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crowd indicator with Hero
                Hero(
                  tag: 'venue_icon_${widget.venue.id}',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _getCrowdGradient(),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _getCrowdColor().withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          _getCategoryEmoji(),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Venue name
                Text(
                  widget.venue.name,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 6),
                
                // Crowd level with Pill design
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCrowdColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getCrowdColor(),
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.3, 1.3),
                            duration: 800.ms,
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.3, 1.3),
                            end: const Offset(1, 1),
                            duration: 800.ms,
                          ),
                      const SizedBox(width: 6),
                      Text(
                        widget.venue.currentCrowdLevel.displayName,
                        style: AppTypography.labelSmall.copyWith(
                          color: _getCrowdColor(),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (widget.venue.averageWaitMinutes > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppColors.textTertiaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '~${widget.venue.averageWaitMinutes} min',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiaryLight,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getCrowdColor() {
    switch (widget.venue.currentCrowdLevel) {
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
  
  LinearGradient _getCrowdGradient() {
    switch (widget.venue.currentCrowdLevel) {
      case CrowdLevel.low:
        return AppColors.crowdLowGradient;
      case CrowdLevel.medium:
        return AppColors.crowdMediumGradient;
      case CrowdLevel.high:
      case CrowdLevel.veryHigh:
        return AppColors.crowdHighGradient;
    }
  }
  
  String _getCategoryEmoji() {
    final category = VenueCategory.values.firstWhere(
      (c) => c.name == widget.venue.category,
      orElse: () => VenueCategory.other,
    );
    return category.icon;
  }
}
