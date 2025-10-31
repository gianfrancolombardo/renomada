# ReNomada — Brand Book v1

> Guía viva de identidad visual y verbal para producto, landing, emails y comunicación comunitaria.

---

## 1) Esencia de marca
**Propósito**: ayudar a personas **en movimiento** (vanlife/AC, furgoneta, mochileras/os, nómadas digitales) a **liberar espacio** dando **segunda vida** a sus objetos, reduciendo su **huella** mientras conectan con gente cercana a su ruta.

**Promesa**: *Libera espacio. Reduce tu huella.*

**Territorio**: sostenibilidad práctica, minimalismo móvil, hiperlocalidad/itinerancia, confianza y cuidado mutuo (comunidad como habilitador, no fin en sí mismo).

**Prioridades de posicionamiento**
1. **Sostenibilidad y huella** (principal): segunda vida, menos residuo, impacto visible.
2. **Espacio reducido y ligereza**: viaja ligero, despréndete fácil.
3. **Conexión local** (de soporte): quedadas seguras y simples en el camino.

**Pilares**
- **Segunda vida sin fricción**: publicar en segundos, coordinar en minutos.
- **Ligereza nómada**: pensado para mover, pausar y entregar sobre la marcha.
- **Hiperlocal/itinerante**: descubre por radio dinámico y puntos en ruta.
- **Privacidad y seguridad**: tu ubicación y ruta, siempre bajo tu control.
- **Claridad radical**: lenguaje simple, decisiones sencillas.

**Arquetipo**: *La Exploradora útil* — práctica, cercana y respetuosa con el entorno.

**Elevator pitch**: *ReNomada permite a nómadas y viajeros desprenderse de lo que ya no usan y encontrar lo que necesitan, cerca de donde están o por donde pasan — coordinando entregas en persona, fácil y sin regateos.*

**Tagline principal**
- **Libera espacio. Reduce tu huella.**

**Alternativas cortas (para test A/B)**
- *Viaja ligero, comparte cerca.*
- *Segunda vida en cada parada.*
- *Menos carga, más camino.*

---

## 2) Buyer personas (foco nómada)

### 2.1 Vanlife / AC / furgo en ruta (core)
- **Quién**: 25–45, viajes medios/largos, vida en vehículo.
- **Jobs**: rotar equipamiento, liberar espacio antes de avanzar, conseguir básicos en la zona.
- **Dolores**: poco espacio, tiempo limitado, no quiere negociar.
- **Triggers**: cambio de ruta, quedar con alguien en el siguiente pueblo.
- **Mensajes**: *“Menos carga, más camino.” “Entrega en tu próxima parada.”*
- **Canales**: YouTube/IG vanlife, foros/Telegram, parkings y áreas AC.

### 2.2 Mochilera/o en ciudad nueva (core)
- **Quién**: 18–35, estancias cortas o Erasmus, presupuesto limitado.
- **Jobs**: conseguir básicos rápido; desprenderse al irse.
- **Dolores**: logística, apps de venta lentas.
- **Mensajes**: *“Equipa tu piso en un paseo.” “Regala lo que no viaja contigo.”*
- **Canales**: TikTok/IG, grupos uni/hostels.

### 2.3 Nómada digital itinerante (core)
- **Quién**: 24–40, remoto, temporadas en hotspots.
- **Jobs**: entrar/salir ligero, compartir excedentes.
- **Dolores**: tiempo, confianza, saturación de apps.
- **Mensajes**: *“Llegaste ayer, hoy ya formas parte.”*
- **Canales**: IG, Slack/Telegram de colivings.

### 2.4 Vecina/o anfitrión (secundaria para balance)
- **Rol**: residente que dona o intercambia puntualmente; clave para oferta estable.
- **Mensaje**: *“Regala sin dramas, ayuda a quien está de paso.”*

> **Implicación UX**: onboarding pregunta **tipo de viaje** (furgo/mochila/otro) para ajustar radio, copy y plantillas de quedada.

---

## 3) Voz y tono
**Personalidad verbal**: cercana y práctica; optimista sin grandilocuencia; vocabulario de **viaje ligero** y **segunda vida**.

**Principios**
- **Háblale a una sola persona** (tú) con frases cortas y activas.
- **Sostenibilidad tangible**: muestra impacto concreto (p. ej., “x kg CO₂e evitados”).
- **Cero regateo, cero postureo**: coordinar, no vender.
- **Orientación a ruta**: tiempos y lugares claros; propone puntos de encuentro.
- **Privacidad explícita**: recuerda el control de ubicación.

