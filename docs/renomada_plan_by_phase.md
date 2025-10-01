# ReNomada – Plan de Entregas y To‑Do por Fases (PO)

> Documento de Product Ownership para ejecutar el MVP hiperlocal. Estructurado **de lo general a lo específico**, con backlog por fases, criterios de aceptación, dependencias y trade‑offs técnicos. **Regla:** el texto va en español; nombres técnicos/stack en **inglés**. Sin código.

---

## 1) Objetivo del MVP y north star
- **Objetivo:** validar que existe **demanda real** de intercambio/regalo hiperlocal con baja fricción en 1–2 hotspots.
- **North star metric:** % de **items reclamados** dentro de 14 días en hotspot inicial.
- **Guardrails:** coste infra ~0 €, **time‑to‑market** corto, foco en **seguridad/privacidad**.

---

## 2) Alcance funcional del MVP (visión resumida)
1) **Auth** (login/signup) con **Supabase Auth**; sesiones persistentes y recuperación de cuenta.
2) **Profiles** con `last_location` (redondeada) + `last_seen_at`.
3) **Items** (CRUD) sin geolocalización; se asume co‑ubicación con su owner.
4) **Feed por radio**: filtrado por **usuarios cercanos** y listado de **todos sus items** públicos/activos.
5) **Swipe** (like/pass) con exclusión futura de *pass*.
6) **Chat** 1‑a‑1 (realtime) al primer *like*.
7) **Push notifications** (new message / new like).
8) **Landing** (Astro) para captación y enlaces a stores.

---

## 3) Stack técnico (selección y justificación)
**Mobile app:** **Flutter** (o **React Native (Expo)** como plan B)
- *Por qué Flutter*: rendimiento nativo consistente iOS/Android, UI rápida de implementar, SDK oficial `supabase_flutter`, buen soporte offline simple. Expo también es válido pero condiciona a JS; Flutter permite UI consistente y animaciones fluidas para la vista tipo Tinder.

**BaaS:** **Supabase** (Postgres + RLS + Auth + Storage + Realtime + Edge Functions)
- *Por qué Supabase*: SQL estándar (escala a futuro), **RLS** nativo para seguridad desde el día 1, **Auth** integrado, **Realtime** para chat, **Storage** con **signed URLs**. Alternativas como Firebase pierden SQL/joins y hacen más compleja la agregación por usuario.

**Maps:** **MapLibre** con tiles *free‑tier* (p. ej., Stadia/MapTiler en dev; plan Starter al escalar)
- *Por qué MapLibre*: evita lock‑in y tarjetas de crédito tempranas; Suficiente para geovisualización básica.

**Push:** **FCM** (Android) / **APNs** (iOS)
- *Por qué*: nativos, gratuitos, estándar.

**Landing:** **Astro** + **Cloudflare Pages** (o Netlify/Vercel)
- *Por qué*: 0 € con CDN global y despliegue continuo.

**Sin backend propio** en Fase 1
- *Por qué*: menor TTM, menos puntos de fallo; lógica declarativa (RLS, consultas). **Edge Functions** sólo si aporta seguridad/operación (p. ej., envíos de push, moderación, rate‑limit avanzado).

---

## 4) Decisiones de arquitectura (rationale y trade‑offs)
1) **Ubicación sólo en `profiles` (usuario) y no en `items`**
   - *Pro*: dato único de geo, simplicidad, privacidad. *Contra*: si owner se mueve sin abrir app, su `last_location` puede quedar desfasada → *Mitigación*: `last_seen_at` y aviso de frescura, degradar resultados viejos.
2) **RLS como pilar de seguridad**
   - *Pro*: enforcement en base de datos (zero‑trust del cliente). *Contra*: requiere pensar políticas desde el diseño → *Mitigación*: plantillas de policies por dominio y tests.
3) **Supabase vs Firebase**
   - *Pro Supabase*: SQL/joins, RLS, Realtime, Storage, Auth integrados; fácil consulta por usuario y agregaciones. *Contra*: Edge Functions (Deno) no es Python; si se requiere Python luego, se añade microservicio. *Pro Firebase*: SDKs maduros, FCM integrado; *Contra*: consultas compuestas y joins más complejos.
