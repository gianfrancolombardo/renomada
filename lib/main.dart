import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/services/chat_realtime_service.dart';

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

class RenomadaApp extends ConsumerWidget {
  final String initialLocation;
  
  const RenomadaApp({super.key, required this.initialLocation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          routerConfig: AppRouter.createRouter(initialLocation, ProviderScope.containerOf(context)),
        );
      },
    );
  }
}

