import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Memory Match Game - Find matching pairs of colored cards
class MemoryMatchGame extends FlameGame with TapCallbacks {
  final Function(int score) onScoreUpdate;
  final Function(int matches) onMatchFound;
  final Function() onGameOver;
  
  // Game state
  int _score = 0;
  int _matches = 0;
  int _moves = 0;
  static const int _gridSize = 4; // 4x4 grid = 8 pairs
  static const int _totalPairs = 8;
  
  // Cards state
  final List<_MemoryCard> _cards = [];
  _MemoryCard? _firstSelected;
  _MemoryCard? _secondSelected;
  bool _canTap = true;
  
  // Card colors
  final List<Color> _cardColors = [
    const Color(0xFFE53935), // Red
    const Color(0xFF1E88E5), // Blue
    const Color(0xFF43A047), // Green
    const Color(0xFFFDD835), // Yellow
    const Color(0xFF8E24AA), // Purple
    const Color(0xFFFF6F00), // Orange
    const Color(0xFF00ACC1), // Cyan
    const Color(0xFFD81B60), // Pink
  ];
  
  MemoryMatchGame({
    required this.onScoreUpdate,
    required this.onMatchFound,
    required this.onGameOver,
  });
  
  @override
  Color backgroundColor() => const Color(0xFF1E293B);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializeCards();
  }
  
  void _initializeCards() {
    // Create pairs
    final colorPairs = <Color>[];
    for (int i = 0; i < _totalPairs; i++) {
      colorPairs.add(_cardColors[i]);
      colorPairs.add(_cardColors[i]);
    }
    
    // Shuffle
    colorPairs.shuffle(Random());
    
    // Calculate card size and positions
    final padding = 20.0;
    final availableWidth = size.x - (padding * 2);
    final availableHeight = size.y - (padding * 2) - 60; // Leave space for header
    final cardWidth = (availableWidth - (padding * (_gridSize - 1))) / _gridSize;
    final cardHeight = (availableHeight - (padding * (_gridSize - 1))) / _gridSize;
    final cardSize = min(cardWidth, cardHeight);
    
    final startX = (size.x - (cardSize * _gridSize + padding * (_gridSize - 1))) / 2;
    final startY = 60 + (availableHeight - (cardSize * _gridSize + padding * (_gridSize - 1))) / 2;
    
    // Create card components
    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        final index = row * _gridSize + col;
        final card = _MemoryCard(
          matchColor: colorPairs[index],
          position: Vector2(
            startX + col * (cardSize + padding),
            startY + row * (cardSize + padding),
          ),
          size: Vector2.all(cardSize),
          onTap: () => _onCardTapped(index),
        );
        _cards.add(card);
        add(card);
      }
    }
    
    // Add title
    add(TextComponent(
      text: 'Find the matching pairs!',
      position: Vector2(size.x / 2, 30),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
  }
  
  void _onCardTapped(int index) {
    if (!_canTap) return;
    
    final card = _cards[index];
    if (card.isMatched || card.isFlipped) return;
    
    card.flip();
    _moves++;
    
    if (_firstSelected == null) {
      _firstSelected = card;
    } else {
      _secondSelected = card;
      _canTap = false;
      
      // Check for match
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_firstSelected!.matchColor == _secondSelected!.matchColor) {
          // Match found
          _firstSelected!.setMatched();
          _secondSelected!.setMatched();
          _matches++;
          _score += 100 - min(50, _moves * 2); // Bonus for fewer moves
          
          onScoreUpdate(_score);
          onMatchFound(_matches);
          
          if (_matches >= _totalPairs) {
            onGameOver();
          }
        } else {
          // No match, flip back
          _firstSelected!.flipBack();
          _secondSelected!.flipBack();
        }
        
        _firstSelected = null;
        _secondSelected = null;
        _canTap = true;
      });
    }
  }
  
  int get score => _score;
  int get matches => _matches;
  int get moves => _moves;
}

/// Individual memory card component
class _MemoryCard extends PositionComponent with TapCallbacks {
  final Color matchColor;
  final VoidCallback onTap;
  
  bool _isFlipped = false;
  bool _isMatched = false;
  
  final Paint _backPaint = Paint()..color = const Color(0xFF374151);
  final Paint _borderPaint = Paint()
    ..color = const Color(0xFF4B5563)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  late Paint _frontPaint;
  
  _MemoryCard({
    required this.matchColor,
    required super.position,
    required Vector2 size,
    required this.onTap,
  }) : super(size: size) {
    _frontPaint = Paint()..color = matchColor;
  }
  
  bool get isFlipped => _isFlipped;
  bool get isMatched => _isMatched;
  
  void flip() {
    _isFlipped = true;
  }
  
  void flipBack() {
    _isFlipped = false;
  }
  
  void setMatched() {
    _isMatched = true;
  }
  
  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(12),
    );
    
    if (_isMatched) {
      // Matched cards show color with fade
      final fadedPaint = Paint()..color = matchColor.withValues(alpha: 0.5);
      canvas.drawRRect(rect, fadedPaint);
    } else if (_isFlipped) {
      // Flipped cards show color
      canvas.drawRRect(rect, _frontPaint);
    } else {
      // Face down
      canvas.drawRRect(rect, _backPaint);
      canvas.drawRRect(rect, _borderPaint);
      
      // Draw question mark
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '?',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.x - textPainter.width) / 2,
          (size.y - textPainter.height) / 2,
        ),
      );
    }
  }
  
  @override
  void onTapDown(TapDownEvent event) {
    onTap();
  }
}