4) **Flutter vs React Native (Expo)**
   - *Pro Flutter*: performance, UI consistente y tooling; *Contra*: tamaño binario inicial. *Pro RN/Expo*: ecosistema JS, EAS builds; *Contra*: rendimiento variable, dependencias nativas si sales de lo soportado por Expo.
5) **No backend propio (inicio)**
   - *Pro*: coste 0, menos mantenimiento, menos latencia. *Contra*: lógica compleja difícil en puro SQL. *Mitigación*: **Edge Functions** y, si escala, añadir **microservicio Python** en **Render/Cloud Run**.

---

## 5) Roadmap por fases (entregas y To‑Do)
> Cada task incluye: objetivo, criterio de aceptación (CA), dependencias (Dep), y sizing **T‑shirt** (S/M/L/XL). Sin estimación horaria para mantener agilidad.

### **Fase 0 – Setup & cimientos (S‑M)**
1) **Project bootstrap** (mobile + repo + CI/CD)
   - **CA:** build local iOS/Android; rama `main` protegida.
   - **Dep:** SDKs instalados.
2) **Supabase project** (Auth, DB, Storage, Realtime)
   - **CA:** tablas y RLS definidas; Realtime activado para `messages`; bucket privado.
   - **Dep:** cuentas creadas.
3) **Landing (Astro)** + deploy en Cloudflare Pages
   - **CA:** URL pública con CTA a stores/newsletter; métricas básicas.
4) **Design system** (tokens, tipografía, colores, componentes base)
   - **CA:** librería de componentes reutilizable (buttons, cards, list items) y pautas de *empty states*.

### **Fase 1 – Core MVP (M‑L)**
5) **Onboarding & permisos de ubicación**
   - **CA:** permiso foreground; fallback si se deniega (entrada manual de ubicación o ciudad); *empty state* claro.
   - **Dep:** design system.
6) **Auth (login/signup)**
   - **CA:** email+password / magic link / OAuth; sesión persistente; logout; recuperación.
   - **Dep:** Supabase Auth configurado.
7) **Perfil (profiles)**
   - **CA:** guardar `last_location` (redondeada) y `last_seen_at` al abrir; editar `username` y `avatar`.
   - **Dep:** Storage privado.
8) **Publicar/Mis Items (CRUD)**
   - **CA:** crear/editar/pausar/eliminar; subir 1–3 fotos con límites; validaciones.
   - **Dep:** RLS items; Storage.
9) **Feed por radio** (agregación por owner)
   - **CA:** filtro por usuarios cercanos (radio configurable), listar todos sus items; paginación; orden por distancia owner → recencia item.
   - **Dep:** profiles con geo + índice espacial; vistas/queries preparadas.
10) **Swipe (like/pass)**
    - **CA:** swipe right crea/recupera chat y registra like; swipe left oculta item; "Undo" opcional.
    - **Dep:** interactions + RLS.
11) **Chat (realtime)**
    - **CA:** lista de chats; mensajes en tiempo real; estados básicos (enviado/recibido); marcado de entrega coordinada.
    - **Dep:** Realtime en `messages`.
12) **Push notifications**
    - **CA:** push por new message y new like (deep links a vistas); opt‑in de usuario.
    - **Dep:** tokens FCM/APNs; opcional **Edge Function** para envío.
13) **Observabilidad mínima**
    - **CA:** eventos clave (auth, publish, like, chat, push) en analítica; logs de errores cliente.

### **Fase 2 – Calidad, densidad y retención (S‑M)**
14) **Rate‑limits y anti‑spam** (publishing, messaging)
    - **CA:** límites por usuario/día; copy de error útil; métricas de abuso.
15) **Mejoras de discoverability**
    - **CA:** estados vacíos inteligentes; hints para aumentar radio o publicar primero.
16) **Seed en hotspot**
    - **CA:** 30–50 items de arranque; acuerdos con 1–2 micro‑influencers; mensajería in‑app contextual.
17) **Métricas de éxito**
    - **CA:** dashboard simple con densidad, % reclamados, tiempo de vida, ratio like→chat.

### **Fase 3 – Escalabilidad suave (M)**
18) **Edge Functions** (moderación simple, thumbnails, push batching)
    - **CA:** funciones desplegadas; coste estable.
