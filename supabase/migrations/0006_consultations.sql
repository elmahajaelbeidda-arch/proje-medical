-- =========================================================================
-- «الاستشارات والمحادثة» — شِفاءٌ لِلنّاس / جمعية عون وسند الخيرية
-- Remote consultations between patients and volunteer doctors: the
-- request, its medical files, the doctor's reply and the conversation.
--
-- Who sees what (row level security):
--   * a patient: their own consultations only;
--   * an approved doctor: new requests of their specialty (and general
--     ones), then the cases they accepted;
--   * the follow-up & management team: everything.
-- Needs 0004 (team) and 0005 (accounts). Run in Supabase: SQL Editor >
-- New query > paste > Run (safe to run again).
-- =========================================================================

-- ---------- Helpers -------------------------------------------------------
create or replace function public.is_approved_doctor()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'doctor' and status = 'approved'
  );
$$;

create or replace function public.my_specialty()
returns text language sql stable security definer set search_path = public as $$
  select specialty_id from public.profiles where user_id = auth.uid();
$$;

-- ---------- Consultations -------------------------------------------------
create table if not exists public.consultations (
  id            uuid primary key default gen_random_uuid(),
  patient_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  patient_name  text not null default '',
  patient_age   int,
  patient_male  boolean not null default true,
  hide_name     boolean not null default false,
  chronic       text[] not null default '{}',
  specialty_id  text not null,
  type          text not null default 'general' check (type in ('lab', 'imaging', 'general')),
  urgency       text not null default 'normal' check (urgency in ('normal', 'soon', 'urgent')),
  symptoms      text not null check (length(trim(symptoms)) between 3 and 4000),
  duration_key  text not null default '',
  status        text not null default 'pending'
                  check (status in ('pending', 'accepted', 'answered', 'closed')),
  doctor_id     uuid references auth.users (id) on delete set null,
  doctor_name   text,
  reply         jsonb,
  rating        int check (rating between 1 and 5),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists consultations_patient on public.consultations (patient_id);
create index if not exists consultations_doctor on public.consultations (doctor_id);
create index if not exists consultations_queue on public.consultations (status, specialty_id);

alter table public.consultations enable row level security;

drop policy if exists "consultations read" on public.consultations;
create policy "consultations read" on public.consultations
  for select to authenticated using (
    patient_id = auth.uid()
    or doctor_id = auth.uid()
    or (status = 'pending' and public.is_approved_doctor()
        and (specialty_id = public.my_specialty() or specialty_id = 'general'))
    or public.is_staff()
  );

-- A patient (not refused) opens a request for themselves: always pending,
-- no doctor, no reply.
drop policy if exists "patients create consultations" on public.consultations;
create policy "patients create consultations" on public.consultations
  for insert to authenticated with check (
    patient_id = auth.uid()
    and status = 'pending' and doctor_id is null and reply is null and rating is null
    and exists (select 1 from public.profiles
                where user_id = auth.uid() and role = 'patient' and status <> 'rejected')
  );

-- Changes go through the functions below (accept, reply, rate); the team
-- may correct a case directly.
drop policy if exists "team updates consultations" on public.consultations;
create policy "team updates consultations" on public.consultations
  for update to authenticated using (public.is_staff()) with check (public.is_staff());

create or replace function public.accept_consultation(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_name text;
begin
  if not public.is_approved_doctor() then raise exception 'not allowed'; end if;
  select name into v_name from public.profiles where user_id = auth.uid();
  update public.consultations
     set doctor_id = auth.uid(), doctor_name = v_name, status = 'accepted', updated_at = now()
   where id = p_id and status = 'pending' and doctor_id is null
     and (specialty_id = public.my_specialty() or specialty_id = 'general');
  if not found then raise exception 'already taken'; end if;
end $$;

create or replace function public.reply_consultation(p_id uuid, p_reply jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.consultations
     set reply = p_reply, status = 'answered', updated_at = now()
   where id = p_id and doctor_id = auth.uid() and status in ('accepted', 'answered');
  if not found then raise exception 'not allowed'; end if;
end $$;

create or replace function public.rate_consultation(p_id uuid, p_stars int)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.consultations
     set rating = greatest(1, least(5, p_stars)), updated_at = now()
   where id = p_id and patient_id = auth.uid() and status in ('answered', 'closed');
  if not found then raise exception 'not allowed'; end if;
end $$;

revoke all on function public.accept_consultation(uuid) from public, anon;
revoke all on function public.reply_consultation(uuid, jsonb) from public, anon;
revoke all on function public.rate_consultation(uuid, int) from public, anon;
grant execute on function public.accept_consultation(uuid) to authenticated;
grant execute on function public.reply_consultation(uuid, jsonb) to authenticated;
grant execute on function public.rate_consultation(uuid, int) to authenticated;

-- Is the signed-in person the patient or the doctor of this consultation?
create or replace function public.in_consultation(p_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.consultations
    where id = p_id and (patient_id = auth.uid() or doctor_id = auth.uid())
  );
$$;

-- ---------- Conversation ---------------------------------------------------
create table if not exists public.consultation_messages (
  id              uuid primary key default gen_random_uuid(),
  consultation_id uuid not null references public.consultations (id) on delete cascade,
  sender_id       uuid not null default auth.uid(),
  from_doctor     boolean not null default false,
  text            text not null default '' check (length(text) <= 4000),
  call_kind       text check (call_kind in ('voice', 'video')),
  created_at      timestamptz not null default now()
);

create index if not exists consultation_messages_by_case
  on public.consultation_messages (consultation_id, created_at);

alter table public.consultation_messages enable row level security;

create or replace function public.consultation_messages_before_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.sender_id := auth.uid();
  new.created_at := now();
  new.from_doctor := exists (
    select 1 from public.consultations
    where id = new.consultation_id and doctor_id = auth.uid()
  );
  return new;
end $$;

drop trigger if exists consultation_messages_before_insert on public.consultation_messages;
create trigger consultation_messages_before_insert
  before insert on public.consultation_messages
  for each row execute function public.consultation_messages_before_insert();

drop policy if exists "messages read" on public.consultation_messages;
create policy "messages read" on public.consultation_messages
  for select to authenticated
  using (public.in_consultation(consultation_id) or public.is_staff());

drop policy if exists "messages write" on public.consultation_messages;
create policy "messages write" on public.consultation_messages
  for insert to authenticated
  with check (public.in_consultation(consultation_id));

-- ---------- Medical files (lab tests, imaging...) -------------------------
create table if not exists public.consultation_files (
  id              uuid primary key default gen_random_uuid(),
  consultation_id uuid not null references public.consultations (id) on delete cascade,
  path            text not null,
  name            text not null default '',
  kind            text not null default 'image' check (kind in ('image', 'pdf')),
  category        text not null default 'lab',
  created_at      timestamptz not null default now()
);

alter table public.consultation_files enable row level security;

drop policy if exists "files read" on public.consultation_files;
create policy "files read" on public.consultation_files
  for select to authenticated using (
    public.is_staff()
    or public.in_consultation(consultation_id)
    or exists (select 1 from public.consultations c
               where c.id = consultation_id and c.status = 'pending'
               and public.is_approved_doctor()
               and (c.specialty_id = public.my_specialty() or c.specialty_id = 'general'))
  );

drop policy if exists "files add" on public.consultation_files;
create policy "files add" on public.consultation_files
  for insert to authenticated with check (
    exists (select 1 from public.consultations c
            where c.id = consultation_id and c.patient_id = auth.uid())
  );

insert into storage.buckets (id, name, public)
values ('consultations', 'consultations', false)
on conflict (id) do nothing;

drop policy if exists "consultation files upload" on storage.objects;
create policy "consultation files upload" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'consultations'
    and exists (select 1 from public.consultations c
                where c.id::text = (storage.foldername(name))[1]
                and c.patient_id = auth.uid())
  );

drop policy if exists "consultation files read" on storage.objects;
create policy "consultation files read" on storage.objects
  for select to authenticated using (
    bucket_id = 'consultations'
    and exists (select 1 from public.consultation_files f
                where f.path = name)  -- visible through consultation_files RLS
  );

-- ---------- Live updates (chat, new requests) -----------------------------
do $$ begin
  alter publication supabase_realtime add table public.consultations;
exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.consultation_messages;
exception when duplicate_object then null; when undefined_object then null; end $$;
