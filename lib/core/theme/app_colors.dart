import 'package:flutter/material.dart';

/// WaitLess Brand Colors
/// 
/// Primary: Electric Blue - represents speed, efficiency, technology
/// Secondary: Vibrant Green - represents time saved, success, go signals
/// Accent: Warm Orange - represents energy, engagement, warmth
abstract class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF2563EB);        // Electric Blue
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  
  // Secondary Brand Colors  
  static const Color secondary = Color(0xFF10B981);       // Emerald Green
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);
  
  // Accent Colors
  static const Color accent = Color(0xFFF59E0B);          // Amber Orange
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);
  
  // Crowd Level Colors
  static const Color crowdLow = Color(0xFF22C55E);        // Green - Low crowd
  static const Color crowdMedium = Color(0xFFEAB308);     // Yellow - Medium crowd
  static const Color crowdHigh = Color(0xFFEF4444);       // Red - High crowd
  static const Color crowdVeryHigh = Color(0xFF7C2D12);   // Dark Red - Very high
  
  // Background Colors - Light Mode
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  
  // Background Colors - Dark Mode
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF334155);
  
  // Text Colors - Light Mode
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF94A3B8);
  
  // Text Colors - Dark Mode
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textTertiaryDark = Color(0xFF94A3B8);
  
  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Glassmorphism Colors
  static final Color glassLight = Colors.white.withValues(alpha: 0.7);
  static final Color glassDark = Color(0xFF1E293B).withValues(alpha: 0.7);
  static final Color glassBorderLight = Colors.white.withValues(alpha: 0.2);
  static final Color glassBorderDark = Colors.white.withValues(alpha: 0.1);
  
  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, Color(0xFF7C3AED)], // Blue to Purple
  );
  
  static const LinearGradient glassGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white54, Colors.white12],
    stops: [0.1, 1],
  );

  static final LinearGradient glassGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B).withValues(alpha: 0.8), Color(0xFF1E293B).withValues(alpha: 0.2)],
    stops: [0.1, 1],
  );
  
  static const LinearGradient crowdLowGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
  );
  
  static const LinearGradient crowdMediumGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
  );
  
  static const LinearGradient crowdHighGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );
}
