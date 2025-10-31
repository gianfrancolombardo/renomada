# 📱 Iconos de la Aplicación

## Archivos Requeridos

Coloca tus archivos de iconos en esta carpeta:

### Opción 1: Icono Simple (Recomendado para comenzar)

Si tu icono ya tiene fondo incluido:

- **`app_icon.png`** (1024x1024 píxeles)
  - Tu icono completo con fondo
  - Formato: PNG, 24-bit o 32-bit
  - Sin bordes redondeados
  - Deja margen de seguridad del 10% en cada lado

### Opción 2: Icono Adaptativo (Para diseño moderno)

Si quieres iconos adaptativos para Android:

- **`app_icon.png`** (1024x1024 píxeles)
  - Tu icono completo para iOS y Android legacy
  
- **`app_icon_foreground.png`** (1024x1024 píxeles)
  - Solo tu logo/símbolo
  - Fondo transparente
  - Centrado con margen del 25-30% en cada lado

**Nota:** El color de fondo para adaptive icons está configurado en `pubspec.yaml` como `#FFFFFF` (blanco). Cámbialo si necesitas otro color.

## Especificaciones Técnicas

- **Tamaño:** 1024x1024 píxeles
- **Formato:** PNG
- **Profundidad de color:** 24-bit (RGB) o 32-bit (RGBA con transparencia)
- **Sin bordes redondeados:** El sistema operativo los aplica automáticamente
- **Márgenes de seguridad:** 10% mínimo en todos los lados

## Después de agregar tus iconos

1. Instala las dependencias:
   ```bash
   flutter pub get
   ```

2. Genera los iconos:
   ```bash
   dart run flutter_launcher_icons
   ```

3. Verifica que se generaron correctamente:
   - Android: `android/app/src/main/res/mipmap-*/`
   - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
   - Web: `web/icons/`

## Ejemplo de Diseño

```
┌─────────────────────────────────┐
│     [10% margen superior]       │
│  ┌─────────────────────────┐   │
│  │                         │   │ 10% margen
│  │    TU LOGO/ICONO        │   │
│  │                         │   │
│  └─────────────────────────┘   │
│     [10% margen inferior]       │
└─────────────────────────────────┘
```

## Recursos Útiles

- [Generador de iconos online](https://appicon.co/)
- [Guía de diseño Material Design](https://m3.material.io/styles/icons/designing-icons)
- [Guía de iconos iOS](https://developer.apple.com/design/human-interface-guidelines/app-icons)

