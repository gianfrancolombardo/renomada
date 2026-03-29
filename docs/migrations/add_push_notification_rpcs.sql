-- Push notifications: push_tokens metadata + RPCs for n8n (service_role only).

alter table public.push_tokens
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists is_active boolean not null default true;

create or replace function public.get_push_recipients_for_new_item(
  p_item_id uuid,
  p_radius_km double precision default 0
)
returns table (
  user_id uuid,
  token text,
  platform text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid;
  v_owner_loc geography;
begin
  select i.owner_id into v_owner_id
  from public.items i
  where i.id = p_item_id;

  if v_owner_id is null then
    return;
  end if;

  select p.last_location into v_owner_loc
  from public.profiles p
  where p.user_id = v_owner_id;

  if p_radius_km is null or p_radius_km <= 0 then
    return query
    select distinct on (t.token)
      t.user_id,
      t.token,
      t.platform
    from public.push_tokens t
    where t.user_id <> v_owner_id
      and t.is_active = true
    order by t.token, t.user_id;
    return;
  end if;

  if v_owner_loc is null then
    return;
  end if;

  return query
  select distinct on (t.token)
    t.user_id,
    t.token,
    t.platform
  from public.profiles p
  inner join public.push_tokens t on t.user_id = p.user_id
  where p.user_id <> v_owner_id
    and t.is_active = true
    and p.last_location is not null
    and st_dwithin(
      p.last_location::geography,
      v_owner_loc::geography,
      p_radius_km * 1000
    )
  order by t.token, t.user_id;
end;
$$;

create or replace function public.get_push_recipients_for_chat_message(
  p_chat_id uuid,
  p_sender_id uuid
)
returns table (
  user_id uuid,
  token text,
  platform text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recipient uuid;
begin
  select
    case
      when c.a_user_id = p_sender_id then c.b_user_id
      when c.b_user_id = p_sender_id then c.a_user_id
      else null
    end
  into v_recipient
  from public.chats c
  where c.id = p_chat_id;

  if v_recipient is null then
    return;
  end if;

  return query
  select distinct on (t.token)
    t.user_id,
    t.token,
    t.platform
  from public.push_tokens t
  where t.user_id = v_recipient
    and t.is_active = true
  order by t.token, t.user_id;
end;
$$;

revoke all on function public.get_push_recipients_for_new_item(uuid, double precision) from public;
grant execute on function public.get_push_recipients_for_new_item(uuid, double precision) to service_role;

revoke all on function public.get_push_recipients_for_chat_message(uuid, uuid) from public;
grant execute on function public.get_push_recipients_for_chat_message(uuid, uuid) to service_role;
