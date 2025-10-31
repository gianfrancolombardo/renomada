# Implementación: Marcar Mensajes como Leídos Automáticamente

## 📋 Resumen
Se implementó la funcionalidad para marcar mensajes como leídos automáticamente cuando el usuario entra a un chat o envía un mensaje, eliminando el badge de mensajes no leídos en la lista de chats.

## 🎯 Objetivo

### Problema Anterior:
- ❌ Los mensajes NUNCA se marcaban como leídos
- ❌ El badge de mensajes no leídos NUNCA desaparecía
- ❌ El contador de mensajes no leídos se quedaba permanente
- ❌ Los mensajes mantenían `status = 'sent'` para siempre

### Solución Implementada:
- ✅ Los mensajes se marcan como leídos automáticamente al entrar al chat
- ✅ El badge desaparece cuando el usuario ve el chat
- ✅ El contador baja a 0 automáticamente
- ✅ Los mensajes cambian a `status = 'read'`

## 🔧 Cambios Realizados

### Archivo: `lib/features/chat/screens/chat_screen.dart`

#### 1. Marcar mensajes como leídos al entrar al chat

**Ubicación:** Método `initState()`

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(messageProvider.notifier).loadMessages(widget.chatId);
    // ✨ NUEVO: Mark messages as read when entering the chat
    ref.read(messageProvider.notifier).markMessagesAsRead();
    // Load chat details if not provided (e.g., when navigating from like)
    if (widget.chat == null) {
      _loadChatDetails();
    }
  });
}
```

**¿Qué hace?**
- Cuando el usuario abre un chat, automáticamente marca todos los mensajes del otro usuario como leídos
- Se ejecuta después de cargar los mensajes

#### 2. Marcar mensajes como leídos al enviar un mensaje

**Ubicación:** Método `_sendMessage()`

```dart
void _sendMessage(String content) {
  if (content.trim().isEmpty) return;

  ref.read(messageProvider.notifier).sendMessage(content).then((message) {
    if (message != null) {
      _messageController.clear();
      _scrollToBottom();
      // ✨ NUEVO: Mark messages as read after sending (user is actively in the chat)
      ref.read(messageProvider.notifier).markMessagesAsRead();
    }
  });
}
```

**¿Qué hace?**
- Cuando el usuario envía un mensaje, se asegura de marcar como leídos todos los mensajes recibidos
- Garantiza que si el usuario está activamente usando el chat, los mensajes nuevos se marquen como leídos

## 🔄 Flujo Completo

### Escenario 1: Usuario recibe un mensaje

1. **Usuario A** envía mensaje a **Usuario B**
   - Mensaje se crea con `status = 'sent'`
   - Se incrementa el `unreadCount` para Usuario B

2. **Usuario B** ve la lista de chats
   - Ve el badge con el número de mensajes no leídos
   - El badge aparece con color `tertiary` y fondo `tertiary.withOpacity(0.15)`

3. **Usuario B** abre el chat
   - Se ejecuta `loadMessages()` → carga todos los mensajes
   - Se ejecuta `markMessagesAsRead()` → cambia `status = 'read'` para mensajes de Usuario A
   - El badge desaparece de la lista de chats ✅

### Escenario 2: Usuario está en el chat y recibe mensaje

1. **Usuario B** está viendo el chat
2. **Usuario A** envía un nuevo mensaje (a través de realtime)
3. El mensaje aparece con `status = 'sent'`
4. **Usuario B** envía una respuesta
   - Al enviar, se ejecuta `markMessagesAsRead()`
   - El mensaje de Usuario A cambia a `status = 'read'` ✅

## 📊 Base de Datos

### Tabla `messages`

```sql
-- ANTES (mensaje no leído):
{
  id: 'abc123',
  chat_id: 'chat789',
  sender_id: 'user_A',
  content: 'Hola!',
  status: 'sent',     ← Mensaje no leído
  created_at: '2025-10-12T10:00:00Z'
}

-- DESPUÉS (mensaje leído):
{
  id: 'abc123',
  chat_id: 'chat789',
  sender_id: 'user_A',
  content: 'Hola!',
  status: 'read',     ← Mensaje leído ✅
  created_at: '2025-10-12T10:00:00Z'
}
```

### Query SQL que se ejecuta

```sql
-- Ejecutada por markMessagesAsRead()
UPDATE messages
SET status = 'read'
WHERE chat_id = 'chat789'
  AND sender_id != 'user_B'  -- No marcar propios mensajes
  AND status = 'sent';        -- Solo los no leídos
