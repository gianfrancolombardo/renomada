# 🎯 Plan de Acción - Completar MVP ReNomada

**Fecha:** 9 de octubre de 2025  
**Objetivo:** MVP lanzable en 2-3 semanas  
**Estado actual:** 85% completo

---

## 📋 Resumen Ejecutivo

Este documento detalla **exactamente qué hacer** para completar el MVP de ReNomada. Cada tarea incluye:
- ✅ Criterios de aceptación claros
- 🔧 Pasos técnicos específicos
- ⏱️ Estimación de tiempo
- 🎯 Prioridad

---

## 🔴 SPRINT 1: Funcionalidad Core (Días 1-4)

### **TAREA 1.1: Sistema de Interacciones** ⭐⭐⭐⭐⭐
**Prioridad:** CRÍTICA  
**Tiempo:** 1-2 días  
**Estado:** ❌ No iniciado

#### Objetivo:
Implementar el sistema completo de like/pass que conecta feed → interacciones → chat.

#### Pasos Técnicos:

1. **Crear `InteractionService`** (30 min)
   ```dart
   // lib/shared/services/interaction_service.dart
   
   class InteractionService {
     Future<void> likeItem(String itemId);
     Future<void> passItem(String itemId);
     Future<bool> hasInteraction(String itemId);
     Future<String?> getChatForItem(String itemId);
   }
   ```

2. **Implementar lógica de `likeItem`** (1-2 horas)
   - Insertar en `interactions` tabla con action='like'
   - Verificar si ya existe chat para ese item
   - Si NO existe: crear chat en tabla `chats`
   - Si existe: retornar chat_id existente
   - Manejar errores (ej: item ya eliminado, owner bloqueado)

3. **Implementar lógica de `passItem`** (30 min)
   - Insertar en `interactions` tabla con action='pass'
   - No crear chat
   - Retornar éxito

4. **Actualizar `FeedService`** (1 hora)
   - Modificar llamada a `feed_items_by_radius()` para excluir items con interacción
   - Verificar que la RPC ya excluye correctamente (revisar SQL)
   - Si no excluye, actualizar RPC en Supabase

5. **Crear `InteractionProvider`** (1 hora)
   ```dart
   // lib/features/feed/providers/interaction_provider.dart
   
   class InteractionState {
     bool isLoading;
     String? error;
     String? createdChatId; // Para navegar después del like
   }
   ```

6. **Actualizar `FeedScreen`** (2 horas)
   - Conectar botones like/pass a InteractionService
   - Mostrar loading durante operación
   - Al hacer like: navegar a chat si se creó
   - Al hacer pass: pasar al siguiente item
   - Mostrar snackbar de confirmación
   - Manejar errores con mensajes amigables

7. **Testing** (1 hora)
   - Flujo completo: like → crea chat → navega a chat
   - Flujo: pass → oculta item → no vuelve a aparecer
   - Verificar que RLS permite las operaciones
   - Probar casos edge: item eliminado, usuario bloqueado

#### Criterios de Aceptación:
- ✅ Al hacer swipe right (like), se crea interacción con action='like'
- ✅ Al hacer like, se crea chat automáticamente (o recupera existente)
- ✅ Al hacer like, navega automáticamente a la pantalla de chat
- ✅ Al hacer swipe left (pass), se crea interacción con action='pass'
- ✅ Items con pass no vuelven a aparecer en el feed
- ✅ Mensajes de error claros cuando algo falla
- ✅ Loading states durante las operaciones

#### Archivos a crear/modificar:
```
lib/shared/services/interaction_service.dart          [CREAR]
lib/features/feed/providers/interaction_provider.dart [CREAR]
lib/features/feed/screens/feed_screen.dart            [MODIFICAR]
docs/database_setup.sql                               [VERIFICAR RPC]
```

---

### **TAREA 1.2: Verificación Chat Realtime** ⭐⭐⭐⭐
**Prioridad:** ALTA  
**Tiempo:** 1 día  
**Estado:** 🟡 Implementado pero sin verificar

