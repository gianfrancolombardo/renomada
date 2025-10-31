#!/usr/bin/env python3
"""
Script para generar 10 items por cada usuario en la base de datos.

IMPORTANTE: Este script requiere la SERVICE_ROLE_KEY de Supabase para bypass RLS.
Para obtenerla:
1. Ve a tu proyecto en Supabase Dashboard
2. Settings > API
3. Copia la "service_role" key (secret)
4. Ejecuta: $env:SUPABASE_SERVICE_KEY="tu-service-key" ; python scripts/generate_items_for_users.py

O bien, edita este script y reemplaza SUPABASE_SERVICE_KEY directamente (NO LO SUBAS A GIT).
"""

import os
import sys
from datetime import datetime
from uuid import uuid4
from supabase import create_client, Client

# Photo path already uploaded to storage
PHOTO_PATH = 'item-photos/6e4b8abf-4fc0-49a4-ab0e-643cc0f764c6/359b4209-14f3-4a7d-b87c-8341f2a2e674_1760230616688_0.jpg'

# Supabase configuration (desde lib/core/constants/supabase_constants.dart)
SUPABASE_URL = 'https://izyqrmpoyxnjzoqlgjoa.supabase.co'
# ANON KEY - tiene restricciones RLS
SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6eXFybXBveXhuanpvcWxnam9hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NDI1MjksImV4cCI6MjA3NDMxODUyOX0.JnRB967BxmS6l4xx29zbZzCqjGeaBimt-bfaLqDQS3k'
# SERVICE ROLE KEY - bypass RLS
# IMPORTANTE: La service_role key NO está en el código por seguridad
# Para obtenerla: Supabase Dashboard > Settings > API > service_role key (secret)
# Luego ejecuta: $env:SUPABASE_SERVICE_KEY="tu-service-key" ; python scripts/generate_items_for_users.py
# O edita esta línea directamente (NO LO SUBAS A GIT):
SUPABASE_SERVICE_KEY = os.environ.get('SUPABASE_SERVICE_KEY', SUPABASE_ANON_KEY)
SUPABASE_KEY = SUPABASE_SERVICE_KEY  # Usamos service key si está disponible, si no usa anon

# Sample item data
SAMPLE_ITEMS = [
    {
        'title': 'Libro de Cocina Italiana',
        'description': 'Libro de recetas tradicionales italianas en excelente estado.',
        'condition': 'like_new',
        'exchange_type': 'exchange',
    },
    {
        'title': 'Mesa de Centro de Madera',
        'description': 'Mesa de centro vintage, perfecta para sala de estar. Algunas marcas de uso.',
        'condition': 'used',
        'exchange_type': 'exchange',
    },
    {
        'title': 'Lámpara de Pie Moderna',
        'description': 'Lámpara de diseño moderno, necesita cambio de bombilla.',
        'condition': 'needs_repair',
        'exchange_type': 'gift',
    },
    {
        'title': 'Bicicleta de Montaña',
        'description': 'Bicicleta en buen estado, ideal para rutas urbanas.',
        'condition': 'used',
        'exchange_type': 'exchange',
    },
    {
        'title': 'Set de Sartenes Antiadherentes',
        'description': 'Set completo de sartenes, prácticamente nuevo.',
        'condition': 'like_new',
        'exchange_type': 'exchange',
    },
    {
        'title': 'Plantas de Interior Variadas',
        'description': 'Variedad de plantas de interior en macetas decorativas.',
        'condition': 'used',
        'exchange_type': 'gift',
    },
    {
        'title': 'Guitarra Acústica',
        'description': 'Guitarra acústica, necesita ajuste de cuerdas.',
        'condition': 'needs_repair',
        'exchange_type': 'exchange',
    },
    {
        'title': 'Ropa Vintage de los 80s',
        'description': 'Colección de prendas vintage en buen estado.',
        'condition': 'used',
        'exchange_type': 'exchange',
    },
    {
        'title': 'Mesa de Comedor Extensible',
        'description': 'Mesa de comedor con hojas extensibles, perfecta para reuniones.',
        'condition': 'used',
        'exchange_type': 'exchange',
    },
    {
        'title': 'Electrodomésticos Pequeños',
        'description': 'Licuadora y exprimidor en excelente estado, casi sin uso.',
        'condition': 'like_new',
        'exchange_type': 'exchange',
    },
]