**Do / Don’t**
- Do: *“Publica y entrega en tu próxima parada.”*
- Don’t: *“Cierra la transacción.”*
- Do: *“Activa tu ubicación para ver objetos a 1–5 km.”*
- Don’t: *“Comparte tu ubicación para siempre.”*

**Vocabulario base** (ver glosario)
- ✅ **objeto**, publicar, regalar, intercambiar, radio, ruta, quedada, punto de encuentro, segunda vida, huella, comunidad.
- ❌ ítem, subasta, pujar, vender, envío obligatorio, premium, spam de urgencia.

**Tono por contexto**
- **Onboarding/Permisos**: pedagógico, eco‑pragmático.
- **Feed/CTA**: directo, orientado a acción: *“Me interesa”*, *“Quedar hoy”*.
- **Error**: empático + acción: *“Vuelve a intentarlo”* / *“Revisa conexión”*.
- **Push**: útil y breve, sin sobresaltos.

**Microcopy clave**
- Permisos: *“Mostramos objetos cerca de ti, nunca tu ruta. Puedes cambiarlo cuando quieras.”*
- Empty state nómada: *“Nada a este radio. Prueba 5–10 km o publica lo que no viaja contigo.”*
- Crear: *“Saca 2–3 fotos, añade una frase útil y listo.”*
- Quedada: *“¿Te viene bien hoy a las {hora} en {punto}?”*

---

## 4) Identidad visual

### 4.1 Paleta de color (tokens)
```js
const BRAND = {
  lilac: "#B7BEFE",   // primary (UI primario, links, highlights)
  magenta: "#FF95DD", // secondary (accent emocional, badges)
  lime: "#F6FF7F",    // tertiary (CTA, foco, éxito suave)
  surface: "#1F1F1F", // fondo principal (modo dark por defecto)
  surfaceVariant: "#313131", // contenedores, cards
  textLight: "#F5F5F5", // texto sobre fondos oscuros
  outline: "#8A8A8A",  // bordes, divisores, inputs
};
```
**Roles recomendados**
- **Primario (lilac)**: acciones secundarias, estados informativos, chips.
- **Secundario (magenta)**: acentos de marca, vacíos ilustrados, insignias.
- **CTA (lime)**: botones primarios, toggles activos, indicadores de éxito.
- **Neutros**: `surface`/`surfaceVariant` para fondos; `textLight` como texto principal.
- **Outline**: bordes de inputs (1 px) y estados de foco (1–2 px).

**Accesibilidad (WCAG)**
- Contraste mínimo: **4.5:1** en texto normal; **3:1** en ≥18 pt o 14 pt bold.
- Combinaciones validadas:
  - `textLight` sobre `surface` y `surfaceVariant` ✅
  - Texto sobre **lime**: usar `#1F1F1F` (negro suave) en el label del botón para ≥4.5:1.
  - Texto sobre **lilac/magenta**: preferir `#1F1F1F` o `#0E0E0E` según prueba.

**Status (opcional, sistema auxiliar)**  
> Para mensajes del sistema puedes derivar:
- **Info**: `lilac` base.
- **Éxito**: `lime` base + icono.
- **Alerta**: `#FFB84D` (Amber 300, propuesto).
- **Error**: `#FF5A78` (Rose 400, propuesto).  
*Aprobar en QA de contraste antes del go‑live.*

**Gradientes (sutiles)**
- *Lila→magenta* para hero: `linear-gradient(135deg, #B7BEFE 0%, #FF95DD 100%)` con opacidad 8–12% sobre `surface`.

### 4.2 Tipografía
- **Títulos**: **Poppins** — pesos 700/600/500.  
  Escala sugerida: H1 32/40, H2 24/32, H3 20/28, H4 18/24.
- **Cuerpo**: **Lato** — pesos 400/500.  
  Párrafo 16/24, Small 14/20, Micro 12/16.
- **Enlaces**: subrayado al foco/hover; color **lilac**.
- **Jerarquía**: máx. 3 niveles por pantalla.