#### Objetivo:
Asegurar que el chat funciona perfectamente en tiempo real entre dispositivos.

#### Pasos Técnicos:

1. **Revisar configuración Realtime en Supabase** (15 min)
   - Verificar que Realtime está habilitado para tabla `messages`
   - Verificar políticas RLS permiten suscripciones
   - Confirmar que las RLS policies tienen permisos de SELECT

2. **Verificar `ChatRealtimeService`** (30 min)
   - Revisar implementación de suscripción
   - Verificar manejo de reconexiones
   - Añadir logs de debug para troubleshooting

3. **Testing Multi-dispositivo** (2-3 horas)
   - Instalar en 2 dispositivos físicos (o emuladores)
   - Crear chat desde dispositivo A
   - Enviar mensaje desde A → verificar aparece en B
   - Enviar mensaje desde B → verificar aparece en A
   - Probar con app en background
   - Probar desconexión/reconexión de red

4. **Implementar Estados de Entrega** (2 horas) - OPCIONAL
   ```dart
   // Añadir a tabla messages (si se desea)
   enum MessageStatus { sending, sent, delivered, read }
   ```
   - Mostrar indicador visual de estado
   - Actualizar estado cuando mensaje llega a DB
   - Opcional: delivery receipts

5. **Mejorar Manejo de Errores** (1 hora)
   - Retry automático si falla envío
   - Mostrar mensaje si usuario está offline
   - Queue de mensajes pendientes

#### Criterios de Aceptación:
- ✅ Mensaje enviado aparece en receptor en <2 segundos
- ✅ Funciona con app en foreground y background
- ✅ Reconexión automática tras pérdida de red
- ✅ No se pierden mensajes durante desconexiones breves
- ✅ Estados de loading claros para el usuario
- ⚠️ OPCIONAL: Estados de entrega visible

#### Archivos a revisar/modificar:
```
lib/shared/services/chat_realtime_service.dart        [REVISAR]
lib/shared/services/message_service.dart              [REVISAR]
lib/features/chat/screens/chat_screen.dart            [MEJORAR]
lib/features/chat/widgets/message_bubble.dart         [OPCIONAL]
```

---

### **TAREA 1.3: Testing de Integración** ⭐⭐⭐⭐
**Prioridad:** ALTA  
**Tiempo:** 1 día  
**Estado:** ❌ No iniciado

#### Objetivo:
Verificar que todo el flujo de usuario funciona end-to-end sin errores.

#### Flujos a Probar:

1. **Flujo Completo de Usuario Nuevo** (1 hora)
   - [ ] Signup con email/password
   - [ ] Creación automática de perfil
   - [ ] Solicitud de permisos de ubicación
   - [ ] Navegación a home
   - [ ] Exploración de feed (debería estar vacío o con seed data)

2. **Flujo de Publicación** (1 hora)
   - [ ] Ir a "Mis Items"
   - [ ] Crear nuevo item con 3 fotos
   - [ ] Verificar aparece en lista
   - [ ] Editar item
   - [ ] Cambiar estado a "paused"
   - [ ] Verificar no aparece en feed de otros
   - [ ] Eliminar item

3. **Flujo de Feed e Interacción** (2 horas)
   - [ ] Abrir feed con radio 10km
   - [ ] Ver items de usuarios cercanos
   - [ ] Hacer swipe left (pass) → item desaparece
   - [ ] Hacer swipe right (like) → crea chat
   - [ ] Navega automáticamente a chat
   - [ ] Verificar chat aparece en lista

4. **Flujo de Chat** (1 hora)
   - [ ] Enviar mensaje desde usuario A
   - [ ] Verificar recepción en usuario B (tiempo real)
   - [ ] Responder desde usuario B
   - [ ] Verificar en lista de chats de ambos usuarios

5. **Flujo de Perfil** (30 min)
   - [ ] Editar username
   - [ ] Subir nuevo avatar
   - [ ] Actualizar ubicación
   - [ ] Verificar cambios se reflejan

