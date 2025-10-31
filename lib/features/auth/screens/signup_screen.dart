import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/utils/snackbar_utils.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/google_sign_in_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isSigningUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        SnackbarUtils.showError(context, next.error!);
      }
      
      // Navigate to location permission screen after successful signup
      // Only show success message if we initiated the signup from this screen
      if (next.user != null && previous?.user == null && mounted) {
        if (_isSigningUp) {
          // Only show message if we're actually signing up, not logging in
          // For Google Sign-In, check if profile already existed (existing user = login, not signup)
          final isNewUser = previous?.profile == null;
          if (isNewUser) {
            SnackbarUtils.showSuccess(context, '¡Cuenta creada! Revisa tu email para confirmar');
          }
          _isSigningUp = false; // Reset flag
        }
        context.pushReplacement('/location-permission');
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60.h),
              
              // Header
              _buildHeader(),
              
              SizedBox(height: 32.h),
              
              // Sign up form with Google button
              _buildSignUpForm(),
              
              SizedBox(height: 32.h),
              
              // Login link
              _buildLoginLink(),
              
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo flat - consistente con empty states
        Hero(
          tag: 'app_logo',
          child: Container(
            width: 100.w,
            height: 100.w,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        
        SizedBox(height: 32.h),
        
        // Título simple sin gradiente
        Text(
          'Únete a ReNomada',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 16.h),
        
        // Descripción
        Text(
          'Únete para darle un respiro al planeta. Regala e intercambia historias cerca de ti.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu perfil nómada',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Email field
            AuthFormField(
              controller: _emailController,
              label: '',
              hint: 'tu@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: LucideIcons.mail,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16.h),
            
            // Password field
            AuthFormField(
              controller: _passwordController,
              label: '',
              hint: 'Mínimo 6 caracteres',
              obscureText: _obscurePassword,
              prefixIcon: LucideIcons.lock,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa una contraseña';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16.h),
            
            // Confirm password field
            AuthFormField(
              controller: _confirmPasswordController,
              label: '',
              hint: 'Repite tu contraseña',
              obscureText: _obscureConfirmPassword,
              prefixIcon: LucideIcons.lock,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirma tu contraseña';
                }
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            
            SizedBox(height: 24.h),
            
            // Terms and conditions checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptTerms = value ?? false;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'Acepto los '),
                        TextSpan(
                          text: 'términos y condiciones',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' y la '),
                        TextSpan(
                          text: 'política de privacidad',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24.h),
            
            // Crear Cuenta button - acción principal
            Consumer(
              builder: (context, ref, child) {
                final isLoading = ref.watch(authLoadingProvider);
                return SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: isLoading || !_acceptTerms ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 0,
                      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: isLoading
                        ? const LoadingWidget(size: 24)
                        : Text(
                            'Comenzar',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 24.h),
            
            // Divider with "o"
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'o continúa con Google',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    thickness: 1,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24.h),
            
            // Google sign in button - alternativa
            Consumer(
              builder: (context, ref, child) {
                final isLoading = ref.watch(authLoadingProvider);
                return GoogleSignInButton(
                  onPressed: _handleGoogleSignIn,
                  isLoading: isLoading,
                  text: 'Continuar con Google',
                );
              },
            ),
          ],
        ),
      ),
    );
  }




  Widget _buildLoginLink() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¿Ya formas parte? ',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: () {
              context.go('/login'); // Use go() instead of push() for better URL handling
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Entrar',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    // Check if this is a new user (signup) or existing user (login) by checking if profile exists
    // For Google sign-in, we set the flag since it could be either signup or login
    // But we'll only show the message if it's actually a new account
    // Note: Google sign-in might create new accounts, so we'll let the auth state listener handle it
    _isSigningUp = true; // Set flag for potential new account
    await ref.read(authProvider.notifier).signInWithGoogle();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      SnackbarUtils.showWarning(context, 'Debes aceptar los términos y condiciones');
      return;
    }

    _isSigningUp = true; // Set flag to indicate we're signing up
    await ref.read(authProvider.notifier).signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }
}
