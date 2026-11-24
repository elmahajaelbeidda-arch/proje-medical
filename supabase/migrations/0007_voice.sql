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

-- A voice clip lasts one minute at most (the app stops at 60 seconds).
do $$ begin
  alter table public.consultation_messages
    add constraint voice_one_minute check (voice_ms is null or voice_ms <= 61000);
exception when duplicate_object then null; end $$;
do $$ begin
  alter table public.consultations
    add constraint voice_one_minute check (voice_ms is null or voice_ms <= 61000);
exception when duplicate_object then null; end $$;

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
