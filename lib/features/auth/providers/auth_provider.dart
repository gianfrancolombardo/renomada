import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/services/profile_service.dart';
import '../../../shared/services/realtime_manager.dart';

// Auth state model
class AuthState {
  final User? user;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initializeAuth();
  }

  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final RealtimeManager _realtimeManager = RealtimeManager();

  // Initialize auth state
  void _initializeAuth() {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      state = state.copyWith(user: currentUser);
      _loadProfile();
    }

    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        state = state.copyWith(user: user, error: null);
        _loadProfile();
        // Initialize realtime after successful auth
        _realtimeManager.initialize();
      } else {
        state = const AuthState();
        // Disconnect realtime when user logs out
        _realtimeManager.disconnect();
      }
    });
  }

  // Load user profile
  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getCurrentProfile();
      state = state.copyWith(profile: profile);
    } catch (e) {
      // Profile might not exist yet, ignore error
    }
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _authService.signUp(
        email: email,
        password: password,
        username: username,
      );

      if (response.user != null) {
        state = state.copyWith(
          user: response.user,
          isLoading: false,
          error: null,
        );
        
        // Load the newly created profile
        try {
          await _loadProfile();
        } catch (e) {
          print('Error loading profile after signup: $e');
          // Don't fail the signup if profile loading fails
          // The profile will be loaded later
        }
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Error al crear la cuenta. Verifica tu email.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e.toString()),
      );
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('Login successful for user: ${response.user!.id}');
        
        state = state.copyWith(
          user: response.user,
          isLoading: false,
          error: null,
        );
        
        // Load profile after successful login
        try {
          await _loadProfile();
          print('Profile loaded successfully');
          // Initialize realtime after successful login
          await _realtimeManager.initialize();
        } catch (e) {
          print('Error loading profile: $e');
          // Don't fail the login if profile loading fails
        }
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Credenciales incorrectas',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e.toString()),
      );
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true);
      // Disconnect realtime before signing out
      await _realtimeManager.disconnect();
      await _authService.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cerrar sesión',
      );
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.resetPassword(email);
      state = state.copyWith(
        isLoading: false,
        error: 'Revisa tu email para restablecer la contraseña',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e.toString()),
      );
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh profile
  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  // Get user-friendly error message
  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos';
    } else if (error.contains('User already registered')) {
      return 'Este email ya está registrado';
    } else if (error.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    } else if (error.contains('Invalid email')) {
      return 'Email inválido';
    } else if (error.contains('Email not confirmed')) {
      return 'Confirma tu email antes de iniciar sesión';
    } else if (error.contains('Too many requests')) {
      return 'Demasiados intentos. Intenta más tarde';
    } else {
      return 'Error inesperado. Intenta nuevamente';
    }
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Convenience providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final currentProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authProvider).profile;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
