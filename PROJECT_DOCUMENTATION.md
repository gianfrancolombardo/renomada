# 📱 ReNomada - Documentación Completa del Proyecto

## 🎯 **Descripción del Proyecto**

ReNomada es una aplicación móvil Flutter para intercambio de artículos basada en proximidad geográfica. Los usuarios pueden crear perfiles, subir artículos con fotos, y descubrir items de otros usuarios cercanos a través de un sistema de feed geográfico.

## 🏗️ **Arquitectura del Proyecto**

### **Tecnologías Utilizadas:**
- **Frontend**: Flutter con Material Design 3
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Realtime)
- **Estado**: Riverpod para gestión de estado reactiva
- **Navegación**: GoRouter para navegación declarativa
- **Geolocalización**: PostGIS para búsquedas espaciales
- **Storage**: Supabase Storage con URLs firmadas

### **Estructura de Carpetas:**
```
lib/
├── core/                    # Configuración central
│   ├── config/             # Configuración de servicios
│   ├── constants/          # Constantes de la aplicación
│   ├── router/             # Configuración de rutas
│   ├── theme/              # Tema Material Design 3
│   └── utils/              # Utilidades generales
├── features/               # Características por dominio
│   ├── auth/              # Autenticación (login/signup)
│   ├── profile/           # Gestión de perfiles
│   ├── items/             # CRUD de artículos
│   ├── feed/              # Feed y geobúsqueda
│   ├── chat/              # Sistema de chat
│   └── notifications/     # Notificaciones push
└── shared/                # Componentes compartidos
    ├── models/            # Modelos de datos
    ├── services/          # Servicios compartidos
    └── widgets/           # Widgets reutilizables
```

## 🗄️ **Base de Datos y Esquema**

### **Extensiones:**
- `pgcrypto` - Para generación de UUIDs
- `postgis` - Para búsquedas espaciales y geolocalización

### **Tablas Principales:**

#### **1. profiles**
```sql
CREATE TABLE public.profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id),
  username text UNIQUE,
  avatar_url text,
  last_location geography(point,4326),
  last_seen_at timestamptz,
  is_location_opt_out boolean DEFAULT false
);
```

#### **2. items**
```sql
CREATE TABLE public.items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid REFERENCES auth.users(id),
  title text NOT NULL,
  description text,
  status item_status DEFAULT 'available',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

#### **3. item_photos**
```sql
CREATE TABLE public.item_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id uuid REFERENCES public.items(id),
  path text NOT NULL,
  mime_type text,
  size_bytes integer,
  created_at timestamptz DEFAULT now()
);
```

#### **4. interactions**
```sql
CREATE TABLE public.interactions (
  user_id uuid REFERENCES auth.users(id),
  item_id uuid REFERENCES public.items(id),
  action text CHECK (action IN ('like','pass')),
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, item_id)
);
```

#### **5. chats**
```sql
CREATE TABLE public.chats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id uuid REFERENCES public.items(id),
  a_user_id uuid REFERENCES auth.users(id),
  b_user_id uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  CHECK (a_user_id <> b_user_id),
  UNIQUE (item_id, a_user_id, b_user_id)
);
```

#### **6. messages**
```sql
CREATE TABLE public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id uuid REFERENCES public.chats(id),
  sender_id uuid REFERENCES auth.users(id),
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);
```

### **Enums:**
```sql
CREATE TYPE item_status AS ENUM ('available', 'exchanged', 'paused');
```

## 🔒 **Seguridad y RLS**

### **Row Level Security (RLS):**
- **Habilitado** en todas las tablas
- **Políticas granulares** por operación (SELECT, INSERT, UPDATE, DELETE)
- **Verificación de ownership** en cada operación
- **Storage privado** con URLs firmadas

### **Políticas de Storage:**
- **Bucket `avatars`**: Solo el propietario puede subir/ver sus avatares
- **Bucket `item-photos`**: Solo el propietario puede subir/ver fotos de sus items
- **Lectura pública** para fotos de items disponibles

## 🚀 **Funcionalidades Implementadas**

### **✅ Autenticación**
- Login y registro con email/contraseña
- Creación automática de perfil al registrarse
- Avatar placeholder automático con DiceBear API
- Logout y manejo de sesiones

### **✅ Gestión de Perfiles**
- Edición de username con validaciones
- Subida de avatar desde cámara/galería
- Actualización de ubicación con PostGIS
- Configuración de privacidad de ubicación

### **✅ CRUD de Artículos**
- Creación de artículos con título, descripción y fotos
- Edición de artículos existentes
- Eliminación lógica (cambio de status a 'exchanged')
- Gestión de fotos con validaciones (máx 5MB)
- Estados: available, exchanged, paused

### **✅ Sistema de Feed**
- Feed por radio de distancia usando PostGIS
- Función RPC `feed_items_by_radius()` optimizada
- Exclusión de items ya pasados (interactions)
- Paginación y filtrado por frescura (24h)

### **✅ Geolocalización**
- Solicitud de permisos de ubicación
- Obtención de ubicación actual
- Redondeo de coordenadas para privacidad (~50m)
- Actualización automática de ubicación

## 🔧 **Configuración e Instalación**

### **1. Configuración de Supabase**

#### **Crear Proyecto:**
1. Ve a [supabase.com](https://supabase.com) y crea una cuenta
2. Crea un nuevo proyecto
3. Anota la URL del proyecto y la clave anónima

#### **Configurar Base de Datos:**
1. Ve al SQL Editor en tu proyecto de Supabase
2. Ejecuta el contenido completo del archivo `database_setup.sql`
3. Esto creará todas las tablas, políticas RLS, funciones y triggers

#### **Configurar Storage:**
1. Ve a Storage en tu proyecto de Supabase
2. Crea buckets:
   - `avatars` (privado)
   - `item-photos` (privado)

#### **Configurar Autenticación:**
1. Ve a Authentication > Settings
2. Habilita Email provider
3. Configura URLs de redirección según sea necesario

### **2. Configuración de la Aplicación Flutter**

#### **Actualizar Configuración de Supabase:**
1. Abre `lib/core/constants/supabase_constants.dart`
2. Reemplaza `YOUR_SUPABASE_URL` con la URL de tu proyecto
3. Reemplaza `YOUR_SUPABASE_ANON_KEY` con tu clave anónima

#### **Instalar Dependencias:**
```bash
flutter pub get
```

#### **Configurar Firebase (para notificaciones push):**
1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Crea un proyecto para Android/iOS
3. Descarga los archivos de configuración:
   - `google-services.json` para Android (coloca en `android/app/`)
   - `GoogleService-Info.plist` para iOS (coloca en `ios/Runner/`)

### **3. Ejecutar la Aplicación**
```bash
flutter run
```

## 📱 **Flujos de Usuario**

### **1. Registro y Login**
```
Signup → Creación automática de perfil → Permisos de ubicación → Home
Login → Permisos de ubicación → Home
```

### **2. Gestión de Perfil**
```
Home → Avatar → "Mi Perfil" → Editar username/avatar → Guardar
```

### **3. Creación de Artículos**
```
Home → "Mis Artículos" → Botón "+" → Formulario → Subir fotos → Crear
```

### **4. Exploración de Feed**
```
Home → "Explorar" → Feed por radio → Swipe (like/pass) → Chat
```

## 🎨 **UI/UX Design**

### **Material Design 3:**
- **Componentes modernos** con Material Design 3
- **Tema personalizado** con colores de marca
- **Bottom Sheets** para formularios
- **Cards** con elevación y bordes redondeados
- **Floating Action Buttons** para acciones principales

### **Responsive Design:**
- **Móvil primero** con diseño adaptativo
- **Grid responsive** para listas de items
- **Navegación fluida** entre pantallas
- **Estados de loading** y error bien manejados

## 🔍 **APIs y Servicios**

### **ProfileService:**
```dart
Future<UserProfile?> getCurrentProfile()
Future<void> updateProfile({...})
Future<void> updateLocation({required double latitude, required double longitude})
Future<void> uploadAvatarFromBytes(Uint8List fileBytes, String fileName)
```

### **ItemService:**
```dart
Future<Item> createItem({required String title, required String description, List<Uint8List>? photos})
Future<List<Item>> getUserItems()
Future<Item?> getItemWithPhotos(String itemId)
Future<Item> updateItem({required String itemId, ...})
Future<void> deleteItem(String itemId)
```

### **FeedService:**
```dart
Future<List<FeedItem>> getFeedItemsByRadius({
  required double latitude,
  required double longitude,
  double radiusKm = 10.0,
  int pageOffset = 0,
  int pageLimit = 20
})
```

## 🧪 **Testing y Debugging**

### **Logs de Debug:**
- **Profile loading**: Verificación de carga de perfiles
- **Location updates**: Confirmación de actualizaciones de ubicación
- **Item creation**: Seguimiento de creación de artículos
- **Storage uploads**: Monitoreo de subidas de archivos

### **Verificaciones de Base de Datos:**
```sql
-- Verificar RLS habilitado
SELECT relname, relrowsecurity FROM pg_class WHERE relnamespace = 'public'::regnamespace;

