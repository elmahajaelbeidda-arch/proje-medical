-- =========================================================================
-- شِفاءٌ لِلنّاس — إعداد قاعدة البيانات كاملة (ملف واحد)
-- Supabase > SQL Editor > New query > الصق كل هذا > Run
-- = 0001 → 0007 (يمكن تشغيله أكثر من مرة)
-- =========================================================================

-- >>>>>>>>>> supabase/migrations/0001_patient_map.sql
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

-- >>>>>>>>>> supabase/migrations/0002_pulse.sql
-- =========================================================================
-- «نبض شفاء» — شِفاءٌ لِلنّاس / جمعية عون وسند الخيرية
-- Community space: news, shared stories (reviewed first), photos and
-- videos, live and recorded talks, likes, comments and reports.
--
-- * Everyone, visitors included, reads what is published, through the
--   views pulse_feed / pulse_feed_comments / pulse_live_feed (no author
--   ids, no anonymous names, no pending or hidden content).
-- * Members (signed in) like, comment, report, ask questions and send
--   stories; a story stays private until a moderator approves it.
-- * Moderators: committee supervisors and the members listed in
--   pulse_moderators (communications team).
--
-- Run after 0001_patient_map.sql: Dashboard > SQL Editor > paste > Run.
-- =========================================================================

-- ---------- Types ----------------------------------------------------------
do $$ begin
  create type pulse_kind as enum ('news', 'story', 'media', 'achievement');
exception when duplicate_object then null; end $$;
do $$ begin
  create type pulse_topic as enum ('association', 'app', 'initiative', 'campaign');
exception when duplicate_object then null; end $$;
do $$ begin
  create type pulse_status as enum ('pending', 'published', 'rejected', 'hidden');
exception when duplicate_object then null; end $$;
do $$ begin
  create type pulse_live_status as enum ('scheduled', 'live', 'ended');
exception when duplicate_object then null; end $$;

-- ---------- Moderators -----------------------------------------------------
create table if not exists public.pulse_moderators (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  name       text not null,
  created_at timestamptz not null default now()
);

create or replace function public.is_pulse_moderator()
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_supervisor()
      or exists (select 1 from pulse_moderators where user_id = auth.uid());
$$;

-- Hides phone and ID numbers: "36 12 34 56" -> "•• •• •• ••".
create or replace function public.pulse_mask_numbers(t text)
returns text language sql immutable as $$
  select regexp_replace(
    t,
    '(\+?222[ -]?)?([0-9][ -]?){8,}',
    '••••••••',
    'g'
  );
$$;

-- ---------- Settings (one row) ---------------------------------------------
create table if not exists public.pulse_settings (
  id                  boolean primary key default true check (id),
  comments_enabled    boolean not null default true,
  submissions_enabled boolean not null default true,
  likes_enabled       boolean not null default true
);
insert into public.pulse_settings (id) values (true) on conflict do nothing;

-- ---------- Posts ----------------------------------------------------------
create table if not exists public.pulse_posts (
  id                uuid primary key default gen_random_uuid(),
  kind              pulse_kind not null,
  topic             pulse_topic,
  title             text not null check (length(trim(title)) between 4 and 140),
  body              text not null default '' check (length(body) <= 6000),
  -- Story author (null: published by the association).
  author_id         uuid default auth.uid() references auth.users (id) on delete set null,
  author_name       text not null default '',
  anonymous         boolean not null default false,
  status            pulse_status not null default 'pending',
  reject_reason     text not null default '',
  pinned            boolean not null default false,
  comments_open     boolean not null default true,
  shares            integer not null default 0,
  -- Figures of an achievement post: [{"label": "...", "value": "..."}].
  stats             jsonb not null default '[]'::jsonb,
  -- A story cannot exist without the author's privacy confirmation.
  privacy_confirmed boolean not null check (privacy_confirmed = true),
  reviewed_by       uuid references auth.users (id),
  created_at        timestamptz not null default now(),
  published_at      timestamptz
);
create index if not exists pulse_posts_status_idx on public.pulse_posts (status, published_at desc);
create index if not exists pulse_posts_author_idx on public.pulse_posts (author_id);

