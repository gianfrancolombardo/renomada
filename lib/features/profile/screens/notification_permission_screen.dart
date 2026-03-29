import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/services/push_notification_service.dart';

/// Same layout and interaction pattern as [LocationPermissionScreen].
/// [nextRoute] is where we go after allow or skip (e.g. `/onboarding` or `/feed`).
class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key, required this.nextRoute});

  final String nextRoute;

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen> {
  bool _hasSeenExplanation = false;
  bool _busy = false;

  Future<void> _handleAllowNotifications() async {
    setState(() => _busy = true);
    try {
      await PushNotificationService.instance.syncSubscriptionForCurrentUser();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) context.go(widget.nextRoute);
  }

  void _handleSkip() {
    context.go(widget.nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),

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
                  LucideIcons.bell,
                  size: 60.sp,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),

              SizedBox(height: 32.h),

              Text(
                'Para avisarte de lo importante',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16.h),

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
                  'Te avisamos de chats y de cosas nuevas cerca de ti. '
                  'Puedes cambiarlo cuando quieras.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 24.h),

              if (_hasSeenExplanation) _buildExplanationPanel(),

              SizedBox(height: 32.h),

              _buildActionButtons(),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationPanel() {
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
              Expanded(
                child: Text(
                  'Qué avisos enviamos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildBulletPoint(
            'Mensajes en el chat',
            'Cuando alguien te escribe en una conversación.',
          ),
          SizedBox(height: 12.h),
          _buildBulletPoint(
            'Nuevos objetos cerca',
            'Cuando se publica algo cerca de tu zona.',
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String title, String description) {
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: _busy ? null : _handleAllowNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _busy
                ? LoadingWidget(
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                : Text(
                    'Activar notificaciones',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          height: 44.h,
          child: TextButton(
            onPressed: _busy ? null : _handleSkip,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Continuar sin avisos',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: _busy
              ? null
              : () {
                  setState(() {
                    _hasSeenExplanation = !_hasSeenExplanation;
                  });
                },
          child: Text(
            _hasSeenExplanation ? 'Ocultar detalles' : 'Más sobre los avisos',
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
}