6. **Testing de Seguridad RLS** (2 horas)
   - [ ] Intentar acceder a items de otro usuario directamente
   - [ ] Intentar modificar perfil de otro usuario
   - [ ] Intentar leer mensajes de chat ajeno
   - [ ] Verificar que todas las operaciones no autorizadas fallan

#### Criterios de Aceptación:
- ✅ Todos los flujos funcionan sin crashes
- ✅ RLS bloquea correctamente accesos no autorizados
- ✅ Mensajes de error son claros y útiles
- ✅ Estados de loading aparecen en operaciones lentas
- ✅ Performance aceptable (<3s para operaciones normales)

---

## 🟡 SPRINT 2: Push Notifications (Días 5-7)

### **TAREA 2.1: Setup Firebase Cloud Messaging** ⭐⭐⭐
**Prioridad:** MEDIA  
**Tiempo:** 4-6 horas  
**Estado:** ❌ No iniciado

#### Objetivo:
Configurar FCM para Android y APNs para iOS, registrar tokens de dispositivos.

#### Pasos Técnicos:

1. **Setup Firebase Android** (1 hora)
   - Crear proyecto en Firebase Console
   - Descargar `google-services.json`
   - Colocar en `android/app/`
   - Configurar `build.gradle`
   - Añadir dependencias de FCM

2. **Setup Firebase iOS** (1 hora)
   - Descargar `GoogleService-Info.plist`
   - Colocar en `ios/Runner/`
   - Configurar certificados APNs en Apple Developer
   - Subir certificado a Firebase

3. **Implementar `NotificationService`** (2 horas)
   ```dart
   // lib/shared/services/notification_service.dart
   
   class NotificationService {
     Future<void> initialize();
     Future<String?> getToken();
     Future<void> requestPermission();
     Future<void> saveToken(String token);
     Stream<RemoteMessage> get onMessage;
   }
   ```

4. **Registrar Token en Supabase** (1 hora)
   - Al obtener token, guardar en tabla `push_tokens`
   - Asociar con `user_id` actual
   - Guardar `platform` (android/ios)
   - Manejar actualizaciones de token

5. **Configurar Permisos** (30 min)
   - Android: Configurar en `AndroidManifest.xml`
   - iOS: Configurar en `Info.plist`
   - Solicitar permisos en momento apropiado

#### Criterios de Aceptación:
- ✅ Token de FCM se obtiene correctamente
- ✅ Token se guarda en tabla `push_tokens`
- ✅ Permisos de notificaciones solicitados al usuario
- ✅ Token se actualiza si cambia

#### Archivos a crear/modificar:
```
lib/shared/services/notification_service.dart         [CREAR]
lib/features/notifications/providers/notification_provider.dart [CREAR]
android/app/google-services.json                      [AÑADIR]
android/app/build.gradle                              [MODIFICAR]
ios/Runner/GoogleService-Info.plist                   [AÑADIR]
ios/Runner/Info.plist                                 [MODIFICAR]
```

---

### **TAREA 2.2: Edge Function para Push** ⭐⭐⭐
**Prioridad:** MEDIA  
**Tiempo:** 3-4 horas  
**Estado:** ❌ No iniciado

#### Objetivo:
Crear Edge Function que envía notificaciones push cuando ocurren eventos.

#### Pasos Técnicos:

1. **Crear Edge Function `send-notification`** (1 hora)
   ```typescript
   // supabase/functions/send-notification/index.ts
   
   import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
   
   serve(async (req) => {
     const { user_id, title, body, data } = await req.json()
     
     // 1. Obtener tokens del usuario
     // 2. Enviar via FCM API
     // 3. Retornar resultado
   })
   ```

2. **Integrar FCM Admin SDK** (1 hora)
   - Configurar credenciales de servicio
   - Implementar envío a múltiples tokens
   - Manejar tokens inválidos (eliminar de DB)

