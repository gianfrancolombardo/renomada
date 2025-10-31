import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/avatar_image.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/utils/snackbar_utils.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final profileState = ref.read(profileProvider);
    print('Loading profile: ${profileState.profile?.username}');
    if (profileState.profile != null && profileState.profile!.username != null) {
      _usernameController.text = profileState.profile!.username!;
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Clear profile state and form before logging out
      ref.read(profileProvider.notifier).clearProfile();
      _usernameController.clear();
      
      final authService = AuthService();
      await authService.signOut();
      
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Error al cerrar sesión: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final isLoading = ref.watch(profileLoadingProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 32.h),
            
            // Avatar section - simplified
            _buildAvatarSection(profileState),
            
            SizedBox(height: 48.h),
            
            // Username form - simplified
            _buildUsernameForm(),
            
            SizedBox(height: 48.h),
            
            // Save button
            _buildSaveButton(isLoading),
            
            SizedBox(height: 32.h),
            
            // Divider before logout section
            Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              thickness: 1,
            ),
            
            SizedBox(height: 32.h),
            
            // Logout text - centered at bottom
            TextButton(
              onPressed: _handleLogout,
              child: Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(profileState) {
    return Column(
      children: [
        // Avatar without gradient background
        GestureDetector(
          onTap: _showAvatarOptions,
          child: Stack(
            children: [
              AvatarImage(
                avatarUrl: profileState.profile?.avatarUrl,
                radius: 72.r,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                placeholder: Icon(
                  LucideIcons.user,
                  size: 72.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Positioned(
                bottom: 0.w,
                right: 0.w,
                child: Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.camera,
                    size: 18.sp,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 24.h),
        
        
        
        // Avatar label with modern styling
        Text(
          'Toca para cambiar foto',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Username field label
          Text(
            'Tu nombre',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          SizedBox(height: 8.h),
          
          // Simplified username field
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Cómo quieres que te llamen',
              prefixIcon: Icon(
                LucideIcons.user,
                size: 20.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa un nombre de usuario';
              }
              if (value.length < 3) {
                return 'El nombre debe tener al menos 3 caracteres';
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                return 'Solo letras, números y guiones bajos';
              }
              return null;
            },
          ),
          
          SizedBox(height: 12.h),
          
          // Simple info message
          Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 16.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Este nombre será visible para otros nómadas',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 2,
          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: isLoading
            ? LoadingWidget(
                size: 20,
                color: Theme.of(context).colorScheme.onPrimary,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.check,
                    size: 18.sp,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Guardar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  'Cambiar foto',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            
              SizedBox(height: 24.h),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAvatarOption(
                        icon: Icons.camera_alt,
                        label: 'Cámara',
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildAvatarOption(
                        icon: Icons.photo_library,
                        label: 'Galería',
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // Show loading indicator
        if (mounted) {
          SnackbarUtils.showInfo(context, 'Subiendo avatar...');
        }

        // Read file bytes directly instead of using path
        final fileBytes = await image.readAsBytes();
        final success = await ref.read(profileProvider.notifier).updateAvatarFromBytes(fileBytes, image.name);
        
        if (success && mounted) {
          SnackbarUtils.showSuccess(context, 'Avatar actualizado correctamente');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Error al subir avatar: ${e.toString()}');
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(profileProvider.notifier).updateUsername(
      _usernameController.text.trim(),
    );

    if (success && mounted) {
      SnackbarUtils.showSuccess(context, 'Perfil actualizado correctamente');
      
      // Go back to previous screen
      context.pop();
    }
  }
}