import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/avatar_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/location_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/widgets/onboarding_dialog.dart';
import '../../items/widgets/create_item_bottom_sheet.dart';
import '../../../shared/services/profile_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    // Update location when entering the app (if permission is granted)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateLocationIfPossible();
      _checkOnboarding();
    });
  }

  Future<void> _updateLocationIfPossible() async {
    final locationState = ref.read(locationProvider);
    
    if (locationState.isPermissionGranted) {
      // Check if location is fresh, if not, update it
      if (!ref.read(locationProvider.notifier).isLocationFresh()) {
        await ref.read(locationProvider.notifier).getCurrentLocation();
      }
    }
  }

  Future<void> _checkOnboarding() async {
    final profileState = ref.read(profileProvider);
    
    // Si no ha visto onboarding, mostrar dialog
    if (profileState.profile != null && 
        !profileState.profile!.hasSeenOnboarding) {
      _showOnboardingDialog();
    }
  }

  void _showOnboardingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // No cerrar tocando fuera
      builder: (context) => OnboardingDialog(
        onExplore: () async {
          await _markOnboardingSeen();
          if (mounted) {
            Navigator.pop(context);
            // Navegar al feed
            context.push('/feed');
          }
        },
        onPublish: () async {
          await _markOnboardingSeen();
          if (mounted) {
            Navigator.pop(context);
            // Mostrar bottom sheet de crear item
            _showCreateItemSheet();
          }
        },
        onSkip: () async {
          await _markOnboardingSeen();
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Future<void> _markOnboardingSeen() async {
    try {
      // await _profileService.markOnboardingAsSeen();
      // Actualizar el estado en el provider
      ref.read(profileProvider.notifier).loadProfile();
    } catch (e) {
      print('Error marking onboarding as seen: $e');
    }
  }

  void _showCreateItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateItemBottomSheet(),
    );
  }


  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppHeader(
        title: 'Inicio',
        actions: [
          // Profile dropdown
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.push('/profile');
                  break;
                case 'my_items':
                  context.push('/my-items');
                  break;
                case 'chats':
                  context.push('/chats');
                  break;
                case 'logout':
                  ref.read(authProvider.notifier).signOut();
                  context.go('/login');
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.user,
                      size: 18.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Perfil',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'my_items',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.package,
                      size: 18.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Mis artículos',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'chats',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.messageCircle,
                      size: 18.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Mis chats',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.logOut,
                      size: 18.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Cerrar sesión',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              margin: EdgeInsets.only(right: 8.w),
              child: CircleAvatar(
                radius: 16.r,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: profileState.profile?.avatarUrl != null
                    ? AvatarImage(
                        avatarUrl: profileState.profile!.avatarUrl!,
                        radius: 16.r,
                      )
                    : Icon(
                        LucideIcons.user,
                        size: 16.sp,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _updateLocationIfPossible();
        },
        child: CustomScrollView(
          slivers: [
            // Welcome section
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(20.w),
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primaryContainer,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Icon(
                            Icons.waving_hand,
                            size: 24.sp,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Hola, ${profileState.profile?.username ?? 'Nómada'}!',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Bienvenido de vuelta',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Comparte lo que ya no necesitas y encuentra tesoros cerca de ti. ¡Forma parte de una comunidad sostenible!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Quick actions section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acciones Rápidas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildQuickActionsGrid(context),
                  ],
                ),
              ),
            ),
            
            // Bottom spacing
            SliverToBoxAdapter(
              child: SizedBox(height: 100.h),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      {
        'title': 'Objetos',
        'icon': Icons.inventory_2_outlined,
        'onTap': () => context.push('/my-items'),
        'color': Theme.of(context).colorScheme.primary,
      },
      {
        'title': 'Explorar',
        'icon': Icons.explore_outlined,
        'onTap': () => context.push('/feed'),
        'color': Theme.of(context).colorScheme.secondary,
      },
      {
        'title': 'Chats',
        'icon': Icons.chat_bubble_outline,
        'onTap': () => context.push('/chats'),
        'color': Theme.of(context).colorScheme.tertiary,
      },
      {
        'title': 'Perfil',
        'icon': Icons.person_outline,
        'onTap': () => context.push('/profile'),
        'color': Theme.of(context).colorScheme.primary,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionCard(
          context,
          action['title'] as String,
          action['icon'] as IconData,
          action['color'] as Color,
          action['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 28.sp,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
