# Auditoría de Iconos y Gradientes - ReNomada

## 📋 Resumen
Este documento lista todos los archivos que necesitan ser actualizados para:
1. Usar **LucideIcons** en lugar de Material Icons
2. Usar **colores sólidos** en lugar de gradientes

## 🎯 Archivos Críticos (Alta Prioridad)

### 1. **Autenticación**
- ✅ `lib/features/auth/screens/login_screen.dart` - COMPLETADO
  - ✅ Gradiente → Sólido
  - ✅ `Icons.email_outlined` → `LucideIcons.mail`
  - ✅ `Icons.lock_outlined` → `LucideIcons.lock`
  - ✅ `Icons.visibility_*` → `LucideIcons.eye/eyeOff`

- `lib/features/auth/screens/signup_screen.dart` - PENDIENTE
  - Gradiente → Sólido (línea 117-124)
  - `Icons.person_add_outlined` → `LucideIcons.userPlus`
  - `Icons.arrow_back_ios` → `LucideIcons.arrowLeft`
  - `Icons.person_outlined` → `LucideIcons.user`
  - `Icons.email_outlined` → `LucideIcons.mail`
  - `Icons.lock_outlined` → `LucideIcons.lock`
  - `Icons.visibility_*` → `LucideIcons.eye/eyeOff`

- `lib/features/auth/screens/onboarding_screen.dart` - PENDIENTE
  - ✅ Ya usa LucideIcons
  - Gradiente → Sólido (línea 34-43)

### 2. **Navegación Principal**
- `lib/shared/widgets/bottom_navigation.dart` - COMPLETADO
  - ✅ Ya usa LucideIcons

- `lib/shared/widgets/app_header.dart` - PENDIENTE
  - ✅ Ya usa LucideIcons
  - Gradiente → Sólido (línea 36-45)

### 3. **Profile**
- `lib/features/profile/screens/profile_screen.dart` - PENDIENTE
  - ✅ Mayoría usa LucideIcons
  - `Icons.camera_alt` → `LucideIcons.camera`
  - `Icons.photo_library` → `LucideIcons.image`
  - Gradiente → Sólido (línea 428-437)

- `lib/features/profile/screens/location_permission_screen.dart` - PENDIENTE
  - `Icons.location_on_outlined` → `LucideIcons.mapPin`
  - `Icons.privacy_tip_outlined` → `LucideIcons.shieldCheck`
  - Gradiente → Sólido (línea 54-63)

### 4. **Chat**
- `lib/features/chat/screens/chat_screen.dart` - PENDIENTE
  - `Icons.arrow_back` → `LucideIcons.arrowLeft`
  - `Icons.error_outline` → `LucideIcons.alertCircle`
  - `Icons.chat_bubble_outline` → `LucideIcons.messageCircle`
  - Gradiente → Sólido (línea 247-256)

- `lib/features/chat/widgets/chat_input.dart` - PENDIENTE
  - `Icons.send_rounded` → `LucideIcons.send`

- `lib/features/chat/widgets/chat_header.dart` - PENDIENTE
  - `Icons.info_outline` → `LucideIcons.info`
  - `Icons.report_outlined` → `LucideIcons.flag`

- `lib/features/chat/widgets/message_bubble.dart` - PENDIENTE
  - `Icons.check` → `LucideIcons.check`
  - `Icons.done_all` → `LucideIcons.checkCheck`

### 5. **Feed**
- `lib/features/feed/screens/feed_screen.dart` - PENDIENTE
  - ✅ Ya usa LucideIcons mayormente
  - `Icons.location_off_outlined` → `LucideIcons.mapPinOff`
  - `Icons.my_location_outlined` → `LucideIcons.locateFixed`
  - Gradiente → Sólido (línea 571-580)

- `lib/shared/widgets/feed_item_card.dart` - PENDIENTE
  - ✅ Ya usa LucideIcons
  - Gradiente → Sólido (línea 352-362)

### 6. **Items**
- `lib/features/items/screens/my_items_screen.dart` - PENDIENTE
  - `Icons.add` → `LucideIcons.plus`
  - `Icons.error_outline` → `LucideIcons.alertCircle`
  - `Icons.more_vert` → `LucideIcons.moreVertical`
  - `Icons.edit_outlined` → `LucideIcons.edit`
  - `Icons.delete_outline` → `LucideIcons.trash2`

- `lib/features/items/widgets/create_item_bottom_sheet.dart` - PENDIENTE
  - `Icons.add_circle_outline` → `LucideIcons.plusCircle`
  - `Icons.close` → `LucideIcons.x`
  - `Icons.title` → `LucideIcons.type`
  - `Icons.description` → `LucideIcons.alignLeft`
  - `Icons.add_a_photo` → `LucideIcons.camera`
  - `Icons.camera_alt` → `LucideIcons.camera`
  - `Icons.photo_library` → `LucideIcons.image`

