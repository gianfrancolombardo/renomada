# 🔐 Tutorial: OAuth con Supabase (Google, Apple, Biometrics)

**Objetivo:** Implementar autenticación social y biométrica en ReNomada  
**Plataformas:** iOS (Face ID, Touch ID, Apple Sign-In) y Android (Biometric, Google Sign-In)  
**Stack:** Flutter + Supabase Auth

---

## 📋 Tabla de Contenidos

1. [Configuración de Supabase](#1-configuración-de-supabase)
2. [Google Sign-In (Android + iOS)](#2-google-sign-in-android--ios)
3. [Apple Sign-In (iOS obligatorio)](#3-apple-sign-in-ios)
4. [Face ID / Touch ID (Re-autenticación)](#4-face-id--touch-id)
5. [Testing y Troubleshooting](#5-testing-y-troubleshooting)

---

## 1. Configuración de Supabase

### 1.1 Habilitar Providers en Supabase Dashboard

1. **Ir a tu proyecto en Supabase**
   - URL: `https://app.supabase.com/project/[TU_PROJECT_ID]`

2. **Navegar a Authentication → Providers**
   - Menú lateral: Authentication
   - Tab: Providers

3. **Habilitar Google**
   - Toggle "Google" a ON
   - Verás campos: Client ID, Client Secret

4. **Habilitar Apple** (si vas a lanzar en iOS)
   - Toggle "Apple" a ON
   - Verás campos: Services ID, Key ID, etc.

---

## 2. Google Sign-In (Android + iOS)

### 2.1 Crear Proyecto en Google Cloud Console

1. **Ir a Google Cloud Console**
   - URL: https://console.cloud.google.com

2. **Crear nuevo proyecto** (o usar existente)
   ```
   Nombre: ReNomada
   Organization: [tu organización]
   ```

3. **Habilitar Google+ API**
   - APIs & Services → Library
   - Buscar "Google+ API"
   - Click "Enable"

### 2.2 Configurar OAuth Consent Screen

1. **Ir a OAuth consent screen**
   - APIs & Services → OAuth consent screen

2. **Configurar**
   ```
   User Type: External
   App name: ReNomada
   User support email: [tu email]
   Developer contact: [tu email]
   ```

3. **Scopes** (añadir estos):
   ```
   .../auth/userinfo.email
   .../auth/userinfo.profile
   openid
   ```

4. **Test users** (mientras está en testing)
   - Añadir emails de testers

### 2.3 Crear OAuth 2.0 Client IDs

Necesitarás crear **3 Client IDs diferentes**:

#### A) Web Application (para Supabase)

```
Application type: Web application
Name: ReNomada Web Client

Authorized redirect URIs:
https://[TU_PROJECT_REF].supabase.co/auth/v1/callback
```

**Copiar:**
- Client ID
- Client Secret

**Guardar en Supabase:**
- Authentication → Providers → Google
- Pegar Client ID y Client Secret
- Save

#### B) Android Application

```
Application type: Android
Name: ReNomada Android

Package name: com.renomada.app
SHA-1 certificate fingerprint: [ver cómo obtener abajo]
```

**Obtener SHA-1:**

```bash
# Para debug (desarrollo):
cd android
./gradlew signingReport

# O con keytool:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copiar el SHA-1 que aparece.

**Para release** (producción):
```bash
keytool -list -v -keystore [ruta-a-tu-keystore.jks] -alias [tu-alias]
```

#### C) iOS Application

```
Application type: iOS
Name: ReNomada iOS

Bundle ID: com.renomada.app
```

### 2.4 Configurar Flutter

#### Instalar dependencias

```yaml
# pubspec.yaml

dependencies:
  supabase_flutter: ^2.0.0
  google_sign_in: ^6.1.5
  sign_in_with_apple: ^5.0.0  # Solo si soportas iOS
```

```bash
flutter pub get
```

#### Configurar Android

**android/app/build.gradle**

```gradle
android {
    defaultConfig {
        // ... otras configuraciones
        
        minSdkVersion 21  // Google Sign-In requiere mínimo 21
    }
}

dependencies {
    // ... otras dependencias
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

#### Configurar iOS

**ios/Runner/Info.plist**

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Reversed client ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.[TU_CLIENT_ID_REVERSIDO]</string>
        </array>
    </dict>
</array>

<!-- Google Sign-In -->
<key>GIDClientID</key>
<string>[TU_IOS_CLIENT_ID].apps.googleusercontent.com</string>
```

**Nota:** El reversed client ID lo encuentras en `GoogleService-Info.plist` si usas Firebase, o créalo invirtiendo tu Client ID.

### 2.5 Implementar Google Sign-In Service

**lib/shared/services/google_auth_service.dart**

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // iOS Client ID
    clientId: '[TU_IOS_CLIENT_ID].apps.googleusercontent.com',
  );

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // 1. Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in aborted by user');
      }

      // 2. Get authentication details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('No ID Token found');
      }

      // 3. Sign in to Supabase with Google credentials
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }

  /// Check if user is signed in
  bool get isSignedIn => _googleSignIn.currentUser != null;
}
```

### 2.6 Actualizar UI de Login

**lib/features/auth/screens/login_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/google_auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _googleAuthService = GoogleAuthService();
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    
    try {
      final response = await _googleAuthService.signInWithGoogle();
      
      if (response.user != null && mounted) {
        // Navigate to home or check if profile exists
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ... Logo y título existentes ...
              
              // Email/Password form existente
              // ...
              
              const SizedBox(height: 24),
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'o continúa con',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                  icon: _isGoogleLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.asset(
                          'assets/images/google_logo.png',
                          height: 24,
                        ),
                  label: Text(
                    _isGoogleLoading 
                        ? 'Iniciando sesión...' 
                        : 'Continuar con Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Nota:** Necesitarás el logo de Google. Descárgalo de las [Brand Guidelines de Google](https://developers.google.com/identity/branding-guidelines).

---

## 3. Apple Sign-In (iOS)

### 3.1 Requisitos

**Importante:** Si ofreces Google Sign-In en iOS, **Apple REQUIERE que también ofrezcas Apple Sign-In**. Es política de App Store.

### 3.2 Configurar en Apple Developer

1. **Ir a Apple Developer Console**
   - URL: https://developer.apple.com/account

2. **Crear App ID con Sign In with Apple**
   - Certificates, Identifiers & Profiles
   - Identifiers → App IDs
   - Tu App ID (ej: com.renomada.app)
   - Capabilities → Sign In with Apple: ✅ Enable

3. **Crear Services ID**
   ```
   Description: ReNomada Web Service
   Identifier: com.renomada.app.service
   
   Enable "Sign In with Apple"
   Configure:
     Primary App ID: com.renomada.app
     Website URLs: 
       Domains: [TU_PROJECT_REF].supabase.co
       Return URLs: https://[TU_PROJECT_REF].supabase.co/auth/v1/callback
   ```

4. **Crear Private Key**
   - Keys → Create new key
   - Name: ReNomada Apple Sign-In Key
   - Enable: Sign In with Apple
   - Download `.p8` file
   - **Guardar el Key ID** (aparece después de crear)

### 3.3 Configurar Supabase

1. **Ir a Supabase Dashboard**
   - Authentication → Providers → Apple

2. **Completar campos:**
   ```
   Enabled: ON
   Services ID: com.renomada.app.service
   Bundle ID: com.renomada.app (tu bundle ID iOS)
   Key ID: [el Key ID que obtuviste]
   Secret Key: [contenido del archivo .p8]
   ```

3. **Save**

### 3.4 Configurar iOS Project

**ios/Runner/Runner.entitlements**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing entitlements -->
    
    <!-- Add Sign In with Apple -->
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
</dict>
</plist>
```

**ios/Runner.xcodeproj**

En Xcode:
1. Abrir `ios/Runner.xcworkspace`
2. Select Runner target
3. Signing & Capabilities
4. Click "+ Capability"
5. Añadir "Sign In with Apple"

### 3.5 Implementar Apple Sign-In Service

**lib/shared/services/apple_auth_service.dart**

```dart
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppleAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with Apple
  Future<AuthResponse> signInWithApple() async {
    try {
      // 1. Request Apple Sign-In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? idToken = credential.identityToken;
      
      if (idToken == null) {
        throw Exception('No identity token received from Apple');
      }

      // 2. Sign in to Supabase with Apple credentials
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );

      // 3. If this is first time, update profile with full name
      if (credential.givenName != null || credential.familyName != null) {
        final fullName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
        
        if (fullName.isNotEmpty && response.user != null) {
          // Update profile with name
          await _supabase.from('profiles').update({
            'username': fullName,
          }).eq('user_id', response.user!.id);
        }
      }

      return response;
    } catch (e) {
      print('Error signing in with Apple: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
```

### 3.6 Actualizar UI con Apple Button

```dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../../../shared/services/apple_auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  // ... código existente ...
  
  final _appleAuthService = AppleAuthService();
  bool _isAppleLoading = false;

  Future<void> _handleAppleSignIn() async {
    setState(() => _isAppleLoading = true);
    
    try {
      final response = await _appleAuthService.signInWithApple();
      
      if (response.user != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAppleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ... Google button ...
          
          // Apple Sign-In Button (solo en iOS)
          if (Platform.isIOS) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _isAppleLoading ? null : _handleAppleSignIn,
                icon: _isAppleLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.apple, size: 24),
                label: Text(
                  _isAppleLoading 
                      ? 'Iniciando sesión...' 
                      : 'Continuar con Apple',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## 4. Face ID / Touch ID (Re-autenticación)

### 4.1 Caso de Uso

No es para el login inicial, sino para **re-autenticación rápida**:
- Usuario ya está logged in
- App se cerró o estuvo en background
- Al reabrir, pedir Face ID/Touch ID en vez de password

### 4.2 Instalar Dependencia

```yaml
# pubspec.yaml

dependencies:
  local_auth: ^2.1.7
```

```bash
flutter pub get
```

### 4.3 Configurar Permisos

**iOS: ios/Runner/Info.plist**

```xml
<key>NSFaceIDUsageDescription</key>
<string>Necesitamos usar Face ID para verificar tu identidad</string>
```

**Android: android/app/src/main/AndroidManifest.xml**

```xml
<manifest>
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.USE_FINGERPRINT"/>
</manifest>
```

**Android: android/app/build.gradle**

```gradle
android {
    defaultConfig {
        minSdkVersion 23  // Biometric requiere mínimo API 23
    }
}
```

### 4.4 Implementar Biometric Service

**lib/shared/services/biometric_auth_service.dart**

```dart
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometrics
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Error checking biometrics availability: $e');
      return false;
    }
  }

  /// Check if device has biometrics enrolled
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({
    String reason = 'Por favor, auténticate para continuar',
  }) async {
    try {
      final bool canAuthenticateWithBiometrics = await canCheckBiometrics();
      final bool canAuthenticate = canAuthenticateWithBiometrics || 
                                   await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Requires re-authentication when app is backgrounded
          biometricOnly: false, // Allow device credentials as fallback
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        print('Biometrics not available on this device');
      } else if (e.code == auth_error.notEnrolled) {
        print('No biometrics enrolled');
      } else {
        print('Error during biometric authentication: $e');
      }
      return false;
    } catch (e) {
      print('Unknown error during authentication: $e');
      return false;
    }
  }

  /// Get biometric type name for UI
  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();
    
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Touch ID';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Biometrics';
    } else {
      return 'Device credentials';
    }
  }
}
```

### 4.5 Implementar Lock Screen con Biometrics

**lib/features/auth/screens/biometric_lock_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/biometric_auth_service.dart';
import '../../../shared/services/auth_service.dart';

class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  final _biometricService = BiometricAuthService();
  final _authService = AuthService();
  
  bool _isAuthenticating = false;
  String _biometricType = 'Biometrics';

  @override
  void initState() {
    super.initState();
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    final type = await _biometricService.getBiometricTypeName();
    setState(() => _biometricType = type);
    
    // Auto-trigger biometric auth on screen load
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    
    setState(() => _isAuthenticating = true);

    final authenticated = await _biometricService.authenticate(
      reason: 'Auténticate para acceder a ReNomada',
    );

    setState(() => _isAuthenticating = false);

    if (authenticated && mounted) {
      // Successfully authenticated, navigate to home
      context.go('/home');
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'ReNomada está bloqueada',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  'Usa $_biometricType para desbloquear',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Biometric button
                ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : _authenticate,
                  icon: _isAuthenticating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_getBiometricIcon()),
                  label: Text(
                    _isAuthenticating 
                        ? 'Autenticando...' 
                        : 'Desbloquear con $_biometricType',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Logout option
                TextButton(
                  onPressed: _logout,
                  child: Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getBiometricIcon() {
    if (_biometricType.contains('Face')) {
      return Icons.face;
    } else if (_biometricType.contains('Touch')) {
      return Icons.fingerprint;
    } else {
      return Icons.security;
    }
  }
}
```

### 4.6 Implementar Lógica de App Lock

**lib/core/router/app_router.dart**

```dart
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/screens/biometric_lock_screen.dart';

class AppRouter {
  static bool _needsBiometricAuth = false;
  
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Check if user is authenticated
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      
      // Check if biometric is enabled
      final prefs = await SharedPreferences.getInstance();
      final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      
      // If authenticated and biometric enabled, check if needs unlock
      if (isAuthenticated && biometricEnabled && _needsBiometricAuth) {
        if (state.location != '/biometric-lock') {
          return '/biometric-lock';
        }
      }
      
      // ... resto de la lógica de redirect ...
      
      return null;
    },
    routes: [
      // ... rutas existentes ...
      
      GoRoute(
        path: '/biometric-lock',
        builder: (context, state) => const BiometricLockScreen(),
      ),
    ],
  );
  
  /// Call this when app goes to background
  static void setNeedsBiometricAuth(bool needs) {
    _needsBiometricAuth = needs;
  }
}
```

**lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'core/router/app_router.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive) {
      // App went to background, require biometric auth on resume
      AppRouter.setNeedsBiometricAuth(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      title: 'ReNomada',
    );
  }
}
```

### 4.7 Añadir Toggle en Settings

**lib/features/profile/screens/profile_screen.dart**

```dart
import '../../../shared/services/biometric_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  // ... código existente ...
  
  final _biometricService = BiometricAuthService();
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometricService.canCheckBiometrics();
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometric_enabled') ?? false;
    
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Test biometric before enabling
      final authenticated = await _biometricService.authenticate(
        reason: 'Auténticate para habilitar el desbloqueo biométrico',
      );
      
      if (!authenticated) return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() => _biometricEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // ... secciones existentes ...
          
          // Security Section
          if (_biometricAvailable) ...[
            ListTile(
              title: Text('Seguridad'),
              dense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            SwitchListTile(
              title: Text('Desbloqueo biométrico'),
              subtitle: Text('Usa Face ID / Touch ID para desbloquear la app'),
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
            Divider(),
          ],
        ],
      ),
    );
  }
}
```

---

## 5. Testing y Troubleshooting

### 5.1 Checklist de Testing

#### Google Sign-In

- [ ] Android: Sign in funciona en emulador
- [ ] Android: Sign in funciona en dispositivo real
- [ ] iOS: Sign in funciona en simulador
- [ ] iOS: Sign in funciona en dispositivo real
- [ ] Profile se crea automáticamente
- [ ] Email se guarda correctamente
- [ ] Avatar de Google se sincroniza (opcional)
- [ ] Sign out funciona

#### Apple Sign-In

- [ ] Solo aparece en iOS
- [ ] Sign in funciona en simulador
- [ ] Sign in funciona en dispositivo real
- [ ] Nombre completo se captura en primer login
- [ ] Email se oculta correctamente si usuario elige "Hide My Email"
- [ ] Profile se crea automáticamente

#### Biometric Auth

- [ ] Detecta correctamente Face ID en iPhone X+
- [ ] Detecta correctamente Touch ID en iPhone 8-
- [ ] Detecta fingerprint en Android
- [ ] Fallback a PIN/Pattern funciona
- [ ] Toggle en settings funciona
- [ ] Lock screen aparece al reabrir app
- [ ] Logout funciona desde lock screen

### 5.2 Problemas Comunes

#### "PlatformException(sign_in_failed)"

**Causa:** SHA-1 no coincide o Client ID incorrecto

**Solución:**
```bash
# Regenerar SHA-1
cd android
./gradlew signingReport

# Actualizar en Google Cloud Console
# Verificar que package name coincide exactamente
```

#### "Error 10" en Google Sign-In (iOS)

**Causa:** Client ID de iOS no configurado

**Solución:**
- Verificar `GIDClientID` en `Info.plist`
- Debe ser el Client ID de iOS (no el de Web)

#### Apple Sign-In no aparece

**Causa:** Capability no añadida

**Solución:**
- Abrir Xcode
- Runner target → Signing & Capabilities
- Añadir "Sign In with Apple"

#### Biometric no funciona en emulador

**Causa:** Emulador no tiene biometric enrolled

**Solución:**
```
iOS Simulator: 
  Features → Face ID → Enrolled

Android Emulator:
  Settings → Security → Fingerprint
  Add fingerprint (usar adb touch en terminal)
```

### 5.3 Logs de Debug

Añadir logging detallado:

```dart
class GoogleAuthService {
  Future<AuthResponse> signInWithGoogle() async {
    print('🔐 Starting Google Sign-In...');
    
    try {
      print('📱 Triggering Google Sign-In flow...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('✅ Google user obtained: ${googleUser?.email}');
      
      print('🔑 Getting authentication details...');
      final googleAuth = await googleUser!.authentication;
      print('✅ Got idToken: ${googleAuth.idToken?.substring(0, 20)}...');
      
      print('🔐 Signing in to Supabase...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      print('✅ Supabase sign-in successful: ${response.user?.email}');
      
      return response;
    } catch (e, stackTrace) {
      print('❌ Error in Google Sign-In: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
```

---

## 📝 Resumen Final

### Lo que has implementado:

1. ✅ **Google Sign-In** (Android + iOS)
   - One-tap login
   - Integración con Supabase
   - Creación automática de perfil

2. ✅ **Apple Sign-In** (iOS)
   - Requerido por Apple Store
   - "Hide My Email" soportado
   - Captura de nombre completo

3. ✅ **Biometric Auth** (Face ID, Touch ID, Fingerprint)
   - Re-autenticación rápida
   - Lock screen al reabrir app
   - Toggle en configuración

### Próximos pasos:

1. Testing exhaustivo en dispositivos reales
2. Preparar assets (logo de Google)
3. Privacy policy que mencione OAuth providers
4. Submit a App Store con "Sign In with Apple" capability

---

## 🎯 Estimación de Tiempo Total

- **Google Sign-In:** 2-3 horas (setup + implementación + testing)
- **Apple Sign-In:** 2-3 horas (setup + implementación + testing)
- **Biometric Auth:** 2-3 horas (implementación + UI + testing)

**Total:** 6-9 horas de trabajo

¡Buena suerte! 🚀


