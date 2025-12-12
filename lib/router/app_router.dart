import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/venue/screens/venue_detail_screen.dart';
import '../features/activities/screens/activities_screen.dart';
import '../features/wallet/screens/wallet_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/home/debounced_search_screen.dart';
import '../features/venue/screens/venue_compare_screen.dart';
import '../features/settings/screens/profile_edit_screen.dart';
import '../features/settings/screens/report_history_screen.dart';
import '../features/settings/screens/interests_screen.dart';
import '../features/wallet/screens/weekly_stats_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../core/services/app_providers.dart';
import '../core/services/firebase_service.dart';
import '../features/venue/screens/venue_map_screen.dart';
import '../features/venue/screens/favorites_screen.dart';
import '../features/gamification/screens/leaderboard_screen.dart';
import '../features/settings/screens/privacy_policy_screen.dart';
import '../features/settings/screens/terms_of_service_screen.dart';
// New feature imports
import '../features/chat/screens/chat_screen.dart';
import '../features/games/screens/games_screen.dart';
import '../features/activities/screens/vocabulary_screen.dart';
import '../features/activities/screens/trivia_screen.dart';
import '../features/activities/screens/breathing_screen.dart';


/// Custom page transitions
CustomTransitionPage<T> _buildPageWithSlideTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;
      final tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

CustomTransitionPage<T> _buildPageWithFadeTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

/// Navigation shell for bottom navigation bar with animations
class MainShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  
  const MainShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: child,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        animationDuration: const Duration(milliseconds: 400),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 8,
        shadowColor: Colors.black26,
        surfaceTintColor: theme.colorScheme.surface,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/activities');
              break;
            case 2:
              context.go('/wallet');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Activities',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// App router configuration with transitions and redirect logic
final appRouterProvider = Provider<GoRouter>((ref) {
  // Check onboarding completion from SharedPreferences
  final prefs = ref.watch(sharedPreferencesProvider);
  final hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
  
  // Firebase Analytics observer for screen tracking
  final firebaseService = ref.watch(firebaseServiceProvider);
  final observers = <NavigatorObserver>[];
  if (firebaseService.isInitialized) {
    observers.add(FirebaseAnalyticsObserver(analytics: firebaseService.analytics));
  }
  
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: hasCompletedOnboarding ? '/' : '/onboarding',
    observers: observers,
    routes: [
      // Onboarding flow with fade transition
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      
      // Auth screen with fade transition
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          context: context,
          state: state,
          child: const AuthScreen(),
        ),
      ),
      
      // Notifications screen
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const NotificationsScreen(),
        ),
      ),
      
      // Search screen with slide transition
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const DebouncedSearchScreen(),
        ),
      ),
      
      // Map screen with slide transition
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const VenueMapScreen(),
        ),
      ),
      
      // Profile edit screen
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const ProfileEditScreen(),
        ),
      ),
      
      // Report history screen
      GoRoute(
        path: '/profile/history',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const ReportHistoryScreen(),
        ),
      ),
      
      // Interests screen
      GoRoute(
        path: '/profile/interests',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const InterestsScreen(),
        ),
      ),
      
      // Venue compare screen
      GoRoute(
        path: '/compare',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const VenueCompareScreen(),
        ),
      ),

      // Favorites screen
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const FavoritesScreen(),
        ),
      ),
      
      // Privacy Policy screen
      GoRoute(
        path: '/privacy-policy',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const PrivacyPolicyScreen(),
        ),
      ),
      
      // Terms of Service screen
      GoRoute(
        path: '/terms-of-service',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const TermsOfServiceScreen(),
        ),
      ),
      
      // AI Chat screen (replaces Report)
      GoRoute(
        path: '/chat',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const ChatScreen(),
        ),
      ),
      
      // Mini Games screen
      GoRoute(
        path: '/games',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const GamesScreen(),
        ),
      ),
      
      // Vocabulary learning screen
      GoRoute(
        path: '/vocabulary',
        pageBuilder: (context, state) {
          final language = state.uri.queryParameters['language'] ?? 'Spanish';
          final difficulty = state.uri.queryParameters['difficulty'] ?? 'beginner';
          return _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: VocabularyScreen(language: language, difficulty: difficulty),
          );
        },
      ),
      
      // Trivia quiz screen
      GoRoute(
        path: '/trivia',
        pageBuilder: (context, state) {
          final category = state.uri.queryParameters['category'] ?? 'general knowledge';
          return _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: TriviaScreen(category: category),
          );
        },
      ),
      
      // Breathing exercise screen
      GoRoute(
        path: '/breathing',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const BreathingScreen(),
        ),
      ),
      
      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          // Determine current index based on location
          final location = state.uri.path;
          int currentIndex = 0;
          if (location.startsWith('/activities')) {
            currentIndex = 1;
          } else if (location.startsWith('/wallet')) {
            currentIndex = 2;
          } else if (location.startsWith('/settings')) {
            currentIndex = 3;
          }
          return MainShell(
            currentIndex: currentIndex,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context: context,
              state: state,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/activities',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context: context,
              state: state,
              child: const ActivitiesScreen(),
            ),
          ),
          GoRoute(
            path: '/wallet',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context: context,
              state: state,
              child: const WalletScreen(),
            ),
            routes: [
              GoRoute(
                path: 'weekly',
                pageBuilder: (context, state) => _buildPageWithSlideTransition(
                  context: context,
                  state: state,
                  child: const WeeklyStatsScreen(),
                ),
              ),
              GoRoute(
                path: 'leaderboard',
                pageBuilder: (context, state) => _buildPageWithSlideTransition(
                  context: context,
                  state: state,
                  child: const LeaderboardScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context: context,
              state: state,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
      
      // Venue detail with slide transition (outside shell for full-screen experience)
      GoRoute(
        path: '/venue/:id',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: VenueDetailScreen(
            venueId: state.pathParameters['id']!,
          ),
        ),
      ),
    ],
  );
});
