# Sistema de Logging de Ubicación

## Resumen

Se ha implementado un sistema completo de logging para rastrear todos los eventos relacionados con la obtención de ubicación del usuario. Este sistema ayuda a diagnosticar problemas en dispositivos móviles donde la ubicación no se obtiene correctamente.

## Componentes Implementados

### 1. Tabla de Base de Datos (`location_logs`)

La tabla `location_logs` almacena todos los eventos relacionados con ubicación:

- **event_type**: Tipo de evento (permission_check, permission_granted, gps_disabled, location_success, etc.)
- **action**: Acción realizada (check_permission, request_permission, get_location, etc.)
- **permission_status**: Estado del permiso (granted, denied, permanently_denied, restricted)
- **gps_enabled**: Si el GPS está activado
- **location_obtained**: Si se obtuvo la ubicación exitosamente
- **latitude, longitude, accuracy**: Datos de ubicación si se obtuvo
- **error_code, error_message**: Información de errores
- **session_id**: Agrupa eventos relacionados en una sesión
- **platform**: Plataforma (web, android, ios)
- **metadata**: Información adicional en formato JSON

### 2. Servicio de Logging (`LocationLogService`)

Servicio singleton que maneja el logging de todos los eventos:

- Inicia sesiones para agrupar eventos relacionados
- Registra eventos de forma asíncrona sin bloquear la app
- Maneja errores silenciosamente para no afectar la experiencia del usuario

### 3. Mejoras en `LocationService`

- **Mejor manejo de errores**: Códigos de error específicos (gps_disabled, timeout, permission_denied, etc.)
- **Detección de cambios de permisos**: Detecta cuando el usuario cambia permisos en configuración
- **Soporte para permisos temporales**: Maneja permisos "While Using App" de iOS
- **Validación de GPS**: Verifica que el GPS esté activado antes de intentar obtener ubicación
- **Detección de baja precisión**: Alerta cuando la precisión es mayor a 100 metros
- **Logging integrado**: Todos los métodos registran sus acciones automáticamente

### 4. Mejoras en `LocationProvider`

- **Manejo de errores específicos**: Mensajes de error claros según el tipo de problema
- **Verificación de GPS**: Verifica GPS antes de solicitar ubicación
- **Logging de actualización de perfil**: Registra cuando la ubicación se guarda exitosamente o falla
- **Sesiones de logging**: Inicia nuevas sesiones cuando el usuario inicia el flujo de ubicación

## Eventos Registrados

### Eventos de Permisos
- `permission_check`: Verificación del estado del permiso
- `permission_request`: Solicitud de permiso
- `permission_granted`: Permiso concedido
- `permission_denied`: Permiso denegado
- `permission_permanently_denied`: Permiso denegado permanentemente
- `permission_restricted`: Permiso restringido
- `permission_limited`: Permiso limitado (iOS "While Using App")
- `permission_changed`: Cambio en el estado del permiso

### Eventos de GPS
- `gps_check`: Verificación del estado del GPS
- `gps_disabled`: GPS desactivado
- `gps_enabled`: GPS activado

### Eventos de Ubicación
- `location_request`: Solicitud de ubicación
- `location_success`: Ubicación obtenida exitosamente
- `location_error`: Error al obtener ubicación
- `location_timeout`: Timeout al obtener ubicación
- `location_low_accuracy`: Ubicación obtenida con baja precisión (>100m)

### Acciones del Usuario
- `settings_opened`: Apertura de configuración
- `app_settings_opened`: Apertura de configuración de la app
- `location_settings_opened`: Apertura de configuración de ubicación
- `skip_location`: Usuario omite la solicitud de ubicación

### Eventos del Sistema
- `initialize`: Inicialización del servicio de ubicación
- `refresh`: Actualización del estado de ubicación

## Códigos de Error

- `gps_disabled`: GPS desactivado
- `permission_denied`: Permiso denegado
- `timeout`: Timeout al obtener ubicación
- `gps_error`: Error del GPS
- `low_accuracy`: Baja precisión en la ubicación
- `save_failed`: Error al guardar ubicación en perfil
- `check_failed`: Error al verificar permisos
- `request_failed`: Error al solicitar permisos
- `unknown_error`: Error desconocido

