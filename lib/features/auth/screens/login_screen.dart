import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      print('Auth state changed:');
      print('  Previous user: ${previous?.user?.id}');
      print('  Next user: ${next.user?.id}');
      print('  Error: ${next.error}');
      print('  IsLoading: ${next.isLoading}');
      
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      
      // Navigate to location permission screen after successful login
      if (next.user != null && previous?.user == null && mounted) {
        print('Navigating to location permission screen');
        context.pushReplacement('/location-permission');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40.h),
              
              // Logo and title
              _buildHeader(),
              
              SizedBox(height: 48.h),
              
              // Login form
              _buildLoginForm(),
              
              SizedBox(height: 24.h),
              
              // Sign up link
              _buildSignUpLink(),
              
              SizedBox(height: 32.h),
              
              // Forgot password
              _buildForgotPassword(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App logo
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Icon(
            Icons.explore_outlined,
            size: 40.sp,
            color: AppTheme.primaryColor,
          ),
        ),
        
        SizedBox(height: 24.h),
        
        // Title
        Text(
          '¡Bienvenido de vuelta!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 8.h),
        
        // Subtitle
        Text(
          'Inicia sesión para continuar',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          AuthFormField(
            controller: _emailController,
            label: 'Email',
            hint: 'tu@email.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
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
            label: 'Contraseña',
            hint: 'Tu contraseña',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outlined,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu contraseña';
              }
              if (value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          
          SizedBox(height: 32.h),
          
          // Login button
          Consumer(
            builder: (context, ref, child) {
              final isLoading = ref.watch(authLoadingProvider);
              return SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  child: isLoading
                      ? const LoadingWidget(size: 20)
                      : Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta? ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        TextButton(
          onPressed: () {
            context.push('/signup');
          },
          child: Text(
            'Regístrate',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: _handleForgotPassword,
      child: Text(
        '¿Olvidaste tu contraseña?',
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu email primero'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).resetPassword(email);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa tu email para restablecer la contraseña'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
