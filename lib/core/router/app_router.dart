import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/profile/screens/location_permission_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/items/screens/my_items_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
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
          return '/feed';
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
        
        // Profile route
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        
        // My Items route
        GoRoute(
          path: '/my-items',
          name: 'my-items',
          builder: (context, state) => const MyItemsScreen(),
        ),
        
        // Feed route
        GoRoute(
          path: '/feed',
          name: 'feed',
          builder: (context, state) => const FeedScreen(),
        ),
        
        // Chat routes
        GoRoute(
          path: '/chats',
          name: 'chats',
          builder: (context, state) => const ChatListScreen(),
        ),
        GoRoute(
          path: '/chat/:chatId',
          name: 'chat',
          builder: (context, state) {
            final chatId = state.pathParameters['chatId']!;
            return ChatScreen(chatId: chatId);
          },
        ),
        
        // Onboarding route (placeholder for now)
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

// Placeholder screens
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 64),
            SizedBox(height: 16),
            Text(
              'Onboarding',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Pantalla de onboarding'),
          ],
        ),
      ),
    );
  }
}