3. **Crear Trigger para Mensajes** (1 hora)
   ```sql
   -- Trigger cuando se crea un mensaje
   CREATE OR REPLACE FUNCTION notify_new_message()
   RETURNS TRIGGER AS $$
   BEGIN
     -- Llamar Edge Function send-notification
     -- Enviar a receptor del mensaje
     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;
   ```

4. **Crear Trigger para Likes** (30 min)
   ```sql
   -- Trigger cuando se crea un like
   CREATE OR REPLACE FUNCTION notify_new_like()
   RETURNS TRIGGER AS $$
   BEGIN
     -- Obtener owner del item
     -- Llamar Edge Function send-notification
     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;
   ```

5. **Testing** (1 hora)
   - Enviar mensaje → verificar push llega
   - Hacer like → verificar push llega
   - Probar con app cerrada, background, foreground

#### Criterios de Aceptación:
- ✅ Push se envía cuando se recibe un mensaje
- ✅ Push se envía cuando se recibe un like
- ✅ Push llega con app cerrada, background y foreground
- ✅ Tokens inválidos se limpian automáticamente
- ✅ Edge Function tiene rate limiting

#### Archivos a crear:
```
supabase/functions/send-notification/index.ts         [CREAR]
docs/database_setup.sql                               [AÑADIR TRIGGERS]
```

---

### **TAREA 2.3: Deep Links** ⭐⭐
**Prioridad:** MEDIA-BAJA  
**Tiempo:** 2-3 horas  
**Estado:** ❌ No iniciado

#### Objetivo:
Implementar navegación automática a la vista correcta al tocar una notificación.

#### Pasos Técnicos:

1. **Configurar Deep Links** (1 hora)
   - Android: Configurar intent filters
   - iOS: Configurar URL schemes
   - Definir rutas: `/chat/:chatId`, `/item/:itemId`

2. **Manejar Notificaciones en App** (1-2 horas)
   ```dart
   class NotificationService {
     void handleNotificationTap(RemoteMessage message) {
       final data = message.data;
       if (data['type'] == 'new_message') {
         navigateTo('/chat/${data['chat_id']}');
       } else if (data['type'] == 'new_like') {
         navigateTo('/chat/${data['chat_id']}');
       }
     }
   }
   ```

3. **Testing** (30 min)
   - Tap en notificación de mensaje → abre chat correcto
   - Tap en notificación de like → abre chat correcto
   - Probar con app cerrada y en background

#### Criterios de Aceptación:
- ✅ Tap en notificación de mensaje abre el chat correcto
- ✅ Tap en notificación de like abre el chat correcto
- ✅ Funciona con app cerrada y en background

---

## 🟢 SPRINT 3: Landing & Preparación (Días 8-10)

### **TAREA 3.1: Landing Page con Astro** ⭐⭐
**Prioridad:** BAJA  
**Tiempo:** 4-6 horas  
**Estado:** ❌ No iniciado

#### Objetivo:
Crear landing page simple y efectiva para captar usuarios y dirigir a stores.

#### Pasos Técnicos:

1. **Setup Astro Project** (30 min)
   ```bash
   npm create astro@latest renomada-landing
   cd renomada-landing
   ```

2. **Crear Estructura** (1 hora)
   - Hero section con propuesta de valor
   - Features section (3-4 features principales)
   - Screenshots de la app
   - CTA a stores (badges iOS/Android)
   - Footer con enlaces

3. **Diseño Responsive** (1 hora)
   - Mobile-first
   - Usar Tailwind CSS
   - Asegurar accesibilidad

4. **Newsletter Signup** (1 hora)
   - Formulario simple
   - Integrar con servicio (Mailchimp/ConvertKit/Supabase)
   - Validación y confirmación

5. **Deploy en Cloudflare Pages** (1 hora)
   - Conectar repo a Cloudflare Pages
   - Configurar build
   - Configurar dominio custom (opcional)
   - Setup analytics

6. **SEO Básico** (30 min)
   - Meta tags
   - Open Graph
   - Sitemap
   - robots.txt

