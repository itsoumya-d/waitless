import 'package:flutter/services.dart';

/// Service for providing haptic feedback throughout the app
class HapticService {
  const HapticService._();
  
  /// Light haptic feedback for subtle interactions
  /// Use for: button taps, selection changes, toggles
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }
  
  /// Medium haptic feedback for moderate interactions
  /// Use for: successful actions, confirmations
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }
  
  /// Heavy haptic feedback for significant interactions
  /// Use for: errors, important completions, achievements
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }
  
  /// Selection click for list items
  /// Use for: selecting items, tapping list tiles
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }
  
  /// Vibrate pattern for major achievements
  /// Use for: level up, badge earned, milestone reached
  static Future<void> achievementUnlocked() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }
  
  /// Success feedback pattern
  /// Use for: report submitted, action completed successfully
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }
  
  /// Error feedback pattern
  /// Use for: validation error, failed action
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }
  
  /// Favorite toggle feedback
  static Future<void> favorite() async {
    await HapticFeedback.mediumImpact();
  }
  
  /// Crowd report submission feedback
  static Future<void> crowdReportSubmitted() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }
}
