import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/utils/snackbar_utils.dart';
import '../providers/location_provider.dart';
import '../providers/profile_provider.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends ConsumerState<LocationPermissionScreen> {
  bool _hasSeenExplanation = false;

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    // Listen to location changes
    ref.listen<LocationState>(locationProvider, (previous, next) {
      if (next.hasLocation && mounted) {
        // Location obtained, check onboarding status and navigate accordingly
        _navigateAfterLocationObtained();
      } else if (next.error != null && mounted) {
        SnackbarUtils.showError(context, next.error!);
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              
              // Location icon
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(60.r),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.mapPin,
                  size: 60.sp,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Title
              Text(
                'Para mostrarte objetos cerca',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onBackground,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 16.h),
              
              // Description
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Mostramos objetos cerca de ti, nunca tu ruta. Puedes cambiarlo cuando quieras.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Privacy explanation
              if (_hasSeenExplanation) _buildPrivacyExplanation(),
              
              SizedBox(height: 32.h),
              
              // Action buttons
              _buildActionButtons(locationState),
              
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyExplanation() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  LucideIcons.shieldCheck,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Control total sobre tu ubicación',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          _buildPrivacyPoint(
            '📍 Ubicación aproximada',
            'Solo guardamos ubicación redondeada (~50m de precisión)',
          ),
          
          SizedBox(height: 12.h),
          
          _buildPrivacyPoint(
            '🔒 Sin historial',
            'No guardamos historial de ubicaciones, solo la última posición',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPoint(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          margin: EdgeInsets.only(top: 6.h, right: 12.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(LocationState locationState) {
    return Column(
      children: [
        // Allow location button
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: locationState.isLoading ? null : _handleAllowLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: locationState.isLoading
                ? LoadingWidget(
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                : Text(
                    'Activar ubicación',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // Skip button
        SizedBox(
          width: double.infinity,
          height: 44.h,
          child: TextButton(
            onPressed: _handleSkip,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Continuar sin ubicación',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        
        SizedBox(height: 8.h),
        
        // Privacy info button
        TextButton(
          onPressed: () {
            setState(() {
              _hasSeenExplanation = !_hasSeenExplanation;
            });
          },
          child: Text(
            _hasSeenExplanation ? 'Ocultar detalles' : 'Más sobre privacidad',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAllowLocation() async {
    final success = await ref.read(locationProvider.notifier).requestLocationPermission();
    
    if (!success && mounted) {
      // Handle different permission states
      final permissionStatus = ref.read(locationProvider).permissionStatus;
      
      if (permissionStatus == LocationPermissionStatus.permanentlyDenied) {
        _showPermanentlyDeniedDialog();
      }
    }
  }

  void _handleSkip() {
    // Navigate to home without location
    _navigateAfterLocationObtained();
  }

  void _navigateAfterLocationObtained() {
    final profileState = ref.read(profileProvider);
    
    // Check if user has seen onboarding
    if (profileState.profile != null && profileState.profile!.hasSeenOnboarding) {
      // User has seen onboarding, go directly to feed
      context.pushReplacement('/feed');
    } else {
      // User hasn't seen onboarding, go to onboarding screen
      context.pushReplacement('/onboarding');
    }
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso denegado'),
        content: const Text(
          'El permiso de ubicación fue denegado permanentemente. '
          'Para usar ReNomada con ubicación, ve a configuración de la aplicación '
          'y habilita el permiso de ubicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(locationProvider.notifier).openAppSettings();
            },
            child: const Text('Ir a configuración'),
          ),
        ],
      ),
    );
  }
}
