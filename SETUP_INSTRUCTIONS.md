# 🚀 ReNomada - Guía de Configuración Rápida

## 📋 **Configuración de Supabase**

### 1. Crear Proyecto
1. Ve a [supabase.com](https://supabase.com) y crea una cuenta
2. Crea un nuevo proyecto
3. Anota la **URL del proyecto** y la **clave anónima**

### 2. Configurar Base de Datos
1. Ve al **SQL Editor** en tu proyecto de Supabase
2. Ejecuta el contenido completo del archivo **`database_setup.sql`**
3. Esto creará todas las tablas, políticas RLS, funciones y triggers necesarios

### 3. Configurar Storage
1. Ve a **Storage** en tu proyecto de Supabase
2. Crea estos buckets:
   - **`avatars`** (privado)
   - **`item-photos`** (privado)

### 4. Configurar Autenticación
1. Ve a **Authentication > Settings**
2. Habilita **Email provider**
3. Configura las URLs de redirección según sea necesario

## 📱 **Configuración de Flutter**

### 1. Actualizar Constantes de Supabase
1. Abre `lib/core/constants/supabase_constants.dart`
2. Reemplaza:
   - `YOUR_SUPABASE_URL` → URL de tu proyecto
   - `YOUR_SUPABASE_ANON_KEY` → Tu clave anónima

### 2. Instalar Dependencias
```bash
flutter pub get
```

### 3. Configurar Firebase (Opcional - para notificaciones)
1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Crea un proyecto para Android/iOS
3. Descarga y coloca:
   - `google-services.json` en `android/app/`
   - `GoogleService-Info.plist` en `ios/Runner/`

### 4. Ejecutar la Aplicación
```bash
flutter run
```

## ✅ **Verificación de la Configuración**

### **1. Verificar Base de Datos:**
```sql
-- Verificar que las tablas existen
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Verificar RLS habilitado
SELECT relname, relrowsecurity FROM pg_class WHERE relnamespace = 'public'::regnamespace;
```

### **2. Probar Funcionalidades:**
1. **Registro/Login** → Debería crear perfil automáticamente
2. **Permisos de ubicación** → Debería guardar ubicación
3. **Crear artículo** → Debería subir fotos y crear item
4. **Ver "Mis Artículos"** → Debería mostrar lista

## 🔧 **Solución de Problemas**

### **Error de RLS:**
- Verifica que ejecutaste `database_setup.sql` completo
- Confirma que las políticas RLS están creadas

### **Error de Storage:**
- Verifica que los buckets existen
- Confirma que las políticas de Storage están configuradas

### **Error de ubicación:**
- Verifica que PostGIS está habilitado
- Confirma que la función RPC está creada

## 📚 **Documentación Completa**

Para documentación detallada, arquitectura, APIs y guías de desarrollo, ver **`PROJECT_DOCUMENTATION.md`**.

## 🎯 **Estado Actual**

✅ **MVP Funcional** - Todas las funcionalidades básicas implementadas
- Autenticación completa
- Gestión de perfiles con ubicación
- CRUD de artículos con fotos
- Feed geográfico por radio
- Sistema de storage con URLs firmadas

🔄 **Próximamente** - Chat en tiempo real y notificaciones push

¡Listo para usar! 🚀
