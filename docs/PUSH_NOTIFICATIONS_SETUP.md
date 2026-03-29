# Push notifications — guía de configuración (ReNomada)

Esta guía resume lo que debes crear, configurar y ejecutar para que las push funcionen con **Flutter (web prioritario)**, **Supabase**, **Firebase Cloud Messaging (FCM)** y **n8n**.

## 1. Resumen del flujo

1. La app registra el token FCM en la tabla `push_tokens` (usuario autenticado).
2. **Supabase Database Webhooks** (o triggers) envían eventos a **n8n** cuando se inserta un ítem o un mensaje.
3. n8n llama por HTTP a las RPC de Postgres (**solo `service_role`**) para obtener `(user_id, token, platform)` y envía FCM HTTP v1.

Funciones SQL (ejecutar en Supabase): [docs/migrations/add_push_notification_rpcs.sql](migrations/add_push_notification_rpcs.sql).

## 2. Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/).
2. Añade una app **Web** y una **Android** (y **iOS** cuando toque).
3. Instala FlutterFire en tu máquina y genera opciones reales:
  ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
  ```
   Esto debe **sustituir** [lib/firebase_options.dart](../lib/firebase_options.dart) con valores reales (no dejes `REPLACE_ME`).
4. **Cloud Messaging**
  - En *Project settings → Cloud Messaging*, para **Web Push**, genera el par de claves **VAPID** y copia la clave pública en [lib/core/constants/firebase_web_constants.dart](../lib/core/constants/firebase_web_constants.dart) (`webVapidKey`).
5. **Web: service worker**
  - Edita [web/firebase-messaging-sw.js](../web/firebase-messaging-sw.js) y pon el mismo `firebaseConfig` que en la consola (apiKey, authDomain, projectId, etc.).
  - Alinea la versión de los `importScripts` (`firebasejs/10.x.x`) con la que recomiende tu versión de `firebase_core` / documentación FlutterFire si hace falta.
6. **Android**
  - Descarga `google-services.json` y colócalo en `android/app/`.
  - En `android/settings.gradle.kts` y `android/app/build.gradle.kts`, aplica el plugin `google-services` según la documentación oficial de FlutterFire.
  - El manifest ya incluye `POST_NOTIFICATIONS`.
7. **iOS** (cuando publiques en App Store)
  - Añade `GoogleService-Info.plist`, capacidad Push, APNs en Firebase, etc.

## 3. Flutter

```bash
flutter pub get
flutter build web   # o run -d chrome
```

- Si Firebase no está configurado, la app sigue arrancando pero el log mostrará que el push está desactivado.
- Tras onboarding, la ruta `/notification-permission` pide permiso y guarda token.
- Perfil → **Notificaciones** vuelve a abrir esa pantalla.

### Payload FCM recomendado (data)

Para que la app abra la pantalla correcta al pulsar la notificación:

- **Nuevo mensaje:** `chatId` = UUID del chat (la app navega a `/chat/{chatId}`).
- **Nuevo ítem (u otras):** `route` = por ejemplo `/feed` (string).

Opcional: `title` / `body` en la sección *notification* de FCM para que el sistema muestre texto cuando la app está en segundo plano.

## 4. Supabase

1. Ejecuta el SQL de [add_push_notification_rpcs.sql](migrations/add_push_notification_rpcs.sql) (columnas `updated_at` / `is_active` en `push_tokens` + funciones + `GRANT` a `service_role`).
   - **MCP de Supabase (Cursor):** si tienes el servidor MCP `user-supabase` conectado, puedes aplicar el mismo SQL con la herramienta **`apply_migration`** (`name`: por ejemplo `add_push_notification_rpcs`, `query`: contenido del archivo). **`execute_sql`** sirve para consultas puntuales; para DDL usa **`apply_migration`**. Este MCP **no** expone creación de Database Webhooks: esos siguen siendo en el Dashboard (paso 2).
2. **Database Webhooks** (Dashboard → Database → Webhooks), con la URL del webhook de n8n:
  - Tabla `items`, evento `INSERT` → flujo “new item”.
  - Tabla `messages`, evento `INSERT` → flujo “new message”.
   El cuerpo incluirá la fila insertada (útil para `id`, `chat_id`, `sender_id`, etc.).
3. **No expongas** las RPC al cliente anónimo/authenticated: deben ejecutarse solo con la `**service_role` key** desde n8n (nunca en el código Flutter).

## 5. n8n

### Flujos listos para importar

En n8n: **Workflows → Import from File** y sube:

- [docs/n8n/workflows/push-new-item.json](n8n/workflows/push-new-item.json) — webhook `items` → RPC `get_push_recipients_for_new_item` → FCM v1 por destinatario.
- [docs/n8n/workflows/push-new-message.json](n8n/workflows/push-new-message.json) — webhook `messages` → RPC `get_push_recipients_for_chat_message` → FCM v1.

Activa cada flujo, copia la **URL del webhook de producción** y pégala en **Supabase → Database → Webhooks** (sección 4): una para `INSERT` en `items`, otra para `INSERT` en `messages`.

### Nodo `Workflow config` (Edit Fields / Set v3.4)

Justo después del webhook, cada flujo incluye un nodo **Set** con **Include Other Input Fields** activado: conserva el payload del webhook (`record`, etc.) y añade la configuración en el mismo ítem (patrón recomendado en n8n actual frente a Variables globales para secretos por flujo).

| Campo (nombre en el Set) | Uso |
|--------------------------|-----|
| `supabase_url` | `https://<PROJECT_REF>.supabase.co` (sin `/` final) |
| `supabase_service_role_key` | Clave **service_role** de Supabase (nunca en Flutter). Opcionalmente puedes moverla a una **credencial** n8n y referenciarla en el HTTP Request; el template la deja en el Set por simplicidad. |
| `firebase_project_id` | ID del proyecto Firebase / GCP (el `projectId` de `firebase_options` / consola). Se usa en la URL de FCM v1. |
| `new_item_radius_km` | Solo en el flujo de **ítems**: `0` = todos menos el dueño; `>0` = radio en km (`last_location`). |

