# Fix: Missing owner_id in Chat Query

## Problema
Después de aplicar el fix de RLS, el chat se encontraba correctamente pero fallaba al parsear los datos del item:

```
✅ [ChatService] Chat data received: xxx
Error: null: type 'Null' is not a subtype of type 'String'
```

## Causa
El query para obtener el chat con los detalles del item no incluía el campo `owner_id`:

```sql
-- ❌ PROBLEMA: Falta owner_id
items!inner(
  id,
  title,
  description,
  status,
  created_at,
  updated_at
)
```

Cuando `Item.fromJson()` intentaba acceder a `owner_id`, el campo no existía y causaba el error de tipo null.

## Solución
Agregado `owner_id` al SELECT del query:

```sql
-- ✅ SOLUCIÓN: owner_id incluido
items!inner(
  id,
  owner_id,  -- ← Agregado
  title,
  description,
  status,
  created_at,
  updated_at
)
```

## Archivo Modificado
- `lib/shared/services/chat_service.dart` - Línea ~194

## Verificación
Después del fix, deberías ver:
```
✅ [ChatService] Chat data received: xxx
📦 [ChatService] Item: Nombre del item
👤 [ChatService] Getting profile for other user: yyy
✅ Chat cargado correctamente
```

## Lección Aprendida
Al hacer JOIN en Supabase, asegúrate de incluir TODOS los campos requeridos por el modelo, no solo los que necesitas mostrar en la UI. Los modelos pueden tener campos obligatorios que no son obvios a primera vista.

