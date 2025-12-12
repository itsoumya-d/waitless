import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Color Tap Game - Tap the correct color as fast as possible
class ColorTapGame extends FlameGame with TapCallbacks {
  final Function(int score) onScoreUpdate;
  final Function(bool correct) onAnswer;
  final Function() onGameOver;
  
  // Game state
  int _score = 0;
  int _round = 0;
  int _correct = 0;
  static const int _maxRounds = 10;
  double _timeRemaining = 30.0;
  bool _gameActive = true;
  
  // Current target
  late Color _targetColor;
  final List<_ColorButton> _colorButtons = [];
  
  // UI Components
  late TextComponent _targetText;
  late TextComponent _scoreText;
  late TextComponent _timerText;
  late RectangleComponent _timerBar;
  
  // Available colors with names
  final Map<String, Color> _colorMap = {
    'RED': const Color(0xFFE53935),
    'BLUE': const Color(0xFF1E88E5),
    'GREEN': const Color(0xFF43A047),
    'YELLOW': const Color(0xFFFDD835),
    'PURPLE': const Color(0xFF8E24AA),
    'ORANGE': const Color(0xFFFF6F00),
  };
  
  ColorTapGame({
    required this.onScoreUpdate,
    required this.onAnswer,
    required this.onGameOver,
  });
  
  @override
  Color backgroundColor() => const Color(0xFF1E293B);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Timer bar background
    add(RectangleComponent(
      position: Vector2(20, 20),
      size: Vector2(size.x - 40, 8),
      paint: Paint()..color = const Color(0xFF374151),
    ));
    
    // Timer bar
    _timerBar = RectangleComponent(
      position: Vector2(20, 20),
      size: Vector2(size.x - 40, 8),
      paint: Paint()..color = const Color(0xFF10B981),
    );
    add(_timerBar);
    
    // Timer text
    _timerText = TextComponent(
      text: '30s',
      position: Vector2(size.x / 2, 45),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    add(_timerText);
    
    // Score text
    _scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(size.x - 20, 45),
      anchor: Anchor.centerRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    add(_scoreText);
    
    // Target instruction
    _targetText = TextComponent(
      text: 'Tap RED',
      position: Vector2(size.x / 2, size.y * 0.2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_targetText);
    
    // Create color buttons in a grid
    _createColorButtons();
    
    // Start game
    _nextRound();
  }
  
  void _createColorButtons() {
    final colors = _colorMap.values.toList();
    final buttonSize = min((size.x - 60) / 3, 100.0);
    final startX = (size.x - (buttonSize * 3 + 20 * 2)) / 2;
    final startY = size.y * 0.35;
    
    for (int i = 0; i < colors.length; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      
      final button = _ColorButton(
        buttonColor: colors[i],
        position: Vector2(
          startX + col * (buttonSize + 20),
          startY + row * (buttonSize + 20),
        ),
        buttonSize: buttonSize,
        onTap: () => _onColorTapped(colors[i]),
      );
      _colorButtons.add(button);
      add(button);
    }
  }
  
  void _nextRound() {
    if (_round >= _maxRounds || !_gameActive) {
      _endGame();
      return;
    }
    
    // Pick random target color
    final colorNames = _colorMap.keys.toList();
    final targetName = colorNames[Random().nextInt(colorNames.length)];
    _targetColor = _colorMap[targetName]!;
    
    // Update instruction with potential trick (show color name in different color)
    final displayColors = colorNames.toList()..shuffle();
    final displayColor = Random().nextBool() ? _targetColor : _colorMap[displayColors.first]!;
    
    _targetText.textRenderer = TextPaint(
      style: TextStyle(
        color: displayColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );
    _targetText.text = 'Tap $targetName';
    
    _round++;
  }
  
  void _onColorTapped(Color color) {
    if (!_gameActive) return;
    
    final isCorrect = color == _targetColor;
    
    if (isCorrect) {
      _correct++;
      _score += 10 + (_timeRemaining * 0.5).toInt(); // Time bonus
    } else {
      _score = max(0, _score - 5);
    }
    
    _scoreText.text = 'Score: $_score';
    onScoreUpdate(_score);
    onAnswer(isCorrect);
    
    // Brief flash feedback
    _nextRound();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_gameActive) {
      _timeRemaining -= dt;
      _timerBar.size.x = (size.x - 40) * (_timeRemaining / 30.0).clamp(0, 1);
      _timerText.text = '${_timeRemaining.toInt()}s';
      
      // Update timer bar color based on time
      if (_timeRemaining < 10) {
        _timerBar.paint.color = const Color(0xFFEF4444); // Red
      } else if (_timeRemaining < 20) {
        _timerBar.paint.color = const Color(0xFFF59E0B); // Yellow
      }
      
      if (_timeRemaining <= 0) {
        _endGame();
      }
    }
  }
  
  void _endGame() {
    _gameActive = false;
    _targetText.text = 'Game Over!';
    _targetText.textRenderer = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );
    onGameOver();
  }
  
  int get score => _score;
  int get correct => _correct;
  int get total => _round;
}

/// Individual color button component
class _ColorButton extends PositionComponent with TapCallbacks {
  final Color buttonColor;
  final double buttonSize;
  final VoidCallback onTap;
  
  late Paint _paint;
  late Paint _shadowPaint;
  
  _ColorButton({
    required this.buttonColor,
    required super.position,
    required this.buttonSize,
    required this.onTap,
  }) : super(size: Vector2.all(buttonSize)) {
    _paint = Paint()..color = buttonColor;
    _shadowPaint = Paint()..color = buttonColor.withValues(alpha: 0.3);
  }
  
  @override
  void render(Canvas canvas) {
    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x, size.y),
        const Radius.circular(16),
      ),
      _shadowPaint,
    );
    
    // Button
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(16),
      ),
      _paint,
    );
  }
  
  @override
  void onTapDown(TapDownEvent event) {
    onTap();
  }
}
