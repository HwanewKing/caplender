-- =====================================================================
-- caplender — initial schema
-- Run in Supabase SQL Editor (Project → SQL Editor → New query → paste).
-- Idempotent: safe to re-run.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. categories (read-only seed: 4 PRD-defined buckets)
-- ---------------------------------------------------------------------
create table if not exists public.categories (
  id          text primary key,
  name        text not null,
  color_hex   text not null,
  sort_order  smallint not null default 0
);

insert into public.categories (id, name, color_hex, sort_order) values
  ('memo',          '메모',   '#F2C19F', 1),
  ('receipt',       '영수증', '#C7E0E2', 2),
  ('business_card', '명함',   '#D7E3E5', 3),
  ('other',         '기타',   '#E8E1CF', 4)
on conflict (id) do update
  set name = excluded.name,
      color_hex = excluded.color_hex,
      sort_order = excluded.sort_order;

alter table public.categories enable row level security;

drop policy if exists "categories_read_all" on public.categories;
create policy "categories_read_all"
  on public.categories for select
  to authenticated
  using (true);

-- ---------------------------------------------------------------------
-- 2. photo_memos (one row per captured photo memo, scoped to user)
-- ---------------------------------------------------------------------
create table if not exists public.photo_memos (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references auth.users(id) on delete cascade,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  -- Calendar day this memo belongs to (defaults to capture date)
  memo_date             date not null default current_date,
  title                 text not null default '',
  memo                  text not null default '',
  category_id           text not null references public.categories(id),
  photo_path            text,        -- {user_id}/{photo_id}.jpg in storage
  ocr_text              text,        -- "내용" extracted by the classifier
  classification_reason text,        -- "근거" from the classifier
  remind                boolean not null default false,
  remind_at             timestamptz  -- null when remind = false
);

create index if not exists photo_memos_user_date_idx
  on public.photo_memos (user_id, memo_date desc);
create index if not exists photo_memos_user_remind_idx
  on public.photo_memos (user_id, remind_at)
  where remind = true;

alter table public.photo_memos enable row level security;

drop policy if exists "photo_memos_select_own" on public.photo_memos;
create policy "photo_memos_select_own"
  on public.photo_memos for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "photo_memos_insert_own" on public.photo_memos;
create policy "photo_memos_insert_own"
  on public.photo_memos for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "photo_memos_update_own" on public.photo_memos;
create policy "photo_memos_update_own"
  on public.photo_memos for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "photo_memos_delete_own" on public.photo_memos;
create policy "photo_memos_delete_own"
  on public.photo_memos for delete
  to authenticated
  using (auth.uid() = user_id);

-- updated_at auto-touch
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists photo_memos_touch on public.photo_memos;
create trigger photo_memos_touch
  before update on public.photo_memos
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------
-- 3. Storage bucket for captured photos (private, user-scoped folders)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'photo-memos',
  'photo-memos',
  false,
  10485760,                                          -- 10 MB
  array['image/jpeg','image/png','image/heic','image/webp']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Files are stored as `{auth.uid()}/{photo_id}.jpg`. Policies restrict every
-- operation to the user's own top-level folder.
drop policy if exists "photo_memos_storage_read_own" on storage.objects;
create policy "photo_memos_storage_read_own"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'photo-memos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "photo_memos_storage_write_own" on storage.objects;
create policy "photo_memos_storage_write_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'photo-memos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "photo_memos_storage_update_own" on storage.objects;
create policy "photo_memos_storage_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'photo-memos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "photo_memos_storage_delete_own" on storage.objects;
create policy "photo_memos_storage_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'photo-memos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
