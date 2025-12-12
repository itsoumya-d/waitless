import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/services/firebase_service.dart';

/// Onboarding screen with 6-step flow including permissions
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _locationGranted = false;
  bool _notificationGranted = false;
  
  final List<String> _selectedInterests = [];
  
  // Total pages: 3 info + 1 location + 1 notification + 1 interests = 6
  static const int _totalPages = 6;
  
  static const List<Map<String, dynamic>> _infoPages = [
    {
      'title': 'Save 2+ Hours\nEvery Week',
      'subtitle': 'Know the perfect time to visit any place. Skip the crowds, save your time.',
      'icon': Icons.access_time_filled,
      'color': AppColors.primary,
    },
    {
      'title': 'Real-Time\nCrowd Pulse',
      'subtitle': 'See live crowd levels at stores, gyms, restaurants, and more—powered by our community.',
      'icon': Icons.people_alt_rounded,
      'color': AppColors.secondary,
    },
    {
      'title': 'Fill the Wait\nWith Wonder',
      'subtitle': 'When you do wait, enjoy personalized activities—learn, play, or just relax.',
      'icon': Icons.auto_awesome,
      'color': AppColors.accent,
    },
  ];
  
  static const List<Map<String, String>> _interests = [
    {'id': 'learning', 'name': 'Learning', 'icon': '📚'},
    {'id': 'news', 'name': 'News', 'icon': '📰'},
    {'id': 'games', 'name': 'Games', 'icon': '🎮'},
    {'id': 'meditation', 'name': 'Meditation', 'icon': '🧘'},
    {'id': 'productivity', 'name': 'Productivity', 'icon': '✅'},
    {'id': 'languages', 'name': 'Languages', 'icon': '🌍'},
    {'id': 'fitness', 'name': 'Fitness', 'icon': '💪'},
    {'id': 'music', 'name': 'Music', 'icon': '🎵'},
  ];

  Future<void> _requestLocationPermission() async {
    HapticFeedback.lightImpact();
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    setState(() {
      _locationGranted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });
    
    if (_locationGranted) {
      await Future.delayed(const Duration(milliseconds: 300));
      _nextPage();
    }
  }
  
  Future<void> _requestNotificationPermission() async {
    HapticFeedback.lightImpact();
    
    final status = await Permission.notification.request();
    
    setState(() {
      _notificationGranted = status.isGranted;
    });
    
    if (_notificationGranted) {
      await Future.delayed(const Duration(milliseconds: 300));
      _nextPage();
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }
  
  Future<void> _completeOnboarding() async {
    HapticFeedback.heavyImpact();
    
    // Save onboarding completion
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hasCompletedOnboarding', true);

    // Track analytics
    try {
        final firebase = ref.read(firebaseServiceProvider);
        if (firebase.isInitialized) {
          await firebase.logEvent(name: 'tutorial_complete');
        }
    } catch (_) {}
    
    // Save selected interests
    await prefs.setStringList('selectedInterests', _selectedInterests);
    
    if (mounted) {
      context.go('/');
    }
  }
  
  void _skip() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  if (index < 3) {
                    return _buildInfoPage(index);
                  } else if (index == 3) {
                    return _buildLocationPermissionPage();
                  } else if (index == 4) {
                    return _buildNotificationPermissionPage();
                  } else {
                    return _buildInterestsPage();
                  }
                },
              ),
            ),
            
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive 
                          ? AppColors.primary 
                          : AppColors.textTertiaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            
            // Next button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _getButtonAction(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _getButtonText(),
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  VoidCallback? _getButtonAction() {
    if (_currentPage == 3) {
      return _locationGranted ? _nextPage : _requestLocationPermission;
    } else if (_currentPage == 4) {
      return _notificationGranted ? _nextPage : _requestNotificationPermission;
    } else if (_currentPage == 5 && _selectedInterests.isEmpty) {
      return null;
    }
    return _nextPage;
  }
  
  String _getButtonText() {
    if (_currentPage == 3) {
      return _locationGranted ? 'Continue' : 'Enable Location';
    } else if (_currentPage == 4) {
      return _notificationGranted ? 'Continue' : 'Enable Notifications';
    } else if (_currentPage == 5) {
      return 'Get Started';
    }
    return 'Continue';
  }

  Widget _buildInfoPage(int index) {
    final page = _infoPages[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (page['color'] as Color).withValues(alpha: 0.2),
                  (page['color'] as Color).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              page['icon'] as IconData,
              size: 64,
              color: page['color'] as Color,
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(delay: 200.ms),
          
          const SizedBox(height: 48),
          
          // Title
          Text(
            page['title'] as String,
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            page['subtitle'] as String,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
  
  Widget _buildLocationPermissionPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withValues(alpha: 0.2),
                  AppColors.info.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 64,
                  color: AppColors.info,
                ),
                if (_locationGranted)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
          
          const SizedBox(height: 48),
          
          Text(
            'Enable Location',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
          
          const SizedBox(height: 16),
          
          Text(
            'We need your location to show nearby venues and their crowd levels in real-time.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          
          if (_locationGranted) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Location enabled',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).scale(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildNotificationPermissionPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.2),
                  AppColors.accent.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 64,
                  color: AppColors.accent,
                ),
                if (_notificationGranted)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
          
          const SizedBox(height: 48),
          
          Text(
            'Stay Notified',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
          
          const SizedBox(height: 16),
          
          Text(
            'Get alerts when your favorite spots are empty or when crowd levels drop.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          
          if (_notificationGranted) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Notifications enabled',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).scale(),
          ],
        ],
      ),
    );
  }

  Widget _buildInterestsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          
          Text(
            'What interests you?',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'We\'ll personalize your wait time activities.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: 32),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _interests.length,
              itemBuilder: (context, index) {
                final interest = _interests[index];
                final isSelected = _selectedInterests.contains(interest['id']);
                
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(interest['id']);
                      } else {
                        _selectedInterests.add(interest['id']!);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primary 
                            : AppColors.textTertiaryLight.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          interest['icon']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          interest['name']!,
                          style: AppTypography.labelLarge.copyWith(
                            color: isSelected 
                                ? AppColors.primary 
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate(delay: (index * 50).ms)
                    .fadeIn(duration: 300.ms)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
              },
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

