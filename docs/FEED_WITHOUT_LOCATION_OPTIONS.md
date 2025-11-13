# Opciones para Manejar Feed Sin Ubicación

## Contexto Actual

El feed actualmente **requiere ubicación** para funcionar porque:
- Usa la función RPC `feed_items_by_radius` que filtra items por distancia
- Los items se ordenan por distancia al usuario
- La funcionalidad core de la app es hiperlocal (objetos cerca de ti)

## Problema

¿Qué mostrar en el feed cuando el usuario **no concede ubicación** o la tiene **permanentemente denegada**?

---

## Opción 1: Modo Degradado - Feed Global Sin Distancia 🌍 (MÁS FLEXIBLE)

### Descripción
Permitir usar la app sin ubicación, mostrando todos los items disponibles sin filtro de distancia.

### Implementación

**Cambios necesarios:**
1. Crear función RPC alternativa `feed_items_all` (sin filtro de distancia)
2. Modificar `FeedService` para detectar si hay ubicación
3. Mostrar items sin distancia, ordenados por fecha (más recientes primero)
4. Mostrar banner/CTA constante: "Habilita ubicación para ver objetos cerca de ti"

**Ventajas:**
- ✅ Usuario puede usar la app inmediatamente
- ✅ No bloquea la experiencia
- ✅ Reduce fricción de onboarding
- ✅ Permite descubrir la app antes de conceder ubicación
- ✅ Mejor para crecimiento (más usuarios activos)

**Desventajas:**
- ❌ Pierde el valor core de la app (hiperlocal)
- ❌ Experiencia menos relevante
- ❌ Puede confundir sobre el propósito de la app
- ❌ Requiere cambios en backend (nueva función RPC)

**Código estimado:** ~200-300 líneas + cambios backend

**Ejemplo de UI:**
```
┌─────────────────────────────────┐
│ [Banner]                        │
│ 📍 Habilita ubicación para      │
│    ver objetos cerca de ti      │
│    [Botón: Activar]             │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│ Feed Items (sin distancia)      │
│ • Item 1                        │
│ • Item 2                        │
│ • Item 3                        │
└─────────────────────────────────┘
```

---

## Opción 2: Forzar Permiso - No Continuar Sin Ubicación 🔒 (MÁS ESTRICTO)

### Descripción
**No permitir** usar el feed sin ubicación. El usuario debe conceder permisos o no puede usar la app.

### Implementación

**Cambios necesarios:**
1. Eliminar opción "Continuar sin ubicación" de `LocationPermissionScreen`
2. En `LocationRecoveryScreen`, eliminar opción "Skip"
3. En `FeedScreen`, si no hay ubicación → redirigir a `LocationRecoveryScreen`
4. Mostrar mensaje claro: "La ubicación es necesaria para usar ReNomada"

**Ventajas:**
- ✅ Mantiene el valor core de la app (hiperlocal)
- ✅ Experiencia consistente (todos con ubicación)
- ✅ Más simple de implementar (menos casos edge)
- ✅ Alineado con el propósito de la app

**Desventajas:**
- ❌ Alta fricción de onboarding
- ❌ Puede perder usuarios que no quieren dar ubicación
- ❌ Experiencia restrictiva
- ❌ No permite descubrir la app antes de comprometerse

**Código estimado:** ~50-100 líneas (principalmente eliminar opciones)

**Ejemplo de UI:**
```
┌─────────────────────────────────┐
│ LocationRecoveryScreen          │
│                                 │
│ "La ubicación es necesaria"    │
│                                 │
│ [Botón: Abrir configuración]   │
│                                 │
│ (Sin opción de skip)            │
└─────────────────────────────────┘
```

---

## Opción 3: Feed Limitado con CTA Persistente 🎯 (RECOMENDADA - BALANCE)

### Descripción
Permitir usar la app sin ubicación, pero con funcionalidad limitada y CTA constante para habilitar ubicación.

### Implementación

**Cambios necesarios:**
1. Crear función RPC `feed_items_recent` (últimos items sin filtro de distancia)
2. Mostrar máximo 10-20 items más recientes
3. Banner prominente en la parte superior: "Habilita ubicación para ver objetos cerca de ti"
4. CTA flotante o en cada refresh: "Activar ubicación"
5. Mostrar mensaje: "Mostrando items recientes. Habilita ubicación para ver objetos cerca de ti"

**Ventajas:**
- ✅ Balance entre flexibilidad y propósito
- ✅ Usuario puede descubrir la app
- ✅ CTA constante pero no intrusivo
- ✅ Mantiene el valor de ubicación visible
- ✅ Mejor conversión que Opción 1 (más incentivo)

**Desventajas:**
- ⚠️ Requiere cambios en backend
- ⚠️ Experiencia limitada puede frustrar
- ⚠️ Necesita diseño cuidadoso del CTA

