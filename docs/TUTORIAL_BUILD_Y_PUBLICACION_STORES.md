# 📱 Tutorial: Build y Publicación en Stores (Android + iOS)

**Objetivo:** Compilar, firmar y publicar ReNomada en Google Play Store y Apple App Store

**Tiempo estimado:** 2-3 días (dependiendo de revisión de las stores)

---

## 📋 Tabla de Contenidos

1. [Preparación Inicial](#1-preparación-inicial)
2. [Android - Google Play Store](#2-android---google-play-store)
3. [iOS - Apple App Store](#3-ios---apple-app-store)
4. [Checklist Final](#4-checklist-final)

---

## 1. Preparación Inicial

### 1.1 Cuentas Necesarias

- ✅ **Google Play Console:** $25 USD (pago único)
- ✅ **Apple Developer Program:** $99 USD/año
- ✅ **Cuenta de desarrollador en ambas plataformas**

### 1.2 Preparar Assets

**Necesitas:**
- Icono de la app (512x512px para Android, múltiples tamaños para iOS)
- Screenshots (mínimo 2, recomendado 5-8)
- Feature graphic (1024x500px para Android)
- App preview video (opcional pero recomendado)
- Descripción corta (80 caracteres)
- Descripción larga (4000 caracteres)

---

## 2. Android - Google Play Store

### 2.1 Configurar Keystore para Firma

**Crear keystore (solo primera vez):**

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Información a completar:**
- Password del keystore (guárdala SEGURA, si la pierdes no podrás actualizar la app)
- Nombre completo
- Unidad organizativa
- Ciudad
- Estado/Provincia
- Código de país (ej: ES para España)

**Resultado:** Se crea `upload-keystore.jks` en la carpeta `android/`

### 2.2 Configurar key.properties

**Crear archivo:** `android/key.properties`

```properties
storePassword=<TU_PASSWORD_DEL_KEYSTORE>
keyPassword=<TU_PASSWORD_DEL_KEYSTORE>
keyAlias=upload
storeFile=upload-keystore.jks
```

**⚠️ IMPORTANTE:** 
- NO subas este archivo a Git
- Agrégalo a `.gitignore`

### 2.3 Configurar build.gradle para Firma

**Archivo:** `android/app/build.gradle`

```gradle
// Agregar al inicio del archivo
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... configuraciones existentes ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ... otras configuraciones ...
        }
    }
}
```

### 2.4 Configurar Version y Build Number

**Archivo:** `pubspec.yaml`

```yaml
version: 1.0.0+1
#         ^^^^ ^
#         |    |
#         |    +-- buildNumber (número interno)
#         +------- versionName (visible para usuarios)
```

**Cada actualización:**
- Cambiar versionName: `1.0.0` → `1.0.1` → `1.1.0` etc.
- Incrementar buildNumber: `1` → `2` → `3` etc.

### 2.5 Build AAB (Android App Bundle)

**Build de release:**

```bash
flutter build appbundle --release
```

**Resultado:** `build/app/outputs/bundle/release/app-release.aab`

**⚠️ Google Play requiere AAB, NO APK** (desde agosto 2021)

### 2.6 Crear App en Google Play Console

1. **Ir a Google Play Console**
   - URL: https://play.google.com/console
   - Crear nueva app

2. **Información de la App**
   - Nombre: `ReNomada`
   - Idioma predeterminado: Español
   - Tipo: App
   - Gratis o de pago: Gratis

3. **Contenido de la app**
   - Descripción corta (80 caracteres)
   - Descripción completa (4000 caracteres)
   - Icono (512x512px)
   - Feature graphic (1024x500px)
   - Screenshots (mínimo 2):
     - Phone (720-3200px altura)
     - Tablet 7" (opcional)
     - Tablet 10" (opcional)

4. **Clasificación de contenido**
   - Completar cuestionario sobre contenido de la app

5. **Precio y distribución**
   - Seleccionar países
   - Precio: Gratis
   - Aceptar términos

### 2.7 Subir AAB a Internal Testing

1. **Crear release interno**
   - Menú lateral: **Release → Testing → Internal testing**
   - Clic en **Create new release**
   - Subir el archivo `app-release.aab`
   - Notas de la versión (lo que cambió)

2. **Revisar release**
   - Verificar que no haya errores
   - Guardar

3. **Crear lista de prueba**
   - Agregar emails de testers (máximo 100)
   - Guardar

4. **Enviar para revisión**
   - Clic en **Review release**
   - Google revisará (puede tardar horas o días)

### 2.8 Proceso de Revisión

- **Tiempo típico:** 1-3 días
- **Estado:** Puedes verlo en Play Console
- **Si es rechazada:** Google te dirá qué corregir

### 2.9 Publicar en Producción

1. **Después de aprobación:**
   - Ir a **Release → Production**
   - Crear nuevo release
   - Subir el mismo AAB (o nueva versión)
   - Configurar rollout gradual (opcional, recomendado)
     - Empezar con 20% de usuarios
     - Si no hay problemas, aumentar a 100%

2. **Activar**
   - Clic en **Activate**
   - La app estará disponible en unas horas

---

## 3. iOS - Apple App Store

### 3.1 Requisitos Previos

- Mac con Xcode instalado
- Cuenta de Apple Developer ($99/año)
- Certificados y perfiles de aprovisionamiento

### 3.2 Configurar Apple Developer Account

1. **Ir a Apple Developer Portal**
   - URL: https://developer.apple.com/account
   - Inscribirse si no tienes cuenta ($99/año)

2. **Crear App ID**
   - **Certificates, Identifiers & Profiles → Identifiers**
   - Clic en **+**
   - Seleccionar **App IDs**
   - Descripción: `ReNomada`
   - Bundle ID: `com.renomada.app` (debe coincidir con `ios/Runner.xcodeproj`)

3. **Configurar Capabilities**
   - Push Notifications (si usas)
   - Sign in with Apple (si usas)
   - Associated Domains (si usas deep links)

### 3.3 Configurar Xcode

1. **Abrir proyecto en Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configurar Signing & Capabilities**
   - Seleccionar proyecto **Runner**
   - Tab **Signing & Capabilities**
   - Team: Seleccionar tu equipo de desarrollo
   - Bundle Identifier: `com.renomada.app`
   - Xcode creará automáticamente los certificados y perfiles

3. **Configurar Version**
   - Tab **General**
   - Version: `1.0.0` (visible para usuarios)
   - Build: `1` (número interno)

### 3.4 Configurar Info.plist

**Archivo:** `ios/Runner/Info.plist`

```xml
<key>CFBundleDisplayName</key>
<string>ReNomada</string>
<key>CFBundleName</key>
<string>renomada</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
```

### 3.5 Crear App en App Store Connect

1. **Ir a App Store Connect**
   - URL: https://appstoreconnect.apple.com
   - Clic en **My Apps → +**

2. **Nueva App**
   - Platform: iOS
   - Name: `ReNomada`
   - Primary Language: Spanish
   - Bundle ID: Seleccionar el creado (`com.renomada.app`)
   - SKU: `renomada-ios` (identificador único, no visible)
   - User Access: Full Access

### 3.6 Preparar Información de la App

1. **App Information**
   - Nombre: `ReNomada`
   - Subtitle (opcional)
   - Category: Seleccionar categoría apropiada

2. **Pricing and Availability**
   - Price: Free
   - Availability: Seleccionar países

3. **App Privacy**
   - Completar cuestionario de privacidad
   - Explicar qué datos recopilas (ubicación, fotos, etc.)

### 3.7 Crear Version y Preparar Assets

1. **App Store Listing**
   - Descripción (4000 caracteres)
   - Keywords (100 caracteres, separados por comas)
   - Screenshots (requeridos):
     - iPhone 6.7" (iPhone 14 Pro Max)
     - iPhone 6.5" (iPhone 11 Pro Max)
     - iPhone 5.5" (iPhone 8 Plus)
   - App Preview Video (opcional)

2. **Version Information**
   - What's New in This Version
   - Version number: `1.0.0`
   - Copyright: Tu nombre/año

### 3.8 Build para App Store

**Opción A: Desde Xcode (Recomendado)**

1. **Product → Archive**
   - Xcode compilará y creará un archive

2. **Window → Organizer**
   - Verás el archive creado
   - Clic en **Distribute App**

3. **Distribute App**
   - Seleccionar **App Store Connect**
   - Siguiente → **Upload**
   - Seleccionar equipo
   - Upload

**Opción B: Desde Terminal**

```bash
# Build para App Store
flutter build ios --release

# Luego abrir en Xcode y hacer Archive manualmente
open ios/Runner.xcworkspace
```

### 3.9 Subir Build a App Store Connect

1. **Desde Xcode Organizer:**
   - Seleccionar archive
   - **Distribute App → App Store Connect → Upload**
   - Esperar a que termine (puede tardar varios minutos)

2. **Verificar en App Store Connect:**
   - **TestFlight → Builds**
   - Verás el build procesándose (puede tardar 10-30 minutos)
   - Estado cambiará a "Ready to Submit"

### 3.10 Configurar Build para Revisión

1. **En App Store Connect:**
   - **App Store → Versiones**
   - Seleccionar versión `1.0.0`
   - Build: Seleccionar el build subido
   - Export Compliance: Completar si es necesario

2. **Completar información:**
   - Screenshots
   - Descripción
   - Keywords
   - Support URL
   - Marketing URL (opcional)

3. **Enviar para revisión:**
   - Clic en **Submit for Review**
   - Contestar preguntas de export compliance
   - Enviar

### 3.11 Proceso de Revisión

- **Tiempo típico:** 24-48 horas (puede ser más)
- **Estado:** Puedes verlo en App Store Connect
- **Si es rechazada:** Apple te dirá qué corregir

---

## 4. Checklist Final

### Antes de Publicar:

#### Android:
- [ ] Keystore creado y guardado de forma segura
- [ ] `key.properties` configurado y en `.gitignore`
- [ ] `build.gradle` configurado para firma
- [ ] Version y build number actualizados en `pubspec.yaml`
- [ ] AAB build exitoso
- [ ] App creada en Play Console
- [ ] Descripción, screenshots y assets completos
- [ ] Política de privacidad publicada (URL)
- [ ] AAB subido a Internal Testing
- [ ] Probado en Internal Testing
- [ ] Aprobado por Google
- [ ] Listo para producción

#### iOS:
- [ ] Apple Developer Account activo
- [ ] App ID creado en Developer Portal
- [ ] Certificados y perfiles configurados
- [ ] Xcode configurado correctamente
- [ ] Version y build number actualizados
- [ ] App creada en App Store Connect
- [ ] Descripción, screenshots y assets completos
- [ ] Política de privacidad publicada (URL)
- [ ] Build archivado y subido
- [ ] Build procesado en App Store Connect
- [ ] Información completa en App Store Connect
- [ ] Enviado para revisión
- [ ] Aprobado por Apple
- [ ] Listo para publicación

### Assets Necesarios:

- [ ] Icono (512x512 Android, múltiples iOS)
- [ ] Feature graphic Android (1024x500)
- [ ] Screenshots Android (mínimo 2)
- [ ] Screenshots iOS (múltiples tamaños)
- [ ] Descripción corta (80 caracteres)
- [ ] Descripción larga (4000 caracteres)
- [ ] Keywords
- [ ] Política de privacidad (URL pública)
- [ ] App preview video (opcional)

---

## 🔐 Seguridad de Credenciales

### ⚠️ IMPORTANTE - Guardar de Forma Segura:

**Android Keystore:**
- Archivo: `upload-keystore.jks`
- Password del keystore
- Password de la key
- **Si los pierdes, NO podrás actualizar la app**

**Recomendaciones:**
- Guardar en gestor de contraseñas (1Password, LastPass, etc.)
- Hacer backup en ubicación segura
- NO subir a Git
- Compartir con equipo de forma segura

**Apple:**
- Credenciales se guardan en Keychain
- Asegúrate de tener acceso a tu cuenta de Apple Developer

---

## 📊 Timeline Típico

### Android:
- **Setup inicial:** 2-4 horas
- **Build y subida:** 30 minutos
- **Revisión Google:** 1-3 días
- **Publicación:** Inmediata después de aprobación

### iOS:
- **Setup inicial:** 4-6 horas (primera vez)
- **Build y subida:** 1 hora
- **Procesamiento Apple:** 10-30 minutos
- **Revisión Apple:** 24-48 horas
- **Publicación:** Inmediata después de aprobación

---

## 🐛 Problemas Comunes

### Android:

**"Keystore file not found"**
- Verifica la ruta en `key.properties`
- Asegúrate de que el archivo existe

**"Password was incorrect"**
- Verifica que las passwords en `key.properties` sean correctas

**"AAB no compatible"**
- Verifica que el `targetSdkVersion` sea actual (ej: 33 o superior)
- Verifica que `compileSdkVersion` sea actual

### iOS:

**"No provisioning profile found"**
- En Xcode, ve a Signing & Capabilities
- Selecciona tu Team
- Xcode creará automáticamente el perfil

**"Archive failed"**
- Limpia el build: `flutter clean`
- Rebuild: `flutter build ios --release`
- Intenta desde Xcode directamente

**"Upload failed"**
- Verifica tu conexión a internet
- Verifica que tengas espacio en App Store Connect
- Reintenta después de unos minutos

---

## 📝 Notas Importantes

1. **Versioning:**
   - Cada actualización debe incrementar el número de versión
   - Android: `versionName` en `pubspec.yaml`
   - iOS: `CFBundleShortVersionString` en `Info.plist`

2. **Build Numbers:**
   - Deben incrementarse con cada build, incluso si la versión no cambia
   - Android: `buildNumber` en `pubspec.yaml`
   - iOS: `CFBundleVersion` en `Info.plist`

3. **Primera publicación:**
   - Toma más tiempo (revisión más estricta)
   - Puede ser rechazada varias veces antes de aprobar
   - Sé paciente y sigue las guías de cada store

4. **Updates futuros:**
   - Mucho más rápido después de la primera publicación
   - Revisión más rápida
   - Puedes hacer rollout gradual

---

## 🔗 Referencias

- [Flutter Build and Release](https://docs.flutter.dev/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)

---

**Fecha de creación:** 2025  
**Versión:** 1.0  
**Estado:** ✅ Listo para uso

