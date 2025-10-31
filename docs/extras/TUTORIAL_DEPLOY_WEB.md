# 🌐 Tutorial: Deploy de ReNomada Web (Firebase Hosting + Netlify)

**Objetivo:** Publicar la versión web de ReNomada en Firebase Hosting o Netlify

**Costo:** ✅ Gratis en ambos servicios (con límites generosos)

---

## 📋 Tabla de Contenidos

1. [Preparación Inicial](#1-preparación-inicial)
2. [Firebase Hosting](#2-firebase-hosting)
3. [Netlify](#3-netlify)
4. [Configuración de Routing (SPA)](#4-configuración-de-routing-spa)
5. [Configuración de Seguridad](#5-configuración-de-seguridad)
6. [Variables de Entorno](#6-variables-de-entorno)
7. [Deploy Continuo (CI/CD)](#7-deploy-continuo-cicd)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Preparación Inicial

### 1.1 Verificar que Flutter Web Está Habilitado

```bash
# Verificar canales disponibles
flutter channels

# Cambiar a canal estable (si no estás en él)
flutter channel stable

# Actualizar Flutter
flutter upgrade

# Habilitar web (si no está habilitado)
flutter config --enable-web
```

### 1.2 Verificar Dependencias Web

**Archivo:** `pubspec.yaml`

Asegúrate de que estas dependencias estén configuradas para web:

```yaml
dependencies:
  # ... otras dependencias ...
  
  # Estas deberían funcionar en web automáticamente
  go_router: ^13.0.0  # Compatible con web
  supabase_flutter: ^2.0.0  # Compatible con web
  flutter_riverpod: ^2.4.0  # Compatible con web
```

### 1.3 Build para Web (Prueba Local)

```bash
# Build para web (modo release)
flutter build web --release

# Probar localmente
cd build/web
# Opción 1: Python
python -m http.server 8000
# Opción 2: Node.js http-server
npx http-server -p 8000

# Abrir en navegador
# http://localhost:8000
```

**Verificar que funciona:**
- ✅ Login/Signup funciona
- ✅ OAuth redirect funciona
- ✅ Routing funciona (navegar entre páginas)
- ✅ No hay errores en consola

---

## 2. Firebase Hosting

### 2.1 Instalar Firebase CLI

```bash
# Instalar Firebase CLI globalmente
npm install -g firebase-tools

# Verificar instalación
firebase --version
```

### 2.2 Login a Firebase

```bash
# Login a Firebase
firebase login

# Verificar proyectos disponibles
firebase projects:list
```

### 2.3 Inicializar Firebase en el Proyecto

```bash
# En la raíz del proyecto Flutter
cd /path/to/renomada

# Inicializar Firebase
firebase init hosting
```

**Configuración interactiva:**

```
? What do you want to use as your public directory? build/web
? Configure as a single-page app (rewrite all urls to /index.html)? Yes
? Set up automatic builds and deploys with GitHub? No (puedes configurarlo después)
? File build/web/index.html already exists. Overwrite? No
```

**Resultado:** Se crea `firebase.json` y `.firebaserc`

### 2.4 Configurar firebase.json

**Archivo:** `firebase.json`

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      },
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      },
      {
        "source": "**",
        "headers": [
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-Frame-Options",
            "value": "DENY"
          },
          {
            "key": "X-XSS-Protection",
            "value": "1; mode=block"
          },
          {
            "key": "Strict-Transport-Security",
            "value": "max-age=31536000; includeSubDomains"
          },
          {
            "key": "Referrer-Policy",
            "value": "strict-origin-when-cross-origin"
          }
        ]
      }
    ]
  }
}
```

**Nota:** Si necesitas Content-Security-Policy (CSP), puedes agregarlo al objeto headers anterior. Ver sección [5.3 🛡️ Headers de Seguridad](#53-️-headers-de-seguridad-en-firebase) para más detalles.

### 2.5 Configurar .firebaserc

**Archivo:** `.firebaserc`

```json
{
  "projects": {
    "default": "tu-proyecto-firebase-id"
  }
}
```

Para obtener tu proyecto Firebase:
- Crear nuevo proyecto en https://console.firebase.google.com
- O usar proyecto existente

### 2.6 Build y Deploy

```bash
# Build para web
flutter build web --release

# Deploy a Firebase Hosting
firebase deploy --only hosting
```

**Resultado:** URL tipo `https://tu-proyecto.web.app` o `https://tu-proyecto.firebaseapp.com`

### 2.7 Configurar Dominio Custom (Opcional)

1. **En Firebase Console**
   - **Hosting → Add custom domain**
   - Ingresar tu dominio
   - Agregar registros DNS según instrucciones
   - Esperar verificación (puede tardar horas)

2. **Configurar SSL**
   - Firebase lo hace automáticamente
   - Puede tardar algunas horas en activarse

---

## 3. Netlify

### 3.1 Opción A: Deploy Manual (Drag & Drop)

1. **Build para web:**
   ```bash
   flutter build web --release
   ```

2. **Ir a Netlify:**
   - URL: https://app.netlify.com
   - Crear cuenta o login

3. **Deploy:**
   - Arrastrar carpeta `build/web` a la zona de deploy
   - Netlify subirá y desplegará automáticamente

**Resultado:** URL tipo `https://random-name-123456.netlify.app`

### 3.2 Opción B: Deploy desde Git (Recomendado)

1. **Push código a Git**
   - GitHub, GitLab, o Bitbucket

2. **Conectar en Netlify:**
   - **Add new site → Import an existing project**
   - Seleccionar tu repositorio
   - Autorizar acceso

3. **Configurar Build Settings:**

   **Build command:**
   ```bash
   flutter build web --release
   ```

   **Publish directory:**
   ```
   build/web
   ```

   **Variables de entorno (si necesitas):**
   ```
   FLUTTER_ROOT=/usr/local/bin/flutter
   ```

4. **Deploy:**
   - Netlify construirá y desplegará automáticamente
   - Cada push a `main` desplegará automáticamente

### 3.3 Configurar netlify.toml

**Archivo:** `netlify.toml` (en raíz del proyecto)

```toml
[build]
  command = "flutter build web --release"
  publish = "build/web"

[build.environment]
  FLUTTER_VERSION = "3.24.0"  # Usa tu versión de Flutter

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[[headers]]
  for = "/*.js"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/*.css"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/*.@(jpg|jpeg|gif|png|svg|webp)"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    X-XSS-Protection = "1; mode=block"
    Referrer-Policy = "strict-origin-when-cross-origin"
```

**Nota:** Netlify puede tener problemas con Flutter build. Ver sección de troubleshooting.

### 3.4 Configurar Dominio Custom

1. **En Netlify Dashboard:**
   - **Site settings → Domain management → Add custom domain**
   - Ingresar tu dominio
   - Configurar DNS según instrucciones

2. **SSL:**
   - Netlify lo configura automáticamente (Let's Encrypt)

---

## 4. Configuración de Routing (SPA)

Flutter web con GoRouter funciona como SPA (Single Page Application), así que necesitas que todas las rutas redirijan a `index.html`.

### 4.1 Firebase Hosting

Ya configurado en `firebase.json` con el rewrite:

```json
"rewrites": [
  {
    "source": "**",
    "destination": "/index.html"
  }
]
```

### 4.2 Netlify

Ya configurado en `netlify.toml` con redirect:

```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### 4.3 Verificar Routing

Después del deploy, prueba:

1. Ir a `https://tu-app.com/feed` directamente
2. Navegar entre páginas
3. Refrescar página en cualquier ruta
4. Verificar que no aparece error 404

---

## 5. Configuración de Seguridad

### 5.1 🔐 Gestión Segura de Claves de Supabase

#### ¿Es Seguro Exponer la Clave Anon de Supabase?

**✅ SÍ, es completamente seguro y es el diseño correcto.**

La clave **anon** (anónima) de Supabase está diseñada para ser pública y puede estar en el código del cliente. La seguridad real proviene de:

1. **Row Level Security (RLS)**: Políticas en la base de datos que controlan el acceso a los datos
2. **Service Role Key**: Esta clave NUNCA debe exponerse (solo en el backend)
3. **Autenticación**: Los usuarios solo pueden acceder a datos que sus permisos permiten

**Lo que debes proteger:**
- ❌ **Service Role Key**: NUNCA exponer en código cliente
- ❌ **JWT Secret**: NUNCA exponer
- ✅ **Anon Key**: Puede estar en código cliente

#### Configuración Actual del Código

El código ya está configurado correctamente:

**Archivo:** `lib/core/constants/supabase_constants.dart`

```dart
class SupabaseConstants {
  // ✅ Esto es seguro de exponer
  static const String supabaseUrl = 'https://tu-proyecto.supabase.co';
  static const String supabaseAnonKey = 'eyJhbG...'; // Anon key pública
  
  // ... otras constantes
}
```

**Archivo:** `lib/core/config/supabase_config.dart`

```dart
static Future<void> initialize() async {
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    debug: kDebugMode, // ✅ Solo debug en desarrollo
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // ✅ PKCE para seguridad OAuth
    ),
  );
  // ...
}
```

**Cambios realizados para producción:**
- ✅ `debug: kDebugMode` - Solo habilita debug en desarrollo
- ✅ OAuth redirect dinámico para web - Detecta automáticamente la URL

#### Opción Alternativa: Variables de Entorno (Opcional)

Si prefieres no hardcodear las claves (aunque no es necesario), puedes usar variables de entorno:

**1. Modificar `lib/core/constants/supabase_constants.dart`:**

```dart
class SupabaseConstants {
  // Obtiene valores de variables de entorno o usa valores por defecto
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tu-proyecto.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbG...', // Tu anon key
  );
  
  // ... resto del código
}
```

**2. Build con variables (opcional):**

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbG...
```

**Nota:** Esta opción es útil si tienes múltiples entornos (dev, staging, prod) o prefieres no hardcodear. Para producción simple, no es necesario.

### 5.2 🔒 Configuración de CORS en Supabase

Para que tu app web pueda comunicarse con Supabase, debes configurar CORS:

**Pasos:**

1. **Ir a Supabase Dashboard**
   - URL: https://app.supabase.com
   - Seleccionar tu proyecto

2. **Configurar CORS:**
   - **Settings → API → CORS Configuration**
   - Agregar tus URLs de producción:
     ```
     https://tu-proyecto.web.app
     https://tu-proyecto.firebaseapp.com
     https://tu-proyecto.netlify.app
     https://tu-dominio-custom.com
     ```
   - También agregar `http://localhost:8000` para desarrollo local

3. **Configurar Redirect URLs (OAuth):**
   - **Authentication → URL Configuration**
   - Agregar en **Redirect URLs**:
     ```
     https://tu-proyecto.web.app/login
     https://tu-proyecto.firebaseapp.com/login
     https://tu-proyecto.netlify.app/login
     https://tu-dominio-custom.com/login
     ```
   - También agregar `http://localhost:8000/login` para desarrollo

4. **Configurar Site URL:**
   - En **Authentication → URL Configuration**
   - **Site URL**: Tu URL principal de producción
     ```
     https://tu-proyecto.web.app
     ```

### 5.3 🛡️ Headers de Seguridad en Firebase

El archivo `firebase.json` ya incluye headers de seguridad básicos. Aquí están explicados:

**Headers actuales en `firebase.json`:**

```json
{
  "headers": [
    {
      "source": "**",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
          // Previene MIME type sniffing
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
          // Previene que la página se muestre en iframes (previene clickjacking)
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
          // Habilita protección XSS en navegadores antiguos
        }
      ]
    }
  ]
}
```

**Headers adicionales recomendados (opcional):**

```json
{
  "headers": [
    {
      "source": "**",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        },
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=31536000; includeSubDomains"
          // Forza HTTPS (HSTS)
        },
        {
          "key": "Referrer-Policy",
          "value": "strict-origin-when-cross-origin"
          // Controla qué información de referrer se envía
        },
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.gstatic.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://*.supabase.co;"
          // Política de seguridad de contenido (ajusta según tus necesidades)
        }
      ]
    }
  ]
}
```

**⚠️ Nota sobre Content-Security-Policy:** Debes ajustarla según las dependencias de tu app. La versión anterior permite:
- Scripts de Google (para CanvasKit)
- Conexiones a Supabase
- Imágenes de cualquier origen HTTPS
- Estilos inline (necesario para Flutter)

### 5.4 🔐 Headers de Seguridad en Netlify

El archivo `netlify.toml` ya incluye headers de seguridad. Para agregar más:

**Archivo:** `netlify.toml`

```toml
[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    X-XSS-Protection = "1; mode=block"
    Referrer-Policy = "strict-origin-when-cross-origin"
    Strict-Transport-Security = "max-age=31536000; includeSubDomains"

# Opcional: Content Security Policy
[[headers]]
  for = "/*"
  [headers.values]
    Content-Security-Policy = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.gstatic.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://*.supabase.co;"
```

### 5.5 ✅ Verificación de Seguridad Post-Deploy

Después del deploy, verifica la seguridad:

**1. Verificar Headers:**

```bash
# Ver headers de tu sitio
curl -I https://tu-proyecto.web.app

# O usar herramienta online:
# https://securityheaders.com
```

**2. Verificar HTTPS:**
- ✅ Debe redirigir automáticamente HTTP → HTTPS
- ✅ SSL debe estar activo (candado verde en navegador)

**3. Verificar OAuth:**
- ✅ Probar login con Google/Apple
- ✅ Verificar que el redirect funciona correctamente
- ✅ Verificar que el usuario queda autenticado

**4. Verificar CORS:**
- ✅ No deben aparecer errores CORS en la consola del navegador
- ✅ Las peticiones a Supabase deben funcionar

**5. Verificar RLS (Row Level Security):**
- ✅ Los usuarios solo pueden acceder a sus propios datos
- ✅ Las políticas de RLS en Supabase están activas

### 5.6 🔑 Checklist de Seguridad

Antes de hacer deploy a producción:

- [ ] ✅ Código usa `debug: kDebugMode` (no hardcoded `true`)
- [ ] ✅ Clave Service Role NUNCA está en el código cliente
- [ ] ✅ CORS configurado en Supabase con URLs de producción
- [ ] ✅ Redirect URLs configuradas en Supabase para OAuth
- [ ] ✅ Headers de seguridad configurados en `firebase.json` o `netlify.toml`
- [ ] ✅ HTTPS habilitado y funcionando
- [ ] ✅ RLS (Row Level Security) activo en todas las tablas de Supabase
- [ ] ✅ OAuth funciona correctamente en producción
- [ ] ✅ No hay claves sensibles en el código (solo anon key es aceptable)

---

## 6. Variables de Entorno

### 6.1 Supabase en Web

**Configuración en Supabase:**

1. **Ir a Supabase Dashboard**
   - **Settings → API**
   - Copiar **Project URL** y **anon public key**

2. **Configurar Redirect URLs:**
   - **Authentication → URL Configuration**
   - Agregar tus URLs web:
     - `https://tu-app.web.app/**`
     - `https://tu-app.netlify.app/**`
     - Tu dominio custom si tienes

### 6.2 Firebase Hosting - Variables de Entorno

**Para Flutter Web, NO necesitas variables de entorno para Supabase** si las claves están en el código (que es seguro para la anon key).

Sin embargo, si prefieres usar variables de entorno:

**Opción 1: En el código (recomendado para anon key)**

Ya están configuradas en `lib/core/constants/supabase_constants.dart`. No necesitas cambios.

**Opción 2: Build con --dart-define**

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJxxx...
```

Y modificar el código para usar `String.fromEnvironment()` (ver sección 5.1).

**Opción 3: Firebase Functions (para valores privados)**

Si necesitas variables privadas (como Service Role Key), usa Firebase Functions (no Hosting).

### 6.3 Netlify - Variables de Entorno

**En Netlify Dashboard:**

1. **Site settings → Environment variables**
2. Agregar variables si necesitas:
   ```
   SUPABASE_URL=https://xxx.supabase.co
   SUPABASE_ANON_KEY=eyJxxx...
   ```

**En build command:**

```bash
flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

**Nota:** Para la anon key de Supabase, esto es opcional ya que está diseñada para ser pública.

---

## 7. Deploy Continuo (CI/CD)

### 7.1 Firebase Hosting + GitHub Actions

**Archivo:** `.github/workflows/firebase-deploy.yml`

```yaml
name: Deploy to Firebase Hosting

on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build web
        run: flutter build web --release
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: tu-proyecto-firebase-id
```

**Configurar secret:**

1. **Crear Service Account en Firebase:**
   - **Project Settings → Service Accounts → Generate new private key**
   - Descargar JSON

2. **En GitHub:**
   - **Repository → Settings → Secrets → New repository secret**
   - Name: `FIREBASE_SERVICE_ACCOUNT`
   - Value: Contenido del JSON descargado

### 7.2 Netlify + GitHub (Automático)

Netlify ya hace deploy automático cuando conectas un repositorio Git. Solo asegúrate de:

1. ✅ Repositorio conectado
2. ✅ Build settings configurados
3. ✅ Branch de producción: `main` (o el que uses)

---

## 8. Troubleshooting

### Problema: "404 Not Found" al refrescar página

**Causa:** Routing SPA no configurado

**Solución:**
- Firebase: Verifica que `firebase.json` tiene el rewrite
- Netlify: Verifica que `netlify.toml` tiene el redirect

### Problema: OAuth no funciona en web

**Causa:** Redirect URLs no configuradas en Supabase

**Solución:**
1. Ir a Supabase Dashboard
2. **Authentication → URL Configuration**
3. Agregar tus URLs de producción

### Problema: Build falla en Netlify

**Causa:** Netlify no tiene Flutter instalado

**Solución 1: Usar buildpack de Flutter**

**Archivo:** `netlify.toml`

```toml
[build]
  command = "bash build.sh"
  publish = "build/web"

[[plugins]]
  package = "@netlify/plugin-lighthouse"
```

**Archivo:** `build.sh`

```bash
#!/bin/bash
set -e

# Instalar Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Verificar instalación
flutter doctor

# Build
flutter build web --release
```

**Solución 2: Usar Docker (avanzado)**

Crear `Dockerfile` y usar build image.

**Solución 3: Deploy desde CI/CD**

- Build en GitHub Actions
- Deploy build result a Netlify

### Problema: Assets no cargan

**Causa:** Base href incorrecto

**Solución:**

```bash
# Build con base href específico
flutter build web --release --base-href="/"

# O para subdirectorio
flutter build web --release --base-href="/renomada/"
```

### Problema: Performance lenta en web

**Optimizaciones:**

1. **Habilitar CanvasKit (mejor performance):**
   ```bash
   flutter build web --release --web-renderer canvaskit
   ```

2. **O usar HTML renderer (menor tamaño):**
   ```bash
   flutter build web --release --web-renderer html
   ```

3. **Lazy loading de imágenes:**
   - Ya deberías estar usando lazy loading
   - Verificar que imágenes grandes están optimizadas

### Problema: CORS errors con Supabase

**Causa:** Configuración de CORS en Supabase

**Solución:**
1. En Supabase Dashboard
2. **Settings → API**
3. Agregar tu dominio a "Allowed CORS origins"

---

## ✅ Checklist de Deploy

### Antes de Deploy:
- [ ] Flutter web habilitado
- [ ] Build local funciona sin errores
- [ ] OAuth funciona en local
- [ ] Routing funciona (refrescar páginas)
- [ ] Todas las dependencias compatibles con web
- [ ] Código actualizado para producción (`debug: kDebugMode`)

### Configuración de Seguridad:
- [ ] CORS configurado en Supabase con URLs de producción
- [ ] Redirect URLs configuradas en Supabase para OAuth
- [ ] Headers de seguridad configurados
- [ ] RLS activo en Supabase

### Firebase Hosting:
- [ ] Firebase CLI instalado
- [ ] Login a Firebase exitoso
- [ ] `firebase.json` configurado
- [ ] `.firebaserc` configurado
- [ ] Build ejecutado exitosamente
- [ ] Deploy completado
- [ ] URL de producción funciona
- [ ] Routing SPA funciona
- [ ] OAuth redirects configurados en Supabase

### Netlify:
- [ ] Cuenta de Netlify creada
- [ ] Repositorio conectado (o deploy manual)
- [ ] `netlify.toml` configurado
- [ ] Build settings correctos
- [ ] Deploy completado
- [ ] URL de producción funciona
- [ ] Routing SPA funciona
- [ ] OAuth redirects configurados en Supabase

### Después de Deploy:
- [ ] Probar login/signup
- [ ] Probar OAuth (Google)
- [ ] Probar todas las rutas principales
- [ ] Refrescar páginas (verificar 404)
- [ ] Probar en diferentes navegadores
- [ ] Verificar performance
- [ ] Configurar dominio custom (opcional)

---

## 📊 Comparación: Firebase Hosting vs Netlify

| Característica | Firebase Hosting | Netlify |
|---------------|------------------|---------|
| **Costo** | ✅ Gratis (10GB storage, 360MB/day transfer) | ✅ Gratis (100GB bandwidth) |
| **SSL** | ✅ Automático | ✅ Automático |
| **CDN** | ✅ Global CDN | ✅ Global CDN |
| **CI/CD** | ✅ Con GitHub Actions | ✅ Integrado |
| **Build time** | Manual (necesitas CI/CD) | Automático |
| **Flutter support** | ✅ Funciona | ⚠️ Requiere configuración |
| **Preview deploys** | Con Firebase CLI | ✅ Automático por PR |
| **Analytics** | Firebase Analytics integrado | Netlify Analytics (pago) |

**Recomendación:**
- **Firebase Hosting:** Si ya usas Firebase para otras cosas
- **Netlify:** Si quieres deploy más simple y previews automáticos

---

## 🔗 Referencias

- [Flutter Web Documentation](https://docs.flutter.dev/deployment/web)
- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [Netlify Documentation](https://docs.netlify.com/)
- [GoRouter Web Support](https://pub.dev/packages/go_router#web)

---

## 🚀 Comandos Rápidos

### Firebase:

```bash
# Build y deploy
flutter build web --release && firebase deploy --only hosting

# Solo deploy (si ya hiciste build)
firebase deploy --only hosting

# Ver logs
firebase hosting:channel:list
```

### Netlify:

```bash
# Build local
flutter build web --release

# Deploy manual (drag & drop build/web)
# O push a Git para deploy automático
```

---

**Fecha de creación:** 2025  
**Versión:** 1.0  
**Estado:** ✅ Listo para uso