### 4.3 Iconografía e ilustración
- **Set**: **Lucide Icons** (stroke 1.75–2 px, esquinas redondeadas, sin rellenos pesados).
- **Tamaños**: 20, 24, 28 px en móvil; 24, 32 px en web. Icono + label cuando sea acción.
- **Colores**: on‑surface para estados neutros; **lilac** para énfasis; **lime** sólo en CTAs.
- **Ejemplos recomendados**: `MapPin`, `Navigation2`, `Route`, `Gift`, `Recycle`, `Leaf`, `Users2`, `MessageSquare`, `Shield`, `Clock`, `Radio`.
- **Ilustración**: escenas reales de ruta (áreas AC, hostels, plazas), manos entregando objetos; evitar clichés tech.
- **Fotografía**: luz natural, diversidad; plano medio en entorno de ruta/barrio.

### 4.4 Layout, espaciado y componentes Layout, espaciado y componentes
- **Grid**: 8‑pt system. Padding de pantalla 16–20 px.
- **Cards**: `surfaceVariant`, radio 16 px, sombra suave (y=8, blur=24, opacidad 16%).
- **Botón primario**: fondo **lime**, texto `#1F1F1F`, radio 14–16 px, altura 48 px.
- **Botón secundario**: borde 1 px **lilac** sobre `surface`, texto **lilac**.
- **Input**: borde **outline**, foco con halo **lilac** (2 px), label always‑visible.
- **Chips**: fondo `#2A2A2A`, texto claro; “Me interesa” como CTA inline.
- **Estados vacíos**: ilustración lineal + copy 1 línea + CTA claro.
- **Focus visible** (teclado): anillo `lilac` 2 px.

### 4.5 Marca mínima (logotipo provisional)
- **Wordmark**: “ReNomada” en **Poppins 700**, tracking +2, color **textLight**.  
- **Clear space**: 1× la altura de la R alrededor.
- **No hacer**: aplicar sombras duras, contornos multicolor, rotaciones.
- **Favicon/App icon**: monograma **RN** sobre **lilac** con trazo `#1F1F1F`.

#### 4.7 Colores semánticos (MD3)
> Mapeo a Material Design 3 manteniendo la paleta.

```js
const MD3 = {
  // Roles de marca
  primary: "#B7BEFE", onPrimary: "#1F1F1F",
  secondary: "#FF95DD", onSecondary: "#1F1F1F",
  tertiary: "#F6FF7F", onTertiary: "#1F1F1F",

  // Superficies
  surface: "#1F1F1F", onSurface: "#F5F5F5",
  surfaceVariant: "#313131", onSurfaceVariant: "#F5F5F5",
  outline: "#8A8A8A",

  // Containers (tintes sobre surface)
  primaryContainer: "#434555", onPrimaryContainer: "#F5F5F5",  // lilac @24%
  secondaryContainer: "#553B4D", onSecondaryContainer: "#F5F5F5", // magenta @24%
  tertiaryContainer: "#535536", onTertiaryContainer: "#1F1F1F",  // lime @24%

  // Estados del sistema
  success: "#F6FF7F", onSuccess: "#1F1F1F", successContainer: "#4E5034",
  warning: "#FFB84D", onWarning: "#1F1F1F", warningContainer: "#504129",
  error:   "#FF5A78", onError:   "#1F1F1F", errorContainer:   "#502C33",

  // Opacidades de state layer (MD3)
  state: { hover: 0.08, focus: 0.12, pressed: 0.12, dragged: 0.16 },
};
```

**Uso práctico**
- **CTA primario**: `tertiary` (lime) con `onTertiary`.
- **Acción secundaria**: borde `primary`, texto `primary` sobre `surface`.
- **Badges / acentos**: `secondary`.
- **Cards**: `surfaceVariant`; para destacar, usar `primaryContainer`.
- **Alertas**: success/warning/error + containers respectivos.
- **Focus visible**: halo 2 px en `primary`.

---

## 5) Ejemplos prácticos (copys listos)

### 5.1 Onboarding
- **Pantalla 1 (beneficio)**: *“Encuentra y comparte cosas útiles a unos pasos.”*
- **Permiso de ubicación**: *“Para mostrarte objetos cerca de ti, necesitamos tu ubicación mientras usas la app. Nunca guardamos tu ruta.”*
- **Crear perfil**: *“Un nombre y una foto bastan.”*

### 5.2 Feed / Tarjeta de item
- **Card**: título claro (máx. 60 car.), distancia del **owner**, 2–3 fotos.
- **Acción**: *“Me interesa”* (primario), *“Pasar”* (secundario).

### 5.3 Chat
- **Mensaje automático de contexto**: *“{Nombre} está interesado/a en **{Item}**.”*
- **Plantillas**: *“¿Te viene bien hoy a las {hora} en {lugar}?”* / *“Llevaré {detalle}.”*

