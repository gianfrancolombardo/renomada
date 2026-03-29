# Digest diario de push (Supabase + OneSignal + n8n)

Paquete listo para **un envío al día** (por ejemplo a las **10:00**) que agrupa:

- ítems creados en las **últimas 24 horas** (respecto al momento de ejecución del workflow), y  
- mensajes de chat creados en ese mismo intervalo,

calcula los destinatarios con la **misma lógica** que las RPC por evento (`get_push_recipients_for_new_item`, `get_push_recipients_for_chat_message`), **deduplica** por usuario y envía **un único mensaje** vía **OneSignal** usando `include_external_user_ids`.

No hace falta tabla `since`/`until`: la ventana es **siempre** `now() - (N horas)` dentro de Postgres (`p_lookback_hours`, por defecto 24).

---

## 1. Requisitos previos

- Proyecto **Supabase** con tablas `items`, `messages`, `chats`, `push_tokens`, `profiles` (y PostGIS si usas radio en ítems), alineado con [docs/database_setup.sql](../database_setup.sql).
- Cuenta **OneSignal** y app creada.
- Instancia **n8n** (self-hosted o cloud) con el workflow importado y activado.

---

## 2. Migraciones SQL (orden obligatorio)

Ejecuta en el **SQL Editor** de Supabase (o `apply_migration` vía MCP), **en este orden**:

1. **[docs/migrations/add_push_notification_rpcs.sql](../migrations/add_push_notification_rpcs.sql)**  
   Añade columnas en `push_tokens` y las RPC base por ítem / mensaje.

2. **`migrations/add_daily_digest_push_rpcs.sql`** (esta carpeta)  
   Añade las tres funciones de digest:
   - `get_daily_digest_recipients_new_items(p_lookback_hours, p_radius_km)`
   - `get_daily_digest_recipients_new_messages(p_lookback_hours)`
   - `get_daily_digest_recipients_merged(p_lookback_hours, p_radius_km)` ← usada por el workflow de n8n

Todas las funciones están restringidas a **`service_role`** (no las llames desde Flutter con la anon key).

---

## 3. Comportamiento de las funciones

| Función | Propósito |
|--------|-----------|
| `get_daily_digest_recipients_new_items` | Por cada `items` con `created_at` dentro de la ventana, aplica la misma audiencia que `get_push_recipients_for_new_item` (excluye dueño; si `p_radius_km > 0`, filtra por `profiles.last_location` vs dueño). |
| `get_daily_digest_recipients_new_messages` | Por cada `messages` en la ventana, destinatario = la otra persona del chat (vía `get_push_recipients_for_chat_message`). |
| `get_daily_digest_recipients_merged` | Unión de ambas, **deduplicada por `token`** para no notificar dos veces el mismo dispositivo. |

**Ventana temporal:** filas con `created_at >= now() - (p_lookback_hours * interval '1 hour')`.  
Si el cron corre **todos los días a las 10:00** con `p_lookback_hours = 24`, en la práctica cubres **las últimas 24 horas** hasta ese instante (ventana móvil, no “calendario ayer 00:00–23:59” salvo que ajustes hora/cron).

**Parámetros útiles:**

- `p_lookback_hours`: por defecto `24` (coincide con “últimas 24h”).
- `p_radius_km`: igual que en el flujo por ítem — `0` = todos los usuarios con token activo salvo el dueño; `> 0` = solo perfiles con ubicación dentro del radio respecto al dueño del ítem.

---

## 4. OneSignal

