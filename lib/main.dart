import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/services/app_providers.dart';
import 'core/widgets/offline_indicator.dart';
import 'router/app_router.dart';
import 'firebase_options.dart';
import 'core/services/firebase_service.dart';
import 'core/services/seed_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseService.instance.initialize();
    
    // Seed initial data if needed
    if (FirebaseService.instance.isInitialized) {
      final seedService = SeedService(FirebaseService.instance.firestore);
      await seedService.seedVenuesIfNeeded();
    }
    
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('💡 Run `flutterfire configure` to set up Firebase');
  }
  // debugPrint('⚠️ Firebase is DISABLED - running in offline mode');
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const WaitLessApp(),
    ),
  );
}

/// Main application widget
class WaitLessApp extends ConsumerWidget {
  const WaitLessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final isDarkMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'WaitLess',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Router configuration
      routerConfig: router,
      
      // Wrap with offline indicator
      builder: (context, child) {
        return OfflineIndicator(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
