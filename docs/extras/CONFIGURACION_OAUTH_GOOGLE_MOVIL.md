# Configuración de OAuth Google para Móvil Android/iOS

## Problema Actual

Cuando pruebas el login con Google en un **dispositivo físico**, ves una redirección extraña a Supabase que luego intenta volver a `localhost`, lo cual no funciona en aplicaciones móviles nativas.

## Por qué sucede esto

En desarrollo web, Supabase redirige a `http://localhost:3000` por defecto. Sin embargo, en apps móviles nativas (Android/iOS), necesitas usar **deep linking** con un esquema de URI personalizado (como `io.supabase.renomada://`) para que el sistema operativo sepa cómo regresar a tu app después de la autenticación con Google.

## Solución Completa

### 1. Configurar URLs de Redirección en Supabase Dashboard

**IMPORTANTE**: Debes hacer esto primero antes de probar en un dispositivo físico.

1. Ve a tu dashboard de Supabase: https://supabase.com/dashboard/project/izyqrmpoyxnjzoqlgjoa/auth/url-configuration

2. En la sección **"Additional Redirect URLs"**, agrega las siguientes URLs (una por línea):
   ```
   io.supabase.renomada://login-callback/
   io.supabase.renomada://**
   ```

3. Haz clic en **"Save"**

#### ¿Por qué estas URLs?

- `io.supabase.renomada://` es el **esquema de deep link** único de tu app
- `login-callback` es la ruta específica que configuraste en `AndroidManifest.xml` e `Info.plist`
- El `**` es un wildcard que permite cualquier sub-ruta, útil para casos edge

### 2. Verificar Configuración de Deep Linking (Ya está hecho ✅)

Tu configuración actual ya está correcta:

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="io.supabase.renomada"
        android:host="login-callback" />
</intent-filter>
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.renomada</string>
        </array>
    </dict>
</array>
```

### 3. Código Actualizado (Ya implementado ✅)

El código en `lib/shared/services/auth_service.dart` ha sido actualizado para usar `LaunchMode.externalApplication`, que abre el navegador del sistema para una mejor experiencia de usuario:

```dart
Future<bool> signInWithProvider(OAuthProvider provider) async {
  try {
    final response = await SupabaseConfig.client.auth.signInWithOAuth(
      provider,
      redirectTo: 'io.supabase.renomada://login-callback/',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    
    return response;
  } catch (e) {
    print('OAuth sign in error: $e');
    return false;
  }
}
```

### 4. Cómo Funciona el Flujo Completo

1. **Usuario toca "Continuar con Google"**
   - Se llama a `signInWithGoogle()` en el `auth_provider`
   
2. **Se abre el navegador del sistema**
   - La app abre el navegador con la URL de OAuth de Google
   - El usuario elige su cuenta de Google y autoriza
   
3. **Google redirige a Supabase**
   - Google envía los tokens a Supabase
   - Supabase procesa la autenticación
   
4. **Supabase redirige a tu app vía deep link**
   - Supabase redirige a `io.supabase.renomada://login-callback/`
   - Android/iOS detectan el esquema y abren tu app
   
5. **`supabase_flutter` maneja el callback automáticamente**
   - La librería detecta el deep link
   - Extrae los tokens
   - Actualiza la sesión
   - El listener de `authStateChanges` detecta el cambio
   
6. **La app navega automáticamente**
   - El `authProvider` detecta el nuevo usuario
   - Navega a la pantalla de permisos de ubicación

### 5. Probar en Dispositivo Físico

#### Android
```bash
# Conecta tu dispositivo Android
flutter run

# O para release build
flutter build apk --release
flutter install
```

#### iOS
```bash
# Conecta tu dispositivo iOS
flutter run

# Para release build necesitas firma de código
# Configura tu equipo en Xcode primero
```

### 6. Debugging

Si algo no funciona, verifica lo siguiente:

1. **Logs en la consola**:
   ```dart
   print('OAuth sign in error: $e');
   ```
   Esto te dirá si hay algún error en la llamada OAuth

2. **Verifica en Supabase Dashboard > Authentication > Users**:
   - Después de un login exitoso, el usuario debería aparecer aquí

3. **Verifica que el deep link funcione**:
   ```bash
   # Android
   adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.renomada://login-callback/" com.example.renomada
   
   # iOS (en un dispositivo físico con la app instalada)
   # Abre Safari y navega a: io.supabase.renomada://login-callback/
   ```

## Mejores Prácticas para UX en Móvil

### ✅ LO QUE HACE TU APP (Correcto)

1. **Usa `LaunchMode.externalApplication`**: Abre el navegador del sistema en vez de un WebView interno
   - **Ventaja**: Google permite autenticación completa y más segura
   - **Ventaja**: El usuario confía más en el navegador del sistema
   - **Ventaja**: Soporte para autenticación biométrica si está configurada

2. **Deep linking nativo**: Usa el esquema de URI propio de la app
   - **Ventaja**: Transición fluida de navegador a app
   - **Ventaja**: Sin necesidad de copiar/pegar tokens
   - **Ventaja**: Experiencia nativa y profesional

3. **PKCE Flow**: Tu config usa `AuthFlowType.pkce`
   - **Ventaja**: Más seguro para apps móviles
   - **Ventaja**: Previene ataques de intercepción

### ❌ LO QUE NO DEBES HACER

1. ❌ Usar `localhost` en `redirectTo`
   - No funciona en dispositivos físicos

2. ❌ Usar `LaunchMode.inAppWebView`
   - Google puede bloquear el login
   - Mala experiencia de usuario

3. ❌ No configurar las URLs en Supabase Dashboard
   - Supabase rechazará la redirección
   - El usuario verá un error

## Configuración de Google Cloud Console

Asegúrate de tener configurado correctamente en Google Cloud Console:

1. **OAuth consent screen** configurado
2. **OAuth 2.0 Client IDs** para:
   - Web application (para Supabase)
   - Android (con SHA-1 fingerprint)
   - iOS (con Bundle ID)

Para obtener el SHA-1 fingerprint en Android:
```bash
# Debug
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release (cuando tengas tu keystore)
keytool -list -v -keystore path/to/your/keystore.jks -alias your-alias
```

## Configuración en Supabase (Authentication Providers)

1. Ve a: https://supabase.com/dashboard/project/izyqrmpoyxnjzoqlgjoa/auth/providers
2. Habilita el proveedor de **Google**
3. Ingresa:
   - **Client ID** (OAuth 2.0 - Web application)
   - **Client Secret** (OAuth 2.0 - Web application)

## Resumen

Con estos cambios:

1. ✅ **Deep linking configurado** en Android e iOS
2. ✅ **Código actualizado** para usar `LaunchMode.externalApplication`
3. ⚠️ **PENDIENTE**: Debes configurar las URLs de redirección en Supabase Dashboard

Una vez que configures las URLs en el Dashboard, el login con Google funcionará perfectamente en dispositivos físicos con una experiencia de usuario nativa y profesional.

## Referencias

- [Supabase Deep Linking Guide](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)
- [Flutter Deep Linking](https://docs.flutter.dev/ui/navigation/deep-linking)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)

