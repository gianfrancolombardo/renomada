# ReNomada – Context Engineering (MVP Hiperlocal)

## 1) Propósito y principios (visión → decisiones técnicas)

**Propósito:** facilitar el **regalo/intercambio hiperlocal** “aquí y ahora” entre personas nómadas, con una experiencia mínima en fricción y máxima utilidad comunitaria.

**Principios de la marca (guían cada decisión):**

- **Comunidad primero:** fomentar conexiones reales y colaboración.
- **Sostenibilidad y minimalismo:** dar segunda vida a los objetos, reducir residuos.
- **Hiperlocalidad e inmediatez:** relevancia por cercanía y momento.
- **Simplicidad radical:** sólo lo imprescindible en el MVP.

**Estándares fundamentales (aplican a TODA implementación):**

- **Seguridad** en cada flujo y dato (RLS, least-privilege, privacidad).
- **Buenas prácticas de UI/UX** (jerarquía clara, estados vacíos, feedback inmediato).
- **Maximizar la satisfacción del usuario** (latencia baja, cero sorpresas, accesibilidad nativa).
- **Comunicación excelente**: *empty states* didácticos, mensajes claros, guías contextuales.

---

## 2) Resumen del producto (qué es el MVP)

- Usuarios publican **items** (sin geolocalización propia del item).
- Cada usuario mantiene su **última ubicación** (redondeada) en su perfil.
- El **feed** filtra **usuarios** dentro de un **radio** respecto a la posición actual del buscador y muestra **todos los items** de esos usuarios (se asume co‑ubicación con su owner).
- Interacción tipo **Tinder**: *swipe right* (me interesa) inicia **chat**; *swipe left* (pasar) oculta futuros avistamientos de ese item.
- **Chat** privado para coordinar entrega **en persona**.

**Ámbito técnico del MVP (sin backend propio):** App móvil (Flutter/React Native) + **Supabase** (Auth, DB Postgres + RLS, Storage, Realtime, Edge Functions opcional). Landing estática (Astro) en Cloudflare Pages/Netlify/Vercel.

---

## 3) Usuarios y recorridos clave (user journeys)

1. **Descubrir → Interesarme → Coordinar**: abro app → concedo ubicación → veo objetos de owners cercanos → *swipe right* → chat → quedo en persona.
2. **Publicar → Esperar → Entregar**: creo un item con fotos → otros me encuentran por cercanía → chateo → concreto entrega.
3. **Reincidencia feliz**: tras entrega, vuelvo a publicar/recibir con menos fricción (autocompletados, plantillas, recordatorios suaves).

---

## 4) Vistas de la app (de lo más general a lo específico)

**A. Onboarding & Permisos**

- Pedir permisos de ubicación ( foreground ).
- Comunicación de propósito: “Mostramos objetos **cerca de ti**, nunca tu ruta”. *Empty state* si se deniega permiso (búsqueda manual por ciudad como fallback).

**B. Autenticación (Login/Signup)**

- Email+password / OAuth (Google/Apple). Recordar sesión.
- Recuperación de cuenta (transparencia y control).

**C. Home (Feed por radio)**

- Selector de **radio** (1–50 km), lista/tarjetas por propietario cercano.
- Estados vacíos: “aumenta radio”, “sé el primero en publicar”. Indicador de frescura (última actualización del owner).

**D. Tarjeta de item (Swipe View)**

- Fotos, título, descripción, distancia del **owner**. Acciones: **Like** (swipe right), **Pass** (swipe left). Undo corto.

**E. Publicar / Mis Items**

- Crear/editar/pausar/eliminar item. Subida de fotos con compresión. Límite de tamaño/cantidad. Historial básico.

**F. Chat**

- Lista de chats. Conversación en tiempo real. Estado “entrega coordinada”/“entrega realizada”. Push notifications.

**G. Perfil**

- Avatar, nombre, insignias (futuro), última ubicación (redondeada y opcional visible), preferencias (privacy toggles).

---

## 5) Requisitos funcionales (por dominio)

### 5.1 Autenticación

- Registro/inicio de sesión; persistencia de sesión; cierre de sesión.
- Verificación de email; límites de intentos; revocación de sesiones.

### 5.2 Gestión de items (CRUD)

- Crear, editar, pausar/activar, eliminar; varias fotos por item.
- Visibilidad pública por defecto; ownership estricto; anti‑spam (rate limit por usuario).

### 5.3 Geobúsqueda (GET por coordenada)

- Obtener **usuarios** dentro de un radio desde la ubicación actual (usar `profiles.last_location` + `last_seen_at`).
- Listar **todos los items** públicos/activos de esos usuarios.
- Orden: distancia del owner → recencia del item; paginación.

### 5.4 Actualización de ubicación

- Al abrir y en refrescos manuales: actualizar `last_location` (redondeada) y `last_seen_at`.
- Sin tracking en background en el MVP. Opt‑out disponible (con degradación del feed).

### 5.5 Interacciones (Swipe)

- **Like**: registra interés y crea/recupera chat con el owner; notificación; mensaje automatico  para contexto en el chat "X esta interesado en Articulo ..."
- **Pass**: no volver a mostrar ese item a ese usuario.

