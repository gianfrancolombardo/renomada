# 🔧 Aplicar Fix de RLS - Instrucciones Rápidas

## ⚠️ Problema Actual
Los usuarios no pueden ver los chats después de hacer like porque las políticas RLS son demasiado restrictivas.

## ✅ Solución

### Paso 1: Ir a Supabase SQL Editor
1. Abre tu proyecto en Supabase
2. Ve a **SQL Editor**
3. Crea un nuevo query

### Paso 2: Ejecutar la Migración
Copia y pega el contenido del archivo:
```
docs/migrations/fix_rls_chats_and_items.sql
```

### Paso 3: Ejecutar
Presiona **Run** o `Ctrl+Enter`

### Paso 4: Verificar
Deberías ver mensajes de éxito:
```
Success. No rows returned
```

## 🎯 Lo Que Se Arregla

### ✅ Tabla `items`
- Participantes del chat pueden ver el item
- Se mantiene la privacidad (solo participantes)

### ✅ Tabla `chats`
- Agregada política de UPDATE
- Participantes pueden actualizar status

### ✅ Tabla `profiles`
- Puedes ver perfiles de usuarios con los que chateas
- Necesario para mostrar avatar y nombre

## 🧪 Prueba Rápida

Después de aplicar:
1. Haz like en un item del feed
2. Deberías ir automáticamente al chat
3. El header debe mostrar:
   - Avatar del otro usuario
   - Nombre del usuario
   - Título del item
4. No debe aparecer el log de "POSIBLE PROBLEMA DE RLS"

## 🆘 Si Algo Sale Mal

La migración usa `drop policy if exists`, así que es seguro ejecutarla múltiples veces.

Si tienes problemas:
1. Verifica que las tablas `chats`, `items`, `profiles` existen
2. Verifica que RLS está habilitado: `alter table X enable row level security;`
3. Revisa los logs en la app para ver si el problema persiste

## 📝 Notas

- **Seguro:** No borra datos, solo modifica políticas
- **Reversible:** Puedes revertir ejecutando las políticas antiguas
- **Performance:** Las políticas usan índices existentes, no afecta performance

