-- =========================================================================
-- «فريق المتابعة والإدارة» — شِفاءٌ لِلنّاس / جمعية عون وسند الخيرية
-- Dashboard on the server: who is in the team (and with which role), and
-- the dashboard data, readable and writable by the team only.
--
-- Run in Supabase: SQL Editor > New query > paste > Run (safe to run again).
-- =========================================================================

-- ---------- Team members --------------------------------------------------
create table if not exists public.admin_staff (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  email      text not null default '',
  name       text not null default '',
  role       text not null default 'followUp' check (role in (
               'superAdmin', 'registrations', 'medical', 'finance',
               'communications', 'auditor', 'followUp')),
  active     boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.admin_staff enable row level security;

-- Helpers (security definer: they read admin_staff whatever the caller).
create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.admin_staff where user_id = auth.uid() and active
  );
$$;

create or replace function public.is_super_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.admin_staff
    where user_id = auth.uid() and active and role = 'superAdmin'
  );
$$;

drop policy if exists "staff read team" on public.admin_staff;
create policy "staff read team" on public.admin_staff
  for select to authenticated using (public.is_staff());

drop policy if exists "super admins manage team" on public.admin_staff;
create policy "super admins manage team" on public.admin_staff
  for all to authenticated
  using (public.is_super_admin()) with check (public.is_super_admin());

-- Add (or update) a member by the e-mail of an existing account
-- (Authentication > Users > Add user, then this from the dashboard).
create or replace function public.grant_staff(p_email text, p_name text, p_role text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not public.is_super_admin() then
    raise exception 'not allowed';
  end if;
  select id into v_id from auth.users where lower(email) = lower(trim(p_email));
  if v_id is null then
    raise exception 'no account with this e-mail';
  end if;
  insert into public.admin_staff (user_id, email, name, role)
  values (v_id, lower(trim(p_email)), coalesce(nullif(trim(p_name), ''), p_email), p_role)
  on conflict (user_id) do update
    set name = excluded.name, role = excluded.role, active = true;
  return v_id;
end $$;

revoke all on function public.grant_staff(text, text, text) from public, anon;
grant execute on function public.grant_staff(text, text, text) to authenticated;

-- ---------- Dashboard data -------------------------------------------------
-- 'state'  : the whole dashboard (team only).
-- 'public' : what the users' app needs (sections on/off, association
--            information, announcements): readable by everyone.
create table if not exists public.admin_store (
  id         text primary key check (id in ('state', 'public')),
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid()
);

alter table public.admin_store enable row level security;

drop policy if exists "read store" on public.admin_store;
create policy "read store" on public.admin_store
  for select to anon, authenticated
  using (id = 'public' or public.is_staff());

drop policy if exists "staff write store" on public.admin_store;
create policy "staff write store" on public.admin_store
  for insert to authenticated with check (public.is_staff());

drop policy if exists "staff update store" on public.admin_store;
create policy "staff update store" on public.admin_store
  for update to authenticated
  using (public.is_staff()) with check (public.is_staff());

create or replace function public.admin_store_touch()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end $$;

drop trigger if exists admin_store_touch on public.admin_store;
create trigger admin_store_touch before insert or update on public.admin_store
  for each row execute function public.admin_store_touch();

-- ---------- The first general managers -------------------------------------
-- The three accounts of the association (Authentication > Users):
-- Admin1@ / Admin2@ / Admin3@Chifa.Linnas.app
insert into public.admin_staff (user_id, email, name, role)
select id, coalesce(email, ''), coalesce(email, ''), 'superAdmin'
from auth.users
where lower(email) in (
  'admin1@chifa.linnas.app',
  'admin2@chifa.linnas.app',
  'admin3@chifa.linnas.app'
)
   or id in (
  'd356ea9c-837f-4f96-992d-b71928ca727c',
  '8150390b-a08f-496b-85e9-7c32b29b5703',
  '9d92877f-1670-479d-a893-f8d73f4214d3'
)
on conflict (user_id) do update set role = 'superAdmin', active = true;
