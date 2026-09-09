
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../../models/user_data.dart';

/// Authentication service for handling user login/signup
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseAnalytics? _analytics;
  
  AuthService(this._auth, [this._analytics]);
  
  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;
  
  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;
  
  /// Check if user is anonymous
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
    }
  }
  
  // ============ Email Auth ============
  
  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Update display name
    await credential.user?.updateDisplayName(displayName);

    // Analytics
    try {
      if (_analytics != null) {
        await _analytics.logSignUp(signUpMethod: 'password');
      }
    } catch (_) {}
    
    return credential;
  }
  
  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    try {
      if (_analytics != null) {
        await _analytics.logLogin(loginMethod: 'password');
      }
    } catch (_) {}

    return credential;
  }
  
  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  // ============ Anonymous Auth ============
  
  /// Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    try {
      if (_analytics != null) {
        await _analytics.logLogin(loginMethod: 'anonymous');
      }
    } catch (_) {}
    return credential;
  }
  
  /// Link anonymous account to email
  Future<UserCredential> linkWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    return await _auth.currentUser!.linkWithCredential(credential);
  }
  
  // ============ Sign Out ============
  
  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
  
  // ============ User Data ============
  
  /// Create UserData from Firebase user
  UserData? createUserDataFromAuth() {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return UserData(
      id: user.uid,
      displayName: user.displayName ?? 'Anonymous',
      email: user.email,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }
}

/// Provider for auth service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseAnalytics.instance);
});

/// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserId;
});

/// Provider for auth state
final isLoggedInProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isLoggedIn;
});

/// Provider for anonymous state
final isAnonymousProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAnonymous;
});

