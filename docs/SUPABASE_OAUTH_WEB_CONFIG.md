# Configuración de OAuth para Web en Supabase

Este documento explica la configuración necesaria para que el login con Google funcione correctamente en la versión web de la aplicación.

## Problema

El login con Google funciona bien en Android, pero en la web (publicado en Firebase Hosting en `renomada.com`), después de seleccionar la cuenta de Google, no redirige correctamente.

## Solución

### 1. Configuración en Supabase Dashboard

**IMPORTANTE:** Puedes tener web y mobile funcionando simultáneamente. No hay conflicto porque cada plataforma usa su propia URL específica definida en el código.

#### Site URL (UNO SOLO)
- **URL:** `https://app.renomada.com`
- **Nota:** Este campo es principalmente para emails y como fallback. Debe ser el dominio base de tu aplicación web.

#### Redirect URLs (LISTA - Aquí van TODAS las URLs permitidas)

Esta es la lista donde van **TODAS** las URLs que pueden recibir callbacks OAuth, tanto web como mobile:

- `https://app.renomada.com/` ← **Para web** (debe estar aquí - SIN el hash `#`)
- `io.supabase.renomada://login-callback/` ← **Para Android** (ya está configurada)
- `io.supabase.renomada://**` ← **Wildcard para Android** (ya está configurada)

**IMPORTANTE sobre Hash Routing:**
- La URL en Supabase debe ser `https://app.renomada.com/` (SIN el `#/login`)
- El hash (`#/login`) es manejado por el router del cliente (GoRouter)
- Cuando Supabase redirige después de OAuth, redirige a `https://app.renomada.com/` con los parámetros de auth
- El router de Flutter detecta estos parámetros y maneja la navegación correctamente

**¿Cómo funciona?**
- Cuando el código detecta que está en **web**, usa `https://app.renomada.com/` como redirect URL
- Cuando el código detecta que está en **mobile**, usa `io.supabase.renomada://login-callback/` como redirect URL
- Supabase verifica que la URL usada esté en esta lista de Redirect URLs
- **NO hay conflicto** porque cada plataforma usa su URL específica

### 2. Cambios en el Código

#### Archivo: `lib/shared/services/auth_service.dart`

El código ahora usa la URL raíz (`https://renomada.com/`) como redirect URL para web en lugar de `/login`. Esto permite que Supabase maneje correctamente el callback OAuth con el flujo PKCE.

```dart
if (kIsWeb) {
  final currentUrl = Uri.base;
  final baseUrl = '${currentUrl.scheme}://${currentUrl.host}${currentUrl.hasPort ? ':${currentUrl.port}' : ''}';
  redirectTo = '$baseUrl/';
}
```

#### Archivo: `lib/core/router/app_router.dart`

El router ahora detecta correctamente los callbacks OAuth y permite que Supabase los procese automáticamente antes de redirigir.

### 3. Flujo de Autenticación

1. Usuario hace clic en "Iniciar sesión con Google"
2. Se redirige a Google para seleccionar la cuenta
3. Google redirige a Supabase, y luego Supabase redirige de vuelta a `https://app.renomada.com/` con los parámetros de autenticación
4. Supabase procesa automáticamente el callback (flujo PKCE)
5. El `AuthProvider` detecta el cambio de estado de autenticación
6. El usuario es redirigido automáticamente según su estado (onboarding o feed)

### 4. Verificación

Para verificar que todo está funcionando:

1. **Verifica en Supabase Dashboard:**
   - Ve a Authentication > URL Configuration
   - Asegúrate de que `https://app.renomada.com/` esté en la lista de Redirect URLs (sin el hash `#`)
   - El Site URL debe ser `https://app.renomada.com`

2. **Prueba el flujo:**
   - Abre `https://app.renomada.com/#/login` en un navegador
   - Haz clic en "Iniciar sesión con Google"
   - Selecciona tu cuenta de Google
   - Deberías ser redirigido de vuelta a la aplicación y autenticado
   - Revisa la consola del navegador (F12) para ver el log: "OAuth redirect URL for web: https://app.renomada.com/"

### 5. Troubleshooting

Si el problema persiste:

1. **Verifica la consola del navegador:**
   - Abre las herramientas de desarrollador (F12)
   - Revisa la pestaña Console para errores
   - Revisa la pestaña Network para ver las peticiones de autenticación

2. **Verifica los logs de Supabase:**
   - Ve a Authentication > Logs en el dashboard de Supabase
   - Busca errores relacionados con OAuth

3. **Verifica que la URL sea exacta:**
   - El redirect URL en el código debe coincidir exactamente con el configurado en Supabase
   - Debe ser `https://app.renomada.com/` (con el `/` final)
   - **NO debe incluir el hash** (`#/login`) - eso es manejado por el router del cliente
   - El código detecta automáticamente el dominio usando `Uri.base`, así que funcionará con `app.renomada.com`

4. **Verifica la configuración de Google OAuth:**
   - Asegúrate de que `https://app.renomada.com` esté en los "Authorized JavaScript origins" en Google Cloud Console
   - Asegúrate de que el redirect URI de Supabase (normalmente algo como `https://[tu-proyecto-supabase].supabase.co/auth/v1/callback`) esté en los "Authorized redirect URIs"
   - **Nota:** El redirect URI de Google apunta a Supabase, no directamente a tu dominio

## Notas Adicionales

- El flujo PKCE es más seguro que el flujo implícito y es el recomendado para aplicaciones web
- La URL de redirect debe ser exacta: si el código genera `https://app.renomada.com/` (con trailing slash), debe estar exactamente así en Supabase
- **Hash routing (`#/login`)**: El hash es manejado por GoRouter en el cliente. Supabase solo necesita el dominio base (`https://app.renomada.com/`)
- El código detecta automáticamente el dominio actual usando `Uri.base`, por lo que funciona con cualquier dominio (dev, staging, producción)
- Para desarrollo local, puedes agregar `http://localhost:port/` a las redirect URLs en Supabase

