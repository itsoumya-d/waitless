import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'haptic_service.dart';
import 'app_providers.dart';

/// Push notification service for crowd alerts
/// 
/// Handles FCM setup, topic subscriptions, and notification display.
class NotificationService {
  final FirebaseMessaging _messaging;
  
  NotificationService(this._messaging);
  
  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('📬 Notification permission: ${settings.authorizationStatus}');
      
      // Get FCM token
      final token = await _messaging.getToken();
      debugPrint('🔑 FCM Token: $token');
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle background message tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Check if app was opened via notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('❌ Notification service init failed: $e');
    }
  }
  
  // ============ Topic Subscriptions ============
  
  /// Subscribe to venue crowd alerts
  Future<void> subscribeToVenue(String venueId) async {
    try {
      await _messaging.subscribeToTopic('venue_$venueId');
      debugPrint('✅ Subscribed to venue_$venueId');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to venue: $e');
    }
  }
  
  /// Unsubscribe from venue alerts
  Future<void> unsubscribeFromVenue(String venueId) async {
    try {
      await _messaging.unsubscribeFromTopic('venue_$venueId');
      debugPrint('✅ Unsubscribed from venue_$venueId');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from venue: $e');
    }
  }
  
  /// Subscribe to city-wide alerts
  Future<void> subscribeToCity(String cityId) async {
    try {
      await _messaging.subscribeToTopic('city_$cityId');
      debugPrint('✅ Subscribed to city_$cityId');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to city: $e');
    }
  }
  
  /// Subscribe to category alerts (e.g., all grocery stores)
  Future<void> subscribeToCategory(String category) async {
    try {
      await _messaging.subscribeToTopic('category_$category');
      debugPrint('✅ Subscribed to category_$category');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to category: $e');
    }
  }
  
  // ============ Message Handling ============
  
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Foreground message: ${message.notification?.title}');
    
    // Show in-app alert using global key
    final title = message.notification?.title;
    final body = message.notification?.body;
    
    if (title != null && rootScaffoldMessengerKey.currentState != null) {
      rootScaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (body != null) Text(body),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          action: SnackBarAction(
            label: 'VIEW',
            onPressed: () {
              if (message.data.isNotEmpty) {
                _handleNotificationTap(message);
              }
            },
          ),
        ),
      );
    }
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    
    // Haptic feedback for notification tap
    HapticService.mediumImpact();
    
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final router = GoRouter.of(context);
    final data = message.data;

    // Enhanced navigation logic based on payload type
    if (data.containsKey('venueId')) {
      // Navigate to specific venue
      final venueId = data['venueId'];
      router.push('/venue/$venueId');
    } else if (data.containsKey('route')) {
      // Generic route navigation
      final route = data['route'];
      router.push(route);
    } else {
      // Type-based navigation
      switch (data['type']) {
        case 'activity':
          router.go('/activities');
          break;
        case 'wallet':
          router.go('/wallet');
          break;
        case 'leaderboard':
          router.push('/wallet/leaderboard');
          break;
        case 'favorites':
          router.push('/favorites');
          break;
        case 'badge_earned':
          // Show wallet with achievement celebration
          router.go('/wallet');
          HapticService.achievementUnlocked();
          break;
        case 'settings':
          router.go('/settings');
          break;
        default:
          // Default to home
          router.go('/');
      }
    }
  }
  
  // ============ FCM Token ============
  
  /// Get FCM token for server-side targeting
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
      return null;
    }
  }
  
  /// Listen for token refresh
  Stream<String> get tokenRefreshStream => _messaging.onTokenRefresh;
}

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FirebaseMessaging.instance);
});

/// Provider for notification permission status
final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  try {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  } catch (e) {
    return false;
  }
});

