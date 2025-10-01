# 📱 ReNomada

Una aplicación móvil Flutter para intercambio de artículos basada en proximidad geográfica.

## 🚀 **Características Principales**

- **🔐 Autenticación completa** con Supabase Auth
- **👤 Gestión de perfiles** con avatares y ubicación
- **📦 CRUD de artículos** con fotos y estados
- **🗺️ Feed geográfico** por radio de distancia
- **💬 Chat en tiempo real** (próximamente)
- **🔔 Notificaciones push** (próximamente)

## 🛠️ **Tecnologías**

- **Frontend**: Flutter + Material Design 3
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Estado**: Riverpod
- **Geolocalización**: PostGIS
- **Navegación**: GoRouter

## 📋 **Configuración Rápida**

1. **Clona el repositorio**
2. **Configura Supabase** (ver `PROJECT_DOCUMENTATION.md`)
3. **Ejecuta `database_setup.sql`** en tu proyecto Supabase
4. **Actualiza las constantes** en `lib/core/constants/supabase_constants.dart`
5. **Ejecuta** `flutter pub get && flutter run`

## 📚 **Documentación Completa**

Ver `PROJECT_DOCUMENTATION.md` para documentación detallada, configuración completa y guías de desarrollo.

## 🎯 **Estado del Proyecto**

✅ **MVP Completado** - Funcionalidades básicas implementadas
🔄 **En desarrollo** - Chat y notificaciones push
