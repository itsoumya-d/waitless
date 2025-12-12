import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/wait_activity.dart';
import '../../../core/services/social_sharing_service.dart';

/// Full-screen activity launch and execution screen
class ActivityLaunchScreen extends ConsumerStatefulWidget {
  final WaitActivity activity;
  
  const ActivityLaunchScreen({super.key, required this.activity});

  @override
  ConsumerState<ActivityLaunchScreen> createState() => _ActivityLaunchScreenState();
}

class _ActivityLaunchScreenState extends ConsumerState<ActivityLaunchScreen> {
  late Timer _timer;
  int _elapsedSeconds = 0;
  bool _isPlaying = true;
  bool _isCompleted = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying) {
        setState(() {
          _elapsedSeconds++;
          
          // Check if activity is completed
          if (_elapsedSeconds >= widget.activity.durationSeconds) {
            _completeActivity();
          }
        });
      }
    });
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() => _isPlaying = !_isPlaying);
  }

  void _completeActivity() {
    _timer.cancel();
    HapticFeedback.heavyImpact();
    setState(() => _isCompleted = true);
  }

  void _skipToComplete() {
    HapticFeedback.mediumImpact();
    _completeActivity();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double get _progress {
    return (_elapsedSeconds / widget.activity.durationSeconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletedScreen();
    }
    return _buildActiveScreen();
  }

  Widget _buildActiveScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => _showExitDialog(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(widget.activity.durationSeconds - _elapsedSeconds),
                          style: AppTypography.labelLarge.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _skipToComplete,
                    child: Text(
                      'Skip',
                      style: AppTypography.labelMedium.copyWith(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 4,
                ),
              ),
            ),
            
            const Spacer(),
            
            // Activity content
            _buildActivityContent(),
            
            const Spacer(),
            
            // Controls
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Play/Pause button
                  GestureDetector(
                    onTap: _togglePause,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ).animate().scale(duration: 200.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityContent() {
    switch (widget.activity.type) {
      case ActivityType.mindfulness:
        return _buildBreathingContent();
      case ActivityType.microLearning:
        return _buildLearningContent();
      case ActivityType.entertainment:
        return _buildEntertainmentContent();
      case ActivityType.productivity:
        return _buildProductivityContent();
    }
  }

  Widget _buildBreathingContent() {
    // Simple breathing animation
    final breatheIn = (_elapsedSeconds ~/ 4) % 2 == 0;
    
    return Column(
      children: [
        Text(
          widget.activity.title,
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 48),
        AnimatedContainer(
          duration: const Duration(seconds: 4),
          width: breatheIn ? 200 : 120,
          height: breatheIn ? 200 : 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.secondary.withValues(alpha: 0.8),
                AppColors.secondary.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Center(
            child: Text(
              breatheIn ? 'Breathe In' : 'Breathe Out',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLearningContent() {
    final steps = [
      'Did you know? 🧠',
      'Here\'s a quick fact!',
      'Keep learning!',
    ];
    
    return Column(
      children: [
        Text(
          widget.activity.title,
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Text(
            steps[_currentStep % steps.length],
            style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _currentStep++);
          },
          icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
          label: Text(
            'Next',
            style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildEntertainmentContent() {
    return Column(
      children: [
        Text(
          widget.activity.title,
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          widget.activity.type.icon,
          style: const TextStyle(fontSize: 80),
        ).animate(onPlay: (c) => c.repeat())
          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1000.ms)
          .then()
          .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1), duration: 1000.ms),
        const SizedBox(height: 24),
        Text(
          'Playing...',
          style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildProductivityContent() {
    return Column(
      children: [
        Text(
          widget.activity.title,
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
              const SizedBox(height: 12),
              Text(
                'Focus Time',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(_elapsedSeconds),
                style: AppTypography.headlineLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 60,
                ),
              ).animate()
                .scale(duration: 400.ms, curve: Curves.elasticOut)
                .fadeIn(),
              const SizedBox(height: 32),
              Text(
                'Activity Complete!',
                style: AppTypography.headlineMedium.copyWith(color: Colors.white),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Text(
                widget.activity.title,
                style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 48),
              
              // Stats
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Duration', _formatTime(_elapsedSeconds)),
                    _buildStat('Points', '+5'),
                    _buildStat('Streak', '🔥 3'),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Done'),
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(socialSharingProvider).shareAchievement(
                    achievementName: 'Completed ${widget.activity.title}!',
                    description: 'I just saved time with a quick ${widget.activity.type.displayName} session on WaitLess.',
                  );
                },
                icon: const Icon(Icons.share, color: Colors.white70),
                label: const Text(
                  'Share Achievement',
                  style: TextStyle(color: Colors.white70),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Activity?'),
        content: const Text('Your progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              this.context.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