#### Criterios de Aceptación:
- ✅ Landing responsive en mobile y desktop
- ✅ CTAs claros a App Store y Google Play
- ✅ Newsletter signup funcional
- ✅ Deploy automático desde Git
- ✅ Performance >90 en Lighthouse

#### Estructura:
```
renomada-landing/
├── src/
│   ├── pages/
│   │   └── index.astro
│   ├── components/
│   │   ├── Hero.astro
│   │   ├── Features.astro
│   │   ├── Screenshots.astro
│   │   └── Newsletter.astro
│   └── layouts/
│       └── Layout.astro
└── public/
    └── images/
```

---

### **TAREA 3.2: Métricas y Observabilidad** ⭐⭐⭐
**Prioridad:** MEDIA  
**Tiempo:** 3-4 horas  
**Estado:** ❌ No iniciado

#### Objetivo:
Implementar tracking de eventos clave para entender comportamiento de usuarios.

#### Pasos Técnicos:

1. **Setup Analítica** (1 hora)
   - Opción 1: Firebase Analytics (ya configurado)
   - Opción 2: PostHog (open source)
   - Opción 3: Mixpanel (free tier)

2. **Implementar `AnalyticsService`** (1 hora)
   ```dart
   class AnalyticsService {
     void trackSignup(String method);
     void trackLogin(String method);
     void trackItemPublished(String itemId);
     void trackItemLike(String itemId);
     void trackItemPass(String itemId);
     void trackChatCreated(String chatId);
     void trackMessageSent(String chatId);
     void trackScreenView(String screenName);
   }
   ```

3. **Añadir Tracking a Eventos Clave** (1-2 horas)
   - Signup/Login
   - Publicar item
   - Like/Pass
   - Crear chat
   - Enviar mensaje
   - Cambiar radio de búsqueda
   - Actualizar perfil

4. **Dashboard Básico** (opcional, 2 horas)
   - Crear vista en Supabase para métricas
   - Queries para:
     - Items publicados por día
     - Usuarios activos por día
     - % de likes vs passes
     - Ratio like→chat
     - Mensajes enviados por día

#### Criterios de Aceptación:
- ✅ Eventos clave se trackean correctamente
- ✅ Dashboard permite ver métricas básicas
- ✅ Privacy-compliant (GDPR)

---

### **TAREA 3.3: Preparación de Stores** ⭐⭐⭐⭐
**Prioridad:** ALTA  
**Tiempo:** 1-2 días  
**Estado:** ❌ No iniciado

#### Objetivo:
Preparar todo lo necesario para publicar en App Store y Google Play.

#### App Store (iOS):

1. **Apple Developer Account** (30 min)
   - Inscribirse ($99/año)
   - Crear App ID
   - Configurar certificados

2. **App Store Connect** (2 horas)
   - Crear nueva app
   - Screenshots (5 tamaños)
   - App preview video (opcional)
   - Descripción y keywords
   - Privacy policy URL
   - Categoría y rating de edad

3. **Build para Release** (1 hora)
   - Configurar version/build number
   - Archive en Xcode
   - Upload a TestFlight
   - Pruebas internas

#### Google Play (Android):

1. **Google Play Console** (30 min)
   - Crear cuenta ($25 one-time)
   - Crear nueva aplicación

