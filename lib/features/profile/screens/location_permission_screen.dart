import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/services/location_service.dart';
import '../providers/location_provider.dart';

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
        // Location obtained, navigate to home
        context.pushReplacement('/home');
      } else if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Location icon
                    Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60.r),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 60.sp,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    
                    SizedBox(height: 32.h),
                    
                    // Title
                    Text(
                      'Ubicación para ReNomada',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    // Description
                    Text(
                      'Para mostrarte artículos cerca de ti, necesitamos acceso a tu ubicación.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 32.h),
                    
                    // Privacy explanation
                    if (_hasSeenExplanation) _buildPrivacyExplanation(),
                  ],
                ),
              ),
              
              // Action buttons
              _buildActionButtons(locationState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyExplanation() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: AppTheme.primaryColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Tu privacidad es importante',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          _buildPrivacyPoint(
            '📍 Ubicación aproximada',
            'Solo guardamos una ubicación redondeada (aproximadamente 50m de precisión)',
          ),
          
          SizedBox(height: 8.h),
          
          _buildPrivacyPoint(
            '🕒 Sin historial',
            'No guardamos un historial de tus ubicaciones, solo la última posición',
          ),
          
          SizedBox(height: 8.h),
          
          _buildPrivacyPoint(
            '🔒 Control total',
            'Puedes desactivar la ubicación en cualquier momento en tu perfil',
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
            color: AppTheme.primaryColor,
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
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
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
          height: 48.h,
          child: ElevatedButton(
            onPressed: locationState.isLoading ? null : _handleAllowLocation,
            child: locationState.isLoading
                ? const LoadingWidget(size: 20)
                : Text(
                    'Permitir ubicación',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // Skip button
        TextButton(
          onPressed: _handleSkip,
          child: Text(
            'Saltar por ahora',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryColor,
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
            _hasSeenExplanation ? 'Ocultar detalles de privacidad' : 'Ver detalles de privacidad',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.primaryColor,
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
    context.pushReplacement('/home');
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