create table if not exists public.pulse_media (
  id           uuid primary key default gen_random_uuid(),
  post_id      uuid not null references public.pulse_posts (id) on delete cascade,
  type         text not null check (type in ('image', 'video')),
  -- Photo in the private "pulse" storage bucket, or a video link.
  storage_path text,
  url          text,
  caption      text not null default '',
  position     smallint not null default 0,
  check (storage_path is not null or url is not null)
);
create index if not exists pulse_media_post_idx on public.pulse_media (post_id);

-- Members only send stories, always pending, under their own account.
create or replace function public.pulse_posts_guard()
returns trigger language plpgsql security definer set search_path = public as $$
declare s pulse_settings;
begin
  if public.is_pulse_moderator() then
    if tg_op = 'UPDATE' and new.status = 'published' and old.status <> 'published' then
      new.published_at := coalesce(new.published_at, now());
      new.reviewed_by := auth.uid();
      new.title := pulse_mask_numbers(new.title);
      new.body := pulse_mask_numbers(new.body);
    end if;
    if tg_op = 'INSERT' and new.author_id = auth.uid() and new.kind <> 'story' then
      new.author_id := null;  -- published by the association
      new.author_name := 'جمعية عون وسند الخيرية';
      new.published_at := coalesce(new.published_at, now());
    end if;
    return new;
  end if;
  if tg_op <> 'INSERT' then
    raise exception 'only moderators can change posts';
  end if;
  select * into s from pulse_settings;
  if not s.submissions_enabled then
    raise exception 'submissions are closed';
  end if;
  new.kind := 'story';
  new.topic := null;
  new.status := 'pending';
  new.author_id := auth.uid();
  new.pinned := false;
  new.shares := 0;
  new.stats := '[]'::jsonb;
  new.reject_reason := '';
  new.reviewed_by := null;
  new.published_at := null;
  if new.anonymous then new.author_name := ''; end if;
  return new;
end $$;

drop trigger if exists pulse_posts_guard on public.pulse_posts;
create trigger pulse_posts_guard before insert or update on public.pulse_posts
  for each row execute function public.pulse_posts_guard();

