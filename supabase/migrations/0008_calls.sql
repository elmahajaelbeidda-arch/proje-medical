-- =========================================================================
-- «المكالمات الصوتية والمرئية» — شِفاءٌ لِلنّاس / جمعية عون وسند الخيرية
-- Calls inside the app, through LiveKit. The server gives each person a
-- short-lived ticket (signed token) for the private room of THEIR
-- consultation only; the LiveKit secret stays in this database.
--
-- Needs 0006. Run in Supabase: SQL Editor > New query > paste > Run.
-- Then, in a NEW query, put your LiveKit project's values (never share
-- them in a chat):
--
--   insert into private.livekit (url, api_key, api_secret)
--   values ('wss://YOUR-PROJECT.livekit.cloud', 'API_KEY', 'API_SECRET')
--   on conflict (id) do update
--     set url = excluded.url, api_key = excluded.api_key,
--         api_secret = excluded.api_secret;
-- =========================================================================

create extension if not exists pgcrypto with schema extensions;

-- Not reachable from the app (only «public» is exposed by Supabase).
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.livekit (
  id         int primary key default 1 check (id = 1),
  url        text not null,
  api_key    text not null,
  api_secret text not null
);

create or replace function public.b64url(p bytea)
returns text language sql immutable as $$
  select replace(replace(replace(replace(encode(p, 'base64'),
    E'\n', ''), '+', '-'), '/', '_'), '=', '');
$$;

-- Ticket for the call of a consultation: only its patient, its doctor, or
-- the team. Valid one hour; room «shifa-<consultation id>».
create or replace function public.call_token(p_consultation uuid)
returns jsonb language plpgsql security definer
set search_path = public, extensions as $$
declare
  cfg record;
  me uuid := auth.uid();
  v_name text;
  v_room text := 'shifa-' || p_consultation::text;
  now_s bigint := extract(epoch from now())::bigint;
  hdr text;
  body text;
  sig text;
begin
  if me is null then raise exception 'not signed in'; end if;
  if not (public.in_consultation(p_consultation) or public.is_staff()) then
    raise exception 'not allowed';
  end if;
  select * into cfg from private.livekit where id = 1;
  if not found then raise exception 'calls not configured'; end if;
  select name into v_name from public.profiles where user_id = me;

  hdr := public.b64url(convert_to('{"alg":"HS256","typ":"JWT"}', 'utf8'));
  body := public.b64url(convert_to(jsonb_build_object(
    'iss', cfg.api_key,
    'sub', me::text,
    'name', coalesce(v_name, ''),
    'nbf', now_s - 10,
    'exp', now_s + 3600,
    'video', jsonb_build_object(
      'room', v_room,
      'roomJoin', true,
      'canPublish', true,
      'canSubscribe', true
    )
  )::text, 'utf8'));
  sig := public.b64url(extensions.hmac(
    convert_to(hdr || '.' || body, 'utf8'),
    convert_to(cfg.api_secret, 'utf8'),
    'sha256'
  ));
  return jsonb_build_object(
    'url', cfg.url,
    'room', v_room,
    'token', hdr || '.' || body || '.' || sig
  );
end $$;

revoke all on function public.call_token(uuid) from public, anon;
grant execute on function public.call_token(uuid) to authenticated;