-- Verificar políticas RLS
SELECT schemaname, tablename, policyname, cmd FROM pg_policies WHERE schemaname = 'public';

-- Verificar funciones RPC
SELECT proname, proargnames FROM pg_proc WHERE proname IN ('feed_items_by_radius', 'handle_new_user');
```

## 🚀 **Próximos Pasos**

### **Funcionalidades Pendientes:**
1. **Sistema de Chat en Tiempo Real**
   - Mensajería entre usuarios
   - Estados de entrega
   - Notificaciones push

2. **Sistema de Interacciones**
   - Swipe gestures (like/pass)
   - Sistema de matches
   - Historial de interacciones

3. **Notificaciones Push**
   - Notificaciones de mensajes
   - Notificaciones de matches
   - Notificaciones de items cercanos

4. **Mejoras de UX**
   - Filtros avanzados en feed
   - Búsqueda de artículos
   - Categorías de items

## 📋 **Notas Importantes**

### **Seguridad:**
- **Todas las tablas** tienen RLS habilitado
- **URLs firmadas** para acceso temporal a archivos
- **Validaciones** tanto en cliente como servidor
- **Políticas granulares** por operación

### **Performance:**
- **Índices espaciales** para búsquedas PostGIS
- **Lazy loading** de imágenes
- **Cache** con CachedNetworkImage
- **Paginación** en feeds

### **Privacidad:**
- **Ubicaciones redondeadas** a ~50m de precisión
- **Sin historial** de ubicaciones
- **Opt-out** disponible en cualquier momento
- **Control total** del usuario sobre sus datos

### **Escalabilidad:**
- **Arquitectura modular** preparada para Edge Functions
- **Separación clara** de responsabilidades
- **APIs REST** estándar de Supabase
- **Gestión de estado** reactiva con Riverpod

## 🎉 **Estado del Proyecto**

El proyecto está en un estado **MVP funcional** con:
- ✅ **Autenticación completa**
- ✅ **Gestión de perfiles**
- ✅ **CRUD de artículos**
- ✅ **Sistema de feed geográfico**
- ✅ **Geolocalización**
- ✅ **Storage de archivos**

¡Listo para continuar con el desarrollo de funcionalidades avanzadas! 🚀
