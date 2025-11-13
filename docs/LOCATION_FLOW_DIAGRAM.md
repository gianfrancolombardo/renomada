# Diagrama de Flujo de Ubicación - ReNomada

## Flujo Actual (PROBLEMA)

```
┌─────────────────┐
│  WelcomeScreen  │
│      (/)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   LoginScreen   │
│    (/login)     │
└────────┬────────┘
         │ Usuario autenticado
         ▼
┌─────────────────────────────┐
│ LocationPermissionScreen    │
│   (/location-permission)    │
│                             │
│ [PROBLEMA ACTUAL]           │
│ - Si permanently_denied:    │
│   • Muestra botón "Activar" │
│   • Usuario presiona        │
│   • Intenta request()       │
│   • Falla silenciosamente   │
│   • Se queda en loading     │
│   • O muestra snackbar      │
│   • Usuario puede "Skip"    │
└────────┬────────────────────┘
         │
         ├─► Con ubicación ──┐
         │                    │
         └─► Sin ubicación ──┤
                             ▼
                    ┌─────────────────┐
                    │  FeedScreen      │
                    │    (/feed)       │
                    │                  │
                    │ [PROBLEMA]       │
                    │ Si no hay        │
                    │ ubicación:       │
                    │ • Muestra        │
                    │   "Buscando tu   │
                    │   ubicación"     │
                    │ • Se queda       │
                    │   atascado       │
                    │ • isLoading=true │
                    │   indefinidamente│
                    └──────────────────┘
```

## Flujo Objetivo (SOLUCIÓN)

```
┌─────────────────┐
│  WelcomeScreen  │
│      (/)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   LoginScreen   │
│    (/login)     │
└────────┬────────┘
         │ Usuario autenticado
         ▼
┌─────────────────────────────┐
│ LocationPermissionScreen    │
│   (/location-permission)    │
│                             │
│ [MEJORADO]                  │
│ 1. Al cargar, verifica:     │
│    • permissionStatus        │
│    • GPS enabled            │
│                             │
│ 2. Si permanently_denied:   │
│    ──► Redirige a           │
│        LocationRecoveryScreen│
│                             │
│ 3. Si denied (primera vez): │
│    ──► Muestra UI normal    │
│        con botón "Activar"  │
│                             │
│ 4. Si granted:              │
│    ──► Obtiene ubicación    │
│        ──► Navega a Feed    │
└────────┬────────────────────┘
         │
         ├─► permanently_denied ──┐
         │                        │
         ├─► denied (primera vez) │
         │                        │
         └─► granted ─────────────┤
                                 │
                                 ▼
                    ┌─────────────────────────────┐
                    │ LocationRecoveryScreen      │
                    │  (/location-recovery)        │
                    │                              │
                    │ [NUEVA PANTALLA]            │
                    │                              │
                    │ Cubre DOS escenarios:        │
                    │                              │
                    │ 1. Denegado predeterminado: │
                    │    • Usuario nunca vio       │
                    │      diálogo de permiso      │
                    │    • Sistema denegó          │
                    │      automáticamente         │
                    │                              │
                    │ 2. Denegado manualmente:     │
                    │    • Usuario denegó          │
                    │      múltiples veces         │
                    │    • Estado:                 │
                    │      permanently_denied      │
                    │                              │
                    │ Contenido:                   │
                    │ • Explicación del valor      │
                    │ • Guía paso a paso          │
                    │ • Botón "Abrir configuración"│
                    │ • Opción "Continuar sin      │
                    │   ubicación"                 │
                    └────────┬─────────────────────┘
                             │
                             ├─► Usuario abre configuración ──┐
                             │                                  │
                             └─► Usuario hace "Skip" ──────────┤
                                                                 │
                                                                 ▼
                                                    ┌─────────────────┐
                                                    │  FeedScreen      │
                                                    │    (/feed)       │
                                                    │                  │
                                                    │ [MEJORADO]       │
                                                    │                  │
                                                    │ Si no hay        │
                                                    │ ubicación:       │
                                                    │ • Detecta        │
                                                    │   permanently_   │
                                                    │   denied         │
                                                    │ • Muestra CTA    │
                                                    │   para recuperar │
                                                    │ • O modo         │
                                                    │   degradado      │
                                                    └──────────────────┘
```

## Eventos y Condiciones Detallados

### Evento 1: Usuario inicia sesión
**Ubicación:** `LoginScreen` → `authProvider.listen()`
**Acción:** `context.pushReplacement('/location-permission')`