1. Crea un app en el [dashboard de OneSignal](https://onesignal.com/).
2. Configura **Web / Android / iOS** según tus plataformas.
3. En **Settings → Keys & IDs** copia:
   - **OneSignal App ID**
   - **REST API Key** (secreto; solo servidor / n8n).

### External User ID (obligatorio para este flujo)

En la app Flutter, tras el login con Supabase, asigna a OneSignal el **mismo UUID** que `auth.users.id`:

- El workflow envía `include_external_user_ids` con los `user_id` devueltos por Postgres.
- Si no configuras External User ID en el SDK, los usuarios no recibirán el envío aunque la RPC los devuelva.

---

## 5. n8n

### 5.1 Importar el workflow

1. En n8n: **Workflows → Import from File**.
2. Sube [workflows/n8n-daily-digest-onesignal.json](workflows/n8n-daily-digest-onesignal.json).

### 5.2 Nodo «Workflow config»

Edita el nodo **Set** y sustituye:

| Campo | Valor |
|--------|--------|
| `supabase_url` | `https://<PROJECT_REF>.supabase.co` (sin barra final) |
| `supabase_service_role_key` | Clave **service_role** de Supabase (solo aquí o en credencial n8n) |
| `onesignal_app_id` | App ID de OneSignal |
| `onesignal_rest_api_key` | REST API Key de OneSignal |
| `lookback_hours` | `24` (o el número de horas que quieras) |
| `new_item_radius_km` | `0` o tu radio en km |
| `notification_title` / `notification_body` | Texto del digest |

**Recomendación:** mueve `supabase_service_role_key` y `onesignal_rest_api_key` a **credenciales** de n8n y referencia desde expresiones si no quieres valores en claro en el nodo Set.

### 5.3 Horario (10:00 diario)

El nodo **Schedule** usa la expresión cron:

`0 10 * * *`

Eso es **10:00 todos los días** en la **zona horaria de la instancia n8n**. Ajusta la TZ del servidor n8n o cambia el cron si tu “día” debe ser otra zona.

### 5.4 Activar

Activa el workflow. No necesitas Database Webhooks en Supabase para este modo.

### 5.5 Llamadas alternativas (dos RPC en lugar de merged)

Si prefieres dos peticiones HTTP y fusionar en un nodo **Code**:

- `POST /rest/v1/rpc/get_daily_digest_recipients_new_items`  
  Body: `{ "p_lookback_hours": 24, "p_radius_km": 0 }`
- `POST /rest/v1/rpc/get_daily_digest_recipients_new_messages`  
  Body: `{ "p_lookback_hours": 24 }`

Une los arrays, deduplica por `user_id` o `token`, y construye el mismo cuerpo que **Build OneSignal payload**.

---

## 6. Nodo OneSignal (HTTP)

El workflow publicado usa:

- **URL:** `https://api.onesignal.com/notifications`
- **Header:** `Authorization: Key <REST_API_KEY>`
- **Body:** JSON con `app_id`, `include_external_user_ids`, `headings`, `contents`, `data`.

Confirma en la [documentación actual de OneSignal](https://documentation.onesignal.com/) si el host o el formato del header cambian.

**Límites:** si el número de `external_user_ids` supera el máximo por petición, divide en lotes en el nodo Code (bucles o varias peticiones).

---

## 7. Seguridad — checklist

- [ ] La **service_role** de Supabase no está en el cliente Flutter.
- [ ] La **REST API Key** de OneSignal solo en n8n (credenciales o Set privado).
- [ ] Las RPC de digest solo ejecutables por **`service_role`** (ya aplicado en el SQL).

---

## 8. Prueba manual

1. Usuario de prueba con sesión iniciada y **External User ID** = UUID de Supabase.
2. Crea un ítem o un mensaje dentro de la ventana de 24 h.
3. Ejecuta el workflow en n8n con **Execute Workflow** (sin esperar al cron).
4. Revisa la respuesta del nodo OneSignal y el panel de entregas.

---

## 9. Archivos en esta carpeta

| Ruta | Descripción |
|------|-------------|
| `migrations/add_daily_digest_push_rpcs.sql` | Funciones Postgres del digest |
| `workflows/n8n-daily-digest-onesignal.json` | Workflow importable (cron + RPC merged + OneSignal) |
| `README.md` | Esta guía |

---

## 10. Relación con otras guías

- Arquitectura OneSignal + webhooks en tiempo real: [docs/PUSH_NOTIFICATIONS_ONESIGNAL.md](../PUSH_NOTIFICATIONS_ONESIGNAL.md)  
- Stack histórico FCM + n8n por evento: [docs/PUSH_NOTIFICATIONS_SETUP.md](../PUSH_NOTIFICATIONS_SETUP.md)

Este digest es una vía **simple** para validar el canal; cuando necesites avisos casi instantáneos (sobre todo en chat), conviene el flujo por **webhook** o evento en tiempo real descrito en esas guías.
