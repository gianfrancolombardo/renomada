# Aplicar Correcciones RLS para Imágenes en Chat

## Problema Identificado

Las imágenes de items no se muestran en el componente `ChatItemCard` porque las políticas RLS de `item_photos` tienen conflictos que impiden el acceso legítimo de los participantes del chat a las fotos del item.

## Políticas Problemáticas

1. **Conflicto en `item_photos`**: 
   - `item_photos_owner_likers_and_chat_participants` (permite acceso amplio)
   - `item_photos_owner_select` (solo owner - más restrictiva)
   - La política más restrictiva sobrescribe la permisiva

2. **Storage policies**: Algunas políticas pueden ser demasiado restrictivas

## Solución

### Paso 1: Aplicar la Corrección Principal

Ejecutar en el SQL Editor de Supabase:

```sql
-- Ejecutar el contenido completo de fix_item_photos_rls_for_chat.sql
```

Este script:
- ✅ Elimina políticas conflictivas
- ✅ Crea políticas unificadas y seguras
- ✅ Permite acceso a owners, likers y chat participants
- ✅ Mantiene seguridad con principio de mínimo privilegio

### Paso 2: Limpiar Políticas Innecesarias (Opcional)

```sql
-- Ejecutar el contenido completo de cleanup_conflicting_rls_policies.sql
```

Este script:
- ✅ Elimina políticas redundantes
- ✅ Añade comentarios explicativos
- ✅ Crea funciones de debug para desarrollo

## Verificación

### 1. Probar Acceso a Fotos en Chat

```sql
-- Verificar que los participantes del chat pueden acceder a las fotos
SELECT 
  c.id as chat_id,
  i.title as item_title,
  ip.path as photo_path,
  can_access_item_photos(i.id, auth.uid()) as can_access
FROM chats c
JOIN items i ON i.id = c.item_id
JOIN item_photos ip ON ip.item_id = i.id
WHERE (c.a_user_id = auth.uid() OR c.b_user_id = auth.uid())
LIMIT 5;
```

### 2. Probar Función de Debug

```sql
-- Probar con un item específico (reemplazar 'item-uuid' con un ID real)
SELECT * FROM test_item_photos_rls('item-uuid');
```

### 3. Verificar en la App

1. Crear un item con fotos
2. Hacer "like" al item desde otra cuenta
3. Abrir el chat
4. Verificar que la imagen se muestra en `ChatItemCard`

## Políticas RLS Finales (Resumen)

### item_photos
- **SELECT**: Owners + Likers + Chat participants
- **INSERT/UPDATE/DELETE**: Solo owners
- **Storage**: Lectura pública (signed URLs) + Upload/Delete solo owners

### items  
- **SELECT**: Owners + Chat participants
- **INSERT/UPDATE/DELETE**: Solo owners

### chats
- **SELECT/INSERT/UPDATE**: Solo participants

### messages
- **SELECT/INSERT/UPDATE**: Solo participants del chat

### profiles
- **SELECT/UPDATE**: Solo el propio usuario

### interactions
- **ALL**: Solo el propio usuario

## Seguridad Mantenida

✅ **Principio de mínimo privilegio**: Cada usuario solo accede a lo necesario
✅ **No enumeración**: No se puede listar datos de otros usuarios
✅ **Chat isolation**: Solo participantes pueden ver mensajes
✅ **Photo access control**: Solo acceso legítimo a fotos
✅ **Owner protection**: Solo owners pueden modificar sus datos

## Troubleshooting

### Si las imágenes siguen sin aparecer:

1. **Verificar RLS está habilitado**:
   ```sql
   SELECT schemaname, tablename, rowsecurity 
   FROM pg_tables 
   WHERE tablename IN ('item_photos', 'items', 'chats');
   ```

2. **Verificar políticas activas**:
   ```sql
   SELECT policyname, cmd, roles, qual 
   FROM pg_policies 
   WHERE tablename = 'item_photos';
   ```

3. **Probar acceso directo**:
   ```sql
   -- Como usuario autenticado, probar acceso a fotos
   SELECT * FROM item_photos WHERE item_id = 'item-uuid';
   ```

4. **Verificar logs de la app**: Revisar los logs de `ChatService.getChatWithDetails()` para ver errores específicos.

### Si hay problemas de permisos:

1. Verificar que el usuario está autenticado
2. Verificar que el usuario es participante del chat
3. Verificar que el item existe y está activo
4. Verificar que las fotos existen en storage

## Notas de Desarrollo

- Las funciones `can_access_item_photos()` y `test_item_photos_rls()` son útiles para debugging
- El view `item_photos_access_debug` ayuda a entender patrones de acceso
- Mantener estos scripts para futuras migraciones y troubleshooting