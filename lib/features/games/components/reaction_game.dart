import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Reaction Time Game - Tap the circle when it changes color
class ReactionGame extends FlameGame with TapCallbacks {
  // Callbacks to Flutter UI
  final Function(int score) onScoreUpdate;
  final Function(int reactionTime) onReactionComplete;
  final Function() onGameOver;
  
  // Game state
  int _score = 0;
  int _round = 0;
  static const int _maxRounds = 5;
  bool _canTap = false;
  DateTime? _colorChangeTime;
  final List<int> _reactionTimes = [];
  
  // Components
  late CircleComponent _targetCircle;
  late TextComponent _instructionText;
  
  // Colors
  final _waitColor = const Color(0xFFE53935); // Red
  final _goColor = const Color(0xFF43A047); // Green
  
  ReactionGame({
    required this.onScoreUpdate,
    required this.onReactionComplete,
    required this.onGameOver,
  });
  
  @override
  Color backgroundColor() => const Color(0xFF1E293B);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Create target circle
    _targetCircle = CircleComponent(
      radius: 80,
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      paint: Paint()..color = _waitColor,
    );
    add(_targetCircle);
    
    // Create instruction text
    _instructionText = TextComponent(
      text: 'Wait for green...',
      position: Vector2(size.x / 2, size.y * 0.2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_instructionText);
    
    // Start first round
    _startRound();
  }
  
  void _startRound() {
    _canTap = false;
    _targetCircle.paint.color = _waitColor;
    _instructionText.text = 'Wait for green...';
    
    // Random delay between 1-4 seconds
    final delay = 1000 + Random().nextInt(3000);
    
    Future.delayed(Duration(milliseconds: delay), () {
      if (!_canTap && _round < _maxRounds) {
        _targetCircle.paint.color = _goColor;
        _instructionText.text = 'TAP NOW!';
        _canTap = true;
        _colorChangeTime = DateTime.now();
      }
    });
  }
  
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    
    if (!_canTap) {
      // Tapped too early
      _instructionText.text = 'Too early! Wait for green.';
      _startRound();
      return;
    }
    
    // Calculate reaction time
    final reactionTime = DateTime.now().difference(_colorChangeTime!).inMilliseconds;
    _reactionTimes.add(reactionTime);
    
    // Calculate score (faster = more points, max 100 per round)
    final roundScore = max(0, 100 - (reactionTime ~/ 10));
    _score += roundScore;
    _round++;
    
    onScoreUpdate(_score);
    onReactionComplete(reactionTime);
    
    if (_round >= _maxRounds) {
      _gameOver();
    } else {
      _instructionText.text = '${reactionTime}ms! Round ${_round + 1}/$_maxRounds';
      Future.delayed(const Duration(seconds: 1), _startRound);
    }
  }
  
  void _gameOver() {
    _canTap = false;
    final avgReaction = _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;
    _instructionText.text = 'Done! Avg: ${avgReaction}ms';
    onGameOver();
  }
  
  int get score => _score;
  int get averageReactionTime => _reactionTimes.isEmpty 
      ? 0 
      : _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;
}
