import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

class AuthCallbackHandler {
  static final AuthCallbackHandler _instance = AuthCallbackHandler._internal();
  factory AuthCallbackHandler() => _instance;
  AuthCallbackHandler._internal();

  StreamSubscription<AuthState>? _authSubscription;

  /// Initialize auth callback listener
  void initialize(BuildContext context) {
    // Listen to auth state changes
    _authSubscription = SupabaseConfig.client.auth.onAuthStateChange.listen(
      (AuthState data) {
        final event = data.event;
        debugPrint('Auth event: $event');
        
        if (event == AuthChangeEvent.signedIn) {
          debugPrint('User signed in successfully');
          // The auth provider will handle navigation
        } else if (event == AuthChangeEvent.signedOut) {
          debugPrint('User signed out');
        } else if (event == AuthChangeEvent.tokenRefreshed) {
          debugPrint('Token refreshed');
        }
      },
      onError: (error) {
        debugPrint('Auth error: $error');
      },
    );
  }

  /// Dispose the listener
  void dispose() {
    _authSubscription?.cancel();
  }

  /// Handle deep link callback (for mobile)
  Future<void> handleDeepLink(Uri uri) async {
    debugPrint('Handling deep link: $uri');
    
    // Supabase automatically handles the OAuth callback
    // No additional processing needed
  }
}

