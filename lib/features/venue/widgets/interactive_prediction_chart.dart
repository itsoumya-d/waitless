import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/venue.dart';

/// Interactive prediction chart with tap-to-show details
class InteractivePredictionChart extends StatefulWidget {
  final List<HourlyPrediction> predictions;
  final int currentHour;
  
  const InteractivePredictionChart({
    super.key,
    required this.predictions,
    required this.currentHour,
  });

  @override
  State<InteractivePredictionChart> createState() => _InteractivePredictionChartState();
}

class _InteractivePredictionChartState extends State<InteractivePredictionChart> {
  int? _selectedHour;
  
  @override
  Widget build(BuildContext context) {
    final displayPredictions = widget.predictions
        .where((p) => p.hour >= 6 && p.hour <= 22)
        .toList();
    
    return Column(
      children: [
        // Selected hour tooltip
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _selectedHour != null ? 60 : 0,
          child: _selectedHour != null
              ? _buildTooltip()
              : const SizedBox(),
        ),
        
        // Chart
        Container(
          height: 120,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Bars
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: displayPredictions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final p = entry.value;
                    final isNow = p.hour == widget.currentHour;
                    final isSelected = p.hour == _selectedHour;
                    final barHeight = p.crowdScore * 55;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedHour = _selectedHour == p.hour ? null : p.hour;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: isSelected ? barHeight + 4 : barHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _getColorForScore(p.crowdScore),
                                  _getColorForScore(p.crowdScore).withValues(alpha: 0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: (isNow || isSelected)
                                  ? Border.all(
                                      color: isSelected 
                                          ? AppColors.primary 
                                          : Colors.white,
                                      width: 2,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _getColorForScore(p.crowdScore).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        )
                            .animate(delay: (index * 30).ms)
                            .fadeIn(duration: 200.ms)
                            .slideY(begin: 0.3, end: 0),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Hour labels
              Row(
                children: [6, 9, 12, 15, 18, 21].map((hour) {
                  final label = hour == 12 ? '12p' : hour < 12 ? '${hour}a' : '${hour - 12}p';
                  final isCurrentHourLabel = hour == widget.currentHour || 
                      (hour <= widget.currentHour && widget.currentHour < hour + 3 && hour != 21);
                  
                  return Expanded(
                    child: Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: isCurrentHourLabel 
                            ? AppColors.primary 
                            : AppColors.textTertiaryLight,
                        fontSize: 10,
                        fontWeight: isCurrentHourLabel ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTooltip() {
    final prediction = widget.predictions.firstWhere(
      (p) => p.hour == _selectedHour,
      orElse: () => const HourlyPrediction(hour: 0, crowdScore: 0, confidence: 0),
    );
    
    final timeLabel = _formatHour(_selectedHour!);
    final crowdLabel = _getCrowdLabel(prediction.crowdScore);
    final color = _getColorForScore(prediction.crowdScore);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            timeLabel,
            style: AppTypography.titleSmall.copyWith(color: color),
          ),
          const SizedBox(width: 16),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            crowdLabel,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Text(
            '${(prediction.crowdScore * 100).round()}%',
            style: AppTypography.titleMedium.copyWith(color: color),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.3, end: 0);
  }
  
  String _formatHour(int hour) {
    if (hour == 0 || hour == 12) {
      return hour == 0 ? '12 AM' : '12 PM';
    } else if (hour < 12) {
      return '$hour AM';
    } else {
      return '${hour - 12} PM';
    }
  }
  
  String _getCrowdLabel(double score) {
    if (score < 0.3) return 'Very Quiet';
    if (score < 0.5) return 'Light Crowd';
    if (score < 0.7) return 'Moderate';
    if (score < 0.85) return 'Busy';
    return 'Very Busy';
  }
  
  Color _getColorForScore(double score) {
    if (score < 0.3) return AppColors.crowdLow;
    if (score < 0.5) return AppColors.crowdMedium;
    if (score < 0.7) return AppColors.crowdHigh;
    return AppColors.crowdVeryHigh;
  }
}

/// Compact legend for the prediction chart
class PredictionChartLegend extends StatelessWidget {
  const PredictionChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Quiet', AppColors.crowdLow),
        const SizedBox(width: 16),
        _buildLegendItem('Moderate', AppColors.crowdMedium),
        const SizedBox(width: 16),
        _buildLegendItem('Busy', AppColors.crowdHigh),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }
}
