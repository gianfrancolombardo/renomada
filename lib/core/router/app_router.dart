import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/profile/screens/location_permission_screen.dart';
import '../../features/profile/screens/location_recovery_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../shared/screens/main_screens.dart';
import '../../core/config/supabase_config.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppRouter {
  static GoRouter createRouter(String initialLocation, ProviderContainer container) {
    // Create a notifier that will trigger router refresh when auth state changes
    final authListenable = _AuthListenable(container);
    
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: authListenable,
      redirect: (context, state) {
        // Check if this is an OAuth callback (has code or access_token in query/fragment)
        final uri = state.uri;
        final hasAuthCode = uri.queryParameters.containsKey('code');
        final hasAccessToken = uri.fragment.contains('access_token=') || 
                               uri.queryParameters.containsKey('access_token');
        
        if (hasAuthCode || hasAccessToken) {
          // This is an OAuth callback
          // Supabase will automatically process it via onAuthStateChange
          // Wait a bit for Supabase to process, then check auth status
          print('OAuth callback detected, processing...');
          
          // Check if user is already authenticated (callback may have been processed)
          final isAuthenticated = SupabaseConfig.isAuthenticated;
          if (isAuthenticated) {
            // Callback already processed, redirect based on onboarding status
            final authState = container.read(authProvider);
            final profile = authState.profile;
            if (profile != null && !profile.hasSeenOnboarding) {
              return '/onboarding';
            }
            return '/feed';
          }
          
          // Return null to allow the route to load, Supabase will handle the auth
          // The router will refresh when auth state changes (via refreshListenable)
          return null;
        }
        
        // Check if user is authenticated
        final isAuthenticated = SupabaseConfig.isAuthenticated;
        final currentPath = state.matchedLocation;
        
        // Public routes that don't require authentication
        final isPublicRoute = currentPath == '/' || 
                              currentPath == '/login' || 
                              currentPath == '/signup' ||
                              currentPath == '/register';
        
        // If user is authenticated and trying to access public routes, check onboarding status
        if (isAuthenticated && isPublicRoute) {
          final authState = container.read(authProvider);
          final profile = authState.profile;
          
          // If trying to access onboarding but already seen it, redirect to feed
          if (currentPath == '/onboarding' && profile != null && profile.hasSeenOnboarding) {
            return '/feed';
          }
          
          // If accessing other public routes and hasn't seen onboarding, redirect to onboarding
          if (currentPath != '/onboarding' && profile != null && !profile.hasSeenOnboarding) {
            return '/onboarding';
          }
          
          // Otherwise redirect to feed
          if (currentPath != '/onboarding') {
            return '/feed';
          }
        }
        
        // If user is not authenticated and trying to access protected routes
        if (!isAuthenticated && !isPublicRoute) {
          return '/';
        }
        
        return null; // No redirect needed
      },
      routes: [
        // Welcome screen - Root route
        GoRoute(
          path: '/',
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        
        // Auth routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        // Alias for signup - register route (same page, different URL)
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const SignUpScreen(), // Same page as signup
        ),
        
        // Location permission route
        GoRoute(
          path: '/location-permission',
          name: 'location-permission',
          builder: (context, state) => const LocationPermissionScreen(),
        ),
        
        // Location recovery route
        GoRoute(
          path: '/location-recovery',
          name: 'location-recovery',
          builder: (context, state) => const LocationRecoveryScreen(),
        ),
        
        // Home route
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        
        // Main app routes with bottom navigation
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileMainScreen(),
        ),
        
        // My Items route
        GoRoute(
          path: '/my-items',
          name: 'my-items',
          builder: (context, state) => const MyItemsMainScreen(),
        ),
        
        // Feed route
        GoRoute(
          path: '/feed',
          name: 'feed',
          builder: (context, state) => const FeedMainScreen(),
        ),
        
        // Chat routes
        GoRoute(
          path: '/chats',
          name: 'chats',
          builder: (context, state) => const ChatsMainScreen(),
        ),
        GoRoute(
          path: '/chat/:chatId',
          name: 'chat',
          builder: (context, state) {
            final chatId = state.pathParameters['chatId']!;
            return ChatScreen(chatId: chatId);
          },
        ),
        
        // Onboarding route
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
      ],
    );
  }
  
  // Note: Static router removed - use createRouter with ProviderContainer instead
}

// ChangeNotifier that notifies router when auth state changes
class _AuthListenable extends ChangeNotifier {
  final ProviderContainer _container;
  _AuthListenable(this._container) {
    // Listen to auth state changes
    _container.listen(
      authProvider,
      (previous, next) {
        // Notify listeners when auth state changes (user logs in/out)
        // This will trigger the router to re-evaluate redirects
        notifyListeners();
      },
      fireImmediately: false,
    );
  }
}

