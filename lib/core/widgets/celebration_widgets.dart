import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// A confetti celebration overlay for achievements
class ConfettiCelebration extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onComplete;
  final Duration duration;
  final int particleCount;

  const ConfettiCelebration({
    super.key,
    required this.isActive,
    this.onComplete,
    this.duration = const Duration(seconds: 3),
    this.particleCount = 50,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startCelebration();
    }
  }

  void _startCelebration() {
    HapticFeedback.heavyImpact();
    _generateParticles();
    _controller.forward(from: 0);
  }

  void _generateParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return _ConfettiParticle(
        color: _getRandomColor(),
        startX: _random.nextDouble(),
        startY: -0.1 - _random.nextDouble() * 0.2,
        velocityX: (_random.nextDouble() - 0.5) * 2,
        velocityY: 0.5 + _random.nextDouble(),
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
        size: 8 + _random.nextDouble() * 8,
        shape: _ConfettiShape.values[_random.nextInt(_ConfettiShape.values.length)],
      );
    });
  }

  Color _getRandomColor() {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
      AppColors.crowdLow,
      Colors.amber,
      Colors.pink,
      Colors.purple,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive && !_controller.isAnimating) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

enum _ConfettiShape { square, circle, rectangle }

class _ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final _ConfettiShape shape;

  _ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = size.width * (particle.startX + particle.velocityX * progress);
      final y = size.height * (particle.startY + particle.velocityY * progress * 1.5);
      final rotation = particle.rotation + particle.rotationSpeed * progress * pi;
      
      // Fade out as it falls
      final opacity = (1 - progress * 0.7).clamp(0.0, 1.0);
      
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      switch (particle.shape) {
        case _ConfettiShape.square:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size),
            paint,
          );
          break;
        case _ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;
        case _ConfettiShape.rectangle:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 0.5),
            paint,
          );
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// An animated progress bar with fill animation
class AnimatedProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Duration animationDuration;
  final BorderRadius? borderRadius;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.backgroundColor,
    this.gradient,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(height / 2);
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade200,
        borderRadius: radius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Container(
                    width: constraints.maxWidth * value,
                    decoration: BoxDecoration(
                      gradient: gradient ?? AppColors.primaryGradient,
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// An animated counter that ticks up to the target value
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          '$prefix${animatedValue.round()}$suffix',
          style: style,
        );
      },
    );
  }
}
