-- Script para verificar y arreglar avatares de usuarios en el feed
-- Ejecuta este script en Supabase SQL Editor

-- 1. Ver usuarios y sus avatares actuales
SELECT 
  user_id, 
  username, 
  avatar_url,
  CASE 
    WHEN avatar_url IS NULL THEN 'Sin avatar'
    WHEN avatar_url LIKE 'http%' THEN 'URL externa'
    WHEN avatar_url LIKE 'avatars/%' THEN 'Path en storage'
    ELSE 'Desconocido'
  END as avatar_type
FROM profiles
ORDER BY username;

-- 2. Verificar datos del feed para un usuario específico
-- Reemplaza 'TU_USER_ID' con tu ID de usuario
SELECT 
  i.id as item_id,
  i.title as item_title,
  p.username as owner_username,
  p.avatar_url as owner_avatar_url,
  CASE 
    WHEN p.avatar_url IS NULL THEN 'Sin avatar'
    WHEN p.avatar_url LIKE 'http%' THEN 'URL externa'
    WHEN p.avatar_url LIKE 'avatars/%' THEN 'Path en storage'
    ELSE 'Desconocido'
  END as avatar_type
FROM items i
JOIN profiles p ON i.owner_id = p.user_id
WHERE i.status = 'available'
  AND i.owner_id != 'TU_USER_ID'
ORDER BY i.created_at DESC
LIMIT 10;

-- 3. Asignar avatares de Dicebear a usuarios que no tienen avatar
UPDATE profiles
SET avatar_url = 'https://api.dicebear.com/9.x/thumbs/png?seed=' || 
                 COALESCE(username, 'user' || user_id)
WHERE avatar_url IS NULL 
   OR avatar_url = '';

-- 4. Verificar usuarios con avatares en storage pero archivos no existen
-- Esta query lista avatares que están en formato de path pero podrían no existir en storage
SELECT 
  user_id,
  username,
  avatar_url,
  'Verificar si existe en Storage' as nota
FROM profiles
WHERE avatar_url LIKE 'avatars/%'
  AND avatar_url NOT LIKE 'http%';

-- 5. Test la función feed_items_by_radius para ver qué devuelve
-- Reemplaza 'TU_USER_ID' con tu ID de usuario
SELECT 
  item_id,
  item_title,
  owner_username,
  owner_avatar_url,
  distance_km,
  CASE 
    WHEN owner_avatar_url IS NULL THEN 'Sin avatar'
    WHEN owner_avatar_url LIKE 'http%' THEN 'URL externa'
    WHEN owner_avatar_url LIKE 'avatars/%' THEN 'Path en storage'
    ELSE 'Desconocido'
  END as avatar_type
FROM feed_items_by_radius(
  p_user_id := 'TU_USER_ID',
  p_radius_km := 50.0,
  p_page_offset := 0,
  p_page_limit := 20
);

