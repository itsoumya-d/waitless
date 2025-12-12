import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/ai_service.dart';

/// Interactive trivia quiz screen with AI-generated questions
class TriviaScreen extends ConsumerStatefulWidget {
  final String category;
  
  const TriviaScreen({
    super.key,
    this.category = 'general knowledge',
  });

  @override
  ConsumerState<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends ConsumerState<TriviaScreen> {
  TriviaQuestion? _currentQuestion;
  int _score = 0;
  int _questionsAnswered = 0;
  int _correctAnswers = 0;
  int? _selectedIndex;
  bool _showResult = false;
  bool _isLoading = true;
  static const int _totalQuestions = 5;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _selectedIndex = null;
      _showResult = false;
    });
    
    try {
      final aiService = ref.read(aiServiceProvider);
      final question = await aiService.generateTriviaQuestion(
        category: widget.category,
      );
      
      setState(() {
        _currentQuestion = question;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _selectAnswer(int index) {
    if (_selectedIndex != null) return; // Already answered
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _selectedIndex = index;
      _showResult = true;
      _questionsAnswered++;
      
      if (index == _currentQuestion!.correctIndex) {
        _correctAnswers++;
        _score += 10;
      }
    });

    // Auto-advance after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (_questionsAnswered >= _totalQuestions) {
        _showCompletionDialog();
      } else {
        _loadQuestion();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(_correctAnswers >= 3 ? '🏆' : '📊'),
            const SizedBox(width: 8),
            const Text('Quiz Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You got $_correctAnswers out of $_totalQuestions correct!',
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: _correctAnswers >= 4
                    ? AppColors.secondaryGradient
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '+$_score points',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildResultBadge(),
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
              setState(() {
                _score = 0;
                _questionsAnswered = 0;
                _correctAnswers = 0;
              });
              _loadQuestion();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBadge() {
    String badge;
    Color color;
    
    if (_correctAnswers == _totalQuestions) {
      badge = '🌟 Perfect Score!';
      color = AppColors.secondary;
    } else if (_correctAnswers >= 4) {
      badge = '⭐ Excellent!';
      color = AppColors.primary;
    } else if (_correctAnswers >= 3) {
      badge = '👍 Good job!';
      color = AppColors.accent;
    } else {
      badge = '💪 Keep learning!';
      color = AppColors.crowdMedium;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        badge,
        style: AppTypography.labelLarge.copyWith(color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_score',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress
          LinearProgressIndicator(
            value: _questionsAnswered / _totalQuestions,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentQuestion == null
                    ? _buildEmptyState()
                    : _buildQuestionCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('❓', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Failed to load question',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadQuestion,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question number
          Text(
            'Question ${_questionsAnswered + 1} of $_totalQuestions',
            style: AppTypography.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          
          // Question
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentQuestion!.question,
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn().slideY(begin: -0.1, end: 0),
          
          const SizedBox(height: 24),
          
          // Options
          ...List.generate(_currentQuestion!.options.length, (index) {
            final option = _currentQuestion!.options[index];
            final isSelected = _selectedIndex == index;
            final isCorrect = index == _currentQuestion!.correctIndex;
            
            Color? backgroundColor;
            Color? borderColor;
            
            if (_showResult) {
              if (isCorrect) {
                backgroundColor = AppColors.success.withValues(alpha: 0.2);
                borderColor = AppColors.success;
              } else if (isSelected && !isCorrect) {
                backgroundColor = AppColors.error.withValues(alpha: 0.2);
                borderColor = AppColors.error;
              }
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _selectedIndex == null ? () => _selectAnswer(index) : null,
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor ?? Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor ?? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: (_showResult && isCorrect)
                                ? AppColors.success
                                : (_showResult && isSelected && !isCorrect)
                                    ? AppColors.error
                                    : AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _showResult
                                ? Icon(
                                    isCorrect ? Icons.check : (isSelected ? Icons.close : null),
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : Text(
                                    String.fromCharCode(65 + index), // A, B, C, D
                                    style: AppTypography.labelLarge.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option,
                            style: AppTypography.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn()
                  .slideX(begin: 0.1, end: 0),
            );
          }),
          
          // Explanation
          if (_showResult && _currentQuestion!.explanation.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentQuestion!.explanation,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
