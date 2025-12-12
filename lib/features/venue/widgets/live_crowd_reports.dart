import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/venue_data_provider.dart';
import '../../../core/services/firestore_venue_repository.dart';
import '../../../models/crowd_report.dart';
import '../../../models/venue.dart';

/// Live crowd reports widget with real-time updates
class LiveCrowdReports extends ConsumerWidget {
  final String venueId;
  
  const LiveCrowdReports({super.key, required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(crowdReportsStreamProvider(venueId));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat())
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1000.ms)
              .then()
              .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 1000.ms),
            const SizedBox(width: 8),
            Text(
              'Live Reports',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => ref.invalidate(crowdReportsStreamProvider(venueId)),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        reportsAsync.when(
          loading: () => _buildLoadingState(),
          error: (e, _) => _buildErrorState(e.toString()),
          data: (reports) => reports.isEmpty 
              ? _buildEmptyState() 
              : _buildReportsList(reports, ref),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unable to load reports',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textTertiaryLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 48,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No recent reports',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to report the crowd level!',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(List<CrowdReport> reports, WidgetRef ref) {
    return Column(
      children: reports.take(5).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final report = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ReportCard(
            report: report,
            onUpvote: () => _handleVote(ref, report.id, true),
            onDownvote: () => _handleVote(ref, report.id, false),
          ).animate(delay: (index * 100).ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.1, end: 0),
        );
      }).toList(),
    );
  }

  void _handleVote(WidgetRef ref, String reportId, bool isUpvote) {
    HapticFeedback.lightImpact();
    final firestoreRepo = ref.read(firestoreVenueRepositoryProvider);
    if (isUpvote) {
      firestoreRepo.upvoteReport(reportId);
    } else {
      firestoreRepo.downvoteReport(reportId);
    }
  }
}

/// Individual report card with voting
class _ReportCard extends StatelessWidget {
  final CrowdReport report;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;

  const _ReportCard({
    required this.report,
    required this.onUpvote,
    required this.onDownvote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Crowd level indicator
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCrowdColor(report.crowdLevel).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCrowdIcon(report.crowdLevel),
              color: _getCrowdColor(report.crowdLevel),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Report info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.crowdLevel.description,
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeago.format(report.reportedAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                    if (report.waitMinutes > 0) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: AppColors.textTertiaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '~${report.waitMinutes}min wait',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Vote buttons
          Column(
            children: [
              _VoteButton(
                icon: Icons.thumb_up_outlined,
                count: report.upvotes,
                onTap: onUpvote,
                color: AppColors.success,
              ),
              const SizedBox(height: 4),
              _VoteButton(
                icon: Icons.thumb_down_outlined,
                count: report.downvotes,
                onTap: onDownvote,
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCrowdColor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low: return AppColors.crowdLow;
      case CrowdLevel.medium: return AppColors.crowdMedium;
      case CrowdLevel.high: return AppColors.crowdHigh;
      case CrowdLevel.veryHigh: return AppColors.crowdVeryHigh;
    }
  }

  IconData _getCrowdIcon(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low: return Icons.person;
      case CrowdLevel.medium: return Icons.people;
      case CrowdLevel.high: return Icons.groups;
      case CrowdLevel.veryHigh: return Icons.groups_3;
    }
  }
}

/// Small vote button
class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onTap;
  final Color color;

  const _VoteButton({
    required this.icon,
    required this.count,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: AppTypography.labelSmall.copyWith(
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
