-- Daily digest push recipients (last N hours rolling window).
-- REQUIRES: docs/migrations/add_push_notification_rpcs.sql applied first
-- (functions get_push_recipients_for_new_item, get_push_recipients_for_chat_message).

-- 1) All recipients that should be notified for items created in the lookback window.
--    Reuses per-item logic (radius / exclude owner) for each qualifying item.
create or replace function public.get_daily_digest_recipients_new_items(
  p_lookback_hours integer default 24,
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
begin
  if p_lookback_hours is null or p_lookback_hours < 1 then
    raise exception 'p_lookback_hours must be >= 1';
  end if;

  return query
  select distinct on (r.token)
    r.user_id,
    r.token,
    r.platform
  from public.items i
  inner join lateral public.get_push_recipients_for_new_item(i.id, p_radius_km) r on true
  where i.created_at >= now() - (interval '1 hour' * p_lookback_hours)
  order by r.token, r.user_id;
end;
$$;

-- 2) Recipients for new chat messages in the lookback window (other participant per message).
create or replace function public.get_daily_digest_recipients_new_messages(
  p_lookback_hours integer default 24
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
begin
  if p_lookback_hours is null or p_lookback_hours < 1 then
    raise exception 'p_lookback_hours must be >= 1';
  end if;

  return query
  select distinct on (r.token)
    r.user_id,
    r.token,
    r.platform
  from public.messages m
  inner join lateral public.get_push_recipients_for_chat_message(m.chat_id, m.sender_id) r on true
  where m.created_at >= now() - (interval '1 hour' * p_lookback_hours)
  order by r.token, r.user_id;
end;
$$;

-- 3) Single call for n8n: union of items + messages, deduplicated by device token.
create or replace function public.get_daily_digest_recipients_merged(
  p_lookback_hours integer default 24,
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
begin
  if p_lookback_hours is null or p_lookback_hours < 1 then
    raise exception 'p_lookback_hours must be >= 1';
  end if;

  return query
  select distinct on (x.token)
    x.user_id,
    x.token,
    x.platform
  from (
    select u.user_id, u.token, u.platform
    from public.get_daily_digest_recipients_new_items(p_lookback_hours, p_radius_km) u
    union all
    select m.user_id, m.token, m.platform
    from public.get_daily_digest_recipients_new_messages(p_lookback_hours) m
  ) x
  order by x.token, x.user_id;
end;
$$;

revoke all on function public.get_daily_digest_recipients_new_items(integer, double precision) from public;
grant execute on function public.get_daily_digest_recipients_new_items(integer, double precision) to service_role;

revoke all on function public.get_daily_digest_recipients_new_messages(integer) from public;
grant execute on function public.get_daily_digest_recipients_new_messages(integer) to service_role;

revoke all on function public.get_daily_digest_recipients_merged(integer, double precision) from public;
grant execute on function public.get_daily_digest_recipients_merged(integer, double precision) to service_role;
