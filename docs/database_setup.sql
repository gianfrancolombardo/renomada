-- ===== RENOMADA DATABASE SETUP COMPLETE =====
-- Setup completo de base de datos para Renomada
-- Incluye: Extensiones, tablas, políticas RLS, funciones RPC, triggers y storage

-- ===== 1. EXTENSIONS =====
create extension if not exists pgcrypto;   -- gen_random_uuid()
create extension if not exists postgis;    -- geography, ST_DWithin

-- ===== 2. ENUMS =====
-- Crear tipo enum para status de items
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'item_status') THEN
        CREATE TYPE item_status AS ENUM ('available', 'exchanged', 'paused');
    END IF;
END $$;

-- ===== 3. TABLES =====

-- ===== PROFILES =====
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  avatar_url text,
  last_location geography(point,4326),
  last_seen_at timestamptz,
  is_location_opt_out boolean not null default false
);

-- Spatial index for radius queries
create index if not exists profiles_last_location_gix
  on public.profiles using gist (last_location);

alter table public.profiles enable row level security;

-- Only the owner can read/update their own profile
drop policy if exists profiles_self_select on public.profiles;
create policy profiles_self_select
  on public.profiles for select
  using (auth.uid() = user_id);

drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_update
  on public.profiles for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Insert only by the authenticated user for their own row
drop policy if exists profiles_self_insert on public.profiles;
create policy profiles_self_insert
  on public.profiles for insert
  with check (auth.uid() = user_id);

-- ===== ITEMS =====
create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  status item_status not null default 'available',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists items_owner_idx on public.items(owner_id);
create index if not exists items_status_idx on public.items(status);
create index if not exists items_created_idx on public.items(created_at);

alter table public.items enable row level security;

-- Owner can do everything on their items
drop policy if exists items_owner_all on public.items;
create policy items_owner_all
  on public.items for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- ===== ITEM_PHOTOS =====
create table if not exists public.item_photos (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  path text not null,
  mime_type text,
  size_bytes integer,
  created_at timestamptz not null default now()
);

create index if not exists item_photos_item_idx on public.item_photos(item_id);

alter table public.item_photos enable row level security;

-- Only the item owner can manage photo records
drop policy if exists item_photos_owner_all on public.item_photos;
create policy item_photos_owner_all
  on public.item_photos for all
  using (exists (
    select 1 from public.items i where i.id = item_photos.item_id and i.owner_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.items i where i.id = item_photos.item_id and i.owner_id = auth.uid()
  ));

-- ===== INTERACTIONS =====
create table if not exists public.interactions (
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null references public.items(id) on delete cascade,
  action text not null check (action in ('like','pass')),
  created_at timestamptz not null default now(),
  primary key (user_id, item_id)
);

create index if not exists interactions_item_idx on public.interactions(item_id);
create index if not exists interactions_user_idx on public.interactions(user_id);

alter table public.interactions enable row level security;

drop policy if exists interactions_self_all on public.interactions;
create policy interactions_self_all
  on public.interactions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ===== CHATS =====
create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items(id) on delete cascade,
  a_user_id uuid not null references auth.users(id),
  b_user_id uuid not null references auth.users(id),
  status text not null default 'coordinating',
  created_at timestamptz not null default now(),
  check (a_user_id <> b_user_id),
  unique (item_id, a_user_id, b_user_id)
);

create index if not exists chats_item_idx on public.chats(item_id);
create index if not exists chats_participant_a_idx on public.chats(a_user_id);
create index if not exists chats_participant_b_idx on public.chats(b_user_id);

alter table public.chats enable row level security;

drop policy if exists chats_participants_select on public.chats;
create policy chats_participants_select
  on public.chats for select
  using (auth.uid() = a_user_id or auth.uid() = b_user_id);

drop policy if exists chats_participants_insert on public.chats;
create policy chats_participants_insert
  on public.chats for insert
  with check (auth.uid() = a_user_id or auth.uid() = b_user_id);

-- ===== MESSAGES =====
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid not null references auth.users(id),
  content text not null,
  status text not null default 'sent',
  created_at timestamptz not null default now()
);

create index if not exists messages_chat_created_idx on public.messages(chat_id, created_at);

alter table public.messages enable row level security;