### 5.6 Chat

- Crear chat al primer like; enviar/recibir mensajes en tiempo real.
- Marcado de estado (p. ej., “entrega coordinada/realizada”). Reportar/bloquear (básico)., No nesesario en MVP

### 5.7 Notificaciones

- Push al recibir mensaje nuevo y al recibir like.
- Contenido pequeño, sin datos sensibles; deep link a la vista correspondiente.

---

## 6) No funcionales (seguridad, privacidad, rendimiento, accesibilidad)

**Seguridad**

- Acceso directo a BaaS con **RLS activo** en todas las tablas. Clave **anon** en cliente; **service role** sólo en servidor (Edge Functions/panel).
- Políticas por dominio: items (owner CRUD, lectura pública de activos), interactions (propietario), chats/messages (sólo participantes), profiles (self‑write, lectura pública de campos no sensibles).
- Storage: bucket privado, URLs firmadas de corta vida; validación de tipo/tamaño.

**Privacidad**

- `last_location` redondeada (50–100 m), sin historial (sólo última).
- Opt‑out claro y *fallback* de experiencia.

**Rendimiento**

- Geobúsqueda sobre índice espacial de perfiles. P95 <200 ms en radio típico.
- Imágenes optimizadas (peso/formatos). Paginación en feed y chat.

**Accesibilidad y UX**

- Targets táctiles ≥44 px, contraste suficiente, soporte lector de pantalla.
- *Empty states* y microcopys que guían sin fricción.

---

## 7) Arquitectura de solución (quién hace qué)

**App (cliente)**

- UI/UX, permisos, obtención de ubicación, subida de imágenes, llamadas a BaaS, suscripción a realtime, recepción de push.

**BaaS – Supabase**

- Auth, DB Postgres, Realtime, Storage, **RLS** y lógica declarativa (consultas y vistas). `profiles.last_location` como **fuente única** de geolocalización en MVP.

**Edge Functions (opcional, sólo cuando aporte valor)**

- Envío de notificaciones push (leer token y llamar a FCM/APNs).
- Moderación, rate‑limits reforzados, tareas batch/cron.

---

## 8) Modelo de datos (alto nivel, sin código)

- **users/auth**: identidad gestionada por Supabase Auth.
- **profiles**: `user_id`, `username`, `avatar_url`, `last_location` (redondeada), `last_seen_at`.
- **items**: `id`, `owner_id`, `title`, `description`, `visibility`, `is_active`, `created_at` (sin coordenadas).
- **item\_photos**: `item_id`, `path`, metadatos.
- **interactions**: `user_id`, `item_id`, `action` (*like/pass*), `created_at`.
- **chats**: `id`, `item_id`, `a_user_id`, `b_user_id`, `created_at`.
- **messages**: `chat_id`, `sender_id`, `content`, `created_at`.

---

## 9) Flujos operativos (sin código)

**Publicar item** → subir fotos (privado) → crear item (sin geo) → visible en feed si owner está dentro del radio de otros.

**Descubrir cerca** → app obtiene ubicación + radio → filtra **usuarios** por cercanía y frescura → agrega y muestra todos los items de esos owners → excluye items con *pass*.

**Swipe → Chat** → *like* genera/recupera chat y notifica al owner → conversar → marcar “entrega coordinada/realizada”. *Pass* oculta futuras apariciones.

**Actualizar ubicación** → al abrir la app y en refrescos, guardar `last_location` redondeada y `last_seen_at`.

---

## 10) Métricas y analítica (privacidad primero)

- Densidad de usuarios e items por km² en hotspots.
- CTR de feed (vistas → likes), ratio like→chat, tiempo hasta entrega.
- % items reclamados y tiempo de vida de publicación.
- Salud de la experiencia: latencias, errores, abandonos en permisos.

---

## 11) “Nice to have” alineados con la propuesta de valor

- **Insignias** (Pionero/a, Eco‑Guerrero, Manitas, Chef Rodante) visibles en perfil.
- **Programa de referidos** con recompensa social (insignias/estatus).
- **Hotspots** (mapa de calor) para activar campañas locales.
- **Auto‑expirar** items (p. ej., 14 días) para mantener frescura del catálogo.
- **Trust & Safety**: verificación ligera, reportes, bloqueo.
- **Mensajes rápidos** (plantillas) para coordinar entregas.
- **Modo offline** (cache de feed) y **multi‑idioma**.

---

## 12) Plan de lanzamiento (fases)

- **Fase 0**: Datos + RLS + landing + build canary.
- **Fase 1**: Feed por radio + publicar + swipe + chat + push.
- **Fase 2**: Seed de oferta en 1 hotspot + referidos + primeras insignias.
- **Fase 3**: Moderación, miniaturas en servidor, métricas avanzadas, expandir a 2º hotspot.

---

## 13) Publicación y costes inevitables

- **Android (Play Store)**: cuota única de alta del desarrollador.
- **iOS (App Store)**: cuota anual del Apple Developer Program.
- Infra del MVP: Supabase + hosting estático **en capas gratuitas**; coste 0 salvo picos o crecimiento (entonces migrar a planes starter).

