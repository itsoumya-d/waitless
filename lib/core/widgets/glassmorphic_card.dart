import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A premium glassmorphic card with blur effect and gradient border
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 10,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.glassGradientDark
                      : AppColors.glassGradientLight,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isDark
                        ? AppColors.glassBorderDark
                        : AppColors.glassBorderLight,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Factory for a highlighted glassmorphic card with accent border
  factory GlassmorphicCard.highlighted({
    required Widget child,
    Color accentColor = AppColors.primary,
    double borderRadius = 20,
    double blur = 10,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return _HighlightedGlassmorphicCard(
      accentColor: accentColor,
      borderRadius: borderRadius,
      blur: blur,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

/// Highlighted variant with accent gradient border
class _HighlightedGlassmorphicCard extends GlassmorphicCard {
  final Color accentColor;

  const _HighlightedGlassmorphicCard({
    required super.child,
    required this.accentColor,
    super.borderRadius = 20,
    super.blur = 10,
    super.padding,
    super.margin,
    super.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.5),
            accentColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2), // Border width
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius - 2),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppColors.glassGradientDark
                        : AppColors.glassGradientLight,
                    borderRadius: BorderRadius.circular(borderRadius - 2),
                  ),
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple elevated card with premium shadow
class PremiumCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final int elevation; // 0, 1, 2, 4, 8, 16

  const PremiumCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Calculate shadow based on elevation
    final shadowOffset = elevation.toDouble();
    final shadowBlur = elevation * 2.0;
    final shadowOpacity = isDark ? 0.3 : 0.08 + (elevation * 0.01);
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? AppColors.cardDark : AppColors.cardLight),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: shadowOpacity),
                  blurRadius: shadowBlur,
                  spreadRadius: -2,
                  offset: Offset(0, shadowOffset),
                ),
                if (!isDark)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: shadowBlur / 2,
                    spreadRadius: -1,
                    offset: Offset(0, -shadowOffset / 2),
                  ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
