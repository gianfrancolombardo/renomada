import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/profile/screens/location_permission_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../shared/screens/main_screens.dart';
import '../../core/config/supabase_config.dart';

class AppRouter {
  static GoRouter createRouter(String initialLocation) {
    return GoRouter(
      initialLocation: initialLocation,
      redirect: (context, state) {
        // Check if user is authenticated
        final isAuthenticated = SupabaseConfig.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
        
        // If user is not authenticated and trying to access protected routes
        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }
        
        // If user is authenticated and trying to access login/signup
        if (isAuthenticated && isLoggingIn) {
          return '/location-permission';
        }
        
        return null; // No redirect needed
      },
      routes: [
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
        
        // Location permission route
        GoRoute(
          path: '/location-permission',
          name: 'location-permission',
          builder: (context, state) => const LocationPermissionScreen(),
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
  
  // Keep the old static router for backward compatibility
  static final GoRouter router = createRouter('/login');
}