drop policy if exists messages_participants_select on public.messages;
create policy messages_participants_select
  on public.messages for select
  using (exists (
    select 1 from public.chats c
    where c.id = messages.chat_id
      and (auth.uid() = c.a_user_id or auth.uid() = c.b_user_id)
  ));

drop policy if exists messages_participants_insert on public.messages;
create policy messages_participants_insert
  on public.messages for insert
  with check (exists (
    select 1 from public.chats c
    where c.id = messages.chat_id
      and (auth.uid() = c.a_user_id or auth.uid() = c.b_user_id)
  ));

-- ===== PUSH_TOKENS =====
create table if not exists public.push_tokens (
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('web','android','ios')),
  token text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, platform, token)
);

create unique index if not exists push_tokens_token_uidx on public.push_tokens(token);

alter table public.push_tokens enable row level security;

drop policy if exists push_tokens_self_all on public.push_tokens;
create policy push_tokens_self_all
  on public.push_tokens for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ===== 4. STORAGE POLICIES =====

-- Create buckets if they don't exist
insert into storage.buckets (id, name, public)
values 
  ('avatars', 'avatars', false),
  ('item-photos', 'item-photos', false)
on conflict (id) do nothing;


-- ===== AVATAR POLICIES =====
create policy "storage_avatars_owner_insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

create policy "storage_avatars_owner_update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

create policy "storage_avatars_owner_select"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

create policy "storage_avatars_owner_delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

-- ===== ITEM PHOTOS POLICIES =====
-- Public read access for available item photos
create policy "Public read access for available item photos"
  on storage.objects
  for select using (
    bucket_id = 'item-photos' 
    and exists (
      select 1 from public.items
      where id::text = (regexp_match(name, '^item-photos/[^/]+/([^_]+)_'))[1]
        and status = 'available'
    )
  );

-- Owners can upload item photos
create policy "Owners can upload item photos"
  on storage.objects
  for insert with check (
    bucket_id = 'item-photos' 
    and auth.uid()::text = (regexp_match(name, '^item-photos/([^/]+)/'))[1]
    and exists (
      select 1 from public.items
      where id::text = (regexp_match(name, '^item-photos/[^/]+/([^_]+)_'))[1]
        and owner_id = auth.uid()
    )
  );

-- Owners can update item photos
create policy "Owners can update item photos"
  on storage.objects
  for update using (
    bucket_id = 'item-photos' 
    and auth.uid()::text = (regexp_match(name, '^item-photos/([^/]+)/'))[1]
    and exists (
      select 1 from public.items
      where id::text = (regexp_match(name, '^item-photos/[^/]+/([^_]+)_'))[1]
        and owner_id = auth.uid()
    )
  );

-- Owners can delete item photos
create policy "Owners can delete item photos"
  on storage.objects
  for delete using (
    bucket_id = 'item-photos' 
    and auth.uid()::text = (regexp_match(name, '^item-photos/([^/]+)/'))[1]
    and exists (
      select 1 from public.items
      where id::text = (regexp_match(name, '^item-photos/[^/]+/([^_]+)_'))[1]
        and owner_id = auth.uid()
    )
  );

-- Owners can list their item photos
create policy "Owners can list their item photos"
  on storage.objects
  for select using (
    bucket_id = 'item-photos' 
    and auth.uid()::text = (regexp_match(name, '^item-photos/([^/]+)/'))[1]
  );

-- ===== 5. RPC FUNCTIONS =====

-- ===== FEED ITEMS BY RADIUS =====
-- Drop existing function first
drop function if exists public.feed_items_by_radius(double precision,double precision,double precision, integer);
drop function if exists public.feed_items_by_radius(uuid, float, integer, integer);

-- Create the final version of the function
create or replace function public.feed_items_by_radius(
  p_user_id uuid,
  p_radius_km float default 10.0,
  p_page_offset integer default 0,
  p_page_limit integer default 20
)
returns table(
  -- Item fields
  item_id uuid,
  item_title text,
  item_description text,
  item_status text,
  item_created_at timestamptz,
  item_updated_at timestamptz,
  
  -- Owner fields
  owner_id uuid,
  owner_username text,
  owner_avatar_url text,
  owner_last_seen_at timestamptz,
  
  -- Distance and photo
  distance_km float,
  first_photo_path text
)
language plpgsql
security definer
as $$
declare
  user_lat float;
  user_lng float;
  user_location geometry;
