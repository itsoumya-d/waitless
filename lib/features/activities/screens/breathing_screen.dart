import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/ai_service.dart';

/// Breathing exercise preset patterns
enum BreathingPattern {
  boxBreathing,
  relaxing,
  energizing,
  sleepInducing,
}

extension BreathingPatternExtension on BreathingPattern {
  String get name {
    switch (this) {
      case BreathingPattern.boxBreathing:
        return 'Box Breathing';
      case BreathingPattern.relaxing:
        return '4-7-8 Relaxing';
      case BreathingPattern.energizing:
        return 'Energizing';
      case BreathingPattern.sleepInducing:
        return 'Sleep Helper';
    }
  }
  
  String get description {
    switch (this) {
      case BreathingPattern.boxBreathing:
        return 'Equal breathing for focus and calm';
      case BreathingPattern.relaxing:
        return 'Deep relaxation technique';
      case BreathingPattern.energizing:
        return 'Quick energy boost';
      case BreathingPattern.sleepInducing:
        return 'Prepare for restful sleep';
    }
  }
  
  String get emoji {
    switch (this) {
      case BreathingPattern.boxBreathing:
        return '📦';
      case BreathingPattern.relaxing:
        return '😌';
      case BreathingPattern.energizing:
        return '⚡';
      case BreathingPattern.sleepInducing:
        return '🌙';
    }
  }
  
  BreathingExercise get exercise {
    switch (this) {
      case BreathingPattern.boxBreathing:
        return const BreathingExercise(
          name: 'Box Breathing',
          inhaleSeconds: 4,
          holdAfterInhale: 4,
          exhaleSeconds: 4,
          holdAfterExhale: 4,
          cycles: 4,
          description: 'Used by Navy SEALs to stay calm under pressure.',
        );
      case BreathingPattern.relaxing:
        return const BreathingExercise(
          name: '4-7-8 Relaxing',
          inhaleSeconds: 4,
          holdAfterInhale: 7,
          exhaleSeconds: 8,
          holdAfterExhale: 0,
          cycles: 4,
          description: 'Dr. Weil\'s natural tranquilizer for the nervous system.',
        );
      case BreathingPattern.energizing:
        return const BreathingExercise(
          name: 'Energizing Breath',
          inhaleSeconds: 4,
          holdAfterInhale: 2,
          exhaleSeconds: 4,
          holdAfterExhale: 0,
          cycles: 6,
          description: 'Quick technique to boost alertness and energy.',
        );
      case BreathingPattern.sleepInducing:
        return const BreathingExercise(
          name: 'Sleep Helper',
          inhaleSeconds: 4,
          holdAfterInhale: 4,
          exhaleSeconds: 6,
          holdAfterExhale: 2,
          cycles: 6,
          description: 'Long exhales activate your relaxation response.',
        );
    }
  }
  
  Color get color {
    switch (this) {
      case BreathingPattern.boxBreathing:
        return AppColors.primary;
      case BreathingPattern.relaxing:
        return AppColors.secondary;
      case BreathingPattern.energizing:
        return AppColors.accent;
      case BreathingPattern.sleepInducing:
        return const Color(0xFF6366F1); // Indigo
    }
  }
}

/// Enhanced breathing exercise screen with patterns and animations
class BreathingScreen extends ConsumerStatefulWidget {
  final BreathingPattern? initialPattern;
  
  const BreathingScreen({super.key, this.initialPattern});

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen>
    with SingleTickerProviderStateMixin {
  BreathingPattern? _selectedPattern;
  BreathingExercise? _exercise;
  
  bool _isExercising = false;
  bool _isPaused = false;
  int _currentCycle = 0;
  String _phase = 'inhale';
  int _phaseSecondsRemaining = 0;
  Timer? _timer;
  
  // Animation
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    _breathAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    
    if (widget.initialPattern != null) {
      _selectPattern(widget.initialPattern!);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  void _selectPattern(BreathingPattern pattern) {
    setState(() {
      _selectedPattern = pattern;
      _exercise = pattern.exercise;
    });
  }

  void _startExercise() {
    if (_exercise == null) return;
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isExercising = true;
      _isPaused = false;
      _currentCycle = 1;
      _phase = 'inhale';
      _phaseSecondsRemaining = _exercise!.inhaleSeconds;
    });
    
    _updateBreathAnimation();
    _startTimer();
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() => _isPaused = !_isPaused);
    
