import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/services/profile_service.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _profileService = ProfileService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon/Logo
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.compass,
                  size: 60.sp,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              
              SizedBox(height: 40.h),
              
              // Title
              Text(
                '¡Hola! Esto es ReNomada',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 16.h),
              
              // Description
              Text(
                'Cerca, útil y ahora.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 48.h),
              
              // Main description
              Text(
                '¿Cómo quieres empezar?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 24.h),
              
              // Action options
              _buildActionOptions(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildActionOptions() {
    return Column(
      children: [
        // Explore option - Secondary theme
        _buildOptionCard(
          title: 'Explorar',
          subtitle: 'Descubre objetos cerca de ti',
          icon: LucideIcons.compass,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          iconColor: Theme.of(context).colorScheme.onSecondaryContainer,
          textColor: Theme.of(context).colorScheme.onSecondaryContainer,
          onTap: _handleExplore,
        ),
        
        SizedBox(height: 16.h),
        
        // Publish option - Tertiary theme
        _buildOptionCard(
          title: 'Publicar',
          subtitle: 'Regala lo que no viaja contigo',
          icon: LucideIcons.plusCircle,
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          iconColor: Theme.of(context).colorScheme.onTertiaryContainer,
          textColor: Theme.of(context).colorScheme.onTertiaryContainer,
          onTap: _handlePublish,
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                icon,
                size: 28.sp,
                color: iconColor,
              ),
            ),
            
            SizedBox(width: 20.w),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontSize: 18.sp,
                    ),
                  ),
                  
                  SizedBox(height: 6.h),
                  
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor.withOpacity(0.8),
                      height: 1.3,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                LucideIcons.arrowRight,
                size: 16.sp,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExplore() async {
    await _markOnboardingSeen();
    if (mounted) {
      context.go('/feed');
    }
  }

  Future<void> _handlePublish() async {
    await _markOnboardingSeen();
    if (mounted) {
      context.go('/my-items');
    }
  }


  Future<void> _markOnboardingSeen() async {
    try {
      // Mark onboarding as seen
      await _profileService.markOnboardingAsSeen();
      // Refresh the profile state
      ref.read(authProvider.notifier).refreshProfile();
    } catch (e) {
      print('Error marking onboarding as seen: $e');
    }
  }
}
