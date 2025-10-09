# 🎯 Implementación: Onboarding + Estado de Item desde Chat

**Tareas pendientes críticas para UX**  
**Tiempo estimado total:** 5-7 horas

---

## 📋 Tabla de Contenidos

1. [Onboarding Primera Vez](#1-onboarding-primera-vez)
2. [Estado de Item desde Chat](#2-estado-de-item-desde-chat)
3. [Testing](#3-testing)

---

## 1. Onboarding Primera Vez

### 1.1 Objetivo

Mostrar un diálogo/pantalla al primer login que explique las 2 funcionalidades centrales y permita al usuario elegir qué hacer:
- 🔍 **Explorar** items cercanos
- 📦 **Publicar** un item

### 1.2 Migración de Base de Datos

Primero, añadimos el flag a la tabla `profiles`:

**SQL a ejecutar en Supabase:**

```sql
-- Añadir columna para trackear si vio onboarding
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS has_seen_onboarding boolean DEFAULT false;

-- Actualizar usuarios existentes para que NO vean onboarding
-- (solo nuevos usuarios lo verán)
UPDATE public.profiles 
SET has_seen_onboarding = true 
WHERE has_seen_onboarding IS NULL;
```

### 1.3 Actualizar Modelo de UserProfile

**lib/shared/models/user_profile.dart**

```dart
class UserProfile {
  final String userId;
  final String? username;
  final String? avatarUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSeenAt;
  final bool isLocationOptOut;
  final bool hasSeenOnboarding; // NUEVO

  UserProfile({
    required this.userId,
    this.username,
    this.avatarUrl,
    this.latitude,
    this.longitude,
    this.lastSeenAt,
    this.isLocationOptOut = false,
    this.hasSeenOnboarding = false, // NUEVO
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      isLocationOptOut: json['is_location_opt_out'] as bool? ?? false,
      hasSeenOnboarding: json['has_seen_onboarding'] as bool? ?? false, // NUEVO
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'latitude': latitude,
      'longitude': longitude,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'is_location_opt_out': isLocationOptOut,
      'has_seen_onboarding': hasSeenOnboarding, // NUEVO
    };
  }

  UserProfile copyWith({
    String? userId,
    String? username,
    String? avatarUrl,
    double? latitude,
    double? longitude,
    DateTime? lastSeenAt,
    bool? isLocationOptOut,
    bool? hasSeenOnboarding, // NUEVO
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isLocationOptOut: isLocationOptOut ?? this.isLocationOptOut,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding, // NUEVO
    );
  }
}
```

### 1.4 Actualizar ProfileService

**lib/shared/services/profile_service.dart**

Añadir método para marcar onboarding como visto:

```dart
class ProfileService {
  // ... métodos existentes ...

  /// Mark onboarding as seen
  Future<void> markOnboardingAsSeen() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      await _supabase
          .from('profiles')
          .update({'has_seen_onboarding': true})
          .eq('user_id', userId);

      print('✅ Onboarding marked as seen');
    } catch (e) {
      print('❌ Error marking onboarding as seen: $e');
      rethrow;
    }
  }
}
```

### 1.5 Crear Widget de Onboarding

**lib/features/auth/widgets/onboarding_dialog.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OnboardingDialog extends StatelessWidget {
  final VoidCallback onExplore;
  final VoidCallback onPublish;
  final VoidCallback onSkip;

  const OnboardingDialog({
    super.key,
    required this.onExplore,
    required this.onPublish,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        constraints: BoxConstraints(maxWidth: 400.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon/Logo
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.sparkles,
                size: 40.sp,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Title
            Text(
              '¡Bienvenido a ReNomada!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12.h),
            
            // Subtitle
            Text(
              'Dale una segunda vida a tus cosas y descubre tesoros cerca de ti',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 32.h),
            
            // Features
            _FeatureRow(
              icon: LucideIcons.search,
              title: 'Explora',
              description: 'Descubre items cerca de ti',
              color: Colors.blue,
            ),
            
            SizedBox(height: 16.h),
            
            _FeatureRow(
              icon: LucideIcons.package,
              title: 'Publica',
              description: 'Comparte lo que no usas',
              color: Colors.green,
            ),
            
            SizedBox(height: 32.h),
            
            // Question
            Text(
              '¿Qué quieres hacer ahora?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Explore Button
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton.icon(
                onPressed: onExplore,
                icon: Icon(LucideIcons.search, size: 20.sp),
                label: Text(
                  'Explorar Feed',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            
            SizedBox(height: 12.h),
            
            // Publish Button
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: OutlinedButton.icon(
                onPressed: onPublish,
                icon: Icon(LucideIcons.package, size: 20.sp),
                label: Text(
                  'Publicar Item',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Skip Button
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Saltar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            size: 24.sp,
            color: color,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

### 1.6 Integrar en HomeScreen

**lib/features/home/screens/home_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/widgets/onboarding_dialog.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../shared/services/profile_service.dart';
import '../../items/widgets/create_item_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    // Check if should show onboarding after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  Future<void> _checkOnboarding() async {
    final profileState = ref.read(profileProvider);
    
    // Si no ha visto onboarding, mostrar dialog
    if (profileState.profile != null && 
        !profileState.profile!.hasSeenOnboarding) {
      _showOnboardingDialog();
    }
  }

  void _showOnboardingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // No cerrar tocando fuera
      builder: (context) => OnboardingDialog(
        onExplore: () async {
          await _markOnboardingSeen();
          if (mounted) {
            Navigator.pop(context);
            // Navegar al tab de feed (index 0)
            _navigateToTab(0);
          }
        },
        onPublish: () async {
          await _markOnboardingSeen();
          if (mounted) {
            Navigator.pop(context);
            // Mostrar bottom sheet de crear item
            _showCreateItemSheet();
          }
        },
        onSkip: () async {
          await _markOnboardingSeen();
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Future<void> _markOnboardingSeen() async {
    try {
      await _profileService.markOnboardingAsSeen();
      // Actualizar el estado en el provider
      ref.read(profileProvider.notifier).refreshProfile();
    } catch (e) {
      print('Error marking onboarding as seen: $e');
    }
  }

  void _navigateToTab(int index) {
    // Implementar navegación a tab específico
    // Esto depende de cómo tengas implementado tu bottom navigation
    // Ejemplo:
    setState(() {
      _currentIndex = index;
    });
  }

  void _showCreateItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateItemBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... resto de tu implementación de HomeScreen ...
  }
}
```

---

## 2. Estado de Item desde Chat

### 2.1 Diseño UX (Opción Recomendada)

**Header del Chat con Menú de Opciones:**

```
┌────────────────────────────────┐
│ ← [Avatar] Bicicleta MTB    ⋮ │ <- Tap para abrir menú
├────────────────────────────────┤
│                                │
│  Mensajes del chat...          │
│                                │
```

**Menú desplegable:**
- ✅ Marcar como intercambiado
- ⏸️ Pausar conversación
- 📋 Ver detalles del item
- 🚫 Reportar (futuro)

### 2.2 Actualizar ChatHeader Widget

**lib/features/chat/widgets/chat_header.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/models/chat_with_details.dart';
import '../../../shared/widgets/avatar_image.dart';
import '../../items/screens/item_detail_screen.dart';

class ChatHeader extends StatelessWidget {
  final ChatWithDetails chat;
  final VoidCallback onMarkAsExchanged;
  final VoidCallback onPauseConversation;
  final bool isItemOwner;

  const ChatHeader({
    super.key,
    required this.chat,
    required this.onMarkAsExchanged,
    required this.onPauseConversation,
    required this.isItemOwner,
  });

  @override
  Widget build(BuildContext context) {
    final otherUser = chat.otherUser;
    final item = chat.item;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(LucideIcons.chevronLeft),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
          
          SizedBox(width: 12.w),
          
          // Avatar
          AvatarImage(
            avatarUrl: otherUser.avatarUrl,
            username: otherUser.username ?? 'Usuario',
            size: 40.w,
          ),
          
          SizedBox(width: 12.w),
          
          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Con ${otherUser.username ?? 'Usuario'}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Menu button
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.moreVertical),
            onSelected: (value) {
              switch (value) {
                case 'mark_exchanged':
                  _showMarkAsExchangedDialog(context);
                  break;
                case 'pause':
                  _showPauseDialog(context);
                  break;
                case 'details':
                  _showItemDetails(context);
                  break;
                case 'report':
                  // TODO: Implementar reportar
                  break;
              }
            },
            itemBuilder: (context) => [
              // Solo mostrar si es el owner del item y el item está available
              if (isItemOwner && item.status == 'available')
                PopupMenuItem(
                  value: 'mark_exchanged',
                  child: Row(
                    children: [
                      Icon(LucideIcons.checkCircle, size: 20.sp, color: Colors.green),
                      SizedBox(width: 12.w),
                      Text('Marcar como intercambiado'),
                    ],
                  ),
                ),
              
              PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(LucideIcons.info, size: 20.sp),
                    SizedBox(width: 12.w),
                    Text('Ver detalles del item'),
                  ],
                ),
              ),
              
              PopupMenuItem(
                value: 'pause',
                child: Row(
                  children: [
                    Icon(LucideIcons.pause, size: 20.sp),
                    SizedBox(width: 12.w),
                    Text('Pausar conversación'),
                  ],
                ),
              ),
              
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(LucideIcons.flag, size: 20.sp, color: Colors.red),
                    SizedBox(width: 12.w),
                    Text('Reportar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMarkAsExchangedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Marcar como intercambiado'),
        content: Text(
          '¿Estás seguro que quieres marcar "${chat.item.title}" como intercambiado? '
          'Esta acción notificará al otro usuario y cerrará la conversación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onMarkAsExchanged();
            },
            child: Text('Marcar como intercambiado'),
          ),
        ],
      ),
    );
  }

  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pausar conversación'),
        content: Text(
          '¿Quieres pausar esta conversación? Podrás reactivarla más tarde.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onPauseConversation();
            },
            child: Text('Pausar'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(itemId: chat.item.id),
      ),
    );
  }
}
```

### 2.3 Actualizar ItemService

**lib/shared/services/item_service.dart**

```dart
class ItemService {
  // ... métodos existentes ...

  /// Mark item as exchanged from chat
  Future<void> markAsExchanged({
    required String itemId,
    required String chatId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // 1. Verificar que el usuario es el owner del item
      final itemResponse = await _supabase
          .from('items')
          .select('owner_id')
          .eq('id', itemId)
          .single();

      if (itemResponse['owner_id'] != userId) {
        throw Exception('Only item owner can mark as exchanged');
      }

      // 2. Actualizar status del item
      await _supabase
          .from('items')
          .update({
            'status': 'exchanged',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', itemId);

      // 3. Insertar mensaje de sistema en el chat
      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': userId,
        'content': '📦 Item marcado como intercambiado',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Item marked as exchanged');
    } catch (e) {
      print('❌ Error marking item as exchanged: $e');
      rethrow;
    }
  }
}
```

### 2.4 Actualizar ChatScreen

**lib/features/chat/screens/chat_screen.dart**

```dart
import '../../../shared/services/item_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({
    super.key,
    required this.chatId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _itemService = ItemService();
  bool _isMarking = false;

  // ... resto del código ...

  Future<void> _handleMarkAsExchanged(ChatWithDetails chat) async {
    setState(() => _isMarking = true);

    try {
      await _itemService.markAsExchanged(
        itemId: chat.item.id,
        chatId: widget.chatId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item marcado como intercambiado'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh chat para mostrar mensaje de sistema
        ref.read(messagesProvider(widget.chatId).notifier).loadMessages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMarking = false);
      }
    }
  }

  void _handlePauseConversation() {
    // TODO: Implementar pausar conversación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Función en desarrollo')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatDetailsProvider(widget.chatId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header con menú
            if (chatState.chat != null)
              ChatHeader(
                chat: chatState.chat!,
                isItemOwner: chatState.chat!.item.ownerId == 
                            _supabase.auth.currentUser?.id,
                onMarkAsExchanged: () => _handleMarkAsExchanged(chatState.chat!),
                onPauseConversation: _handlePauseConversation,
              ),
            
            // Messages list
            Expanded(
              child: _buildMessagesList(),
            ),
            
            // Input (deshabilitar si item está exchanged)
            if (chatState.chat?.item.status != 'exchanged')
              ChatInput(
                onSend: _handleSendMessage,
                enabled: !_isMarking,
              )
            else
              _buildExchangedBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangedBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(
          top: BorderSide(color: Colors.green.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.checkCircle,
            color: Colors.green,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            'Item intercambiado - Conversación cerrada',
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 3. Testing

### 3.1 Testing Onboarding

**Checklist:**

- [x] Onboarding aparece al primer login (solo usuarios nuevos) ✅ COMPLETADO
- [x] Botón "Explorar" navega al feed ✅ COMPLETADO
- [x] Botón "Publicar" navega a my-items ✅ COMPLETADO
- [x] `has_seen_onboarding` se actualiza a `true` ✅ COMPLETADO
- [x] Onboarding NO aparece en logins posteriores ✅ COMPLETADO
- [x] Usuarios existentes NO ven el onboarding ✅ COMPLETADO

**NOTA:** Se cambió la implementación de diálogo modal a pantalla completa dedicada con mejor UX y texto amable enfocado en nómadas digitales.

**Pasos de testing:**

1. Crear nuevo usuario
2. Verificar que aparece onboarding
3. Elegir "Explorar" → verificar navega a feed
4. Logout y login → verificar NO aparece onboarding
5. Crear otro usuario nuevo
6. Elegir "Publicar" → verificar abre bottom sheet
7. Crear item → verificar funciona normal

### 3.2 Testing Estado de Item

**Checklist:**

- [ ] Menú (⋮) aparece en header del chat
- [ ] Opción "Marcar como intercambiado" solo visible para owner
- [ ] Opción solo visible si item status = 'available'
- [ ] Diálogo de confirmación aparece
- [ ] Item status cambia a 'exchanged'
- [ ] Mensaje de sistema aparece en chat
- [ ] Input se deshabilita después de marcar
- [ ] Banner de "intercambiado" aparece
- [ ] Otros chats del mismo item se actualizan

**Pasos de testing:**

1. Usuario A publica item
2. Usuario B hace like → crea chat
3. Usuario A abre chat con B
4. Tap en menú (⋮)
5. Tap "Marcar como intercambiado"
6. Confirmar en diálogo
7. Verificar:
   - Mensaje de sistema aparece
   - Input deshabilitado
   - Banner visible
8. Usuario B refresca chat
9. Verificar que ve los cambios

### 3.3 Edge Cases

**Onboarding:**
- [ ] Qué pasa si hay error al marcar como visto
- [ ] Qué pasa si usuario cierra app durante onboarding
- [ ] Múltiples dispositivos del mismo usuario

**Estado de Item:**
- [ ] Owner intenta marcar item ya exchanged
- [ ] Usuario no-owner intenta marcar item
- [ ] Error de red durante marcado
- [ ] Múltiples chats para el mismo item
- [ ] Marcar como exchanged sin internet

---

## 4. Notas de Implementación

### 4.1 Mejoras Futuras

**Onboarding:**
- Añadir animaciones suaves
- Tour guiado de la app (opcional)
- Personalización según tipo de usuario

**Estado de Item:**
- Rating del intercambio
- Feedback automático
- Notificar a otros interesados
- Estadísticas de intercambios

### 4.2 Consideraciones UX

**Onboarding:**
- Mantenerlo corto (30 segundos máximo)
- Texto claro y conciso
- Botones grandes y accesibles
- Permitir skip fácilmente

**Estado de Item:**
- Confirmación clara antes de cambiar estado
- Mensajes de sistema distinguibles
- No permitir reversar acción (o implementar "deshacer")
- Notificar claramente todos los efectos

---

## 5. Tiempo Estimado

### Onboarding:
- **Migración DB:** 5 min
- **Actualizar modelo:** 15 min
- **Actualizar service:** 15 min
- **Crear widget:** 1-1.5 horas
- **Integrar en home:** 30 min
- **Testing:** 30 min

**Subtotal:** ~2.5-3 horas

### Estado de Item:
- **Actualizar ChatHeader:** 1 hora
- **Actualizar ItemService:** 30 min
- **Actualizar ChatScreen:** 1 hora
- **Banner y estados:** 30 min
- **Testing:** 1 hora

**Subtotal:** ~4 horas

**TOTAL: 6.5-7 horas**

---

## 6. Orden de Implementación Sugerido

**Día 1 (Mañana):**
1. Onboarding completo (2.5-3h)

**Día 1 (Tarde):**
2. Estado de Item desde Chat (4h)

**Día 2:**
3. Testing exhaustivo y fixes

¡Buena suerte con la implementación! 🚀


