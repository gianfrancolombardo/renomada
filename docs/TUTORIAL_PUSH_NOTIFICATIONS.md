# 🔔 Tutorial: Push Notifications en ReNomada

**Objetivo:** Implementar notificaciones push gratuitas para avisar a usuarios cuando se crea un nuevo item en su radio

**Stack:** Flutter + Supabase + Firebase Cloud Messaging (FCM) + Supabase Edge Functions

**Costo:** ✅ Gratis (Firebase tiene free tier generoso)

---

## 📋 Tabla de Contenidos

1. [Arquitectura General](#1-arquitectura-general)
2. [Setup Firebase Cloud Messaging](#2-setup-firebase-cloud-messaging)
3. [Implementar en Flutter](#3-implementar-en-flutter)
4. [Edge Function para Envío](#4-edge-function-para-envío)
5. [Trigger en Base de Datos](#5-trigger-en-base-de-datos)
6. [Testing](#6-testing)
7. [Notificación Específica: Nuevo Item en Radio](#7-notificación-específica-nuevo-item-en-radio)

---

## 1. Arquitectura General

```
Usuario crea item
    ↓
Database Trigger detecta nuevo item
    ↓
Edge Function se ejecuta
    ↓
Busca usuarios cercanos (mismo radio)
    ↓
Obtiene tokens push de esos usuarios
    ↓
Envía notificación via FCM
    ↓
Usuario recibe notificación en su dispositivo
```

**¿Por qué gratis?**
- Firebase Cloud Messaging es **completamente gratis**
- Supabase Edge Functions tienen **500K invocaciones/mes gratis**
- Perfecto para MVP y apps pequeñas/medianas

---

## 2. Setup Firebase Cloud Messaging

### 2.1 Crear Proyecto en Firebase

1. **Ir a Firebase Console**
   - URL: https://console.firebase.google.com
   - Clic en **Add project**

2. **Configurar proyecto**
   - Nombre: `renomada-push`
   - Desactivar Google Analytics (opcional, para MVP no necesario)
   - Crear proyecto

### 2.2 Configurar Android App en Firebase

1. **Agregar app Android**
   - Clic en icono Android
   - Package name: `com.renomada.app` (debe coincidir con tu app)
   - App nickname: `ReNomada Android`
   - Registrar app

2. **Descargar google-services.json**
   - Descargar el archivo
   - Colocar en: `android/app/google-services.json`

3. **Configurar build.gradle**

**Archivo:** `android/build.gradle`

```gradle
buildscript {
    dependencies {
        // ... otras dependencias ...
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**Archivo:** `android/app/build.gradle`

```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'com.google.gms.google-services' // ← Agregar esta línea

// ... resto del archivo ...
```

### 2.3 Configurar iOS App en Firebase

1. **Agregar app iOS**
   - Clic en icono iOS
   - Bundle ID: `com.renomada.app`
   - App nickname: `ReNomada iOS`
   - Register

2. **Descargar GoogleService-Info.plist**
   - Descargar el archivo
   - Colocar en: `ios/Runner/GoogleService-Info.plist`

3. **Configurar APNs (Apple Push Notification Service)**
   - En Xcode: Abrir `ios/Runner.xcworkspace`
   - **Signing & Capabilities → + Capability → Push Notifications**
   - En Firebase Console:
     - **Project Settings → Cloud Messaging → Apple app configuration**
     - Subir certificado APNs (o usar APNs Auth Key, más fácil)

**Obtener APNs Auth Key (Recomendado):**
- Ir a https://developer.apple.com/account/resources/authkeys/list
- Crear nueva key con **Apple Push Notifications service (APNs)**
- Descargar `.p8` file (solo se descarga una vez, guárdalo)
- Subir en Firebase Console

### 2.4 Obtener Server Key de Firebase

1. **En Firebase Console**
   - **Project Settings → Cloud Messaging**
   - Copiar **Server key** (lo necesitarás para Edge Function)
   - También copiar **Sender ID**

---

## 3. Implementar en Flutter

### 3.1 Agregar Dependencias

**Archivo:** `pubspec.yaml`

```yaml
dependencies:
  # ... otras dependencias ...
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
```

Ejecutar:
```bash
flutter pub get
```

### 3.2 Inicializar Firebase

**Archivo:** `lib/main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

**Generar firebase_options.dart:**

```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar Firebase
flutterfire configure
```

Esto creará `lib/firebase_options.dart` automáticamente.

### 3.3 Crear NotificationService

**Archivo:** `lib/shared/services/notification_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/supabase_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Top-level function for handling background messages
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('📨 Background message received: ${message.messageId}');
    // Handle background message here
  }

  Future<void> initialize() async {
    // Request permission (iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else {
      print('❌ User declined notification permission');
      return;
    }

    // Configure foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message: ${message.notification?.title}');
      // Handle foreground message (show in-app notification)
    });

    // Configure background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 Notification opened: ${message.data}');
      _handleNotificationTap(message);
    });

    // Get initial message (if app was opened from notification)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      print('📱 FCM Token: $token');
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> saveTokenToSupabase() async {
    try {
      final token = await getToken();
      if (token == null) return;

      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) return;

      // Save token to push_tokens table
      await SupabaseConfig.from('push_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Push token saved to Supabase');
    } catch (e) {
      print('❌ Error saving push token: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    
    // Navigate based on notification type
    if (data['type'] == 'new_item_in_radius') {
      // Navigate to feed or item details
      // Use your navigation system (GoRouter, etc.)
      print('Navigate to item: ${data['item_id']}');
    } else if (data['type'] == 'new_message') {
      // Navigate to chat
      print('Navigate to chat: ${data['chat_id']}');
    }
  }
}
```

### 3.4 Inicializar en App

**Archivo:** `lib/main.dart` o donde inicializas servicios

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Save token after user logs in
  // (llamar después de login exitoso)
  
  runApp(const MyApp());
}
```

**Después de login exitoso:**

```dart
// En tu auth_provider.dart o donde manejas login
Future<bool> signIn(...) async {
  // ... código de login ...
  
  if (loginSuccessful) {
    // Save push token
    await NotificationService().saveTokenToSupabase();
  }
  
  return loginSuccessful;
}
```

---

## 4. Edge Function para Envío

### 4.1 Crear Edge Function

**Archivo:** `supabase/functions/send-push-notification/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY') || ''
const FCM_URL = 'https://fcm.googleapis.com/fcm/send'

serve(async (req) => {
  try {
    const { user_ids, title, body, data } = await req.json()

    if (!user_ids || !Array.isArray(user_ids) || user_ids.length === 0) {
      return new Response(
        JSON.stringify({ error: 'user_ids required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Get push tokens for users
    const { data: tokens, error: tokensError } = await supabase
      .from('push_tokens')
      .select('token, platform')
      .in('user_id', user_ids)

    if (tokensError) {
      throw tokensError
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No tokens found', sent: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Send push notifications
    const results = await Promise.all(
      tokens.map(async (tokenData) => {
        const payload = {
          to: tokenData.token,
          notification: {
            title: title,
            body: body,
          },
          data: data || {},
          priority: 'high',
        }

        try {
          const response = await fetch(FCM_URL, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `key=${FCM_SERVER_KEY}`,
            },
            body: JSON.stringify(payload),
          })

          const result = await response.json()
          return { success: response.ok, token: tokenData.token, result }
        } catch (error) {
          console.error('Error sending push:', error)
          return { success: false, token: tokenData.token, error: error.message }
        }
      })
    )

    const successCount = results.filter(r => r.success).length

    return new Response(
      JSON.stringify({ 
        message: 'Push notifications sent',
        sent: successCount,
        total: tokens.length,
        results 
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
```

### 4.2 Configurar Secrets en Supabase

1. **En Supabase Dashboard**
   - **Settings → Edge Functions → Secrets**
   - Agregar:
     - `FCM_SERVER_KEY`: Tu Server Key de Firebase

### 4.3 Desplegar Edge Function

```bash
# Instalar Supabase CLI si no lo tienes
npm install -g supabase

# Login a Supabase
supabase login

# Link proyecto
supabase link --project-ref tu-project-ref

# Deploy function
supabase functions deploy send-push-notification
```

---

## 5. Trigger en Base de Datos

### 5.1 Crear Función PostgreSQL

**Ejecutar en Supabase SQL Editor:**

```sql
-- Function to notify users when new item is created in their radius
CREATE OR REPLACE FUNCTION notify_new_item_in_radius()
RETURNS TRIGGER AS $$
DECLARE
  nearby_user_ids uuid[];
  item_owner_location geometry;
BEGIN
  -- Get owner's location
  SELECT last_location INTO item_owner_location
  FROM profiles
  WHERE user_id = NEW.owner_id;

  -- If owner has no location, skip
  IF item_owner_location IS NULL THEN
    RETURN NEW;
  END IF;

  -- Find users within default radius (10km) who have push tokens
  SELECT ARRAY_AGG(p.user_id)
  INTO nearby_user_ids
  FROM profiles p
  WHERE p.user_id != NEW.owner_id -- Don't notify owner
    AND p.last_location IS NOT NULL
    AND p.last_seen_at > NOW() - INTERVAL '24 hours' -- Active in last 24h
    AND ST_DWithin(
      p.last_location::geography,
      item_owner_location::geography,
      10000 -- 10km in meters
    )
    AND EXISTS (
      SELECT 1 FROM push_tokens pt
      WHERE pt.user_id = p.user_id
    )
    -- Don't notify if user already passed on this item
    AND NOT EXISTS (
      SELECT 1 FROM interactions i
      WHERE i.user_id = p.user_id
        AND i.item_id = NEW.id
        AND i.action = 'pass'
    );

  -- If no nearby users, return
  IF nearby_user_ids IS NULL OR array_length(nearby_user_ids, 1) = 0 THEN
    RETURN NEW;
  END IF;

  -- Call Edge Function to send push notifications
  PERFORM
    net.http_post(
      url := current_setting('app.supabase_url') || '/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.supabase_service_role_key')
      ),
      body := jsonb_build_object(
        'user_ids', nearby_user_ids,
        'title', '¡Nuevo item cerca de ti!',
        'body', NEW.title,
        'data', jsonb_build_object(
          'type', 'new_item_in_radius',
          'item_id', NEW.id,
          'owner_id', NEW.owner_id
        )
      )
    );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Nota:** La función `net.http_post` requiere la extensión `pg_net`. Si no está disponible, usa un trigger que llame a la Edge Function de otra forma.

### 5.2 Crear Trigger

```sql
-- Create trigger on items insert
CREATE TRIGGER on_item_created_notify_users
AFTER INSERT ON items
FOR EACH ROW
WHEN (NEW.status = 'available')
EXECUTE FUNCTION notify_new_item_in_radius();
```

### 5.3 Alternativa: Webhook desde Edge Function

Si `pg_net` no está disponible, puedes usar un webhook desde la app Flutter:

**En ItemService cuando se crea un item:**

```dart
Future<Item> createItem(...) async {
  // ... crear item en Supabase ...
  
  // After successful creation, call Edge Function
  try {
    await SupabaseConfig.client.functions.invoke(
      'send-push-notification',
      body: {
        'user_ids': await _getNearbyUserIds(radius: 10.0),
        'title': '¡Nuevo item cerca de ti!',
        'body': item.title,
        'data': {
          'type': 'new_item_in_radius',
          'item_id': item.id,
        },
      },
    );
  } catch (e) {
    print('Error sending push notification: $e');
    // Don't fail item creation if push fails
  }
  
  return item;
}
```

---

## 6. Testing

### 6.1 Testing Local

1. **Obtener token FCM:**
   ```dart
   final token = await NotificationService().getToken();
   print('Token: $token');
   ```

2. **Guardar token manualmente en Supabase:**
   ```sql
   INSERT INTO push_tokens (user_id, token, platform)
   VALUES ('tu-user-id', 'tu-token-fcm', 'android');
   ```

3. **Probar Edge Function:**
   ```bash
   curl -X POST https://tu-proyecto.supabase.co/functions/v1/send-push-notification \
     -H "Authorization: Bearer tu-anon-key" \
     -H "Content-Type: application/json" \
     -d '{
       "user_ids": ["tu-user-id"],
       "title": "Test",
       "body": "This is a test",
       "data": {"type": "test"}
     }'
   ```

### 6.2 Testing End-to-End

1. **Crear item desde app A**
2. **Verificar que usuario B (cercano) recibe notificación**
3. **Tap en notificación → verifica navegación correcta**

---

## 7. Notificación Específica: Nuevo Item en Radio

### 7.1 Flujo Completo

```
Usuario A crea item
    ↓
ItemService.createItem() guarda item
    ↓
Trigger detecta nuevo item (o llamada directa a Edge Function)
    ↓
Buscar usuarios cercanos (mismo radio, activos últimas 24h)
    ↓
Filtrar usuarios que ya hicieron "pass" en ese item
    ↓
Obtener tokens push de usuarios válidos
    ↓
Llamar Edge Function send-push-notification
    ↓
Edge Function envía notificación via FCM
    ↓
Usuarios reciben: "¡Nuevo item cerca de ti! - [Título del item]"
    ↓
Tap en notificación → Abre app → Navega a feed/item
```

### 7.2 Personalización por Radio del Usuario

**Mejora futura:** En lugar de radio fijo (10km), usar el radio configurado por cada usuario:

```sql
-- Obtener radio de cada usuario desde su perfil o configuración
SELECT p.user_id, COALESCE(p.notification_radius_km, 10) as radius
FROM profiles p
WHERE ...
```

---

## ✅ Checklist de Implementación

- [ ] Firebase proyecto creado
- [ ] Android app configurada en Firebase
- [ ] iOS app configurada en Firebase
- [ ] `google-services.json` en Android
- [ ] `GoogleService-Info.plist` en iOS
- [ ] Dependencias Flutter agregadas
- [ ] `firebase_options.dart` generado
- [ ] `NotificationService` implementado
- [ ] Token guardado en Supabase después de login
- [ ] Edge Function `send-push-notification` creada
- [ ] FCM_SERVER_KEY configurada en Supabase
- [ ] Edge Function desplegada
- [ ] Trigger o webhook configurado
- [ ] Testing realizado
- [ ] Navegación desde notificación implementada

---

## 📊 Costos

**Firebase Cloud Messaging:**
- ✅ Completamente gratis (sin límites razonables)

**Supabase Edge Functions:**
- ✅ 500,000 invocaciones/mes gratis
- 💰 Después: $2 por 1M invocaciones

**Para MVP:** 100% gratis si tienes < 500K notificaciones/mes

---

## 🔗 Referencias

- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://firebase.flutter.dev/docs/messaging/overview)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [FCM REST API](https://firebase.google.com/docs/cloud-messaging/http-server-ref)

---

**Fecha de creación:** 2025  
**Versión:** 1.0  
**Estado:** ✅ Listo para implementación

