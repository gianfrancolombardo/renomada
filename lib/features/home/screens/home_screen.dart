import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/avatar_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/location_provider.dart';
import '../../profile/providers/profile_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Update location when entering the app (if permission is granted)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateLocationIfPossible();
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


  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReNomada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              // Navigate to location permission screen
              context.push('/location-permission');
            },
          ),
          _buildProfileDropdown(context, profileState.profile),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh is not needed in HomeScreen anymore
        },
        child: CustomScrollView(
          slivers: [
            // Welcome section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${profileState.profile?.username ?? 'Nómada'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comparte lo que ya no necesitas y encuentra tesoros cerca de ti',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Quick actions section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acciones Rápidas',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            'Mis Artículos',
                            Icons.inventory_2_outlined,
                            () => context.push('/my-items'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            'Explorar',
                            Icons.explore_outlined,
                            () => context.push('/feed'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            'Conversaciones',
                            Icons.chat_bubble_outline,
                            () => context.push('/chats'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            'Mi Perfil',
                            Icons.person_outline,
                            () => context.push('/profile'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDropdown(BuildContext context, profile) {
    return PopupMenuButton<String>(
      icon: AvatarImage(
        avatarUrl: profile?.avatarUrl,
        radius: 16,
        backgroundColor: Colors.grey.shade300,
        placeholder: const Icon(Icons.person, size: 20),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            context.push('/profile');
            break;
          case 'items':
            context.push('/my-items');
            break;
          case 'chats':
            context.push('/chats');
            break;
          case 'logout':
            _handleLogout(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline),
              SizedBox(width: 8),
              Text('Mi Perfil'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'items',
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined),
              SizedBox(width: 8),
              Text('Mis Artículos'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'chats',
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline),
              SizedBox(width: 8),
              Text('Conversaciones'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout),
              SizedBox(width: 8),
              Text('Cerrar Sesión'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
