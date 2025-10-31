-- ===== AUTO-GENERATE USERNAME FROM EMAIL =====
-- Migration to automatically generate username from email (without domain)
-- Works for any authentication provider (email/password, Google OAuth, etc.)

-- Drop existing function
drop function if exists public.handle_new_user() cascade;

-- Recreate the function with automatic username generation from email
create or replace function public.handle_new_user()
returns trigger as $$
declare
  username_value text;
  avatar_url_value text;
  random_seed text;
  email_username text;
  base_username text;
  username_counter integer;
begin
  -- Extract username from email (part before @)
  email_username := split_part(new.email, '@', 1);
  
  -- Sanitize username: replace dots, hyphens, and other special chars with underscores
  -- Allow only alphanumeric and underscores
  base_username := regexp_replace(lower(email_username), '[^a-z0-9_]', '_', 'g');
  
  -- Ensure username doesn't start or end with underscore
  base_username := trim(both '_' from base_username);
  
  -- Ensure username is not empty after sanitization
  if base_username = '' or base_username is null then
    base_username := 'user_' || extract(epoch from now())::text;
  end if;
  
  -- Check if username already exists and make it unique
  username_value := base_username;
  username_counter := 1;
  
  while exists (select 1 from public.profiles where username = username_value) loop
    username_value := base_username || '_' || username_counter::text;
    username_counter := username_counter + 1;
  end loop;
  
  -- Get random seed for dicebear avatar
  random_seed := public.get_random_avatar_seed();
  
  -- Generate dicebear avatar url
  avatar_url_value := 'https://api.dicebear.com/9.x/thumbs/png?seed=' || random_seed;
  
  -- Insert new profile with auto-generated username
  insert into public.profiles (user_id, username, avatar_url)
  values (new.id, username_value, avatar_url_value);
  
  return new;
end;
$$ language plpgsql security definer;

-- Recreate trigger to automatically create profile on user signup
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Add comment
comment on function public.handle_new_user is 'Automatically creates user profile with username extracted from email';

-- ===== VERIFICATION =====
-- You can test this with:
-- 1. Sign up with email: test.user@example.com -> username will be "test_user"
-- 2. Sign up with Google using email: john.doe@gmail.com -> username will be "john_doe"
-- 3. If username exists, it will append a number: "test_user_1", "test_user_2", etc.

