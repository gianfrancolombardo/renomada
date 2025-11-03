import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/services/chat_realtime_service.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  // Initialize chat realtime if user is authenticated
  if (SupabaseConfig.isAuthenticated) {
    await ChatRealtimeService().initialize();
  }
  
  // Check if user is already authenticated and set initial route
  final isAuthenticated = SupabaseConfig.isAuthenticated;
  final initialLocation = isAuthenticated ? '/feed' : '/';
  
  runApp(
    ProviderScope(
      child: RenomadaApp(initialLocation: initialLocation),
    ),
  );
}

class RenomadaApp extends ConsumerStatefulWidget {
  final String initialLocation;
  
  const RenomadaApp({super.key, required this.initialLocation});

  @override
  ConsumerState<RenomadaApp> createState() => _RenomadaAppState();
}

class _RenomadaAppState extends ConsumerState<RenomadaApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    // Create router once using the container from context
    _router ??= AppRouter.createRouter(
      widget.initialLocation,
      ProviderScope.containerOf(context),
    );
    // Listen to auth changes globally to handle OAuth callbacks
    // This is especially important for Android where the callback may arrive
    // when the app is in any screen (not just LoginScreen)
    // Note: The router's refreshListenable should handle most cases,
    // but this provides a fallback for edge cases
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Only handle navigation if user just authenticated (was null, now has user)
      if (next.user != null && previous?.user == null) {
        // Use a small delay to ensure Supabase has fully processed the session
        // and router refresh has been triggered
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          
          try {
            final router = GoRouter.of(context);
            final currentPath = router.routerDelegate.currentConfiguration.uri.path;
            
            // Only navigate if we're still on a public route (welcome/login/signup)
            // The router's redirect logic should handle this, but this is a fallback
            if (currentPath == '/' || 
                currentPath == '/login' || 
                currentPath == '/signup' ||
                currentPath == '/register') {
              print('Global auth listener (fallback): User authenticated, navigating from $currentPath');
              
              // Check if user needs onboarding
              final authState = ref.read(authProvider);
              final profile = authState.profile;
              
              if (profile != null && !profile.hasSeenOnboarding) {
                router.go('/onboarding');
              } else {
                router.go('/feed');
              }
            }
          } catch (e) {
            print('Error in global auth listener navigation: $e');
          }
        });
      }
    });

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'ReNomada',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark, // Modo oscuro por defecto
          routerConfig: _router!,
        );
      },
    );
  }
}