**Google / FCM (recomendado):** no metas el JSON de la cuenta de servicio en el Set. Crea en n8n una credencial **Google Service Account API** (email + private key), activa **Set up for use in HTTP Request node** y en **Scope(s)** pon `https://www.googleapis.com/auth/firebase.messaging`. Vincula esa credencial al nodo **FCM HTTP v1 send** (autenticación *Predefined — Google Service Account API*). n8n obtiene el `Bearer` por ti.

**Importante:** la **service_role** de Supabase y la **cuenta de servicio de Google** son cosas distintas: la primera llama a las RPC; la segunda autoriza el envío a FCM.

El nodo **Expand recipients for FCM** (Code) solo parte el array de la RPC y renombra `token` → `device_token`; **no** firma JWT ni usa `crypto`.

### Contrato manual (si montas el flujo a mano)

- **URL** (ejemplos):
  - `https://<PROJECT_REF>.supabase.co/rest/v1/rpc/get_push_recipients_for_new_item`
  - `https://<PROJECT_REF>.supabase.co/rest/v1/rpc/get_push_recipients_for_chat_message`
- **Method:** POST
- **Headers:** `apikey` y `Authorization: Bearer` con **service_role**; `Content-Type: application/json`
- **Body (JSON):**
  - Nuevo ítem: `{ "p_item_id": "<uuid>", "p_radius_km": 0 }`  
    - `p_radius_km <= 0` → todos los tokens activos excepto el dueño.  
    - `p_radius_km > 0` → usuarios con `profiles.last_location` dentro del radio respecto al dueño del ítem.
  - Mensaje: `{ "p_chat_id": "<uuid>", "p_sender_id": "<uuid>" }`

La respuesta es un array de `{ user_id, token, platform }`. Itera y llama a **FCM HTTP v1** con OAuth de la cuenta de servicio.

### Idempotencia (recomendado)

Evita reenvíos duplicados guardando `item_id` / `message_id` procesados (p. ej. tabla en Supabase o memoria en n8n).

## 6. Checklist maestra (qué había que hacer y qué queda)

Leyenda: **[hecho]** = ya está en el repo o lo dimos por hecho en tu entorno local; **[tú]** = debes confirmarlo o hacerlo en consolas / n8n / Supabase (no lo ve el repo).

### Firebase

