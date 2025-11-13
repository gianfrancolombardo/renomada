-- Migration: Add total_active_items and total_likes_given to get_users_last_10_days function
-- Adds two new fields to track user engagement metrics
DROP FUNCTION IF EXISTS public.get_users_last_10_days();

CREATE OR REPLACE FUNCTION public.get_users_last_10_days()

RETURNS TABLE (
  user_id uuid,
  email text,
  username text,
  created_at timestamptz,
  days_since_registration integer,
  total_active_items integer,
  total_likes_given integer
)

LANGUAGE sql

SECURITY DEFINER

STABLE

AS $$

  SELECT
    u.id AS user_id,
    u.email,
    p.username,
    u.created_at,
    FLOOR(EXTRACT(EPOCH FROM (now() - u.created_at)) / 86400)::int AS days_since_registration,
    COALESCE((
      SELECT COUNT(*)::int
      FROM public.items i
      WHERE i.owner_id = u.id
        AND i.status = 'available'
    ), 0) AS total_active_items,
    COALESCE((
      SELECT COUNT(*)::int
      FROM public.interactions ia
      WHERE ia.user_id = u.id
        AND ia.action = 'like'
    ), 0) AS total_likes_given
  FROM auth.users u
  LEFT JOIN public.profiles p ON p.user_id = u.id
  WHERE u.created_at >= (now() - interval '10 days')
    AND u.confirmed_at IS NOT NULL
  ORDER BY u.created_at DESC;

$$;

GRANT EXECUTE ON FUNCTION public.get_users_last_10_days() TO anon, authenticated;

COMMENT ON FUNCTION public.get_users_last_10_days() IS 
'Returns users registered in the last 10 days with their username, active items count, and total likes given.';

