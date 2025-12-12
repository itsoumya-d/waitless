import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/ai_service.dart';

/// Vocabulary learning screen with AI-generated words
class VocabularyScreen extends ConsumerStatefulWidget {
  final String language;
  final String difficulty;
  
  const VocabularyScreen({
    super.key,
    this.language = 'Spanish',
    this.difficulty = 'beginner',
  });

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  List<VocabularyWord> _words = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showMeaning = false;
  int _learnedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    
    try {
      final aiService = ref.read(aiServiceProvider);
      final words = await aiService.generateVocabularyWords(
        language: widget.language,
        difficulty: widget.difficulty,
        count: 5,
      );
      
      setState(() {
        _words = words;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _nextWord() {
    HapticFeedback.lightImpact();
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _showMeaning = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _markAsLearned() {
    HapticFeedback.mediumImpact();
    setState(() => _learnedCount++);
    _nextWord();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('🎉'),
            const SizedBox(width: 8),
            const Text('Lesson Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You learned $_learnedCount of ${_words.length} words!',
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    '+${_learnedCount * 2} points',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.secondary,
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
              setState(() {
                _currentIndex = 0;
                _learnedCount = 0;
                _showMeaning = false;
              });
              _loadWords();
            },
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Learn ${widget.language}'),
        actions: [
          if (_words.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentIndex + 1}/${_words.length}',
                  style: AppTypography.labelLarge,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? _buildEmptyState()
              : _buildWordCard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📚', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'No words available',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadWords,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard() {
    final word = _words[_currentIndex];
    final progress = (_currentIndex + 1) / _words.length;
    
    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                
                // Word card
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showMeaning = !_showMeaning);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          word.word,
                          style: AppTypography.displayMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          word.pronunciation,
                          style: AppTypography.bodyLarge.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: _showMeaning
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Text(
                              'Tap to reveal meaning',
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          secondChild: Column(
                            children: [
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              Text(
                                word.meaning,
                                style: AppTypography.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  word.exampleSentence,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                
                const Spacer(),
                
                // Action buttons
                if (_showMeaning) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _nextWord,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Still Learning'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _markAsLearned,
                          icon: const Icon(Icons.check),
                          label: const Text('Got It!'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