### Evento 2: LocationPermissionScreen se carga
**Ubicación:** `LocationPermissionScreen.initState()` o `build()`
**Verificaciones:**
```dart
1. checkLocationPermission()
   ├─► granted ──► getCurrentLocation() ──► Navega a Feed
   ├─► denied ──► Muestra UI normal con botón "Activar"
   ├─► permanently_denied ──► NUEVO: Redirige a LocationRecoveryScreen
   └─► restricted ──► Manejar según plataforma

2. isLocationServiceEnabled()
   ├─► false ──► Mostrar mensaje "GPS desactivado"
   └─► true ──► Continuar flujo
```

### Evento 3: Usuario presiona "Activar ubicación"
**Ubicación:** `LocationPermissionScreen._handleAllowLocation()`
**Flujo:**
```dart
requestLocationPermission()
├─► granted ──► getHighAccuracyLocation() ──► Navega a Feed
├─► denied ──► Muestra snackbar "Permiso denegado"
├─► permanently_denied ──► NUEVO: Redirige a LocationRecoveryScreen
└─► Error ──► Muestra error específico
```

### Evento 4: Usuario presiona "Continuar sin ubicación"
**Ubicación:** `LocationPermissionScreen._handleSkip()`
**Acción:** `_navigateAfterLocationObtained()`
**Flujo:**
```dart
if (hasSeenOnboarding)
  └─► /feed
else
  └─► /onboarding
```

### Evento 5: FeedScreen se carga sin ubicación
**Ubicación:** `FeedScreen._initializeFeed()`
**Problema actual:**
```dart
if (!hasLocation && isLoading)
  └─► Muestra "Buscando tu ubicación" indefinidamente ❌
```

**Solución:**
```dart
if (!hasLocation)
  if (permissionStatus == permanently_denied)
    └─► Muestra CTA para LocationRecoveryScreen
  else if (isLoading)
    └─► Muestra "Buscando tu ubicación" con timeout
  else
    └─► Muestra modo degradado o CTA
```

## Nueva Pantalla: LocationRecoveryScreen

### Ruta
`/location-recovery`

### Cuándo se muestra

#### Escenario A: Denegado predeterminado
**Condición:** `permissionStatus == denied` (primera vez, nunca se mostró diálogo)
**Origen:** 
- Sistema operativo denegó automáticamente
- Usuario nunca vio el diálogo nativo
- Puede ser por configuración del dispositivo

**Detección:**
```dart
// En LocationPermissionScreen.initState()
final permission = await checkLocationPermission();
if (permission == denied && !hasRequestedPermission) {
  // Primera vez, pero ya está denegado
  // Posiblemente denegado predeterminadamente
  context.pushReplacement('/location-recovery');
}
```

#### Escenario B: Denegado manualmente (permanently_denied)
**Condición:** `permissionStatus == permanently_denied`
**Origen:**
- Usuario denegó el permiso múltiples veces
- Usuario denegó y marcó "No preguntar de nuevo"
- Sistema operativo bloqueó futuras solicitudes

**Detección:**
```dart
// En LocationPermissionScreen.initState() o build()
final permission = await checkLocationPermission();
if (permission == permanentlyDenied) {
  context.pushReplacement('/location-recovery');
}

// O después de requestLocationPermission()
if (permission == permanentlyDenied) {
  context.pushReplacement('/location-recovery');
}
```

### Contenido de LocationRecoveryScreen

```
┌─────────────────────────────────────┐
│  LocationRecoveryScreen            │
│                                     │
│  [Icono de ubicación]              │
│                                     │
│  "Necesitamos tu ubicación"         │
│                                     │
│  Explicación del valor:            │
│  • Ver objetos cerca de ti         │
│  • Encontrar intercambios          │
│  • Mejor experiencia               │
│                                     │
│  ───────────────────────────────   │
│                                     │
│  "Cómo habilitar:"                 │
│                                     │
│  1. Presiona "Abrir configuración" │
│  2. Busca "Ubicación" o "Location" │
│  3. Selecciona "Permitir siempre"  │
│     o "Permitir mientras usas      │
│     la app"                        │
│  4. Vuelve a la app                │
│                                     │
│  ───────────────────────────────   │
│                                     │
│  [Botón: "Abrir configuración"]   │
│                                     │
│  [Botón: "Continuar sin ubicación"]│
└─────────────────────────────────────┘
```