-- ---------- Interactions ---------------------------------------------------
create table if not exists public.pulse_likes (
  post_id    uuid not null references public.pulse_posts (id) on delete cascade,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.pulse_comments (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid not null references public.pulse_posts (id) on delete cascade,
  author_id   uuid not null default auth.uid() references auth.users (id) on delete cascade,
  author_name text not null,
  text        text not null check (length(trim(text)) between 1 and 500),
  hidden      boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists pulse_comments_post_idx on public.pulse_comments (post_id, created_at);

-- What a member reported: a post or a comment (one report per member).
create table if not exists public.pulse_reports (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid references public.pulse_posts (id) on delete cascade,
  comment_id  uuid references public.pulse_comments (id) on delete cascade,
  reporter_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  reason      text not null default '',
  handled     boolean not null default false,
  created_at  timestamptz not null default now(),
  check ((post_id is null) <> (comment_id is null)),
  unique (post_id, comment_id, reporter_id)
);

create or replace function public.pulse_comments_guard()
returns trigger language plpgsql security definer set search_path = public as $$
declare p pulse_posts; s pulse_settings;
begin
  if tg_op = 'UPDATE' then
    if not public.is_pulse_moderator() then
      raise exception 'only moderators can change comments';
    end if;
    return new;
  end if;
  select * into p from pulse_posts where id = new.post_id;
  select * into s from pulse_settings;
  if p.status <> 'published' or not p.comments_open or not s.comments_enabled then
    raise exception 'comments are closed';
  end if;
  new.author_id := auth.uid();
  new.hidden := false;
  new.text := pulse_mask_numbers(trim(new.text));
  return new;
end $$;

drop trigger if exists pulse_comments_guard on public.pulse_comments;
create trigger pulse_comments_guard before insert or update on public.pulse_comments
  for each row execute function public.pulse_comments_guard();

-- ---------- Live and recorded talks ----------------------------------------
create table if not exists public.pulse_lives (
  id               uuid primary key default gen_random_uuid(),
  title            text not null check (length(trim(title)) > 2),
  speaker          text not null,
  description      text not null default '',
  starts_at        timestamptz not null,
  duration_minutes integer not null default 60 check (duration_minutes between 10 and 480),
  status           pulse_live_status not null default 'scheduled',
  -- The video is broadcast on YouTube Live, Facebook Live...
  stream_url       text not null default '',
  recording_url    text not null default '',
  comments_open    boolean not null default true,
  questions_open   boolean not null default true,
  views            integer not null default 0,
  created_at       timestamptz not null default now(),
  check (status = 'scheduled' or stream_url <> '')
);

create table if not exists public.pulse_live_messages (
  id          uuid primary key default gen_random_uuid(),
  live_id     uuid not null references public.pulse_lives (id) on delete cascade,
  author_id   uuid not null default auth.uid() references auth.users (id) on delete cascade,
  author_name text not null,
  text        text not null check (length(trim(text)) between 1 and 300),
  hidden      boolean not null default false,
  created_at  timestamptz not null default now()
);

create table if not exists public.pulse_live_questions (
  id          uuid primary key default gen_random_uuid(),
  live_id     uuid not null references public.pulse_lives (id) on delete cascade,
  author_id   uuid not null default auth.uid() references auth.users (id) on delete cascade,
  author_name text not null,
  text        text not null check (length(trim(text)) between 5 and 300),
  answered    boolean not null default false,
  hidden      boolean not null default false,
  created_at  timestamptz not null default now()
);

create table if not exists public.pulse_question_votes (
  question_id uuid not null references public.pulse_live_questions (id) on delete cascade,
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  primary key (question_id, user_id)
);

create table if not exists public.pulse_live_reminders (
  live_id uuid not null references public.pulse_lives (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  primary key (live_id, user_id)
);

create or replace function public.pulse_live_input_guard()
returns trigger language plpgsql security definer set search_path = public as $$
declare l pulse_lives; s pulse_settings;
begin
  if tg_op = 'UPDATE' then
    if not public.is_pulse_moderator() then
      raise exception 'only moderators can change this';
    end if;
    return new;
  end if;
  select * into l from pulse_lives where id = new.live_id;
  select * into s from pulse_settings;
  if tg_table_name = 'pulse_live_messages' then
    if l.status <> 'live' or not l.comments_open or not s.comments_enabled then
      raise exception 'live chat is closed';
    end if;
  else
    if l.status = 'ended' or not l.questions_open then
      raise exception 'questions are closed';
    end if;
    new.answered := false;
  end if;
  new.author_id := auth.uid();
  new.hidden := false;
  new.text := pulse_mask_numbers(trim(new.text));
  return new;
end $$;

drop trigger if exists pulse_live_messages_guard on public.pulse_live_messages;
create trigger pulse_live_messages_guard before insert or update on public.pulse_live_messages
  for each row execute function public.pulse_live_input_guard();
drop trigger if exists pulse_live_questions_guard on public.pulse_live_questions;
create trigger pulse_live_questions_guard before insert or update on public.pulse_live_questions
  for each row execute function public.pulse_live_input_guard();

-- ---------- Audit (every moderator action) ---------------------------------
create table if not exists public.pulse_audit (
  id         bigint generated always as identity primary key,
  at         timestamptz not null default now(),
  user_id    uuid default auth.uid(),
  table_name text not null,
  action     text not null,
  row_id     text,
  details    jsonb
);

create or replace function public.pulse_audit_row()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_pulse_moderator() then
    insert into pulse_audit (table_name, action, row_id, details)
    values (
      tg_table_name, lower(tg_op),
      coalesce((case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end) ->> 'id', ''),
      case when tg_op = 'UPDATE' then jsonb_build_object('before', to_jsonb(old) - 'body', 'after', to_jsonb(new) - 'body') else null end
    );
  end if;
  return coalesce(new, old);
end $$;

do $$ declare t text; begin
  foreach t in array array['pulse_posts', 'pulse_media', 'pulse_comments', 'pulse_lives',
                           'pulse_live_messages', 'pulse_live_questions', 'pulse_settings', 'pulse_reports']
  loop
    execute format('drop trigger if exists %I_audit on public.%I', t, t);
    execute format('create trigger %I_audit after insert or update or delete on public.%I
                    for each row execute function public.pulse_audit_row()', t, t);
  end loop;
end $$;

-- ---------- Row level security ---------------------------------------------
alter table public.pulse_moderators     enable row level security;
alter table public.pulse_settings       enable row level security;
alter table public.pulse_posts          enable row level security;
alter table public.pulse_media          enable row level security;
alter table public.pulse_likes          enable row level security;
alter table public.pulse_comments       enable row level security;
alter table public.pulse_reports        enable row level security;
alter table public.pulse_lives          enable row level security;
alter table public.pulse_live_messages  enable row level security;
alter table public.pulse_live_questions enable row level security;
alter table public.pulse_question_votes enable row level security;
alter table public.pulse_live_reminders enable row level security;
alter table public.pulse_audit          enable row level security;

-- Moderators manage everything; supervisors manage the moderators list.
create policy "supervisors manage moderators" on public.pulse_moderators
  for all to authenticated using (public.is_supervisor()) with check (public.is_supervisor());

create policy "settings readable by all" on public.pulse_settings
  for select to anon, authenticated using (true);
create policy "moderators change settings" on public.pulse_settings
  for update to authenticated using (public.is_pulse_moderator());

-- Base tables: owners and moderators. The public reads the views below.
create policy "author reads own posts" on public.pulse_posts
  for select to authenticated using (author_id = auth.uid() or public.is_pulse_moderator());
create policy "members send stories" on public.pulse_posts
  for insert to authenticated with check (true); -- the guard trigger enforces the rules
create policy "moderators change posts" on public.pulse_posts
  for update to authenticated using (public.is_pulse_moderator());
create policy "moderators delete posts" on public.pulse_posts
  for delete to authenticated using (public.is_pulse_moderator());

create policy "media of own or any post for moderators" on public.pulse_media
  for select to authenticated using (
    public.is_pulse_moderator()
    or exists (select 1 from pulse_posts p where p.id = post_id and p.author_id = auth.uid()));
create policy "author adds media to own pending story" on public.pulse_media
  for insert to authenticated with check (
    public.is_pulse_moderator()
    or exists (select 1 from pulse_posts p
               where p.id = post_id and p.author_id = auth.uid() and p.status = 'pending'));
create policy "moderators manage media" on public.pulse_media
  for all to authenticated using (public.is_pulse_moderator()) with check (public.is_pulse_moderator());

create policy "member likes" on public.pulse_likes
  for insert to authenticated with check (
    user_id = auth.uid()
    and (select likes_enabled from pulse_settings)
    and exists (select 1 from pulse_posts p where p.id = post_id and p.status = 'published'));
create policy "member unlikes" on public.pulse_likes
  for delete to authenticated using (user_id = auth.uid());
create policy "member sees own likes" on public.pulse_likes
  for select to authenticated using (user_id = auth.uid());

create policy "members comment" on public.pulse_comments
  for insert to authenticated with check (true); -- guard trigger
create policy "moderators read comments" on public.pulse_comments
  for select to authenticated using (public.is_pulse_moderator() or author_id = auth.uid());
create policy "moderators hide comments" on public.pulse_comments
  for update to authenticated using (public.is_pulse_moderator());
create policy "moderators delete comments" on public.pulse_comments
  for delete to authenticated using (public.is_pulse_moderator());

create policy "members report" on public.pulse_reports
  for insert to authenticated with check (reporter_id = auth.uid());
create policy "moderators handle reports" on public.pulse_reports
  for all to authenticated using (public.is_pulse_moderator()) with check (public.is_pulse_moderator());

create policy "lives readable by all" on public.pulse_lives
  for select to anon, authenticated using (true);
create policy "moderators manage lives" on public.pulse_lives
  for all to authenticated using (public.is_pulse_moderator()) with check (public.is_pulse_moderator());

create policy "members write in live chat" on public.pulse_live_messages
  for insert to authenticated with check (true); -- guard trigger
create policy "moderators manage live chat" on public.pulse_live_messages
  for all to authenticated using (public.is_pulse_moderator()) with check (public.is_pulse_moderator());

create policy "members ask questions" on public.pulse_live_questions
  for insert to authenticated with check (true); -- guard trigger
create policy "moderators manage questions" on public.pulse_live_questions
  for all to authenticated using (public.is_pulse_moderator()) with check (public.is_pulse_moderator());

create policy "member votes" on public.pulse_question_votes
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "member reminders" on public.pulse_live_reminders
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "moderators read audit" on public.pulse_audit
  for select to authenticated using (public.is_pulse_moderator());

-- ---------- Public views (visitors included) ------------------------------
-- Views run with the owner's rights: they expose only safe columns.
create or replace view public.pulse_feed as
  select p.id, p.kind, p.topic, p.title, p.body,
         case when p.author_id is null then 'جمعية عون وسند الخيرية'
              when p.anonymous then '' else p.author_name end as author_name,
         p.anonymous, p.pinned, p.comments_open, p.shares, p.stats, p.published_at,
         (select count(*) from pulse_likes l where l.post_id = p.id) as likes,
         (select count(*) from pulse_comments c where c.post_id = p.id and not c.hidden) as comments,
         coalesce((select jsonb_agg(jsonb_build_object(
                     'type', m.type, 'url', m.url, 'storage_path', m.storage_path, 'caption', m.caption)
                   order by m.position)
                   from pulse_media m where m.post_id = p.id), '[]'::jsonb) as media
  from pulse_posts p
  where p.status = 'published';

create or replace view public.pulse_feed_comments as
  select c.id, c.post_id, c.author_name, c.text, c.created_at
  from pulse_comments c join pulse_posts p on p.id = c.post_id
  where not c.hidden and p.status = 'published';

create or replace view public.pulse_live_feed as
  select l.id, l.title, l.speaker, l.description, l.starts_at, l.duration_minutes, l.status,
         case when l.status = 'scheduled' then '' else l.stream_url end as stream_url,
         l.recording_url, l.comments_open, l.questions_open, l.views,
         (select count(*) from pulse_live_reminders r where r.live_id = l.id) as reminders
  from pulse_lives l;

create or replace view public.pulse_live_public_questions as
  select q.id, q.live_id, q.author_name, q.text, q.answered, q.created_at,
         (select count(*) from pulse_question_votes v where v.question_id = q.id) as votes
  from pulse_live_questions q where not q.hidden;

create or replace view public.pulse_live_public_chat as
  select m.id, m.live_id, m.author_name, m.text, m.created_at
  from pulse_live_messages m where not m.hidden;

grant select on public.pulse_feed, public.pulse_feed_comments, public.pulse_live_feed,
                public.pulse_live_public_questions, public.pulse_live_public_chat
  to anon, authenticated;

-- Shares and views are counted by functions (no direct update rights).
create or replace function public.pulse_count_share(p_post uuid)
returns void language sql security definer set search_path = public as $$
  update pulse_posts set shares = shares + 1 where id = p_post and status = 'published';
$$;
create or replace function public.pulse_count_view(p_live uuid)
returns void language sql security definer set search_path = public as $$
  update pulse_lives set views = views + 1 where id = p_live;
$$;
grant execute on function public.pulse_count_share(uuid), public.pulse_count_view(uuid)
  to anon, authenticated;

-- ---------- Photos: private bucket "pulse" ----------------------------------
-- Uploads go to "<user id>/<file>". Moderators and the uploader read them;
-- everyone reads photos attached to a published post.
insert into storage.buckets (id, name, public) values ('pulse', 'pulse', false)
  on conflict (id) do nothing;

create policy "pulse upload own folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'pulse' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "pulse read published or own" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'pulse' and (
    public.is_pulse_moderator()
    or (storage.foldername(name))[1] = auth.uid()::text
    or exists (select 1 from public.pulse_media m join public.pulse_posts p on p.id = m.post_id
               where m.storage_path = name and p.status = 'published')));

create policy "pulse moderators delete photos" on storage.objects
  for delete to authenticated
  using (bucket_id = 'pulse' and public.is_pulse_moderator());

-- ---------- Add a communications moderator ---------------------------------
-- insert into public.pulse_moderators (user_id, name)
-- values ('<UID من Authentication > Users>', 'اسم المسؤول');

-- >>>>>>>>>> supabase/migrations/0003_visit_counter.sql
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

-- >>>>>>>>>> supabase/migrations/0004_admin.sql
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

-- >>>>>>>>>> supabase/migrations/0005_accounts.sql
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

-- >>>>>>>>>> supabase/migrations/0006_consultations.sql
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

-- >>>>>>>>>> supabase/migrations/0007_voice.sql
-- =========================================================================
-- «الرسائل الصوتية» — شِفاءٌ لِلنّاس / جمعية عون وسند الخيرية
-- Voice messages in the conversation, and the voice note of a request,
-- kept in the private «consultations» storage.
--
-- Needs 0006. Run in Supabase: SQL Editor > New query > paste > Run
-- (safe to run again).
-- =========================================================================

alter table public.consultation_messages
  add column if not exists voice_path text,
  add column if not exists voice_ms int;

alter table public.consultations
  add column if not exists voice_path text,
  add column if not exists voice_ms int;

-- A consultation id taken from a storage path «<id>/...».
create or replace function public.consultation_of_path(p_name text)
returns uuid language sql immutable as $$
  select case
    when (storage.foldername(p_name))[1] ~ '^[0-9a-f-]{36}$'
      then ((storage.foldername(p_name))[1])::uuid
    else null
  end;
$$;

-- Files of a consultation: sent by its patient or its doctor, read by them
-- and by the team.
drop policy if exists "consultation files upload" on storage.objects;
create policy "consultation files upload" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'consultations'
    and public.in_consultation(public.consultation_of_path(name))
  );

drop policy if exists "consultation files read" on storage.objects;
create policy "consultation files read" on storage.objects
  for select to authenticated using (
    bucket_id = 'consultations'
    and (
      public.in_consultation(public.consultation_of_path(name))
      or public.is_staff()
      -- a new request's files, for the doctors who may accept it
      or exists (select 1 from public.consultation_files f where f.path = name)
    )
  );

-- The patient may add the voice note of their own request right after
-- sending it.
create or replace function public.set_consultation_voice(p_id uuid, p_path text, p_ms int)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.consultations
     set voice_path = p_path, voice_ms = p_ms
   where id = p_id and patient_id = auth.uid();
  if not found then raise exception 'not allowed'; end if;
end $$;

revoke all on function public.set_consultation_voice(uuid, text, int) from public, anon;
grant execute on function public.set_consultation_voice(uuid, text, int) to authenticated;
