# 🗺️ ReNomada - Roadmap Visual del MVP

**Actualizado:** 9 de octubre de 2025

---

## 📍 DÓNDE ESTAMOS AHORA

```
████████████████████░░░░  85% COMPLETO
```

### ✅ Lo que YA funciona:
- 🔐 Autenticación completa (login, signup, sesiones)
- 👤 Perfiles con avatares y ubicación
- 📦 CRUD de items con fotos
- 🗺️ Feed geográfico por radio (PostGIS)
- 📱 UI completa con Material Design 3
- 🔒 Seguridad (RLS en todas las tablas)
- 💾 Base de datos optimizada
- 🎨 Design system implementado

### 🟡 Lo que está a medias:
- 💬 Chat (implementado pero sin verificar realtime)
- 👍 Sistema de like/pass (UI existe, falta lógica)

### ❌ Lo que falta:
- 🔔 Push notifications
- 🌐 Landing page
- 📊 Métricas y analytics
- 📱 Preparación de stores

---

## 🎯 HACIA DÓNDE VAMOS

### Objetivo: **MVP Lanzable en App Stores**

**Meta de lanzamiento:** 2-3 semanas desde hoy

---

## 📅 TIMELINE

```
SEMANA 1              SEMANA 2              SEMANA 3
│                     │                     │
├─ Sprint 1: CORE     ├─ Sprint 2: PUSH    ├─ Sprint 3: LAUNCH
│  (Días 1-4)         │  (Días 5-7)        │  (Días 8-10)
│                     │                     │
▼                     ▼                     ▼
```

---

## 📋 SPRINT 1: Funcionalidad Core (Días 1-4)

**Objetivo:** Completar flujo principal usuario → publicar → feed → like → chat

### Día 1-2: Sistema de Interacciones 🔴
```
┌──────────────────────────────────────┐
│ 1. Crear InteractionService          │
│ 2. Implementar like → crear chat     │
│ 3. Implementar pass → ocultar item   │
│ 4. Conectar con FeedScreen           │
│ 5. Testing                           │
└──────────────────────────────────────┘
Prioridad: ⭐⭐⭐⭐⭐ CRÍTICA
Tiempo: 1-2 días
```

### Día 2-3: Verificación Chat Realtime 🟡
```
┌──────────────────────────────────────┐
│ 1. Testing multi-dispositivo         │
│ 2. Verificar suscripciones Realtime  │
│ 3. Manejo de reconexiones            │
│ 4. Estados de entrega (opcional)     │
└──────────────────────────────────────┘
Prioridad: ⭐⭐⭐⭐ ALTA
Tiempo: 1 día
```

### Día 3-4: Testing Integración 🔵
```
┌──────────────────────────────────────┐
│ 1. Flujo completo signup → chat      │
│ 2. Testing de seguridad RLS          │
│ 3. Performance testing               │
│ 4. Fixing de bugs críticos           │
└──────────────────────────────────────┘
Prioridad: ⭐⭐⭐⭐ ALTA
Tiempo: 1 día
```

**Entregable Sprint 1:** ✨ **App funcional con flujo completo**

---

## 📋 SPRINT 2: Push Notifications (Días 5-7)

**Objetivo:** Notificaciones push para mensajes y likes

### Día 5: Setup FCM/APNs 🟡
```
┌──────────────────────────────────────┐
│ 1. Configurar Firebase Android/iOS   │
│ 2. Crear NotificationService         │
│ 3. Registrar tokens en Supabase      │
│ 4. Solicitar permisos al usuario     │
└──────────────────────────────────────┘
Prioridad: ⭐⭐⭐ MEDIA
Tiempo: 4-6 horas
```

### Día 6: Edge Function Push 🟡
```
┌──────────────────────────────────────┐
│ 1. Crear Edge Function send-push     │
│ 2. Trigger para nuevos mensajes      │
│ 3. Trigger para nuevos likes         │
│ 4. Testing end-to-end                │
└──────────────────────────────────────┘
Prioridad: ⭐⭐⭐ MEDIA
Tiempo: 3-4 horas
```