| Estado | Tarea |
|--------|--------|
| **[hecho]** | Proyecto Firebase y apps Web/Android registradas. |
| **[hecho]** | `lib/firebase_options.dart` con valores reales (FlutterFire). |
| **[hecho]** | Clave pública VAPID en `lib/core/constants/firebase_web_constants.dart` (`webVapidKey`). |
| **[hecho]** | `web/firebase-messaging-sw.js` con el mismo `firebaseConfig` que la app web (alineado con `firebase_options` web). |
| **[tú]** | En Google Cloud del proyecto: API **Firebase Cloud Messaging** usable por la cuenta de servicio que use n8n (FCM HTTP v1). |
| **[tú]** | iOS / App Store: `GoogleService-Info.plist`, APNs, etc. (solo cuando toque). |

### Flutter / app

| Estado | Tarea |
|--------|--------|
| **[hecho]** | Código de push, permisos, guardado de token en `push_tokens`, rutas (`/notification-permission`, perfil). |
| **[tú]** | `flutter pub get` y probar en web (`flutter run -d chrome` o build) y/o Android con `google-services.json` en `android/app/`. |

### Android

| Estado | Tarea |
|--------|--------|
| **[hecho]** | Plugin `google-services` en `settings.gradle.kts` / `app/build.gradle.kts`. |
| **[tú]** | Tener `android/app/google-services.json` del proyecto correcto (no subir secretos al repo si no quieres). |

### Supabase

| Estado | Tarea |
|--------|--------|
| **[tú]** | Ejecutar en el SQL Editor el script [add_push_notification_rpcs.sql](migrations/add_push_notification_rpcs.sql) en **tu** proyecto. |
| **[tú]** | Crear **Database Webhooks**: `items` INSERT → URL webhook n8n (ítems); `messages` INSERT → URL webhook n8n (mensajes). |
| **[hecho]** | Documentado: RPC solo con `service_role` desde n8n, no desde Flutter. |

### n8n

| Estado | Tarea |
|--------|--------|
| **[hecho]** | Archivos importables: [push-new-item.json](n8n/workflows/push-new-item.json), [push-new-message.json](n8n/workflows/push-new-message.json). |
| **[tú]** | Importar ambos flujos, rellenar **Workflow config**, crear credencial **Google Service Account API** (FCM) y enlazarla al nodo FCM, activar. |
| **[tú]** | Primera ejecución OK (sin error en nodo Code / FCM). |
| **[tú]** | *(Opcional recomendado)* Idempotencia para no reenviar el mismo `item_id` / `message_id`. |

### Cierre

| Estado | Tarea |
|--------|--------|
| **[tú]** | Prueba real: dos usuarios con token en `push_tokens`; A crea ítem o envía mensaje → B recibe notificación. |

---

### Pasos que te quedan (orden sugerido)

1. **Supabase:** ejecutar el SQL de `add_push_notification_rpcs.sql` si aún no lo hiciste.
2. **n8n:** importar los dos workflows, completar **Workflow config**, asignar credencial Google al nodo FCM, activar y copiar las dos URLs de webhook.
3. **Supabase:** crear los dos webhooks apuntando a esas URLs.
4. **Google Cloud:** confirmar que la cuenta de servicio de FCM puede usar FCM HTTP v1.
5. **App:** `flutter pub get`, probar web (y Android con `google-services.json`); asegurar permiso de notificaciones y fila en `push_tokens`.
6. **Prueba end-to-end** con dos cuentas.

## 7. Checklist rápido (resumen)

- [x] `firebase_options.dart` real y VAPID en código; SW web alineado con el mismo proyecto.
- [ ] SQL de push ejecutado en Supabase (producción/staging que uses).
- [ ] Webhooks `items` / `messages` → URLs n8n.
- [ ] n8n: flujos activos + **Workflow config** + credencial **Google Service Account API** (FCM) en el nodo HTTP de FCM + envíos sin error.
- [ ] Probar: usuario A → usuario B recibe push (tokens en `push_tokens`).

## 8. Constantes en código

Los nombres RPC están documentados en `SupabaseConstants` (`pushRecipientsNewItemRpc`, `pushRecipientsChatMessageRpc`) para referencia; **la app no debe invocarlos** con el anon key.