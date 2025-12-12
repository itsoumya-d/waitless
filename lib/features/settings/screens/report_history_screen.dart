import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/crowd_report.dart';
import '../../../models/venue.dart';

/// Screen to view user's report history
class ReportHistoryScreen extends ConsumerWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app we'd query by userId, but for MVP we might mock
    // if Firestore isn't indexed or structure doesn't support easy 'my reports'.
    // Here we'll just show a placeholder listing mechanism or mock data if no real query yet.
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Reports'),
        backgroundColor: AppColors.backgroundLight,
      ),
      body: _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    // Mock data for display purposes since we don't have a 'getMyReports' query yet
    final reports = List.generate(5, (index) => CrowdReport(
      id: 'r$index',
      venueId: 'v1',
      userId: 'user1',
      crowdLevel: CrowdLevel.values[index % 4],
      reportedAt: DateTime.now().subtract(Duration(days: index)),
      waitMinutes: 10 + index * 5,
      comment: index % 2 == 0 ? 'Quite busy but moving fast!' : null,
      upvotes: index * 2,
      downvotes: 0,
    ));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.textTertiaryLight.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: report.crowdLevel.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.crowdLevel.displayName,
                        style: AppTypography.labelSmall.copyWith(
                          color: report.crowdLevel.color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, h:mm a').format(report.reportedAt),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Venue Name Here', // In real app, fetch venue name or store denormalized
                  style: AppTypography.titleSmall,
                ),
                if (report.comment != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    report.comment!,
                    style: AppTypography.bodyMedium,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '+10 Points',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight),
                    ),
                    const Spacer(),
                    Icon(Icons.thumb_up_outlined, size: 14, color: AppColors.textTertiaryLight),
                    const SizedBox(width: 4),
                    Text(
                      '${report.upvotes}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiaryLight),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1, end: 0);
      },
    );
  }
}
