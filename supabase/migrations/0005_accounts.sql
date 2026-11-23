-- =========================================================================
-- «حسابات المرضى والأطباء» — شِفاءٌ لِلنّاس / جمعية عون وسند الخيرية
-- Real accounts: every patient and volunteer doctor has a profile with an
-- account code (P-001 / M-001), reviewed by the follow-up & management
-- team. One account per person: same NNI, phone or licence refused.
--
-- Needs 0004_admin.sql (team). Run in Supabase: SQL Editor > New query >
-- paste > Run (safe to run again).
-- Also: Authentication > Sign In / Providers > Email > turn OFF
-- «Confirm email» (accounts use the phone number, not a real mailbox).
-- =========================================================================

create sequence if not exists public.profile_seq_patient;
create sequence if not exists public.profile_seq_doctor;

-- Phone number as digits, without the 222 country code.
create or replace function public.norm_phone(p text)
returns text language sql immutable as $$
  select case
    when length(regexp_replace(coalesce(p, ''), '\D', '', 'g')) = 11
         and regexp_replace(p, '\D', '', 'g') like '222%'
      then substr(regexp_replace(p, '\D', '', 'g'), 4)
    else regexp_replace(coalesce(p, ''), '\D', '', 'g')
  end;
$$;

create table if not exists public.profiles (
  user_id          uuid primary key references auth.users (id) on delete cascade,
  role             text not null check (role in ('patient', 'doctor')),
  code             text unique,
  name             text not null check (length(trim(name)) between 2 and 120),
  phone            text not null,
  national_id      text not null check (national_id ~ '^[0-9]{10}$'),
  specialty_id     text,
  license_number   text,
  certificate_path text,
  status           text not null default 'pending'
                     check (status in ('pending', 'approved', 'rejected')),
  reviewed_at      timestamptz,
  reviewed_by      uuid,
  created_at       timestamptz not null default now()
);

-- One active account per person and role.
create unique index if not exists profiles_one_phone
  on public.profiles (role, phone) where status <> 'rejected';
create unique index if not exists profiles_one_nni
  on public.profiles (role, national_id) where status <> 'rejected';
create unique index if not exists profiles_one_license
  on public.profiles (upper(license_number))
  where license_number is not null and status <> 'rejected';

alter table public.profiles enable row level security;

-- New profile: clean values, code given by the server, always «pending».
create or replace function public.profiles_before_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.phone := public.norm_phone(new.phone);
  new.name := trim(new.name);
  new.license_number := nullif(upper(trim(coalesce(new.license_number, ''))), '');
  new.status := 'pending';
  new.reviewed_at := null;
  new.reviewed_by := null;
  new.created_at := now();
  new.code := case new.role
    when 'patient' then 'P-' || lpad(nextval('public.profile_seq_patient')::text, 3, '0')
    else 'M-' || lpad(nextval('public.profile_seq_doctor')::text, 3, '0')
  end;
  return new;
end $$;

drop trigger if exists profiles_before_insert on public.profiles;
create trigger profiles_before_insert before insert on public.profiles
  for each row execute function public.profiles_before_insert();

-- Changes: the person may fix their name / specialty; only the team decides.
create or replace function public.profiles_before_update()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_staff() then
    if new.status is distinct from old.status then
      new.reviewed_at := now();
      new.reviewed_by := auth.uid();
    end if;
  else
    new.status := old.status;
    new.reviewed_at := old.reviewed_at;
    new.reviewed_by := old.reviewed_by;
  end if;
  new.user_id := old.user_id;
  new.role := old.role;
  new.code := old.code;
  new.national_id := old.national_id;
  new.created_at := old.created_at;
  return new;
end $$;

drop trigger if exists profiles_before_update on public.profiles;
create trigger profiles_before_update before update on public.profiles
  for each row execute function public.profiles_before_update();

drop policy if exists "own profile insert" on public.profiles;
create policy "own profile insert" on public.profiles
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "own profile or team read" on public.profiles;
create policy "own profile or team read" on public.profiles
  for select to authenticated
  using (user_id = auth.uid() or public.is_staff());

drop policy if exists "own profile or team update" on public.profiles;
create policy "own profile or team update" on public.profiles
  for update to authenticated
  using (user_id = auth.uid() or public.is_staff())
  with check (user_id = auth.uid() or public.is_staff());

-- ---------- Before signing up: already registered? -------------------------
-- Returns 'phone', 'id' or 'license' when taken, else null.
create or replace function public.registration_conflict(
  p_role text, p_phone text, p_national_id text, p_license text
) returns text language sql stable security definer set search_path = public as $$
  select case
    when exists (select 1 from public.profiles where role = p_role
                 and national_id = regexp_replace(p_national_id, '\D', '', 'g')
                 and status <> 'rejected') then 'id'
    when exists (select 1 from public.profiles where role = p_role
                 and phone = public.norm_phone(p_phone)
                 and status <> 'rejected') then 'phone'
    when nullif(trim(coalesce(p_license, '')), '') is not null
         and exists (select 1 from public.profiles
                     where upper(license_number) = upper(trim(p_license))
                     and status <> 'rejected') then 'license'
    else null
  end;
$$;

-- ---------- Sign in with a code, a phone number or the NNI ----------------
-- Gives the sign-in address of the account (not a secret: it is made from
-- the phone number); the password is still checked by Supabase.
create or replace function public.login_email(p_identifier text)
returns text language sql stable security definer set search_path = public, auth as $$
  select u.email
  from public.profiles p
  join auth.users u on u.id = p.user_id
  where p.status <> 'rejected'
    and (
      upper(replace(trim(p_identifier), ' ', '')) = p.code
      or (length(regexp_replace(p_identifier, '\D', '', 'g')) = 10
          and p.national_id = regexp_replace(p_identifier, '\D', '', 'g'))
      or (length(public.norm_phone(p_identifier)) = 8
          and p.phone = public.norm_phone(p_identifier))
    )
  order by p.created_at desc
  limit 1;
$$;

revoke all on function public.registration_conflict(text, text, text, text) from public;
revoke all on function public.login_email(text) from public;
grant execute on function public.registration_conflict(text, text, text, text) to anon, authenticated;
grant execute on function public.login_email(text) to anon, authenticated;

-- ---------- Doctors' certificates (private files) -------------------------
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do nothing;

drop policy if exists "own documents upload" on storage.objects;
create policy "own documents upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'documents'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own documents or team read" on storage.objects;
create policy "own documents or team read" on storage.objects
  for select to authenticated
  using (bucket_id = 'documents'
         and ((storage.foldername(name))[1] = auth.uid()::text
              or public.is_staff()));
