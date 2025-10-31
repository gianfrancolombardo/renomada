import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Welcome screen - First screen users see when opening the app
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerLow,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                
                // Brand name - Más grande y prominente
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Renomada',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      fontSize: 56,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Main welcome text
                Text(
                  'Únete a la comunidad que',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Re-words emphasized - Tamaño reducido para mejor jerarquía
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Re-',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: 'descubre, ',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: 'Re-',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: 'utiliza, ',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: 'Re-',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: 'vive',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 56),
                
                // Logo flat - consistente con el diseño de la app
                Container(
                  height: size.height * 0.32,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo circular flat
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primaryContainer,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withOpacity(0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Texto descriptivo simple
                        Text(
                          'Libera espacio. Reduce tu huella.',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(flex: 3),
                
                // Primary button - Create account
                FilledButton(
                  onPressed: () {
                    context.go('/signup'); // Use go() for better URL handling
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                  ),
                  child: Text(
                    'Comenzar',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Login text and link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya formas parte? ',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/login'); // Use go() for better URL handling
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Entrar',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

