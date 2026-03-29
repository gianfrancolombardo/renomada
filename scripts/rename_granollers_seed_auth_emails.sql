-- Supabase Dashboard → SQL Editor (once). Only the two seed user UUIDs.
-- New logins (app validator needs TLD length 2–4, e.g. .com):
--   grano1@test.com / grano2@test.com  password: 123456.a

UPDATE auth.users
SET email = 'grano1@test.com'
WHERE id = '754f655e-3951-48b6-ad7d-a5c2574a56f7';

UPDATE auth.users
SET email = 'grano2@test.com'
WHERE id = '4327808c-a049-469c-9d57-1db9f91d9a0b';

UPDATE auth.identities
SET identity_data = jsonb_set(
    identity_data::jsonb,
    '{email}',
    to_jsonb('grano1@test.com'::text),
    true
)
WHERE user_id = '754f655e-3951-48b6-ad7d-a5c2574a56f7'
  AND provider = 'email';

UPDATE auth.identities
SET identity_data = jsonb_set(
    identity_data::jsonb,
    '{email}',
    to_jsonb('grano2@test.com'::text),
    true
)
WHERE user_id = '4327808c-a049-469c-9d57-1db9f91d9a0b'
  AND provider = 'email';
