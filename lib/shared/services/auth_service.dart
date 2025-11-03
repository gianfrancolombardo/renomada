import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/config/supabase_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Current user stream
  Stream<User?> get authStateChanges => 
      SupabaseConfig.client.auth.onAuthStateChange.map((data) => data.session?.user);

  // Current user
  User? get currentUser => SupabaseConfig.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => SupabaseConfig.isAuthenticated;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await SupabaseConfig.client.auth.signUp(
      email: email,
      password: password,
    );

    // Profile will be created automatically by the database trigger
    // Username is auto-generated from email (part before @)
    // Just wait a bit for it to be created
    if (response.user != null) {
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await SupabaseConfig.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with OAuth provider
  Future<bool> signInWithProvider(OAuthProvider provider) async {
    try {
      // Determine redirect URL based on platform
      String redirectTo;
      if (kIsWeb) {
        // For web, use current origin (root URL without hash/path)
        // This allows Supabase to handle the OAuth callback properly
        // The redirect URL must match exactly what's configured in Supabase dashboard
        // Example: https://app.renomada.com/ (without #/login)
        final currentUrl = Uri.base;
        final baseUrl = '${currentUrl.scheme}://${currentUrl.host}${currentUrl.hasPort ? ':${currentUrl.port}' : ''}';
        // Use root URL - Supabase will append the callback params
        // Note: The hash routing (#/login) is handled by the client-side router
        redirectTo = '$baseUrl/';
        print('OAuth redirect URL for web: $redirectTo');
      } else {
        // For mobile native apps, use deep link
        redirectTo = 'io.supabase.renomada://login-callback/';
      }
      
      final response = await SupabaseConfig.client.auth.signInWithOAuth(
        provider,
        redirectTo: redirectTo,
        // Launch URL in system browser for better mobile UX (only on mobile)
        authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
      
      return response;
    } catch (e) {
      print('OAuth sign in error: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await SupabaseConfig.client.auth.resetPasswordForEmail(email);
  }

  // Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await SupabaseConfig.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

}