### Día 7: Deep Links 🟢
```
┌──────────────────────────────────────┐
│ 1. Configurar deep linking           │
│ 2. Manejar tap en notificación       │
│ 3. Testing navegación                │
└──────────────────────────────────────┘
Prioridad: ⭐⭐ BAJA (opcional)
Tiempo: 2-3 horas
```

**Entregable Sprint 2:** 🔔 **Notificaciones push funcionando**

---

## 📋 SPRINT 3: Landing & Launch (Días 8-10)

**Objetivo:** Preparar todo para lanzamiento público

### Día 8: Landing Page 🟢
```
┌──────────────────────────────────────┐
│ 1. Crear sitio Astro                 │
│ 2. Diseño responsive                 │
│ 3. Newsletter signup                 │
│ 4. Deploy Cloudflare Pages           │
└──────────────────────────────────────┘
Prioridad: ⭐⭐ BAJA (puede ser simple)
Tiempo: 4-6 horas
```

### Día 9: Analytics & Métricas 🟡
```
┌──────────────────────────────────────┐
│ 1. Setup Firebase Analytics          │
│ 2. Implementar tracking eventos      │
│ 3. Dashboard básico (opcional)       │
└──────────────────────────────────────┘
Prioridad: ⭐⭐⭐ MEDIA
Tiempo: 3-4 horas
```

### Día 9-10: Preparación Stores 🔴
```
┌──────────────────────────────────────┐
│ 1. Crear App Store Connect           │
│ 2. Crear Google Play Console         │
│ 3. Screenshots y assets              │
│ 4. Descripciones y textos            │
│ 5. Builds de release                 │
│ 6. TestFlight / Internal Testing     │
└──────────────────────────────────────┘
Prioridad: ⭐⭐⭐⭐ ALTA
Tiempo: 1-2 días
```

**Entregable Sprint 3:** 🚀 **App lista para soft-launch**

---

## 🎯 HITOS CLAVE

### ✅ Hito 1: MVP Core Completo
**Cuándo:** Fin Sprint 1 (Día 4)
**Qué:** App funcional con flujo signup → publicar → feed → like → chat
**Validación:** Testing manual de flujo completo sin errores

### ✅ Hito 2: Notificaciones Activas
**Cuándo:** Fin Sprint 2 (Día 7)
**Qué:** Push notifications funcionando para mensajes y likes
**Validación:** Recibir notificación en dispositivo real

### ✅ Hito 3: Ready for Soft Launch
**Cuándo:** Fin Sprint 3 (Día 10)
**Qué:** App en TestFlight/Internal Testing, landing live
**Validación:** 5-10 beta testers usando la app

---

## 🚦 CRITERIOS DE ÉXITO

### Para considerar el MVP "listo":

#### Funcionalidad ✅
- [ ] Usuario puede registrarse y login
- [ ] Usuario puede publicar item con fotos
- [ ] Usuario puede ver feed por radio
- [ ] Usuario puede hacer like → se crea chat
- [ ] Usuario puede chatear en tiempo real
- [ ] Usuario recibe push cuando hay mensaje/like

#### Calidad ✅
- [ ] No hay crashes críticos
- [ ] RLS bloquea accesos no autorizados
- [ ] Performance aceptable (<3s operaciones)
- [ ] Funciona en conexión lenta

#### Launch ✅
- [ ] Build en TestFlight/Internal Testing
- [ ] 5+ beta testers han probado
- [ ] Assets de store preparados
- [ ] Landing page live

---

## 🔄 PLAN B: Si hay retrasos

### Escenario: Solo 2 semanas disponibles

**Recortar en orden:**

1. 🟢 **Deep Links** - No crítico, puede ir en v1.1
2. 🟢 **Landing elaborada** - Puede ser página HTML simple
3. 🟢 **Analytics dashboard** - Queries manuales por ahora
4. 🟡 **Estados de entrega chat** - Nice to have
5. 🟡 **Push notifications** - Funcionalidad importante pero no bloqueante