begin
  -- Get current user coordinates
  select st_y(last_location::geometry), st_x(last_location::geometry), last_location::geometry
  into user_lat, user_lng, user_location
  from profiles
  where user_id = p_user_id;
  
  -- If no location, return empty
  if user_lat is null or user_lng is null or user_location is null then
    raise notice 'User % has no location data', p_user_id;
    return;
  end if;
  
  -- Return items from nearby users
  return query
  with nearby_users as (
    select 
      p.user_id,
      p.username,
      p.avatar_url,
      p.last_seen_at,
      st_distance(
        p.last_location::geography,
        user_location::geography
      ) / 1000.0 as distance_km
    from profiles p
    where p.last_location is not null
      and p.user_id != p_user_id
      and st_dwithin(
        p.last_location::geography,
        user_location::geography,
        p_radius_km * 1000
      )
      and p.last_seen_at > now() - interval '7 days'
    order by distance_km asc
    limit 50
  ),
  user_items as (
    select 
      i.id as item_id,
      i.title as item_title,
      i.description as item_description,
      i.status::text as item_status,
      i.created_at as item_created_at,
      i.updated_at as item_updated_at,
      i.owner_id as owner_id,
      nu.username as owner_username,
      nu.avatar_url as owner_avatar_url,
      nu.last_seen_at as owner_last_seen_at,
      nu.distance_km,
      (
        select ip.path 
        from item_photos ip 
        where ip.item_id = i.id 
        order by ip.created_at asc 
        limit 1
      ) as first_photo_path
    from items i
    join nearby_users nu on i.owner_id = nu.user_id
    where i.status = 'available'
      and i.id not in (
        select interactions.item_id 
        from interactions 
        where interactions.user_id = p_user_id 
          and interactions.action = 'pass'
      )
    order by nu.distance_km asc, i.created_at desc
    limit p_page_limit offset p_page_offset
  )
  select 
    ui.item_id,
    ui.item_title,
    ui.item_description,
    ui.item_status,
    ui.item_created_at,
    ui.item_updated_at,
    ui.owner_id,
    ui.owner_username,
    ui.owner_avatar_url,
    ui.owner_last_seen_at,
    ui.distance_km,
    ui.first_photo_path
  from user_items ui;
end;
$$;

-- Grant execute permissions
revoke all on function public.feed_items_by_radius(uuid, float, integer, integer) from public;
grant execute on function public.feed_items_by_radius(uuid, float, integer, integer) to authenticated;

-- Add comment
comment on function public.feed_items_by_radius is 'Obtiene items del feed filtrados por radio de distancia desde la ubicación del usuario';

-- ===== 6. UTILITY FUNCTIONS =====

-- ===== RANDOM AVATAR SEED =====
create or replace function public.get_random_avatar_seed()
returns text as $$
declare
  seeds text[] := array['valentina', 'sara', 'sophia', 'avery', 'adrian', 'emery', 'alex', 'jordan', 'taylor', 'casey'];
begin
  return seeds[1 + floor(random() * array_length(seeds, 1))];
end;
$$ language plpgsql;

-- ===== 7. TRIGGERS =====

-- ===== AUTO-CREATE PROFILE ON USER SIGNUP =====
create or replace function public.handle_new_user()
returns trigger as $$
declare
  username_value text;
  avatar_url_value text;
  random_seed text;
begin
  -- Generate username from user id or metadata
  if new.raw_user_meta_data->>'username' is not null then
    username_value := new.raw_user_meta_data->>'username';
  else
    username_value := 'user_' || extract(epoch from now())::text;
  end if;
  
  -- Get random seed for dicebear avatar
  random_seed := get_random_avatar_seed();
  
  -- Generate dicebear avatar url
  avatar_url_value := 'https://api.dicebear.com/9.x/thumbs/png?seed=' || random_seed;
  
  -- Insert new profile
  insert into public.profiles (user_id, username, avatar_url)
  values (new.id, username_value, avatar_url_value);
  
  return new;
end;
$$ language plpgsql security definer;

-- Create trigger to automatically create profile on user signup
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ===== AUTO-UPDATE UPDATED_AT =====
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Add updated_at trigger to items
drop trigger if exists items_updated_at on public.items;
create trigger items_updated_at
  before update on public.items
  for each row execute procedure public.handle_updated_at();