- `lib/features/items/widgets/edit_item_bottom_sheet.dart` - SIMILAR al create

### 7. **Home**
- `lib/features/home/screens/home_screen.dart` - PENDIENTE
  - Mayoría usa LucideIcons
  - `Icons.waving_hand` → `LucideIcons.hand` (o mantener material si es específico)
  - `Icons.inventory_2_outlined` → `LucideIcons.package`
  - `Icons.explore_outlined` → `LucideIcons.compass`
  - `Icons.chat_bubble_outline` → `LucideIcons.messageCircle`
  - `Icons.person_outline` → `LucideIcons.user`
  - Gradientes múltiples (líneas 238, 261, 434)

## 🔧 Widgets Compartidos

- `lib/shared/widgets/item_photo.dart` - PENDIENTE
  - `Icons.inventory_2_outlined` → `LucideIcons.package`
  - `Icons.error_outline` → `LucideIcons.alertCircle`

- `lib/shared/widgets/avatar_image.dart` - PENDIENTE
  - `Icons.person` → `LucideIcons.user`

- `lib/shared/widgets/error_widget.dart` - PENDIENTE
  - `Icons.error_outline` → `LucideIcons.alertCircle`

- `lib/shared/widgets/feed_skeleton_card.dart` - PENDIENTE
  - Gradientes múltiples (líneas 69-77, 93-102)

## 📊 Estadísticas

- **Total de archivos con Icons.**: 30
- **Total de usos de Icons.**: 116
- **Total de archivos con gradientes**: 14
- **Total de gradientes**: 22

## ✅ Progreso

- [ ] Autenticación (2/3)
- [ ] Navegación (1/2)
- [ ] Profile (0/2)
- [ ] Chat (0/4)
- [ ] Feed (0/2)
- [ ] Items (0/3)
- [ ] Home (0/1)
- [ ] Widgets compartidos (0/4)
- [ ] Empty states (3/3) ✅

## 🎯 Mapa de Conversión de Iconos

| Material Icons | LucideIcons |
|----------------|-------------|
| `Icons.arrow_back` | `LucideIcons.arrowLeft` |
| `Icons.arrow_back_ios` | `LucideIcons.chevronLeft` |
| `Icons.email_outlined` | `LucideIcons.mail` |
| `Icons.lock_outlined` | `LucideIcons.lock` |
| `Icons.visibility_outlined` | `LucideIcons.eye` |
| `Icons.visibility_off_outlined` | `LucideIcons.eyeOff` |
| `Icons.person_outlined` / `Icons.person` | `LucideIcons.user` |
| `Icons.person_add_outlined` | `LucideIcons.userPlus` |
| `Icons.error_outline` | `LucideIcons.alertCircle` |
| `Icons.check` | `LucideIcons.check` |
| `Icons.done_all` | `LucideIcons.checkCheck` |
| `Icons.send_rounded` | `LucideIcons.send` |
| `Icons.info_outline` | `LucideIcons.info` |
| `Icons.report_outlined` | `LucideIcons.flag` |
| `Icons.chat_bubble_outline` | `LucideIcons.messageCircle` |
| `Icons.location_on_outlined` | `LucideIcons.mapPin` |
| `Icons.location_off_outlined` | `LucideIcons.mapPinOff` |
| `Icons.my_location_outlined` | `LucideIcons.locateFixed` |
| `Icons.privacy_tip_outlined` | `LucideIcons.shieldCheck` |
| `Icons.add` | `LucideIcons.plus` |
| `Icons.add_circle_outline` | `LucideIcons.plusCircle` |
| `Icons.close` | `LucideIcons.x` |
| `Icons.more_vert` | `LucideIcons.moreVertical` |
| `Icons.edit_outlined` | `LucideIcons.edit` |
| `Icons.delete_outline` | `LucideIcons.trash2` |
| `Icons.title` | `LucideIcons.type` |
| `Icons.description` | `LucideIcons.alignLeft` |
| `Icons.camera_alt` | `LucideIcons.camera` |
| `Icons.photo_library` / `Icons.image` | `LucideIcons.image` |
| `Icons.add_a_photo` | `LucideIcons.camera` |
| `Icons.inventory_2_outlined` | `LucideIcons.package` |
| `Icons.explore_outlined` | `LucideIcons.compass` |
| `Icons.refresh` | `LucideIcons.refreshCw` |
| `Icons.waving_hand` | `LucideIcons.hand` o mantener Material |

## 💡 Patrón de Reemplazo de Gradientes

### ANTES (❌):
```dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.primaryContainer,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
)
```

### DESPUÉS (✅):
```dart
decoration: BoxDecoration(
  color: Theme.of(context).colorScheme.primary,
  // o primaryContainer según el contexto
)
```

