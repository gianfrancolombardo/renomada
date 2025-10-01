# ReNomada – Data Model & RLS for Supabase (MVP)

> Estructura de datos y políticas de seguridad para el MVP hiperlocal. **Descripciones en español**; **código, nombres de campos y comentarios en inglés**. Diseño alineado con: *items sin geolocalización*, **la ubicación vive en `profiles`**, y el feed filtra **usuarios** por radio para listar **todos sus items** públicos/activos.

---

## 1) Vista general y principios
- **Fuente única de geolocalización**: `profiles.last_location` (punto `geography(POINT,4326)` redondeado). `last_seen_at` controla frescura.
- **Privacidad**: otros usuarios **no leen** `profiles` directamente. El acceso a items cercanos ocurre vía **RPC `feed_items_by_radius`** (con `SECURITY DEFINER`) que **no expone** coordenadas y aplica reglas de frescura.
- **RLS en todas las tablas**. Acceso directo sólo al dueño de los datos, salvo lectura pública de lo estrictamente necesario mediante funciones controladas.
- **Storage**: bucket privado con **signed URLs**; lectura directa restringida por políticas.

---

## 2) Tablas, campos y relaciones

### 2.1 `profiles`
**Propósito:** metadatos del usuario y su última ubicación (fuente única de geo).

**Campos**
- `user_id uuid PK` → `auth.users.id` (1–1).
- `username text UNIQUE` → identificador público.
- `avatar_url text` → ruta en Storage (privado) o URL pública si procede.
- `last_location geography(point,4326)` → posición **redondeada** (no histórica).
- `last_seen_at timestamptz` → timestamp de frescura de ubicación.
- `is_location_opt_out boolean default false` → permite degradar feed si el usuario no comparte ubicación.

**Relaciones**
- 1 → N con `items` (via `items.owner_id`).

**Notas**
- Índice espacial sobre `last_location` para búsquedas por radio.

---

### 2.2 `items`
**Propósito:** publicaciones de objetos. **Sin coordenadas**; se asume co‑ubicación con su owner.

**Campos**
- `id uuid PK default gen_random_uuid()`.
- `owner_id uuid NOT NULL` → `auth.users.id`.
- `title text NOT NULL`.
- `description text`.
- `status text NOT NULL` ('available', 'exchanged', 'paused').
- `is_active boolean NOT NULL default true`.
- `created_at timestamptz NOT NULL default now()`.
- `updated_at timestamptz NULL`

**Relaciones**
- N → 1 con `profiles` (owner).
- 1 → N con `item_photos`.
- 1 → N con `chats` (a través del interés).

**Notas**
- RLS restringe lectura directa para evitar enumeración; lectura para clientes sólo vía **RPC**.

---

### 2.3 `item_photos`
**Propósito:** metadatos de las fotos; el binario vive en **Storage**.

**Campos**
- `id uuid PK default gen_random_uuid()`.
- `item_id uuid NOT NULL` → `items.id`.
- `path text NOT NULL` → ruta en Storage.
- `mime_type text`.
- `size_bytes integer`.
- `created_at timestamptz NOT NULL default now()`.

**Relaciones**
- N → 1 con `items`.

**Notas**
- Políticas de Storage controlan acceso al binario; esta tabla ayuda a listar fotos por item.

---

### 2.4 `interactions`
**Propósito:** registrar **swipes** del usuario sobre items (*like/pass*) para personalizar el feed y evitar repetidos.

**Campos**
- `user_id uuid NOT NULL` → `auth.users.id`.
- `item_id uuid NOT NULL` → `items.id`.
- `action text NOT NULL` (`like`|`pass`).
- `created_at timestamptz NOT NULL default now()`.

**Claves**
- `PRIMARY KEY (user_id, item_id)`.

**Relaciones**
- N → 1 con `items`.

**Notas**
- RLS: sólo el autor puede ver/escribir sus interacciones.

---

### 2.5 `chats`
**Propósito:** conversación 1–a–1 entre interesado y dueño para un `item`.

**Campos**
- `id uuid PK default gen_random_uuid()`.
- `item_id uuid NOT NULL` → `items.id`.
- `a_user_id uuid NOT NULL` → `auth.users.id`.
- `b_user_id uuid NOT NULL` → `auth.users.id`.
- `created_at timestamptz NOT NULL default now()`.

**Restricciones**
- `check (a_user_id <> b_user_id)`.
- `unique (item_id, a_user_id, b_user_id)` → una pareja por item.