### Flujo post-configuración

```
Usuario presiona "Abrir configuración"
  └─► openAppSettings()
      └─► Usuario cambia permisos
          └─► Usuario vuelve a la app
              └─► App detecta cambio (AppLifecycleState.resumed)
                  └─► checkLocationPermission()
                      ├─► granted ──► getCurrentLocation() ──► Navega a Feed
                      └─► still denied ──► Muestra mensaje "Aún no concedido"
```

## Estados y Transiciones

### Estados de Permiso
```
┌─────────────┐
│   initial   │ (Primera vez, nunca verificado)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   denied    │ (Denegado, puede solicitarse)
└──────┬──────┘
       │
       ├─► Usuario deniega múltiples veces
       │
       ▼
┌─────────────────────┐
│ permanently_denied  │ (Bloqueado, solo configuración)
└──────────┬──────────┘
           │
           └─► Usuario habilita en configuración
               │
               ▼
          ┌─────────┐
          │ granted │
          └─────────┘
```

### Estados de Ubicación
```
┌──────────────┐
│  No Location │
└──────┬───────┘
       │
       ├─► permission granted + GPS enabled
       │
       ▼
┌──────────────┐
│  Obtaining   │ (isLoading = true)
└──────┬───────┘
       │
       ├─► Success
       │   └─► hasLocation = true
       │
       └─► Error
           ├─► GPS disabled
           ├─► Timeout
           └─► Permission denied
```

## Puntos de Entrada para LocationRecoveryScreen

### 1. Al cargar LocationPermissionScreen
```dart
@override
void initState() {
  super.initState();
  _checkPermissionStatus();
}

Future<void> _checkPermissionStatus() async {
  final permission = await _locationService.checkLocationPermission();
  
  if (permission == LocationPermissionStatus.permanentlyDenied) {
    // Redirigir inmediatamente
    if (mounted) {
      context.pushReplacement('/location-recovery');
    }
  }
}
```

### 2. Después de requestLocationPermission()
```dart
Future<void> _handleAllowLocation() async {
  final success = await ref.read(locationProvider.notifier)
      .requestLocationPermission();
  
  if (!success && mounted) {
    final permissionStatus = ref.read(locationProvider).permissionStatus;
    
    if (permissionStatus == LocationPermissionStatus.permanentlyDenied) {
      // Redirigir a recovery screen
      context.pushReplacement('/location-recovery');
      return;
    }
  }
}
```

### 3. Desde FeedScreen (cuando detecta permanently_denied)
```dart
// En FeedScreen cuando no hay ubicación
if (!locationState.hasLocation) {
  if (locationState.permissionStatus == 
      LocationPermissionStatus.permanentlyDenied) {
    // Mostrar CTA o redirigir
    _showLocationRecoveryCTA();
  }
}
```

### 4. Al volver de configuración (AppLifecycleState)
```dart
// En LocationRecoveryScreen
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    // Usuario volvió de configuración
    _checkIfPermissionGranted();
  }
}

Future<void> _checkIfPermissionGranted() async {
  final permission = await _locationService.checkLocationPermission();
  
  if (permission == LocationPermissionStatus.granted) {
    // ¡Éxito! Obtener ubicación y navegar
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      context.pushReplacement('/feed');
    }
  }
}
```

## Resumen de Cambios Necesarios

### 1. Nueva Pantalla
- ✅ Crear `LocationRecoveryScreen` en `/location-recovery`
- ✅ Agregar ruta en `app_router.dart`

### 2. LocationPermissionScreen
- ✅ Detectar `permanently_denied` al cargar
- ✅ Redirigir a `LocationRecoveryScreen` si detectado
- ✅ Detectar `denied` predeterminado (primera vez)

### 3. FeedScreen
- ✅ Detectar `permanently_denied` cuando no hay ubicación
- ✅ Mostrar CTA o redirigir a `LocationRecoveryScreen`
- ✅ Evitar mostrar "Buscando..." indefinidamente

### 4. LocationRecoveryScreen
- ✅ Detectar cuando usuario vuelve de configuración
- ✅ Verificar si permiso cambió
- ✅ Obtener ubicación y navegar si exitoso

### 5. Logging
- ✅ Log cuando se detecta `permanently_denied`
- ✅ Log cuando se muestra `LocationRecoveryScreen`
- ✅ Log cuando usuario abre configuración
- ✅ Log cuando usuario vuelve de configuración
- ✅ Log resultado final (granted/denied)

