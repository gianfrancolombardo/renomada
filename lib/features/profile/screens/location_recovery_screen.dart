import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/services/location_log_service.dart';
import '../../../shared/utils/snackbar_utils.dart';
import '../providers/location_provider.dart';
import '../providers/profile_provider.dart';

class LocationRecoveryScreen extends ConsumerStatefulWidget {
  const LocationRecoveryScreen({super.key});

  @override
  ConsumerState<LocationRecoveryScreen> createState() => _LocationRecoveryScreenState();
}

class _LocationRecoveryScreenState extends ConsumerState<LocationRecoveryScreen> with WidgetsBindingObserver {
  bool _hasSeenSteps = false;
  bool _isCheckingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When user returns from settings, check if permission was granted
    if (state == AppLifecycleState.resumed) {
      _checkIfPermissionGranted();
    }
  }

  Future<void> _checkInitialPermission() async {
    final locationState = ref.read(locationProvider);
    
    // If already granted, navigate to feed
    if (locationState.isPermissionGranted && locationState.hasLocation) {
      if (mounted) {
        _navigateAfterLocationObtained();
      }
      return;
    }

    // Log that recovery screen was shown
    final logService = LocationLogService();
    await logService.logEvent(
      eventType: LocationEventType.permissionPermanentlyDenied,
      action: LocationAction.initialize,
      permissionStatus: locationState.permissionStatus,
      metadata: {'screen': 'location_recovery'},
    );
  }

  Future<void> _checkIfPermissionGranted() async {
    if (_isCheckingPermission) return;
    
    setState(() {
      _isCheckingPermission = true;
    });

    try {
      // Check permission status
      final locationService = LocationService();
      final permission = await locationService.checkLocationPermission();
      
      if (permission == LocationPermissionStatus.granted) {
        // Permission granted! Try to get location
        final logService = LocationLogService();
        await logService.logEvent(
          eventType: LocationEventType.permissionGranted,
          action: LocationAction.checkPermission,
          permissionStatus: permission,
          metadata: {'source': 'settings_return'},
        );

        final success = await ref.read(locationProvider.notifier).getCurrentLocation();
        
        if (success && mounted) {
          // Success! Navigate to feed
          SnackbarUtils.showSuccess(context, '¡Ubicación activada!');
          _navigateAfterLocationObtained();
        } else if (mounted) {
          SnackbarUtils.showError(context, 'No se pudo obtener la ubicación. Verifica que el GPS esté activado.');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Error al verificar permisos: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPermission = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              
              // Location icon with warning style
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(60.r),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.mapPinOff,
                  size: 60.sp,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Title
              Text(
                'Necesitamos tu ubicación',
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
                child: Column(
                  children: [
                    Text(
                      'Para mostrarte objetos cerca de ti y mejorar tu experiencia en ReNomada, necesitamos acceso a tu ubicación.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    _buildValuePoint(
                      LucideIcons.mapPin,
                      'Ver objetos cerca',
                      'Encuentra intercambios en tu zona',
                    ),
                    SizedBox(height: 12.h),
                    _buildValuePoint(
                      LucideIcons.search,
                      'Búsqueda inteligente',
                      'Filtra por distancia',
                    ),
                    SizedBox(height: 12.h),
                    _buildValuePoint(
                      LucideIcons.shield,
                      'Privacidad protegida',
                      'Solo compartimos ubicación aproximada',
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Steps explanation
              if (_hasSeenSteps) _buildStepsGuide(),
              
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

  Widget _buildValuePoint(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 18.sp,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        SizedBox(width: 12.w),
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

  Widget _buildStepsGuide() {
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
                  LucideIcons.settings,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Cómo habilitar la ubicación',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          _buildStep(
            1,
            'Presiona "Abrir configuración"',
            'Te llevaremos a la configuración de la app',
          ),
          
          SizedBox(height: 12.h),
          
          _buildStep(
            2,
            'Busca "Ubicación" o "Location"',
            'En la lista de permisos de ReNomada',
          ),
          
          SizedBox(height: 12.h),
          
          _buildStep(
            3,
            'Selecciona "Permitir siempre"',
            'O "Permitir mientras usas la app"',
          ),
          
          SizedBox(height: 12.h),
          
          _buildStep(
            4,
            'Vuelve a la app',
            'Tu ubicación se activará automáticamente',
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24.w,
          height: 24.w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
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
        // Open settings button
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: _isCheckingPermission ? null : _handleOpenSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _isCheckingPermission
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.settings,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Abrir configuración',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // Skip button (only if we allow it - depends on chosen option)
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
        
        // Show steps button
        TextButton(
          onPressed: () {
            setState(() {
              _hasSeenSteps = !_hasSeenSteps;
            });
          },
          child: Text(
            _hasSeenSteps ? 'Ocultar pasos' : 'Ver pasos para habilitar',
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

  Future<void> _handleOpenSettings() async {
    final logService = LocationLogService();
    await logService.logSettingsOpened('app');
    
    await ref.read(locationProvider.notifier).openAppSettings();
    
    // Note: We'll check permission when user returns via didChangeAppLifecycleState
  }

  void _handleSkip() {
    // Log skip action
    final logService = LocationLogService();
    logService.logSkipLocation();
    
    // Navigate to feed without location
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
}

