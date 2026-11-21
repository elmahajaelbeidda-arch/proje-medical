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
