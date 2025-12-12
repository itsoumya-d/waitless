import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium Glassmorphism container widget.
/// 
/// Adds a blur effect, semi-transparent background, and subtle border
/// to create a "frosted glass" look.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Gradient? borderGradient;
  final double borderOpacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.borderGradient,
    this.borderOpacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(20);
    
    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (color ?? (isDark ? Colors.black : Colors.white)).withValues(alpha: opacity),
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: borderOpacity) 
                  : Colors.white.withValues(alpha: borderOpacity + 0.1),
              width: 1.5,
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