**MVP Mínimo Viable:**
- ✅ Sistema de interacciones completo
- ✅ Chat en tiempo real funcional
- ✅ Testing exhaustivo
- ✅ Build en stores

Con esto se puede lanzar en **~2 semanas** y añadir push en **v1.1**.

---

## 📊 MÉTRICAS A VALIDAR POST-LANZAMIENTO

Según el plan original, los objetivos son:

### 🎯 North Star Metric
**% de items reclamados en ≤14 días**
- Objetivo: ≥25%

### 📈 Métricas Clave

| Métrica | Objetivo | Cómo Medir |
|---------|----------|------------|
| **Liquidez local** | ≥30 items activos<br>≥100 usuarios activos | Query a DB |
| **Conversión feed→chat** | ≥10% de likes<br>≥40% likes→chat | Analytics |
| **Satisfacción** | Rating ≥4.3<br>NPS ≥30 | Store reviews<br>Encuestas |
| **Coste infra** | 0€ (free tier) | Supabase dashboard |

### 📅 Timeline de Validación

```
SEMANA 1-2          SEMANA 3-4          MES 2
(Beta Testing)      (Soft Launch)       (Validación)
│                   │                   │
├─ 5-10 testers    ├─ 50-100 usuarios  ├─ Análisis métricas
├─ Fix bugs        ├─ Seed en hotspot  ├─ Go/No-go decisión
└─ Iterar UX       └─ Monitorear       └─ Escalar o pivotar
```

---

## 🎯 DECISIÓN ESTRATÉGICA

### ¿Cuándo lanzar?

**Opción A: Lanzamiento Rápido (2 semanas)**
- ✅ Pro: Validación rápida del producto
- ✅ Pro: Menos desarrollo sin validación
- ❌ Contra: Sin push notifications inicialmente

**Opción B: Lanzamiento Completo (3 semanas)**
- ✅ Pro: Todas las features del MVP
- ✅ Pro: Mejor experiencia para primeros usuarios
- ❌ Contra: 1 semana más de desarrollo

**Recomendación:** 👉 **Opción A + v1.1 rápida**

**Rationale:**
1. Lo crítico es validar que **existe demanda** de intercambio hiperlocal
2. El chat funcional es suficiente para validar esto
3. Push mejora retención pero no es necesario para validación inicial
4. Se puede lanzar v1.1 con push en **1 semana después** basado en feedback

---

## 🏁 PRÓXIMO PASO INMEDIATO

### 👉 ¡Empezar HOY con Tarea 1.1!

```bash
# Crear nueva rama
git checkout -b feature/interaction-system

# Crear archivo del servicio
mkdir -p lib/shared/services
touch lib/shared/services/interaction_service.dart

# Empezar a codear 🚀
```

### Foco del día:
**Implementar `InteractionService` completo**
- Tiempo estimado: 4-6 horas
- Prioridad: CRÍTICA
- Bloqueante: Sí

---

## 💡 RECORDATORIOS

### ✨ Mantener en mente:

1. **MVP = Minimum VIABLE Product**
   - No tiene que ser perfecto
   - Tiene que funcionar bien para el caso de uso core

2. **Validar > Perfeccionar**
   - Mejor 80% funcional hoy que 100% perfecto en 2 meses

3. **Los usuarios beta perdonan bugs**
   - Si la propuesta de valor es clara
   - Si comunicas y arreglas rápido

4. **Escalar es más fácil que pivotar**
   - Primero validar que hay demanda
   - Luego optimizar y añadir features

---

## 🎉 ¡ESTAMOS MUY CERCA!

```
                    🏁 MVP LANZABLE
                         │
                         │
                    ┌────┴────┐
                    │         │
               SPRINT 3   SPRINT 2
                         │
                         │
                    ┌────┴────┐
                    │         │
               SPRINT 1      HOY
                              ▲
                              │
                         ¡EMPEZAR AQUÍ!
```

**El MVP está a solo 2-3 semanas de distancia.**  
**El trabajo más difícil (arquitectura, seguridad, UI) ya está hecho.**  
**¡Ahora es momento de conectar las piezas y lanzar! 🚀**


