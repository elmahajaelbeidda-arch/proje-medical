-- =========================================================================
-- عدّاد الزوار العام — شِفاءٌ لِلنّاس
-- Public counter: total visits since launch, visitors today, people online
-- now, registered users and beneficiaries. Readable by everyone, visitors
-- included; nobody can read who visited.
--
-- Privacy: a visitor is a random id created on the device. No name, phone,
-- IP address or location is stored.
--
-- Run after 0001 (uses patients_requests): SQL Editor > paste > Run.
-- =========================================================================

create table if not exists public.app_visitors (
  visitor_id    text primary key check (visitor_id ~ '^[A-Za-z0-9-]{16,64}$'),
  first_seen    timestamptz not null default now(),
  last_seen     timestamptz not null default now(),
  last_visit_at timestamptz not null default now()
);
create index if not exists app_visitors_last_seen_idx on public.app_visitors (last_seen desc);

-- One row per visitor and day (for "visitors today").
create table if not exists public.app_visitor_days (
  day        date not null,
  visitor_id text not null references public.app_visitors (visitor_id) on delete cascade,
  primary key (day, visitor_id)
);

-- Running totals (one row).
create table if not exists public.app_stats (
  id                 boolean primary key default true check (id),
  total_visits       bigint not null default 0,
  -- Beneficiaries helped outside the app (set by the association).
  beneficiaries_base integer not null default 0,
  show_registered    boolean not null default true,
  show_beneficiaries boolean not null default true
);
insert into public.app_stats (id) values (true) on conflict do nothing;

alter table public.app_visitors     enable row level security;
alter table public.app_visitor_days enable row level security;
alter table public.app_stats        enable row level security;
-- No policies on app_visitors / app_visitor_days: only the functions below
-- touch them. Supervisors adjust the public options of app_stats.
create policy "supervisors update stats options" on public.app_stats
  for update to authenticated using (public.is_supervisor()) with check (public.is_supervisor());

-- Called when the app opens, then every minute while it stays open.
-- A new visit is counted after 30 minutes without activity.
create or replace function public.record_visit(p_visitor text)
returns void language plpgsql security definer set search_path = public as $$
declare v app_visitors;
begin
  if p_visitor !~ '^[A-Za-z0-9-]{16,64}$' then
    raise exception 'invalid visitor id';
  end if;
  select * into v from app_visitors where visitor_id = p_visitor for update;
  if not found then
    insert into app_visitors (visitor_id) values (p_visitor);
    update app_stats set total_visits = total_visits + 1;
  elsif v.last_seen < now() - interval '30 minutes' then
    update app_visitors set last_seen = now(), last_visit_at = now() where visitor_id = p_visitor;
    update app_stats set total_visits = total_visits + 1;
  elsif v.last_seen < now() - interval '20 seconds' then
    update app_visitors set last_seen = now() where visitor_id = p_visitor;
  end if;
  insert into app_visitor_days (day, visitor_id)
    values ((now() at time zone 'Africa/Nouakchott')::date, p_visitor)
    on conflict do nothing;
end $$;

-- The public figures (no individual data).
create or replace function public.public_stats()
returns json language sql stable security definer set search_path = public as $$
  select json_build_object(
    'total_visits',   s.total_visits,
    'today_visitors', (select count(*) from app_visitor_days
                       where day = (now() at time zone 'Africa/Nouakchott')::date),
    'online_now',     (select count(*) from app_visitors
                       where last_seen > now() - interval '2 minutes'),
    'registered',     case when s.show_registered
                           then (select count(*) from auth.users) end,
    'beneficiaries',  case when s.show_beneficiaries
                           then s.beneficiaries_base
                                + (select count(distinct user_id) from patients_requests
                                   where status in ('helped', 'closed')) end
  )
  from app_stats s;
$$;

grant execute on function public.record_visit(text), public.public_stats() to anon, authenticated;

-- Keep the table small: visitor days older than 90 days are not needed.
-- (Optional, with the pg_cron extension:)
-- select cron.schedule('trim-visitor-days', '0 3 * * *',
--   $$delete from public.app_visitor_days where day < current_date - 90$$);

-- Beneficiaries helped before the app (example):
-- update public.app_stats set beneficiaries_base = 350;