**Código estimado:** ~250-350 líneas + cambios backend

**Ejemplo de UI:**
```
┌─────────────────────────────────┐
│ [Banner destacado]              │
│ 📍 Ver objetos cerca de ti      │
│    Habilita ubicación para      │
│    una mejor experiencia         │
│    [Botón: Activar ubicación]   │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│ "Mostrando items recientes"     │
│                                 │
│ Feed Items (limitado, sin dist)│
│ • Item 1                        │
│ • Item 2                        │
│ • ... (máx 20 items)            │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│ [CTA flotante al final]         │
│ "¿Quieres ver objetos cerca?"   │
│ [Activar ubicación]             │
└─────────────────────────────────┘
```

---

## Comparación de Opciones

| Aspecto | Opción 1 (Degradado) | Opción 2 (Forzar) | Opción 3 (Limitado) |
|---------|---------------------|-------------------|---------------------|
| **Fricción onboarding** | ⭐ Baja | ⭐⭐⭐ Alta | ⭐⭐ Media |
| **Retención usuarios** | ⭐⭐⭐ Alta | ⭐ Baja | ⭐⭐⭐ Media-Alta |
| **Valor core app** | ⭐ Bajo | ⭐⭐⭐ Alto | ⭐⭐ Medio |
| **Complejidad backend** | ⭐⭐ Media | ⭐ Baja | ⭐⭐ Media |
| **Conversión permisos** | ⭐ Baja | ⭐⭐⭐ Alta | ⭐⭐⭐ Alta |
| **Experiencia usuario** | ⭐⭐⭐ Buena | ⭐ Limitada | ⭐⭐⭐ Buena |
| **Crecimiento** | ⭐⭐⭐ Alto | ⭐ Bajo | ⭐⭐⭐ Alto |

---

## Recomendación: Opción 3 (Feed Limitado)

### Razones:
1. **Balance perfecto**: Permite descubrir la app pero mantiene el incentivo de ubicación
2. **Mejor conversión**: CTA constante pero no bloqueante
3. **Experiencia clara**: Usuario entiende qué se pierde sin ubicación
4. **Escalable**: Puede evolucionar a Opción 1 o 2 según métricas

### Implementación Sugerida:

**Fase 1 (MVP):**
- Implementar Opción 3 con feed limitado
- CTA prominente pero no bloqueante
- Máximo 20 items recientes

**Fase 2 (Optimización):**
- A/B testing: Opción 1 vs Opción 3
- Medir conversión de permisos
- Medir retención de usuarios

**Fase 3 (Decisión basada en datos):**
- Si conversión alta → Mantener Opción 3
- Si retención baja → Considerar Opción 1
- Si propósito core crítico → Considerar Opción 2

---

## Implementación Técnica Opción 3

### Backend (Supabase SQL)
```sql
-- Nueva función RPC para items recientes sin distancia
CREATE OR REPLACE FUNCTION feed_items_recent(
  page_limit INTEGER DEFAULT 20,
  page_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  item_id UUID,
  owner_id UUID,
  owner_username TEXT,
  owner_avatar_url TEXT,
  item_title TEXT,
  item_description TEXT,
  item_status TEXT,
  item_created_at TIMESTAMPTZ,
  item_updated_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.id as item_id,
    p.user_id as owner_id,
    p.username as owner_username,
    p.avatar_url as owner_avatar_url,
    i.title as item_title,
    i.description as item_description,
    i.status::TEXT as item_status,
    i.created_at as item_created_at,
    i.updated_at as item_updated_at
  FROM items i
  JOIN profiles p ON i.owner_id = p.user_id
  WHERE i.status = 'available'
    AND p.is_location_opt_out = false
  ORDER BY i.created_at DESC
  LIMIT page_limit
  OFFSET page_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Frontend (Flutter)
```dart
// En FeedService
Future<List<FeedItem>> getFeedItemsWithoutLocation({
  int page = 0,
  int limit = 20,
}) async {
  // Llamar a feed_items_recent en lugar de feed_items_by_radius
  final response = await SupabaseConfig.rpc('feed_items_recent', {
    'page_limit': limit,
    'page_offset': page * limit,
  });
  // ... procesar respuesta
}

// En FeedScreen
if (!locationState.hasLocation) {
  if (locationState.permissionStatus == permanentlyDenied) {
    return _buildFeedWithoutLocation(); // Opción 3
  }
}
```

---

## Decisión Final

**Recomendación:** Implementar **Opción 3** (Feed Limitado) porque:
- ✅ Mejor balance UX/Propósito
- ✅ Permite crecimiento sin sacrificar valor core
- ✅ CTA constante mejora conversión
- ✅ Escalable según métricas

**Alternativa rápida:** Si necesitas MVP rápido, implementar **Opción 2** (Forzar) temporalmente y luego evolucionar a Opción 3.

