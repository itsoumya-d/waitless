import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flame/game.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../components/reaction_game.dart';
import '../components/memory_match_game.dart';
import '../components/color_tap_game.dart';

/// Type of mini game
enum MiniGameType {
  reaction,
  memoryMatch,
  colorTap,
}

/// Mini game data
class MiniGameData {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final MiniGameType type;
  final int estimatedSeconds;
  
  const MiniGameData({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.type,
    required this.estimatedSeconds,
  });
}

/// Games selection screen
class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  static const List<MiniGameData> _games = [
    MiniGameData(
      id: 'reaction',
      title: 'Reaction Time',
      description: 'Test your reflexes! Tap when the color changes.',
      emoji: '⚡',
      color: Color(0xFFE53935),
      type: MiniGameType.reaction,
      estimatedSeconds: 30,
    ),
    MiniGameData(
      id: 'memory',
      title: 'Memory Match',
      description: 'Find all matching pairs before time runs out.',
      emoji: '🧠',
      color: Color(0xFF8E24AA),
      type: MiniGameType.memoryMatch,
      estimatedSeconds: 60,
    ),
    MiniGameData(
      id: 'colortap',
      title: 'Color Tap',
      description: 'Tap the correct color as fast as you can!',
      emoji: '🎨',
      color: Color(0xFF1E88E5),
      type: MiniGameType.colorTap,
      estimatedSeconds: 30,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
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
                  child: const Text('🎮', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Play While You Wait',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quick games to pass the time!',
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
          
          // Games grid
          ...List.generate(_games.length, (index) {
            final game = _games[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildGameCard(game),
            ).animate(delay: Duration(milliseconds: 100 * index))
                .fadeIn()
                .slideX(begin: 0.1, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildGameCard(MiniGameData game) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchGame(game),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: game.color.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: game.color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: game.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(game.emoji, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: game.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '~${game.estimatedSeconds}s',
                          style: AppTypography.labelSmall.copyWith(
                            color: game.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: game.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+5 pts',
                            style: AppTypography.labelSmall.copyWith(
                              color: game.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_filled,
                color: game.color,
                size: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchGame(MiniGameData game) {
    HapticFeedback.mediumImpact();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _GamePlayScreen(game: game),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _helpItem('⚡ Reaction Time', 'Wait for green, then tap as fast as you can!'),
            const SizedBox(height: 12),
            _helpItem('🧠 Memory Match', 'Tap cards to reveal colors. Find all matching pairs.'),
            const SizedBox(height: 12),
            _helpItem('🎨 Color Tap', 'Tap the color shown in the text (ignore the text color!).'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _helpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.labelLarge),
        Text(
          description,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Game play screen with Flame game
class _GamePlayScreen extends StatefulWidget {
  final MiniGameData game;
  
  const _GamePlayScreen({required this.game});

  @override
  State<_GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<_GamePlayScreen> {
  int _score = 0;
  bool _isGameOver = false;

  FlameGame _createGame() {
    switch (widget.game.type) {
      case MiniGameType.reaction:
        return ReactionGame(
          onScoreUpdate: (score) => setState(() => _score = score),
          onReactionComplete: (time) {}, // Feedback not displayed
          onGameOver: () => setState(() => _isGameOver = true),
        );
      case MiniGameType.memoryMatch:
        return MemoryMatchGame(
          onScoreUpdate: (score) => setState(() => _score = score),
          onMatchFound: (matches) {}, // Feedback not displayed
          onGameOver: () => setState(() => _isGameOver = true),
        );
      case MiniGameType.colorTap:
        return ColorTapGame(
          onScoreUpdate: (score) => setState(() => _score = score),
          onAnswer: (correct) {}, // Feedback not displayed
          onGameOver: () => setState(() => _isGameOver = true),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.game.title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: widget.game.color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Game
          GameWidget(
            game: _createGame(),
          ),
          
          // Game over overlay
          if (_isGameOver)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.game.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Game Complete!',
                        style: AppTypography.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Score: $_score',
                        style: AppTypography.titleLarge.copyWith(
                          color: widget.game.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _score = 0;
                                _isGameOver = false;
                              });
                            },
                            child: const Text('Play Again'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
              ),
            ),
        ],
      ),
    );
  }
}