19) **Hardening de seguridad**
    - **CA:** revisión de RLS, pruebas de acceso, rotación de claves, CSP en landing.
20) **Optimización de imágenes y caché**
    - **CA:** miniaturas server‑side; reducción de egress.
21) **Playbook de expansión a 2º hotspot**
    - **CA:** checklist operativo (pre‑seed, campañas, métricas base).

---

## 6) Criterios de aceptación (ejemplos por feature)
- **Auth**: tras signup/login, el usuario permanece autenticado al reabrir; logout borra sesión; recuperación funciona.
- **Feed por radio**: con permisos concedidos, al seleccionar 10 km se muestran items cuyos owners están ≤10 km y `last_seen_at ≤ 24h`.
- **Swipe**: al hacer *pass*, ese item no vuelve a aparecer para ese usuario en el mismo hotspot; al hacer *like*, existe chat y notificación al owner.
- **Chat**: mensaje enviado se refleja en el otro dispositivo en <2 s; si el receptor está offline, se envía push.
- **Publicar**: subir 3 fotos ≤2 MB cada una; si sobrepasa límites, se muestra error claro.

---

## 7) Seguridad, privacidad y cumplimiento (mínimos MVP)
- **RLS everywhere**; **anon key** sólo en app; **service role** nunca en cliente.
- **Storage privado** + **signed URLs** de vida corta; validación MIME/size.
- **Geo‑privacy**: `last_location` redondeada; sin histórico; opt‑out y degradación de experiencia documentada.
- **Rate‑limit** en rutas sensibles (publicación, mensajes).
- **Auditoría**: timestamps, soft‑delete en items/chats opcional; registro de reportes (si se activa).

---

## 8) Dependencias, riesgos y mitigación
- **Publicación iOS (99 $/año)** y **Android (25 $ one‑time)**: únicos costes inevitables. *Mitigación*: lanzar Android primero si es necesario.
- **Desfase de `last_location`** si usuario no abre la app: *Mitigación*: avisos de frescura, degradación en ranking, recordatorios suaves.
- **Abuso/Spam** en chat/publicaciones: *Mitigación*: rate‑limits, bloqueo/reportes (Fase 2), plantillas de mensajes.
- **Crecimiento de egress** por imágenes: *Mitigación*: thumbnails y compresión en Fase 3.

---

## 9) Métricas y umbrales de decisión (go/no‑go, pivot)
- **Liquidez local**: ≥30 items activos y ≥100 usuarios activos en el hotspot.
- **Conversión feed→chat**: ≥10% likes, ≥40% de likes terminan en chat.
- **Éxito de intercambio**: ≥25% de items reclamados ≤14 días.
- **Satisfacción**: app rating ≥4.3; NPS ≥ 30.
- **Coste infra**: 0 € sostenido en free tier (o <20 €/mes si se activa algún plan Starter).

---

## 10) Plan de lanzamiento y comunicación
- **Soft‑launch** en 1 hotspot (Tarifa / Pirineos según temporada) con seed de oferta.
- **Guiones de contenido**: stories de usuarios, before/after, “buen karma y buena ruta”.
- **Programa de referidos** ligero (insignias/estatus) en Fase 2.

---

## 11) Roadmap técnico futuro (post‑MVP)
- **Microservicio Python** (Render / Cloud Run) para ranking avanzado, moderación ML ligera y jobs batch.
- **Override opcional de ubicación por item** (para casos especiales).
- **Gamificación** completa (badges, niveles) y recomendaciones basadas en afinidad.

---

## 12) Resumen de trade‑offs clave
- **Sin backend propio** ahora → **+ velocidad, + coste 0**, − flexibilidad para lógica compleja (cubierto con Edge Functions y, más tarde, microservicio Python).
- **Ubicación en profiles** → **+ simplicidad/privacidad**, − riesgo de desfasar (cubierto con `last_seen_at` + UX de frescura).
- **Flutter** → **+ UI consistente/performance**, − binario más grande (aceptable para este caso). **RN/Expo** sigue como plan B válido.
- **Supabase** → **+ SQL/RLS/Realtime/Storage integrados**, − Edge Functions en Deno (se acepta; Python se añade en Fase post‑MVP si hace falta).

