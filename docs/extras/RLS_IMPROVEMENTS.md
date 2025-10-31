# Mejoras de RLS (Row Level Security) - ReNomada

## Problema Detectado

El sistema de logs detectó que los chats se creaban correctamente en la base de datos, pero no eran accesibles para los usuarios debido a configuraciones restrictivas de RLS.

**Síntomas:**
- Chat creado exitosamente en BD
- Usuario no puede ver el chat después de hacer like
- Log: "POSIBLE PROBLEMA DE RLS: El chat existe en la BD pero no es accesible"

## Problemas Identificados

### 1. **Tabla `items` - Demasiado Restrictiva**
**Antes:** Solo el owner podía ver sus items
```sql
-- ❌ PROBLEMA: Chat participants no pueden ver el item
create policy items_owner_all
  on public.items for all
  using (auth.uid() = owner_id);
```

**Después:** Chat participants pueden ver items de sus chats
```sql
-- ✅ SOLUCIÓN: Participantes del chat pueden ver el item
create policy items_chat_participants_select
  on public.items for select
  using (
    auth.uid() = owner_id  -- Owner puede ver
    or
    exists (  -- Participante de chat puede ver
      select 1 from public.chats c
      where c.item_id = items.id
        and (auth.uid() = c.a_user_id or auth.uid() = c.b_user_id)
    )
  );
```

### 2. **Tabla `chats` - Faltaba UPDATE**
**Antes:** Solo SELECT e INSERT, no UPDATE
```sql
-- ❌ PROBLEMA: No se puede actualizar status del chat
create policy chats_participants_select ...
create policy chats_participants_insert ...
-- Falta política de UPDATE
```

**Después:** Agregada política de UPDATE
```sql
-- ✅ SOLUCIÓN: Participantes pueden actualizar el chat
create policy chats_participants_update
  on public.chats for update
  using (auth.uid() = a_user_id or auth.uid() = b_user_id)
  with check (auth.uid() = a_user_id or auth.uid() = b_user_id);
```

### 3. **Tabla `profiles` - Solo Self-Access**
**Antes:** Solo podías ver tu propio perfil
```sql
-- ❌ PROBLEMA: No puedes ver el perfil del otro usuario en el chat
create policy profiles_self_select
  on public.profiles for select
  using (auth.uid() = user_id);
```

**Después:** Puedes ver perfiles de usuarios con los que chateas
```sql
-- ✅ SOLUCIÓN: Puedes ver perfiles de usuarios con los que chateas
create policy profiles_chat_participants_select
  on public.profiles for select
  using (
    auth.uid() = user_id  -- Tu propio perfil
    or
    exists (  -- Perfiles de personas con las que chateas
      select 1 from public.chats c
      where (c.a_user_id = auth.uid() and c.b_user_id = profiles.user_id)
         or (c.b_user_id = auth.uid() and c.a_user_id = profiles.user_id)
    )
  );
```

## Aplicar las Mejoras

### Opción 1: Migración Específica (Recomendado para producción)
```sql
-- Ejecutar en Supabase SQL Editor:
-- Archivo: docs/migrations/fix_rls_chats_and_items.sql
```

### Opción 2: Setup Completo (Para nuevas instalaciones)
```sql
-- Ejecutar en Supabase SQL Editor:
-- Archivo: docs/database_setup.sql
```

## Verificación

Después de aplicar las mejoras, verifica que:

1. **Chats accesibles:** Los usuarios pueden ver chats después de hacer like
2. **Items visibles:** En el header del chat se muestra el título del item
3. **Perfiles visibles:** Se muestra el avatar y nombre del otro usuario
4. **Sin logs de RLS:** No aparece el log "POSIBLE PROBLEMA DE RLS"

## Beneficios

✅ **Seguridad mantenida:** Solo chat participants pueden ver items relacionados  
✅ **Privacidad:** No expones items a usuarios no relacionados  
✅ **Funcionalidad completa:** Chats funcionan correctamente  
✅ **Performance:** Políticas optimizadas con índices apropiados  

## Debugging Futuro

Si vuelve a aparecer un problema de RLS, los logs te indicarán:

```
❌ [ChatService] Chat not found for chatId: xxx
⚠️ [ChatService] POSIBLE PROBLEMA DE RLS: El chat existe en la BD pero no es accesible
⚠️ [ChatService] Chat ID: xxx, User ID: yyy
```

Esto te permite identificar rápidamente si es un problema de RLS (chat existe pero no accesible) vs un problema de creación (chat no existe).

## Principios de RLS en ReNomada

1. **Privacidad por defecto:** Nada es visible a menos que se especifique
2. **Acceso contextual:** Los usuarios ven datos cuando hay una relación válida (chat, ownership)
3. **Mínimo privilegio:** Solo el acceso necesario para la funcionalidad
4. **Debugging habilitado:** Funciones helper con `security definer` para diagnóstico

