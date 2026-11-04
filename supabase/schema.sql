-- HF780 Diary: Supabase setup.
-- Run this whole file once: Supabase dashboard > SQL Editor > New query > paste > Run.

create extension if not exists pgcrypto with schema extensions;

-- 1. Tables ------------------------------------------------------------------

create table if not exists public.diaries (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_key text not null unique,
  code_hash text not null,                      -- the participant's code, stored hashed
  -- Day 1 of the diary. Defaults to the day after sign-up. Edit it in the Table Editor if needed.
  start_date date not null default ((now() at time zone 'America/New_York')::date + 1),
  created_at timestamptz not null default now()
);

create table if not exists public.entries (
  id uuid primary key default gen_random_uuid(),
  diary_id uuid not null references public.diaries(id) on delete cascade,
  study_day int not null check (study_day between 1 and 6),
  kind text not null check (kind in ('prompt','feels_like_me','not_for_me','movement')),
  note text check (note is null or char_length(note) <= 2000),
  media_path text check (media_path is null or char_length(media_path) <= 200),
  media_type text check (media_type is null or char_length(media_type) <= 100),
  created_at timestamptz not null default now(),
  check (note is not null or media_path is not null)
);
create index if not exists entries_diary_idx on public.entries (diary_id, created_at);

-- 2. Lock the tables --------------------------------------------------------
-- Row level security with no policies means the public key cannot read or write
-- these tables directly. The website can only use the three functions below.

alter table public.diaries enable row level security;
alter table public.entries enable row level security;

-- 3. Functions the website calls ------------------------------------------------

create or replace function public.diary_check(p_name text, p_code text)
returns uuid language plpgsql security definer set search_path = public, extensions as $$
declare d public.diaries;
begin
  select * into d from public.diaries where name_key = lower(trim(coalesce(p_name,'')));
  if not found or d.code_hash <> crypt(coalesce(p_code,''), d.code_hash) then
    raise exception 'wrong_code';
  end if;
  return d.id;
end $$;
revoke all on function public.diary_check(text, text) from public, anon, authenticated;

create or replace function public.diary_open(p_name text, p_code text)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare
  d public.diaries;
  k text := lower(trim(coalesce(p_name,'')));
  max_diaries constant int := 5;               -- most diaries that can ever be created (stops spam)
begin
  if char_length(k) < 1 or char_length(k) > 40
     or char_length(coalesce(p_code,'')) < 4 or char_length(p_code) > 40 then
    raise exception 'invalid';
  end if;

  select * into d from public.diaries where name_key = k;

  if not found then
    if (select count(*) from public.diaries) >= max_diaries then
      raise exception 'closed';
    end if;
    insert into public.diaries (name, name_key, code_hash)
    values (trim(p_name), k, crypt(p_code, gen_salt('bf')))
    returning * into d;
    return json_build_object('name', d.name, 'start_date', d.start_date, 'created', true);
  end if;

  if d.code_hash <> crypt(p_code, d.code_hash) then
    raise exception 'wrong_code';
  end if;
  return json_build_object('name', d.name, 'start_date', d.start_date, 'created', false);
end $$;

create or replace function public.diary_add_entry(
  p_name text, p_code text, p_day int, p_kind text, p_note text, p_media_path text, p_media_type text)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare
  v_id uuid := public.diary_check(p_name, p_code);
  e public.entries;
begin
  if p_media_path is not null and p_media_path !~ '^[0-9a-f-]{36}/[A-Za-z0-9._-]{1,80}$' then
    raise exception 'invalid';
  end if;
  insert into public.entries (diary_id, study_day, kind, note, media_path, media_type)
  values (v_id, p_day, p_kind, nullif(trim(coalesce(p_note,'')), ''), p_media_path, p_media_type)
  returning * into e;
  return json_build_object('id', e.id, 'created_at', e.created_at);
end $$;

create or replace function public.diary_list(p_name text, p_code text)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare v_id uuid := public.diary_check(p_name, p_code);
begin
  return coalesce((
    select json_agg(json_build_object(
      'id', e.id, 'study_day', e.study_day, 'kind', e.kind, 'note', e.note,
      'media_path', e.media_path, 'media_type', e.media_type, 'created_at', e.created_at
    ) order by e.created_at)
    from public.entries e where e.diary_id = v_id
  ), '[]'::json);
end $$;

grant execute on function public.diary_open(text, text) to anon;
grant execute on function public.diary_add_entry(text, text, int, text, text, text, text) to anon;
grant execute on function public.diary_list(text, text) to anon;

-- 4. Storage for photos and voice memos -------------------------------------
-- Files get random, unguessable paths. The public key may upload but cannot list or delete.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('diary-media', 'diary-media', true, 15728640, array['image/*', 'audio/*'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "diary anon upload" on storage.objects;
create policy "diary anon upload" on storage.objects
  for insert to anon with check (bucket_id = 'diary-media');
