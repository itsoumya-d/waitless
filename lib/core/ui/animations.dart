import 'package:flutter/material.dart';

/// Standard durations for animations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration verySlow = Duration(milliseconds: 1000);
}

/// Curve definitions for consistent motion
class AppCurves {
  static const Curve emphasis = Curves.easeInOutCubicEmphasized;
  static const Curve smooth = Curves.easeInOut;
  static const Curve bounce = Curves.elasticOut;
}

/// A builder for staggered list animations
class StaggeredAnimation {
  static Widget listSlideFade({
    required int index,
    required Widget child,
    Duration duration = AppDurations.medium,
    double slideOffset = 50.0,
  }) {
    // We'll use flutter_animate in the actual implementation, 
    // but this helper can abstract common patterns if we weren't using that package.
    // Since we ARE using flutter_animate, this class serves as a central config 
    // for durations and curves.
    return child;
  }
}

/// Custom page transition builder
class PremiumPageTransition extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: AppCurves.emphasis,
        )),
        child: child,
      ),
    );
  }
}
