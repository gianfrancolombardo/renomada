# 🔐 Tutorial: OAuth en Apps Móviles (Android APK + iOS)

**Objetivo:** Configurar OAuth con Google para que funcione correctamente en apps móviles compiladas (APK Android y iOS)

**Importante:** El flujo de OAuth funciona diferente en web vs móvil. En móvil necesitamos configurar **deep links** personalizados.

---

## 📋 Tabla de Contenidos

1. [Configuración Android (APK)](#1-configuración-android-apk)
2. [Configuración iOS](#2-configuración-ios)
3. [Verificación y Testing](#3-verificación-y-testing)
4. [Troubleshooting](#4-troubleshooting)

---

## 1. Configuración Android (APK)

### 1.1 Configurar Deep Link en AndroidManifest.xml

**Archivo:** `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <!-- ... otras configuraciones ... -->
        
        <!-- Deep link para OAuth callback -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme">
            
            <!-- Intent filter para deep links -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                
                <!-- URL scheme para OAuth callback -->
                <data
                    android:scheme="renomada"
                    android:host="login-callback" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### 1.2 Configurar Google OAuth en Google Cloud Console

1. **Ir a Google Cloud Console**
   - URL: https://console.cloud.google.com
   - Seleccionar tu proyecto (o crear uno nuevo)

2. **Configurar OAuth Consent Screen**
   - Menú lateral: **APIs & Services → OAuth consent screen**
   - Tipo de usuario: **Externo** (si es público)
   - Completar información de la app:
     - Nombre: `ReNomada`
     - Email de soporte
     - Logo (opcional)
     - Dominio de desarrollador (opcional)
   - Scopes: Agregar `email` y `profile`
   - Guardar y continuar

3. **Crear Credenciales OAuth 2.0**
   - Menú lateral: **APIs & Services → Credentials**
   - Clic en **+ CREATE CREDENTIALS → OAuth client ID**
   - Tipo: **Android**
   - Nombre: `ReNomada Android`
   - Package name: El de tu app (ej: `com.renomada.app`)
   - SHA-1 certificate fingerprint: Necesitas obtenerlo (ver abajo)

#### Obtener SHA-1 Fingerprint:

**Para debug (desarrollo):**
```bash
cd android
./gradlew signingReport
```

Busca en la salida algo como:
```
SHA1: AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12
```

**Para release (producción):**
```bash
keytool -list -v -keystore android/app/keystore.jks -alias upload
```

Si no tienes keystore, créalo:
```bash
keytool -genkey -v -keystore android/app/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

4. **Copiar Client ID**
   - Una vez creado, copia el **Client ID** (algo como: `123456789-abcdefghijk.apps.googleusercontent.com`)
   - Lo necesitarás para Supabase

### 1.3 Configurar Supabase para Android

1. **Ir a Supabase Dashboard**
   - URL: https://app.supabase.com
   - Seleccionar tu proyecto

2. **Configurar OAuth Provider**
   - Menú lateral: **Authentication → Providers**
   - Activar **Google**
   - **Client ID:** Pegar el Client ID de Google Cloud Console
   - **Client Secret:** Pegar el Client Secret de Google Cloud Console
   - **Redirect URL:** Agregar:
     ```
     renomada://login-callback/
     ```
   - Guardar

### 1.4 Actualizar Código Flutter

**Archivo:** `lib/shared/services/auth_service.dart`

Asegúrate de que el `redirectTo` coincida con el deep link:

```dart
Future<bool> signInWithProvider(OAuthProvider provider) async {
  try {
    final response = await SupabaseConfig.client.auth.signInWithOAuth(
      provider,
      redirectTo: 'renomada://login-callback/', // ← Debe coincidir con AndroidManifest
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    
    return response;
  } catch (e) {
    print('OAuth sign in error: $e');
    return false;
  }
}
```

---

## 2. Configuración iOS

### 2.1 Configurar URL Scheme en Info.plist

**Archivo:** `ios/Runner/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... otras configuraciones ... -->
    
    <!-- URL Schemes para OAuth callback -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLName</key>
            <string>com.renomada.app</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>renomada</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

### 2.2 Configurar Google OAuth para iOS

1. **En Google Cloud Console**
   - **APIs & Services → Credentials**
   - Clic en **+ CREATE CREDENTIALS → OAuth client ID**
   - Tipo: **iOS**
   - Nombre: `ReNomada iOS`
   - Bundle ID: El de tu app (ej: `com.renomada.app`)
   - Guardar y copiar el **Client ID**

2. **Configurar Supabase para iOS**
   - En Supabase: **Authentication → Providers → Google**
   - Agregar el mismo **Redirect URL**:
     ```
     renomada://login-callback/
     ```
   - Guardar

### 2.3 Configurar Associated Domains (Opcional pero recomendado)

Para mejor UX con Apple Sign-In y OAuth:

1. **En Xcode:**
   - Abrir `ios/Runner.xcworkspace`
   - Seleccionar proyecto → **Signing & Capabilities**
   - Agregar capability: **Associated Domains**
   - Agregar dominio: `applinks:renomada.app` (si tienes dominio)

2. **En Apple Developer Portal:**
   - Crear App ID con Associated Domains habilitado
   - Configurar dominio en Apple App Site Association

---

## 3. Verificación y Testing

### 3.1 Testing en Android (APK Debug)

```bash
# Build APK debug
cd android
./gradlew assembleDebug

# Instalar en dispositivo
adb install app/build/outputs/apk/debug/app-debug.apk

# Probar login con Google
# 1. Abre la app
# 2. Toca "Iniciar sesión con Google"
# 3. Debería abrirse el navegador
# 4. Después de autorizar, debería volver a la app automáticamente
```

### 3.2 Testing en Android (APK Release)

```bash
# Build APK release (firmado)
flutter build apk --release

# O AAB para Google Play
flutter build appbundle --release

# Instalar y probar
```

### 3.3 Testing en iOS

```bash
# Abrir en Xcode
open ios/Runner.xcworkspace

# Build y ejecutar en simulador/dispositivo
# Probar login con Google igual que en Android
```

### 3.4 Verificar Deep Link Manualmente

**Android:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "renomada://login-callback/?code=test123" com.renomada.app
```

**iOS (desde Mac):**
```bash
xcrun simctl openurl booted "renomada://login-callback/?code=test123"
```

---

## 4. Troubleshooting

### Problema: "Redirect URI mismatch"

**Solución:**
- Verifica que el `redirectTo` en Flutter coincida EXACTAMENTE con el configurado en Supabase
- Formato debe ser: `renomada://login-callback/` (con la barra final)

### Problema: "App doesn't open after OAuth"

**Solución:**
- Verifica que el URL scheme en `AndroidManifest.xml` / `Info.plist` coincida
- Verifica que la app esté instalada en el dispositivo
- En Android, prueba con `adb shell dumpsys package com.renomada.app` para ver los intent filters

### Problema: "Invalid client" en Google OAuth

**Solución:**
- Verifica que el SHA-1 fingerprint esté correcto en Google Cloud Console
- Para release, usa el fingerprint del keystore de producción
- Espera unos minutos después de agregar el fingerprint (Google tarda en actualizar)

### Problema: OAuth funciona en debug pero no en release

**Solución:**
- El SHA-1 de debug es diferente al de release
- Agrega AMBOS SHA-1 en Google Cloud Console:
  - Uno para el keystore de debug (para desarrollo)
  - Otro para el keystore de release (para producción)

### Problema: OAuth funciona en web pero no en móvil

**Solución:**
- Web usa redirects HTTP, móvil usa URL schemes personalizados
- Asegúrate de que el código Flutter use `redirectTo` con el URL scheme correcto
- Verifica que `LaunchMode.externalApplication` esté configurado

---

## ✅ Checklist Final

### Android:
- [ ] URL scheme configurado en `AndroidManifest.xml`
- [ ] SHA-1 fingerprint agregado en Google Cloud Console
- [ ] OAuth Client ID creado para Android
- [ ] Redirect URL configurado en Supabase
- [ ] Código Flutter usa el redirect correcto
- [ ] Probado en APK debug y release

### iOS:
- [ ] URL scheme configurado en `Info.plist`
- [ ] OAuth Client ID creado para iOS
- [ ] Bundle ID coincide en Xcode y Google Cloud
- [ ] Redirect URL configurado en Supabase
- [ ] Probado en simulador y dispositivo real

### Ambos:
- [ ] OAuth funciona en ambas plataformas
- [ ] Deep link redirige correctamente después del login
- [ ] Sesión persiste después del login
- [ ] Logout funciona correctamente

---

## 📝 Notas Importantes

1. **URL Schemes son sensibles a mayúsculas/minúsculas**
   - Usa minúsculas: `renomada://` no `ReNomada://`

2. **SHA-1 Fingerprint es único por keystore**
   - Debug y release tienen fingerprints diferentes
   - Agrega ambos en Google Cloud Console

3. **Testing en release es crítico**
   - OAuth puede funcionar en debug pero fallar en release
   - Siempre prueba con APK/AAB firmado antes de publicar

4. **Deep links funcionan diferente en web**
   - En web, Supabase maneja automáticamente los redirects HTTP
   - En móvil, necesitas configurar URL schemes manualmente

---

## 🔗 Referencias

- [Supabase OAuth Documentation](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Flutter Deep Linking](https://docs.flutter.dev/development/ui/navigation/deep-linking)
- [Google OAuth Setup](https://developers.google.com/identity/protocols/oauth2)
- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)

---

**Fecha de creación:** 2025  
**Versión:** 1.0  
**Estado:** ✅ Listo para implementación