    if (_isPaused) {
      _breathController.stop();
    } else {
      _updateBreathAnimation();
    }
  }

  void _stopExercise() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    _breathController.stop();
    
    setState(() {
      _isExercising = false;
      _isPaused = false;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      
      setState(() {
        _phaseSecondsRemaining--;
        
        if (_phaseSecondsRemaining <= 0) {
          _nextPhase();
        }
      });
    });
  }

  void _nextPhase() {
    HapticFeedback.lightImpact();
    
    switch (_phase) {
      case 'inhale':
        if (_exercise!.holdAfterInhale > 0) {
          _phase = 'holdIn';
          _phaseSecondsRemaining = _exercise!.holdAfterInhale;
        } else {
          _phase = 'exhale';
          _phaseSecondsRemaining = _exercise!.exhaleSeconds;
        }
        break;
      case 'holdIn':
        _phase = 'exhale';
        _phaseSecondsRemaining = _exercise!.exhaleSeconds;
        break;
      case 'exhale':
        if (_exercise!.holdAfterExhale > 0) {
          _phase = 'holdOut';
          _phaseSecondsRemaining = _exercise!.holdAfterExhale;
        } else {
          _completeCycle();
        }
        break;
      case 'holdOut':
        _completeCycle();
        break;
    }
    
    _updateBreathAnimation();
  }

  void _completeCycle() {
    if (_currentCycle >= _exercise!.cycles) {
      _finishExercise();
    } else {
      setState(() {
        _currentCycle++;
        _phase = 'inhale';
        _phaseSecondsRemaining = _exercise!.inhaleSeconds;
      });
    }
  }

  void _finishExercise() {
    _timer?.cancel();
    _breathController.stop();
    HapticFeedback.heavyImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('🧘'),
            SizedBox(width: 8),
            Text('Great Job!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You completed ${_exercise!.cycles} cycles of ${_exercise!.name}.',
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedPattern!.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: _selectedPattern!.color),
                  const SizedBox(width: 8),
                  Text(
                    '+10 points',
                    style: AppTypography.titleMedium.copyWith(
                      color: _selectedPattern!.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startExercise();
            },
            child: const Text('Again'),
          ),
        ],
      ),
    );
    
    setState(() => _isExercising = false);
  }

  void _updateBreathAnimation() {
    switch (_phase) {
      case 'inhale':
        _breathController.duration = Duration(seconds: _exercise!.inhaleSeconds);
        _breathController.forward(from: 0);
        break;
      case 'holdIn':
        // Keep at max
        break;
      case 'exhale':
        _breathController.duration = Duration(seconds: _exercise!.exhaleSeconds);
        _breathController.reverse(from: 1);
        break;
      case 'holdOut':
        // Keep at min
        break;
    }
  }

  String get _phaseText {
    switch (_phase) {
      case 'inhale':
        return 'Breathe In';
      case 'holdIn':
        return 'Hold';
      case 'exhale':
        return 'Breathe Out';
      case 'holdOut':
        return 'Hold';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isExercising) {
      return _buildExerciseScreen();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing Exercises'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary,
                  AppColors.secondary.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🧘', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calm Your Mind',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a pattern that fits your mood',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1, end: 0),
          
          const SizedBox(height: 24),
          
          // Patterns
          ...BreathingPattern.values.map((pattern) {
            final index = BreathingPattern.values.indexOf(pattern);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPatternCard(pattern),
            ).animate(delay: Duration(milliseconds: 100 * index))
                .fadeIn()
                .slideX(begin: 0.1, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildPatternCard(BreathingPattern pattern) {
    final isSelected = _selectedPattern == pattern;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _selectPattern(pattern);
          _startExercise();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? pattern.color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: pattern.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(pattern.emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pattern.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: pattern.color),
                        const SizedBox(width: 4),
                        Text(
                          '~${pattern.exercise.totalDurationSeconds ~/ 60} min',
                          style: AppTypography.labelSmall.copyWith(
                            color: pattern.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_filled, color: pattern.color, size: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseScreen() {
    final color = _selectedPattern!.color;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _stopExercise,
        ),
        title: Text(
          _exercise!.name,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
            onPressed: _togglePause,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cycle indicator
            Text(
              'Cycle $_currentCycle of ${_exercise!.cycles}',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white60,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Breathing circle
            AnimatedBuilder(
              animation: _breathAnimation,
              builder: (context, child) {
                return Container(
                  width: 200 * _breathAnimation.value,
                  height: 200 * _breathAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 48),
            
            // Phase text
            Text(
              _phaseText,
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Countdown
            Text(
              '$_phaseSecondsRemaining',
              style: AppTypography.displayLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Pattern indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _phaseDot('In', _phase == 'inhale', color),
                _phaseLine(_phase == 'holdIn' || _phase == 'exhale' || _phase == 'holdOut'),
                _phaseDot('Hold', _phase == 'holdIn', color),
                _phaseLine(_phase == 'exhale' || _phase == 'holdOut'),
                _phaseDot('Out', _phase == 'exhale', color),
                if (_exercise!.holdAfterExhale > 0) ...[
                  _phaseLine(_phase == 'holdOut'),
                  _phaseDot('Hold', _phase == 'holdOut', color),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _phaseDot(String label, bool isActive, Color color) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : Colors.white24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isActive ? color : Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _phaseLine(bool isPast) {
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isPast ? Colors.white24 : Colors.white12,
    );
  }
}
