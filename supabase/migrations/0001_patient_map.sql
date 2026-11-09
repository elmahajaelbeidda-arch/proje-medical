-- =========================================================================
-- «خريطة المرضى» — شِفاءٌ لِلنّاس / جمعية عون وسند الخيرية
-- Patient aid requests with location, for the medical aid committee.
--
-- Run in Supabase: Dashboard > SQL Editor > New query > paste > Run.
-- Then add the first supervisor (see the end of this file).
-- =========================================================================

-- ---------- Types ----------------------------------------------------------
do $$ begin
  create type aid_urgency as enum ('urgent', 'medium', 'normal');      -- عاجل / متوسط / عادي
exception when duplicate_object then null; end $$;

do $$ begin
  create type aid_status as enum (
    'new',        -- جديد
    'verifying',  -- قيد التحقق
    'verified',   -- تم التحقق
    'helped',     -- تمت المساعدة
    'closed'      -- مغلق
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type committee_role as enum ('member', 'supervisor');
exception when duplicate_object then null; end $$;

-- ---------- Tables ---------------------------------------------------------
create table if not exists public.committee_members (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  name       text not null,
  role       committee_role not null default 'member',
  created_at timestamptz not null default now()
);

create table if not exists public.patients_requests (
  id                    uuid primary key default gen_random_uuid(),
  -- Account that sent the request (the patient or a relative).
  user_id               uuid not null default auth.uid()
                          references auth.users (id) on delete cascade,
  patient_name          text not null check (length(trim(patient_name)) > 1),
  phone                 text not null check (length(regexp_replace(phone, '\D', '', 'g')) >= 8),
  latitude              double precision not null check (latitude between -90 and 90),
  longitude             double precision not null check (longitude between -180 and 180),
  address_note          text,
  condition_description text not null,
  urgency               aid_urgency not null default 'normal',
  status                aid_status not null default 'new',
  verified_by           uuid references auth.users (id),
  verified_at           timestamptz,
  -- A request cannot exist without the explicit consent of the patient.
  consent_given         boolean not null check (consent_given = true),
  created_at            timestamptz not null default now()
);

create index if not exists patients_requests_status_idx  on public.patients_requests (status);
create index if not exists patients_requests_user_idx    on public.patients_requests (user_id);
create index if not exists patients_requests_created_idx on public.patients_requests (created_at desc);

-- ---------- Helper functions (security definer: no RLS recursion) ---------
create or replace function public.is_committee_member()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from committee_members where user_id = auth.uid());
$$;

create or replace function public.is_supervisor()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from committee_members
    where user_id = auth.uid() and role = 'supervisor'
  );
$$;

-- Role of the signed-in user: 'supervisor', 'member' or null (patient).
create or replace function public.my_committee_role()
returns text language sql stable security definer set search_path = public as $$
  select role::text from committee_members where user_id = auth.uid();
$$;

-- ---------- Guard rules on updates ----------------------------------------
-- * Only a supervisor can set the status to "closed".
-- * verified_by / verified_at are filled by the database, not the client.
-- * The patient's own data and location cannot be changed by the committee.
create or replace function public.patients_requests_guard()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'closed' and old.status <> 'closed' and not public.is_supervisor() then
    raise exception 'Only a supervisor can close a case';
  end if;
  if old.status = 'closed' and new.status <> 'closed' and not public.is_supervisor() then
    raise exception 'Only a supervisor can reopen a case';
  end if;

  if new.status = 'verified' and old.status <> 'verified' then
    new.verified_by := auth.uid();
    new.verified_at := now();
  else
    new.verified_by := old.verified_by;
    new.verified_at := old.verified_at;
  end if;

  new.user_id := old.user_id;
  new.patient_name := old.patient_name;
  new.phone := old.phone;
  new.latitude := old.latitude;
  new.longitude := old.longitude;
  new.address_note := old.address_note;
  new.condition_description := old.condition_description;
  new.consent_given := old.consent_given;
  new.created_at := old.created_at;
  return new;
end;
$$;

drop trigger if exists patients_requests_guard on public.patients_requests;
create trigger patients_requests_guard
  before update on public.patients_requests
  for each row execute function public.patients_requests_guard();

-- New requests always start as "new".
create or replace function public.patients_requests_on_insert()
returns trigger language plpgsql as $$
begin
  new.status := 'new';
  new.verified_by := null;
  new.verified_at := null;
  new.user_id := auth.uid();
  return new;
end;
$$;

drop trigger if exists patients_requests_on_insert on public.patients_requests;
create trigger patients_requests_on_insert
  before insert on public.patients_requests
  for each row execute function public.patients_requests_on_insert();

-- ---------- Row Level Security --------------------------------------------
alter table public.patients_requests enable row level security;
alter table public.committee_members enable row level security;

-- patients_requests
drop policy if exists "patient inserts own request" on public.patients_requests;
create policy "patient inserts own request" on public.patients_requests
  for insert to authenticated
  with check (user_id = auth.uid() and consent_given = true);

drop policy if exists "patient reads own request" on public.patients_requests;
create policy "patient reads own request" on public.patients_requests
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "committee reads all requests" on public.patients_requests;
create policy "committee reads all requests" on public.patients_requests
  for select to authenticated
  using (public.is_committee_member());

drop policy if exists "committee updates requests" on public.patients_requests;
create policy "committee updates requests" on public.patients_requests
  for update to authenticated
  using (public.is_committee_member())
  with check (public.is_committee_member());

drop policy if exists "supervisor deletes requests" on public.patients_requests;
create policy "supervisor deletes requests" on public.patients_requests
  for delete to authenticated
  using (public.is_supervisor());

-- committee_members
drop policy if exists "members read members" on public.committee_members;
create policy "members read members" on public.committee_members
  for select to authenticated
  using (public.is_committee_member() or user_id = auth.uid());

drop policy if exists "supervisor manages members" on public.committee_members;
create policy "supervisor manages members" on public.committee_members
  for all to authenticated
  using (public.is_supervisor())
  with check (public.is_supervisor());

-- ---------- Realtime ------------------------------------------------------
-- Map and patient status update live (RLS still applies to Realtime).
do $$ begin
  alter publication supabase_realtime add table public.patients_requests;
exception when duplicate_object then null; end $$;

-- ---------- First supervisor ---------------------------------------------
-- 1. Create the supervisor's account in the app (or Dashboard > Authentication).
-- 2. Copy their user id from Dashboard > Authentication > Users.
-- 3. Run (replace the uuid and the name):
--
-- insert into public.committee_members (user_id, name, role)
-- values ('00000000-0000-0000-0000-000000000000', 'رئيس اللجنة', 'supervisor');