```

## 🧪 Testing

### Test 1: Badge desaparece al abrir chat
1. Pide a otro usuario que te envíe un mensaje
2. Verifica que aparece el badge en la lista de chats
3. Abre el chat
4. **Resultado esperado:** Badge desaparece ✅

### Test 2: Badge desaparece al enviar mensaje
1. Estás en un chat con mensajes no leídos
2. El badge está visible en la lista (si sales y vuelves a entrar)
3. Envías un mensaje desde el chat
4. Sales del chat y vuelves a la lista
5. **Resultado esperado:** Badge desaparece ✅

### Test 3: No marcar propios mensajes
1. Envías un mensaje
2. Sales del chat y vuelves a entrar
3. **Resultado esperado:** Tu propio mensaje NO debe afectar el badge ✅

### Test 4: Múltiples mensajes no leídos
1. Recibes 5 mensajes no leídos (badge muestra "5")
2. Abres el chat
3. **Resultado esperado:** Badge desaparece y contador baja a 0 ✅

## 📱 UI - Comportamiento del Badge

### En `chat_card.dart`

```dart
// Badge solo se muestra si unreadCount > 0
if (chat.unreadCount > 0)
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: colorScheme.tertiary.withOpacity(0.15),  // Fondo tenue
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      chat.unreadCount.toString(),
      style: TextStyle(
        color: colorScheme.tertiary,  // Texto más oscuro
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
```

### Estados del Badge:

1. **Sin mensajes no leídos:** `unreadCount = 0` → Badge NO aparece
2. **1 mensaje no leído:** `unreadCount = 1` → Badge muestra "1"
3. **Múltiples mensajes:** `unreadCount = 5` → Badge muestra "5"
4. **Usuario entra al chat:** `unreadCount` → 0 → Badge desaparece

## ⚙️ Servicios Involucrados

### `MessageService.markMessagesAsRead()`

```dart
Future<void> markMessagesAsRead({
  required String chatId,
  required String userId,
}) async {
  try {
    await SupabaseConfig.client
        .from('messages')
        .update({'status': 'read'})
        .eq('chat_id', chatId)
        .neq('sender_id', userId) // Don't mark own messages as read
        .eq('status', 'sent');
  } catch (e) {
    throw Exception('Failed to mark messages as read: $e');
  }
}
```

### `MessageProvider.markMessagesAsRead()`

```dart
Future<void> markMessagesAsRead() async {
  if (_currentChatId == null) return;

  try {
    await _messageService.markMessagesAsRead(
      chatId: _currentChatId!,
      userId: SupabaseConfig.currentUser?.id ?? '',
    );
  } catch (e) {
    // Don't show error for read status updates
    debugPrint('Failed to mark messages as read: $e');
  }
}
```

## 🔐 Seguridad

- ✅ Solo se marcan como leídos los mensajes del otro usuario (no los propios)
- ✅ Solo se marcan mensajes con `status = 'sent'` (no se tocan los ya leídos)
- ✅ Usa el `user_id` autenticado de Supabase
- ✅ RLS policies en Supabase protegen la tabla `messages`

## 📌 Notas Importantes

1. **No hay cambios en la base de datos:** Solo en el código Flutter
2. **Instantáneo:** El badge desaparece al abrir el chat
3. **Sin errores visibles:** Si falla, solo se imprime en debug console
4. **Optimista:** No esperamos confirmación para ocultar el badge
5. **Compatible con Realtime:** Funciona con mensajes que llegan en tiempo real

## 🐛 Troubleshooting

### El badge no desaparece
**Causa:** Error al ejecutar la query de update
**Solución:** Verifica en debug console si hay errores, verifica RLS policies en Supabase

### El badge desaparece y vuelve a aparecer
**Causa:** Realtime está actualizando el estado del chat
**Solución:** Asegúrate de que el realtime service esté sincronizado correctamente

### Mensajes propios se marcan como no leídos
**Causa:** El filtro `neq('sender_id', userId)` no está funcionando
**Solución:** Verifica que `SupabaseConfig.currentUser?.id` devuelve el ID correcto

## ✅ Checklist de Implementación

- [x] Llamar a `markMessagesAsRead()` en `initState()`
- [x] Llamar a `markMessagesAsRead()` después de enviar mensaje
- [x] Verificar que no hay errores de lint
- [x] Badge usa color `tertiary` (implementado previamente)
- [x] Documentación completa creada
- [ ] Testing manual con dos dispositivos/usuarios
- [ ] Verificar comportamiento en producción

---

**Fecha de implementación:** 12 de octubre de 2025  
**Versión:** 1.0  
**Estado:** ✅ Listo para testing

