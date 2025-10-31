# 📱 Plan de Loading States - ReNomada

**Objetivo:** Definir estrategia de loading states para mejorar UX en cada pantalla principal

**Pantallas a optimizar:**
1. Listado de Chats
2. Listado de Items (Mis Items)
3. Feed

---

## 📋 Tabla de Contenidos

1. [Estrategia General](#1-estrategia-general)
2. [Listado de Chats](#2-listado-de-chats)
3. [Listado de Items](#3-listado-de-items)
4. [Feed](#4-feed)
5. [Implementación](#5-implementación)

---

## 1. Estrategia General

### Principios:

1. **Feedback Inmediato:** Mostrar loading state dentro de 100ms
2. **Optimistic Updates:** Actualizar UI antes de confirmar con servidor
3. **Skeleton Screens:** Mejor que spinners para contenido que se repite
4. **Estados Claros:** Loading, Empty, Error, Success
5. **Pull to Refresh:** Permitir refrescar manualmente

### Componentes Reutilizables:

```dart
// Loading state component
LoadingStateWidget()

// Empty state component  
EmptyStateWidget()

// Error state component
ErrorStateWidget()

// Skeleton loader
SkeletonLoader()
```

---

## 2. Listado de Chats

### 2.1 Estados Necesarios

#### Estado 1: Carga Inicial
- **Cuándo:** Primera carga de la pantalla
- **Duración esperada:** 0.5-2 segundos
- **UI:** Skeleton screens (3-5 items)

#### Estado 2: Refresh (Pull to Refresh)
- **Cuándo:** Usuario hace pull down
- **Duración esperada:** 0.5-1 segundo
- **UI:** Refresh indicator en top

#### Estado 3: Carga de Más (Scroll infinito - futuro)
- **Cuándo:** Usuario llega al final (si implementamos paginación)
- **Duración esperada:** 0.3-0.5 segundos
- **UI:** Loading indicator al final

#### Estado 4: Empty State
- **Cuándo:** No hay chats
- **UI:** Mensaje amigable + CTA

#### Estado 5: Error State
- **Cuándo:** Error al cargar
- **UI:** Mensaje de error + botón retry

### 2.2 Diseño de Skeleton

```
┌─────────────────────────────────┐
│ ┌───┐  ┌──────────────┐        │
│ │ ○ │  │ ▓▓▓▓▓▓▓▓    │        │  ← Avatar + Username
│ └───┘  │ ▓▓▓▓         │        │     placeholder
│        └──────────────┘        │
│        ┌──────────────┐        │
│        │ ▓▓▓▓▓▓▓▓▓▓▓▓│        │  ← Last message
│        └──────────────┘        │     placeholder
│        ┌──┐   ┌─────┐          │
│        │▓▓│   │▓▓▓▓▓│          │  ← Badge + Time
│        └──┘   └─────┘          │     placeholder
└─────────────────────────────────┘
```

**Implementación:**
```dart
Widget _buildChatSkeleton() {
  return Container(
    padding: EdgeInsets.all(16.w),
    child: Row(
      children: [
        // Avatar skeleton
        Skeleton.circle(
          width: 56.w,
          height: 56.w,
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton.rectangular(
                width: double.infinity,
                height: 16.h,
              ),
              SizedBox(height: 8.h),
              Skeleton.rectangular(
                width: 200.w,
                height: 14.h,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

### 2.3 Flujo Completo

```
Pantalla se abre
    ↓
Mostrar skeleton (instantáneo)
    ↓
Cargar chats desde Supabase
    ↓
Actualizar UI con datos reales
    ↓
Si hay error → Mostrar error state
Si está vacío → Mostrar empty state
Si tiene datos → Mostrar lista
```

---

## 3. Listado de Items

### 3.1 Estados Necesarios

#### Estado 1: Carga Inicial
- **Cuándo:** Primera carga de "Mis Items"
- **Duración esperada:** 0.5-2 segundos
- **UI:** Grid skeleton (2 columnas, 3-4 rows)

#### Estado 2: Refresh
- **Cuándo:** Pull to refresh
- **Duración esperada:** 0.5-1 segundo
- **UI:** Refresh indicator

#### Estado 3: Carga de Foto Individual
- **Cuándo:** Foto aún no cargada
- **Duración esperada:** 0.2-1 segundo
- **UI:** Placeholder con shimmer en cada item

#### Estado 4: Empty State
- **Cuándo:** Usuario no tiene items
- **UI:** Mensaje + botón "Crear primer item"

#### Estado 5: Error State
- **Cuándo:** Error al cargar
- **UI:** Error + retry

### 3.2 Diseño de Skeleton

```
┌───────────┬───────────┐
│ ┌───────┐ │ ┌───────┐ │
│ │ ▓▓▓▓▓ │ │ │ ▓▓▓▓▓ │ │  ← Image placeholder
│ │ ▓▓▓▓▓ │ │ │ ▓▓▓▓▓ │ │
│ └───────┘ │ └───────┘ │
│ ┌───────┐ │ ┌───────┐ │
│ │ ▓▓▓▓▓ │ │ │ ▓▓▓▓▓ │ │  ← Title
│ │ ▓▓▓   │ │ │ ▓▓▓   │ │  ← Description
│ └───────┘ │ └───────┘ │
└───────────┴───────────┘
```

### 3.3 Optimizaciones

**Lazy Loading de Imágenes:**
- Cargar imágenes visibles primero
- Pre-cargar siguientes 2-3 items
- Placeholder mientras carga

**Cache de URLs Firmadas:**
- Cachear signed URLs por 1 hora
- Reutilizar para evitar N+1 queries

---

## 4. Feed

### 4.1 Estados Necesarios

#### Estado 1: Carga Inicial
- **Cuándo:** Usuario abre feed por primera vez
- **Duración esperada:** 1-3 segundos (más lento por geolocalización)
- **UI:** Skeleton de card de item (1-2 items)

#### Estado 2: Carga por Cambio de Radio
- **Cuándo:** Usuario cambia el radio del filtro
- **Duración esperada:** 1-2 segundos
- **UI:** Loading overlay en cards existentes + nuevo skeleton

#### Estado 3: Carga de Siguiente Item
- **Cuándo:** Usuario hace swipe y hay más items
- **Duración esperada:** 0.5-1 segundo
- **UI:** Skeleton del siguiente item (pre-cargar)

#### Estado 4: Empty State (Sin Items)
- **Cuándo:** No hay items en el radio seleccionado
- **UI:** Mensaje + sugerencia aumentar radio

#### Estado 5: Empty State (Sin Permisos)
- **Cuándo:** Usuario no dio permisos de ubicación
- **UI:** Mensaje + botón para dar permisos

#### Estado 6: Error State
- **Cuándo:** Error al cargar feed
- **UI:** Error + retry

### 4.2 Diseño de Skeleton

```
┌─────────────────────────────────┐
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ │      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓        │ │  ← Image
│ │      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓        │ │     placeholder
│ │                             │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓          │ │  ← Title
│ │ ▓▓▓▓▓▓▓▓                   │ │  ← Description
│ │                             │ │
│ │ ┌──┐  ┌──┐  ┌────┐        │ │  ← Badges
│ │ │▓▓│  │▓▓│  │▓▓▓▓│        │ │
│ │ └──┘  └──┘  └────┘        │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### 4.3 Optimizaciones Específicas

**Pre-carga Inteligente:**
```dart
// Pre-cargar siguiente item mientras usuario ve el actual
void _preloadNextItem() {
  if (_currentIndex < _feedItems.length - 1) {
    final nextItem = _feedItems[_currentIndex + 1];
    _preloadItemImages(nextItem);
  }
}
```

**Cache de Feed:**
- Guardar feed en cache local (SharedPreferences/Hive)
- Mostrar cache mientras carga nuevo
- Actualizar cuando lleguen datos frescos

**Lazy Loading de Imágenes:**
- Cargar imagen del item actual primero
- Pre-cargar siguiente item en background
- Mostrar placeholder mientras carga

---

## 5. Implementación

### 5.1 Dependencia para Skeleton

**Archivo:** `pubspec.yaml`

```yaml
dependencies:
  shimmer: ^3.0.0  # Para skeleton loaders
```

### 5.2 Componente Base de Skeleton

**Archivo:** `lib/shared/widgets/skeleton_loader.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? child;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surfaceContainer,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius ?? BorderRadius.circular(8.r),
        ),
        child: child,
      ),
    );
  }

  // Factory constructors para casos comunes
  factory SkeletonLoader.circle({
    required double width,
    required double height,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(width / 2),
    );
  }

  factory SkeletonLoader.rectangular({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}
```

### 5.3 Skeleton para Chat List

**Archivo:** `lib/features/chat/widgets/chat_list_skeleton.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class ChatListSkeleton extends StatelessWidget {
  final int itemCount;

  const ChatListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              // Avatar skeleton
              SkeletonLoader.circle(
                width: 56.w,
                height: 56.w,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader.rectangular(
                      width: 150.w,
                      height: 16.h,
                    ),
                    SizedBox(height: 8.h),
                    SkeletonLoader.rectangular(
                      width: 200.w,
                      height: 14.h,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SkeletonLoader.rectangular(
                    width: 40.w,
                    height: 20.h,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  SizedBox(height: 4.h),
                  SkeletonLoader.rectangular(
                    width: 50.w,
                    height: 12.h,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 5.4 Skeleton para Item Grid

**Archivo:** `lib/features/items/widgets/item_grid_skeleton.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class ItemGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ItemGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.75,
      ),
      padding: EdgeInsets.all(16.w),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            Expanded(
              child: SkeletonLoader.rectangular(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            SizedBox(height: 8.h),
            // Title skeleton
            SkeletonLoader.rectangular(
              width: double.infinity,
              height: 16.h,
              borderRadius: BorderRadius.circular(4.r),
            ),
            SizedBox(height: 4.h),
            // Description skeleton
            SkeletonLoader.rectangular(
              width: 120.w,
              height: 14.h,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ],
        );
      },
    );
  }
}
```

### 5.5 Skeleton para Feed Card

**Archivo:** `lib/features/feed/widgets/feed_card_skeleton.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class FeedCardSkeleton extends StatelessWidget {
  const FeedCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          SkeletonLoader.rectangular(
            width: double.infinity,
            height: 300.h,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                SkeletonLoader.rectangular(
                  width: 250.w,
                  height: 20.h,
                ),
                SizedBox(height: 8.h),
                // Description skeleton
                SkeletonLoader.rectangular(
                  width: double.infinity,
                  height: 16.h,
                ),
                SizedBox(height: 4.h),
                SkeletonLoader.rectangular(
                  width: 180.w,
                  height: 16.h,
                ),
                SizedBox(height: 16.h),
                // Badges skeleton
                Row(
                  children: [
                    SkeletonLoader.rectangular(
                      width: 80.w,
                      height: 24.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    SizedBox(width: 8.w),
                    SkeletonLoader.rectangular(
                      width: 100.w,
                      height: 24.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 5.6 Integración en Pantallas

**Ejemplo: ChatListScreen**

```dart
class ChatListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);

    if (chatState.isLoading && chatState.chats.isEmpty) {
      // Primera carga - mostrar skeleton
      return ChatListSkeleton();
    }

    if (chatState.hasError) {
      return ErrorStateWidget(
        error: chatState.error!,
        onRetry: () => ref.read(chatProvider.notifier).loadChats(),
      );
    }

    if (chatState.chats.isEmpty) {
      return EmptyStateWidget(
        message: 'No tienes chats aún',
        icon: Icons.chat_bubble_outline,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(chatProvider.notifier).loadChats(),
      child: ListView.builder(
        itemCount: chatState.chats.length,
        itemBuilder: (context, index) {
          return ChatCard(chat: chatState.chats[index]);
        },
      ),
    );
  }
}
```

---

## ✅ Checklist de Implementación

### Componentes Base:
- [ ] `SkeletonLoader` widget creado
- [ ] Dependencia `shimmer` agregada
- [ ] `EmptyStateWidget` mejorado
- [ ] `ErrorStateWidget` mejorado

### Chat List:
- [ ] `ChatListSkeleton` creado
- [ ] Integrado en `ChatListScreen`
- [ ] Pull to refresh implementado
- [ ] Empty state implementado
- [ ] Error state implementado

### Items List:
- [ ] `ItemGridSkeleton` creado
- [ ] Integrado en `MyItemsScreen`
- [ ] Lazy loading de imágenes
- [ ] Cache de signed URLs
- [ ] Empty state con CTA
- [ ] Error state implementado

### Feed:
- [ ] `FeedCardSkeleton` creado
- [ ] Integrado en `FeedScreen`
- [ ] Pre-carga de siguiente item
- [ ] Cache de feed local
- [ ] Loading al cambiar radio
- [ ] Empty states (sin items, sin permisos)
- [ ] Error state implementado

---

## 📊 Métricas de Mejora Esperadas

### Antes (sin skeleton):
- Percepción de lentitud: Alta
- Abandono durante carga: 15-20%
- Satisfacción UX: 6/10

### Después (con skeleton):
- Percepción de velocidad: Alta (feedback inmediato)
- Abandono durante carga: 5-10%
- Satisfacción UX: 8-9/10

---

## 🎯 Próximos Pasos

1. **Implementar skeleton loaders básicos**
2. **Integrar en cada pantalla**
3. **Testing de UX**
4. **Optimizar tiempos de carga** (cache, pre-loading)
5. **A/B testing** si es necesario

---

**Fecha de creación:** 2025  
**Versión:** 1.0  
**Estado:** ✅ Listo para implementación

