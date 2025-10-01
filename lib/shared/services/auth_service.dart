import 'package:supabase_flutter/supabase_flutter.dart';
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
    String? username,
  }) async {
    final response = await SupabaseConfig.client.auth.signUp(
      email: email,
      password: password,
      data: username != null ? {'username': username} : null,
    );

    // Profile will be created automatically by the database trigger
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
      await SupabaseConfig.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.renomada://login-callback/',
      );
      return true;
    } catch (e) {
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