### 5.4 Landing (estructura)
- **Hero**: H1 *“Cerca, útil y ahora.”*  
  Sub: *“Regala o encuentra lo que necesitas en tu barrio. Sin envíos, sin dramas.”*  
  CTA: *“Descargar app”* (primario lime), *“Cómo funciona”* (secundario).
- **Cómo funciona (3 pasos)**: Descubre → Interés → Queda y entrega.
- **Privacidad**: *“Control total sobre tu ubicación.”*
- **Prueba social**: historias cortas con foto real.

### 5.5 Emails (plantillas breves)

**Bienvenida**
- **Asunto**: *“¡Hola! Esto es ReNomada”*
- **Preheader**: *“Cerca, útil y ahora.”*
- **Cuerpo**: *“Gracias por unirte. Desde hoy, tu comunidad está más cerca. Empieza publicando un objeto o busca a 5 km.”*

**Verificación / Magic link**
- **Asunto**: *“Confirma tu correo para empezar”*
- **Cuerpo**: botón **lime** *“Confirmar”* + nota: *“Si no fuiste tú, ignora este correo.”*

**Nuevo mensaje**
- **Asunto**: *“Tienes un mensaje sobre {Item}”*
- **Cuerpo**: *“{Nombre} te escribió. Abre el chat para coordinar.”*

**Resumen semanal**
- **Asunto**: *“Lo que se movió cerca de ti”*  
- **Cuerpo**: 3 destacados + CTA *“Abrir ReNomada”*.

### 5.6 Push notifications
- **Like recibido**: *“A {Nombre} le interesa **{Item}**.”*
- **Mensaje nuevo**: *“Nuevo mensaje sobre **{Item}**.”*
- **Recordatorio suave**: *“¿Sigue disponible **{Item}**? Puedes pausarlo si ya se entregó.”*

---

## 6) Gobernanza de marca
- **Checklist antes de publicar**:
  1) ¿Mensaje claro en 1 frase?
  2) ¿CTA directo y único?
  3) ¿Privacidad mencionada cuando procede?
  4) ¿Contraste ≥4.5:1?
  5) ¿Máx. 3 niveles tipográficos?
- **A/B a iterar**: tagline en hero, copia de permisos, CTA en tarjeta.
- **Métricas de comunicación**: CTR de CTA, ratio like→chat, % permisos concedidos, tasa de respuesta en chat.
- **Changelog de voz/visual**: documentar cambios y razón.

---

## 7) Anexos (aplicación de tokens)

**Botón primario (estado)**
- Default: fondo **lime** / texto `#1F1F1F`
- Hover/Pressed: **lime** -6% luminancia
- Disabled: `#2A2A2A` / texto `#8A8A8A`

**Input**
- Borde **outline**, foco `box-shadow: 0 0 0 2px #B7BEFE`.

**Link**
- Color **lilac**, subrayado al hover, foco con halo `lilac`.

**Card**
- Fondo `surfaceVariant`, padding 16–20 px, radio 16 px, sombra suave.

---

## 8) Glosario de conceptos (términos de producto)
- **Objeto** (preferido): cualquier cosa que se publica para regalar/intercambiar. *Evitar*: ítem. *Alternativa formal*: artículo (solo legal/soporte).
- **Publicar**: crear una ficha visible de un objeto. *Evitar*: anunciar.
- **Regalar / Intercambiar**: formas de cesión. *Evitar*: vender, subastar.
- **Radio**: distancia de búsqueda (1–20 km), ajustable.
- **Ruta**: trayectoria/plan de desplazamiento del usuario.
- **Quedada / Punto de encuentro**: lugar y hora acordados para la entrega.
- **Pausar**: ocultar temporalmente un objeto sin eliminarlo.
- **Reservado**: objeto apartado para una persona concreta.
- **Entregado**: objeto ya dado; opción para cerrar conversación.
- **Perfil verificado**: cuenta con email/teléfono verificados.
- **Huella**: impacto estimado (CO₂e evitado) por segunda vida.
- **Pack**: varios objetos publicados y entregados juntos.

> Estas elecciones lingüísticas se usan en todo: app, landing, emails y push.

---

### Nota final
Esta guía es **opinionada pero pragmática**. Úsala para decidir rápido y mantener coherencia. Si hay duda, prioriza **claridad**, **accesibilidad** y **cercanía**.