-- ===== 8. REALTIME =====
-- Ensure messages and chats are in the publication used by realtime
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.chats;

-- ===== 9. FINAL SETUP =====
-- Ensure RLS is enabled on storage
alter table storage.objects enable row level security;

-- Add helpful comments
comment on column public.items.status is 'Estado del artículo: available (disponible), exchanged (intercambiado), paused (pausado)';

-- ===== 10. VERIFICATION QUERIES =====
-- Uncomment these to verify the setup:

/*
-- Verify tables exist
select table_name from information_schema.tables 
where table_schema = 'public' 
order by table_name;

-- Verify RLS is enabled
select relname, relrowsecurity 
from pg_class 
where relnamespace = 'public'::regnamespace;

-- Verify policies exist
select schemaname, tablename, policyname, cmd 
from pg_policies 
where schemaname in ('public', 'storage')
order by tablename, policyname;

-- Verify functions exist
select proname, proargnames 
from pg_proc 
where proname in ('feed_items_by_radius', 'handle_new_user', 'get_random_avatar_seed');

-- Test random avatar seed
select get_random_avatar_seed() as seed1, get_random_avatar_seed() as seed2, get_random_avatar_seed() as seed3;

-- ===== CHAT RPC FUNCTIONS =====

-- ===== ITEM RPC FUNCTIONS =====

-- Function to get item owner and title (bypasses RLS for chat creation)
create or replace function get_item_owner(item_id uuid)
returns table (owner_id uuid, title text)
language plpgsql
security definer
as $$
begin
  return query
  select i.owner_id, i.title
  from items i
  where i.id = item_id;
end;
$$;

-- Grant execute permissions
grant execute on function get_item_owner(uuid) to authenticated;

-- ===== END ITEM RPC FUNCTIONS =====

-- ===== CHAT RPC FUNCTIONS =====

-- Function to get user chats with details (bypasses RLS for chat list)
create or replace function get_user_chats_with_details(p_user_id uuid)
returns table (
  chat_id uuid,
  item_id uuid,
  a_user_id uuid,
  b_user_id uuid,
  chat_status text,
  chat_created_at timestamptz,
  item_title text,
  item_description text,
  item_status text,
  item_owner_id uuid,
  other_user_id uuid,
  other_username text,
  other_avatar_url text,
  last_message_id uuid,
  last_message_content text,
  last_message_created_at timestamptz,
  last_message_sender_id uuid,
  unread_count bigint
)
language plpgsql
security definer
as $$
begin
  return query
  select 
    c.id as chat_id,
    c.item_id,
    c.a_user_id,
    c.b_user_id,
    c.status as chat_status,
    c.created_at as chat_created_at,
    i.title as item_title,
    i.description as item_description,
    i.status::text as item_status,
    i.owner_id as item_owner_id,
    case 
      when c.a_user_id = p_user_id then c.b_user_id
      else c.a_user_id
    end as other_user_id,
    p.username as other_username,
    p.avatar_url as other_avatar_url,
    m.id as last_message_id,
    m.content as last_message_content,
    m.created_at as last_message_created_at,
    m.sender_id as last_message_sender_id,
    coalesce(unread.count, 0) as unread_count
  from chats c
  inner join items i on c.item_id = i.id
  left join profiles p on (
    case 
      when c.a_user_id = p_user_id then c.b_user_id
      else c.a_user_id
    end = p.user_id
  )
  left join lateral (
    select id, content, created_at, sender_id
    from messages
    where messages.chat_id = c.id
    order by created_at desc
    limit 1
  ) m on true
  left join lateral (
    select count(*) as count
    from messages
    where messages.chat_id = c.id
      and sender_id != p_user_id
      and status != 'read'
  ) unread on true
  where c.a_user_id = p_user_id or c.b_user_id = p_user_id
  order by c.created_at desc;
end;
$$;

-- Grant execute permissions
grant execute on function get_user_chats_with_details(uuid) to authenticated;

-- ===== END CHAT RPC FUNCTIONS =====

-- ===== REALTIME CONFIGURATION =====

-- Enable realtime for chats table
alter publication supabase_realtime add table public.chats;

-- Enable realtime for messages table  
alter publication supabase_realtime add table public.messages;

-- Enable realtime for interactions table (for swipe updates)
alter publication supabase_realtime add table public.interactions;

-- ===== END REALTIME CONFIGURATION =====
*/