def get_profiles(supabase_client: Client):
    """Get all user profiles from Supabase"""
    try:
        print(f'[*] Intentando obtener perfiles...')
        print(f'[*] Usando SERVICE_KEY: {SUPABASE_KEY != SUPABASE_ANON_KEY}')
        
        response = supabase_client.table('profiles').select('user_id').execute()
        
        if not response.data:
            print(f'[!] No se encontraron perfiles con esta key.')
            print(f'[!] Intentando obtener usuarios directamente desde auth...')
            # Intentar obtener usuarios desde auth
            return get_users_from_auth(supabase_client)
        
        print(f'[OK] Encontrados {len(response.data)} perfiles')
        return response.data
        
    except Exception as e:
        print(f'[ERROR] Error obteniendo perfiles: {e}')
        # Si falla con profiles, intentar con auth.users
        print(f'[!] Intentando obtener usuarios desde auth...')
        return get_users_from_auth(supabase_client)


def get_users_from_auth(supabase_client: Client):
    """Get all users from auth (fallback method)"""
    try:
        print(f'[*] Consultando auth.users...')
        # El cliente de Supabase tiene acceso a auth.admin si usas service_role key
        # Intentamos obtener usuarios usando el método del cliente
        response = supabase_client.auth.admin.list_users()
        
        if response and hasattr(response, 'users'):
            users = response.users
            print(f'[OK] Encontrados {len(users)} usuarios en auth')
            # Convertir a formato similar a profiles
            return [{'user_id': user.id} for user in users]
        elif response and isinstance(response, list):
            print(f'[OK] Encontrados {len(response)} usuarios en auth')
            return [{'user_id': user.id} for user in response]
        else:
            print(f'[!] No se pudieron obtener usuarios de auth')
            return []
    except AttributeError:
        # Si no tiene el método admin, probablemente no es service_role key
        print(f'[ERROR] El cliente no tiene acceso a auth.admin')
        print(f'[ERROR] Necesitas usar SERVICE_ROLE_KEY, no ANON_KEY')
        return []
    except Exception as e:
        print(f'[ERROR] Error obteniendo usuarios de auth: {e}')
        print(f'[ERROR] Esto puede ser porque no estás usando SERVICE_ROLE_KEY')
        return []


def insert_item(supabase_client: Client, item_data):
    """Insert an item into Supabase"""
    response = supabase_client.table('items').insert(item_data).execute()
    return response.data


def insert_photo(supabase_client: Client, photo_data):
    """Insert a photo record into Supabase"""
    response = supabase_client.table('item_photos').insert(photo_data).execute()
    return response.data


def update_profile_location(supabase_client: Client, user_id: str, latitude: float, longitude: float):
    """Update profile with location and last_seen_at"""
    now = datetime.now().isoformat()
    
    try:
        # Use PostGIS ST_MakePoint function via RPC or raw SQL
        # Format: ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
        # But Supabase client doesn't support raw SQL easily, so we use the string format
        # The database should accept: SRID=4326;POINT(longitude latitude)
        location_string = f'SRID=4326;POINT({longitude} {latitude})'
        
        # Update profile with location using PostGIS format
        response = supabase_client.table('profiles').update({
            'last_location': location_string,
            'last_seen_at': now,
            'is_location_opt_out': False,
        }).eq('user_id', user_id).execute()
        
        return response.data
    except Exception as e:
        print(f'  [!] Error con formato SRID, intentando formato simple...')
        try:
            # Try simple POINT format (without SRID prefix)
            location_string = f'POINT({longitude} {latitude})'
            response = supabase_client.table('profiles').update({
                'last_location': location_string,
                'last_seen_at': now,
                'is_location_opt_out': False,
            }).eq('user_id', user_id).execute()
            return response.data
        except Exception as e2:
            print(f'  [!] Error actualizando ubicacion: {e2}')
            # Last resort: try using RPC if available
            try:
                response = supabase_client.rpc('update_profile_location', {
                    'p_user_id': user_id,
                    'p_longitude': longitude,
                    'p_latitude': latitude,
                }).execute()
                return response.data
            except:
                return None


