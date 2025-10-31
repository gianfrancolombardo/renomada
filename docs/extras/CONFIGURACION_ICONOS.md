# 📱 Guía Completa: Configuración de Iconos en Renomada

## 🎨 Diseño del Icono

### ✅ Mejores Prácticas

1. **NO incluyas bordes redondeados** en tu diseño
   - iOS y Android aplican automáticamente sus propias máscaras
   - Si tú agregas bordes, se verá con "doble borde"

2. **Usa un diseño cuadrado completo** (1024x1024)
   - Centra tu logo/símbolo
   - Deja márgenes de seguridad del 10% en cada lado

3. **Fondo sólido o transparente**
   - Ambos funcionan, depende de tu diseño
   - Si usas transparente, Android usará el color configurado

### 📐 Especificaciones Técnicas

| Propiedad | Valor |
|-----------|-------|
| Tamaño | 1024x1024 píxeles |
| Formato | PNG |
| Profundidad | 24-bit (RGB) o 32-bit (RGBA) |
| Bordes redondeados | ❌ NO (el SO los aplica) |
| Márgenes seguros | 10% mínimo en cada lado |

## 🔄 Iconos Adaptativos de Android

### ¿Qué son?

Android 8.0+ usa iconos de **dos capas**:

```
CAPA 1: Background        CAPA 2: Foreground
┌─────────────┐           ┌─────────────┐
│             │           │             │
│   COLOR     │     +     │    LOGO     │
│   SÓLIDO    │           │  (tu ícono) │
│             │           │             │
└─────────────┘           └─────────────┘
                =
        ┌─────────────┐
        │             │
        │   RESULTADO │  ← Android aplica
        │   DINÁMICO  │    formas y efectos
        │             │
        └─────────────┘
```

### Ventajas

✅ Animaciones y efectos parallax  
✅ Se adapta a diferentes formas (círculo, cuadrado, squircle)  
✅ Consistencia con el diseño del sistema  

### Dos Opciones de Implementación

#### Opción 1: Icono Simple (Más fácil)

**Usa esto si:** Tu icono tiene fondo incluido o es sencillo

**Archivos necesarios:**
- `assets/icon/app_icon.png` (1024x1024)

**Configuración en pubspec.yaml:**
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
```

#### Opción 2: Icono Adaptativo (Más moderno)

**Usa esto si:** Quieres aprovechar los efectos de Android

**Archivos necesarios:**
- `assets/icon/app_icon.png` (1024x1024) - Para iOS y Android legacy
- `assets/icon/app_icon_foreground.png` (1024x1024, transparente) - Solo tu logo

**Configuración en pubspec.yaml:**
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#FFFFFF"  # Cambia a tu color
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

**Diseño del foreground:**
```
┌─────────────────────────────────┐
│  [25-30% margen]                │
│     ┌───────────────┐           │
│     │               │           │
│     │   TU LOGO     │  Centrado │
│     │   (sin fondo) │           │
│     │               │           │
│     └───────────────┘           │
│                 [25-30% margen] │
└─────────────────────────────────┘
```

## 🚀 Pasos para Configurar

### Paso 1: Preparar tu Icono

1. Diseña tu icono en 1024x1024 píxeles
2. Exporta como PNG
3. **NO agregues bordes redondeados**

### Paso 2: Colocar Archivos

Coloca tus iconos en la carpeta `assets/icon/`:

**Mínimo requerido:**
```
assets/
  └── icon/
      └── app_icon.png  (1024x1024)
```

**Opcional (para adaptive icons):**
```
assets/
  └── icon/
      ├── app_icon.png            (1024x1024, con fondo)
      └── app_icon_foreground.png (1024x1024, transparente)
```

### Paso 3: Generar Iconos

**Opción A: Usar el script (Recomendado)**
```bash
generate_icons.bat
```

**Opción B: Comandos manuales**
```bash
# 1. Instalar dependencias
flutter pub get

# 2. Generar iconos
dart run flutter_launcher_icons
```

### Paso 4: Verificar

Los iconos se generan en:

- **Android:** `android/app/src/main/res/mipmap-*/ic_launcher.png`
- **iOS:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Web:** `web/icons/Icon-192.png`, `web/icons/Icon-512.png`
- **Windows:** `windows/runner/resources/app_icon.ico`

### Paso 5: Probar

```bash
# Android
flutter run

# iOS (requiere Mac)
flutter run -d ios

# Web
flutter run -d chrome
```

## 🎯 Configuración Actual de Renomada

Ya está configurado en `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  
  # Iconos adaptativos Android
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
  
  # Web
  web:
    generate: true
    image_path: "assets/icon/app_icon.png"
    background_color: "#FFFFFF"
    theme_color: "#FFFFFF"
  
  # Windows
  windows:
    generate: true
    image_path: "assets/icon/app_icon.png"
    icon_size: 48
```

### Personalizar Colores

Cambia los colores según tu marca:

```yaml
adaptive_icon_background: "#FF5722"  # Tu color principal
web:
  background_color: "#FF5722"
  theme_color: "#FF5722"
```

## 🛠️ Solución de Problemas

### Error: "No se encuentra app_icon.png"

✅ **Solución:** Asegúrate de colocar el archivo en `assets/icon/app_icon.png`

### Error: "Image asset not found"

✅ **Solución:** Ejecuta `flutter pub get` y regenera los iconos

### Los iconos no se actualizan en Android

✅ **Solución:** 
```bash
flutter clean
flutter pub get
dart run flutter_launcher_icons
flutter run
```

### Los iconos se ven cortados en Android

✅ **Solución:** Aumenta el margen en tu `app_icon_foreground.png` al 30%

### Quiero diferentes iconos para debug y release

✅ **Solución avanzada:**
```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon/app_icon.png"
  image_path_android: "assets/icon/app_icon_android.png"
  image_path_ios: "assets/icon/app_icon_ios.png"
```

## 📚 Recursos Adicionales

- **Generador online:** https://appicon.co/
- **Guía Material Design:** https://m3.material.io/styles/icons/
- **Guía iOS:** https://developer.apple.com/design/human-interface-guidelines/app-icons
- **Documentación flutter_launcher_icons:** https://pub.dev/packages/flutter_launcher_icons

## ✨ Checklist Final

Antes de liberar tu app, verifica:

- [ ] Icono de 1024x1024 píxeles
- [ ] Formato PNG con buena calidad
- [ ] Sin bordes redondeados
- [ ] Márgenes de seguridad adecuados
- [ ] Iconos generados para todas las plataformas
- [ ] Probado en Android
- [ ] Probado en iOS (si aplica)
- [ ] Colores configurados correctamente
- [ ] Se ve bien en modo claro y oscuro

---

**Nota:** Después de generar los iconos, considera hacer commit de los archivos generados en `android/`, `ios/`, y `web/` para que tu equipo tenga los mismos iconos.