**Relaciones**
- 1 → N con `messages`.

**Notas**
- RLS: sólo participantes pueden ver/crear registros.

---

### 2.6 `messages`
**Propósito:** mensajes de chat (realtime).

**Campos**
- `id uuid PK default gen_random_uuid()`.
- `chat_id uuid NOT NULL` → `chats.id`.
- `sender_id uuid NOT NULL` → `auth.users.id`.
- `content text NOT NULL`.
- `created_at timestamptz NOT NULL default now()`.

**Relaciones**
- N → 1 con `chats`.

**Notas**
- RLS: sólo participantes del chat pueden leer/escribir.

---

### 2.7 `push_tokens`
**Propósito:** tokens por plataforma para notificaciones push.

**Campos**
- `user_id uuid NOT NULL` → `auth.users.id`.
- `platform text NOT NULL` (`web`|`android`|`ios`).
- `token text NOT NULL`.
- `created_at timestamptz NOT NULL default now()`.

**Claves**
- `PRIMARY KEY (user_id, platform, token)`.
- `UNIQUE (token)` para evitar duplicados globales.

**Notas**
- RLS: cada usuario gestiona sólo sus tokens.

---

## 3) Políticas RLS (Row‑Level Security)
> Objetivo: **principio de mínimo privilegio**. El cliente no puede enumerar datos ajenos; el feed se obtiene por **RPC segura**.

### 3.1 `profiles`
- **RLS enabled**.
- **Select**: sólo el propio usuario puede ver su fila (para pantalla de perfil). Los demás **no** pueden listar `profiles`.
- **Insert/Update/Delete**: sólo el propio usuario.

### 3.2 `items`
- **RLS enabled**.
- **Owner**: `select/insert/update/delete` sobre sus items.
- **Público**: **no** hay `select` para otros (evita scraping). Lectura de items ocurre por **RPC**.

### 3.3 `item_photos`
- **RLS enabled**.
- **Owner**: CRUD sólo del owner del `item`.
- **Público**: sin `select` directo (las rutas se exponen mediante **signed URLs** temporales).

### 3.4 `interactions`
- **RLS enabled**.
- **Autor**: CRUD de sus propias interacciones.

### 3.5 `chats`
- **RLS enabled**.
- **Participantes**: `select/insert` si `auth.uid()` ∈ {`a_user_id`,`b_user_id`}.

### 3.6 `messages`
- **RLS enabled**.
- **Participantes**: `select/insert` si `auth.uid()` pertenece a los participantes del chat relacionado.

### 3.7 `push_tokens`
- **RLS enabled**.
- **Propietario**: CRUD sólo del propio usuario.

### 3.8 Storage (bucket `item-photos`)
- **Privado por defecto**.
- Políticas: el owner puede `insert/delete` sus objetos; lectura pública **no** permitida; terceros leen vía **signed URL**.

---

## 4) Búsqueda por radio sin exponer coordenadas (RPC)
**`feed_items_by_radius(lat, lon, radius_km, freshness_hours)`**
- **Qué hace**: devuelve **items** (y datos mínimos del owner) cuyos **owners** están dentro de `radius_km` de `(lat,lon)` y con `last_seen_at` reciente.
- **Seguridad**: `SECURITY DEFINER`, uso de `auth.uid()` sólo para filtros de exclusión (p. ej., ocultar mis propios items y mis `pass`). No devuelve `last_location`.
- **Salida**: campos de item + `owner_username`, `owner_avatar_url`, `owner_distance_m` (derivada, no coordenadas).

---

## 5) SQL (psql) — creación de esquema + RLS + RPC (Supabase)
> **Nota**: ejecutar en el proyecto Supabase (SQL editor). Comentarios y nombres en **inglés**.


---

## 6) Notas de implementación
- **Redondeo de `last_location`**: aplícalo en cliente antes de guardar o mediante trigger en DB si decides centralizar.
- **Frescura**: el parámetro `p_freshness_hours` permite experimentar (24–48 h).
- **Escalabilidad**: el índice GiST en `profiles.last_location` es crítico para mantener latencias bajas.
- **Privacidad**: al no permitir `select` abierto sobre `items`/`profiles`, obligamos a pasar por `feed_items_by_radius`, que controla datos expuestos.
- **Storage**: usa **signed URLs** cortos para compartir fotos con terceros y evitar exposición directa.