def main():
    # Set UTF-8 encoding for Windows
    if sys.platform == 'win32':
        import codecs
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
        sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')
    
    print('[*] Iniciando script de generacion de items...\n')
    
    try:
        # Initialize Supabase client
        print('[*] Conectando a Supabase...')
        print(f'[*] URL: {SUPABASE_URL}')
        print(f'[*] Usando SERVICE_KEY: {SUPABASE_KEY != SUPABASE_ANON_KEY}')
        if SUPABASE_KEY == SUPABASE_ANON_KEY:
            print('[!] ADVERTENCIA: Estás usando ANON_KEY que tiene restricciones RLS.')
            print('[!] Para bypass RLS, configura SUPABASE_SERVICE_KEY como variable de entorno.')
            print('[!] Ejemplo: $env:SUPABASE_SERVICE_KEY="tu-service-key" ; python scripts/generate_items_for_users.py\n')
        
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        print('[OK] Cliente de Supabase inicializado correctamente\n')
        
        # Get all users from profiles table
        print('[*] Obteniendo lista de usuarios...')
        profiles = get_profiles(supabase)
        
        if not profiles:
            print('\n[!] No se encontraron usuarios.')
            print('[!] POSIBLES CAUSAS:')
            print('    1. No hay usuarios en la base de datos')
            print('    2. Las políticas RLS están bloqueando el acceso (usa SERVICE_ROLE_KEY)')
            print('\n[!] SOLUCION:')
            print('    1. Ve a Supabase Dashboard > Settings > API')
            print('    2. Copia la "service_role" key')
            print('    3. Ejecuta: $env:SUPABASE_SERVICE_KEY="tu-service-key" ; python scripts/generate_items_for_users.py')
            print('    4. O edita el script y reemplaza SUPABASE_SERVICE_KEY directamente\n')
            sys.exit(1)
        
        user_ids = [profile['user_id'] for profile in profiles]
        print(f'[OK] Encontrados {len(user_ids)} usuarios\n')
        
        # Generate items for each user
        # Use a default location (Madrid, Spain) for all users - you can change this
        DEFAULT_LATITUDE = 40.4168
        DEFAULT_LONGITUDE = -3.7038
        
        total_items_created = 0
        total_photos_created = 0
        total_profiles_updated = 0
        
        for i, user_id in enumerate(user_ids, 1):
            print(f'[*] Procesando usuario {i}/{len(user_ids)} ({user_id[:8]}...)')
            
            # Update profile with location and last_seen_at (IMPORTANT for feed_items_by_radius)
            try:
                update_profile_location(supabase, user_id, DEFAULT_LATITUDE, DEFAULT_LONGITUDE)
                total_profiles_updated += 1
                print(f'  [OK] Perfil actualizado con ubicacion')
            except Exception as e:
                print(f'  [!] Advertencia: No se pudo actualizar ubicacion: {e}')
            
            # Create 10 items for this user
            for j in range(10):
                sample_item = SAMPLE_ITEMS[j % len(SAMPLE_ITEMS)]
                item_id = str(uuid4())
                now = datetime.now().isoformat()
                
                # Create item record
                item_data = {
                    'id': item_id,
                    'owner_id': user_id,
                    'title': sample_item['title'],
                    'description': sample_item['description'],
                    'status': 'available',
                    'condition': sample_item['condition'],
                    'exchange_type': sample_item['exchange_type'],
                    'created_at': now,
                }
                
                try:
                    insert_item(supabase, item_data)
                    
                    # Create photo record for this item
                    photo_id = str(uuid4())
                    photo_record = {
                        'id': photo_id,
                        'item_id': item_id,
                        'path': PHOTO_PATH,
                        'mime_type': 'image/jpeg',
                        'size_bytes': None,
                        'created_at': now,
                    }
                    
                    insert_photo(supabase, photo_record)
                    
                    total_items_created += 1
                    total_photos_created += 1
                except Exception as e:
                    print(f'  [!] Error creando item {j+1} para usuario {user_id[:8]}...: {e}')
            
            print(f'  [OK] Creados 10 items para usuario {user_id[:8]}...\n')
        
        print('=' * 60)
        print('[*] Proceso completado exitosamente!')
        print('[*] Resumen:')
        print(f'   - Usuarios procesados: {len(user_ids)}')
        print(f'   - Perfiles actualizados con ubicacion: {total_profiles_updated}')
        print(f'   - Items creados: {total_items_created}')
        print(f'   - Fotos asociadas: {total_photos_created}')
        print('=' * 60)
        print('\n[!] IMPORTANTE: Asegurate de que el usuario que consulta el feed')
        print('    tambien tenga last_location y last_seen_at actualizados en su perfil.')
        
    except Exception as e:
        print(f'\n[ERROR] Error durante la ejecucion:')
        print(f'   {e}')
        import traceback
        print(f'\n[*] Stack trace:')
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