2. **Store Listing** (2 horas)
   - Screenshots (phone, tablet, 7")
   - Feature graphic
   - Icono
   - Descripción (corta y larga)
   - Categoría

3. **Build para Release** (1 hour)
   - Generar release signing key
   - Build release APK/AAB
   - Upload a Internal Testing
   - Pruebas internas

#### Común:

4. **Assets Necesarios** (3-4 horas)
   - Screenshots de 5-6 pantallas clave
   - Feature graphic/promo image
   - Icono de app en todos los tamaños
   - Video demo (opcional pero recomendado)

5. **Textos Marketing** (2 horas)
   - Descripción corta (80 chars)
   - Descripción larga (4000 chars)
   - Keywords (App Store)
   - Notas de release
   - Privacy policy

6. **Testing Pre-Release** (1 día)
   - Distribuir via TestFlight/Internal Testing
   - 5-10 beta testers
   - Recoger feedback
   - Fix critical bugs

#### Criterios de Aceptación:
- ✅ App ID creado en ambas plataformas
- ✅ Screenshots y assets preparados
- ✅ Descripción y textos completos
- ✅ Privacy policy publicada
- ✅ Build subido a TestFlight e Internal Testing
- ✅ Beta testing completado sin crashes críticos

---

## 📊 Checklist Final Pre-Lanzamiento

### Funcionalidad:
- [ ] Signup/Login funciona
- [ ] Permisos de ubicación se solicitan correctamente
- [ ] Publicar item con fotos funciona
- [ ] Feed muestra items por radio
- [ ] Like crea chat automáticamente
- [ ] Chat en tiempo real funciona
- [ ] Push notifications llegan
- [ ] Deep links funcionan
- [ ] Perfil se puede editar

### Seguridad:
- [ ] RLS habilitado en todas las tablas
- [ ] Políticas RLS testeadas
- [ ] Storage privado configurado
- [ ] Signed URLs funcionan
- [ ] No hay API keys expuestas en código
- [ ] HTTPS en todas las conexiones

### UX/UI:
- [ ] No hay pantallas en blanco
- [ ] Loading states en operaciones lentas
- [ ] Error messages son claros
- [ ] Empty states tienen CTAs
- [ ] Navegación es intuitiva
- [ ] Accesible en mobile pequeño y grande

### Performance:
- [ ] App carga en <3s
- [ ] Feed scroll es fluido
- [ ] Imágenes cargan con lazy loading
- [ ] No hay memory leaks obvios
- [ ] Funciona con conexión lenta

### Legal:
- [ ] Privacy policy publicada
- [ ] Términos de servicio
- [ ] GDPR compliant
- [ ] Permisos claramente explicados

---

## 🎯 Timeline Estimado

### Escenario Optimista (2 semanas):
- **Semana 1:** Sprint 1 (Core) + mitad Sprint 2 (Push setup)
- **Semana 2:** Completar Sprint 2 + Sprint 3 (Landing + Stores)

### Escenario Realista (3 semanas):
- **Semana 1:** Sprint 1 completo
- **Semana 2:** Sprint 2 completo
- **Semana 3:** Sprint 3 + testing final

### Escenario Conservador (4 semanas):
- **Semana 1:** Sprint 1
- **Semana 2:** Sprint 2
- **Semana 3:** Sprint 3
- **Semana 4:** Testing, fixes, beta testing

---

## 🚀 Decisiones Estratégicas

### ¿Qué se puede recortar si hay presión de tiempo?

**Imprescindible para MVP:**
- ✅ Sistema de interacciones (like/pass)
- ✅ Chat funcional
- ✅ Testing básico end-to-end

**Importante pero no bloqueante:**
- ⚠️ Push notifications (puede ir en v1.1)
- ⚠️ Deep links (nice to have)
- ⚠️ Estados de entrega de mensajes

**Puede esperar:**
- 🟢 Landing page (puede ser simple HTML estático)
- 🟢 Métricas dashboard (puede ser queries manuales)
- 🟢 Newsletter signup

### Recomendación:

**Para lanzar lo antes posible:**
1. Completar Sprint 1 (interacciones + chat)
2. Testing exhaustivo
3. Preparar stores con assets mínimos
4. Soft launch sin push
5. Añadir push en v1.1 (1 semana después)

**Esto permite lanzar en ~2 semanas** con funcionalidad core completa.

---

## 📝 Notas Finales

- Mantener foco en **validar el producto**, no en perfeccionarlo
- Los usuarios beta perdonan bugs si la propuesta de valor es clara
- Es mejor lanzar con funcionalidad limitada pero que funcione bien
- Push notifications no son críticas si el chat funciona
- La landing puede ser simple al inicio

**¡El MVP está muy cerca! 🎉**