## Consultar Logs

### En Supabase SQL Editor

```sql
-- Ver todos los logs de un usuario
SELECT * FROM location_logs 
WHERE user_id = 'user-uuid-here' 
ORDER BY created_at DESC;

-- Ver logs de una sesión específica
SELECT * FROM location_logs 
WHERE session_id = 'session-id-here' 
ORDER BY created_at ASC;

-- Ver errores de ubicación
SELECT * FROM location_logs 
WHERE error_code IS NOT NULL 
ORDER BY created_at DESC;

-- Ver eventos de permisos denegados
SELECT * FROM location_logs 
WHERE event_type IN ('permission_denied', 'permission_permanently_denied')
ORDER BY created_at DESC;

-- Ver problemas de GPS
SELECT * FROM location_logs 
WHERE event_type = 'gps_disabled' OR gps_enabled = false
ORDER BY created_at DESC;

-- Ver timeouts
SELECT * FROM location_logs 
WHERE error_code = 'timeout'
ORDER BY created_at DESC;

-- Estadísticas por plataforma
SELECT 
  platform,
  event_type,
  COUNT(*) as count,
  COUNT(CASE WHEN error_code IS NOT NULL THEN 1 END) as error_count
FROM location_logs
GROUP BY platform, event_type
ORDER BY platform, count DESC;
```

### Análisis de Sesiones Completas

```sql
-- Ver el flujo completo de una sesión
WITH session_events AS (
  SELECT 
    session_id,
    event_type,
    action,
    permission_status,
    gps_enabled,
    location_obtained,
    error_code,
    error_message,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY created_at) as step
  FROM location_logs
  WHERE session_id = 'session-id-here'
)
SELECT * FROM session_events ORDER BY step;
```

## Casos de Uso para Diagnóstico

### Usuario no puede obtener ubicación

1. Buscar la sesión del usuario por `session_id` o `user_id`
2. Verificar el orden de eventos:
   - ¿Se verificó el GPS? (`gps_check`)
   - ¿Está el GPS activado? (`gps_enabled`)
   - ¿Se solicitó el permiso? (`permission_request`)
   - ¿Cuál fue el resultado? (`permission_granted`, `permission_denied`, etc.)
   - ¿Se intentó obtener la ubicación? (`location_request`)
   - ¿Qué error ocurrió? (`error_code`, `error_message`)

### Permisos denegados permanentemente

```sql
SELECT 
  user_id,
  session_id,
  event_type,
  permission_status,
  created_at
FROM location_logs
WHERE event_type = 'permission_permanently_denied'
ORDER BY created_at DESC;
```

### Problemas de GPS

```sql
SELECT 
  user_id,
  session_id,
  gps_enabled,
  event_type,
  error_code,
  created_at
FROM location_logs
WHERE gps_enabled = false OR event_type = 'gps_disabled'
ORDER BY created_at DESC;
```

### Timeouts frecuentes

```sql
SELECT 
  user_id,
  platform,
  COUNT(*) as timeout_count,
  MAX(created_at) as last_timeout
FROM location_logs
WHERE error_code = 'timeout'
GROUP BY user_id, platform
ORDER BY timeout_count DESC;
```

## Mejoras Implementadas

1. **Verificación de GPS antes de solicitar ubicación**: Evita errores innecesarios
2. **Mensajes de error específicos**: El usuario recibe mensajes claros según el problema
3. **Manejo de permisos temporales**: Soporta permisos "While Using App" de iOS
4. **Detección de cambios de permisos**: Detecta cuando el usuario cambia permisos fuera de la app
5. **Logging de guardado de perfil**: Registra cuando la ubicación se guarda o falla al guardarse
6. **Sesiones de logging**: Agrupa eventos relacionados para facilitar el análisis

## Próximos Pasos

1. Ejecutar la migración SQL para crear la tabla `location_logs`
2. Probar el flujo completo de ubicación y verificar que los logs se guarden correctamente
3. Crear dashboards en Supabase para visualizar los logs
4. Configurar alertas para errores frecuentes

## Migración SQL

Ejecutar el archivo `docs/migrations/create_location_logs_table.sql` en Supabase SQL Editor para crear la tabla y las políticas RLS necesarias.

