-- =====================================================================
-- caplender — profiles table + auto-create trigger
-- Run AFTER 0001_initial_schema.sql.
-- Idempotent: safe to re-run.
--
-- profiles is 1:1 with auth.users. Both anonymous and permanent users get a
-- profile row. The user_id stays stable when an anonymous user upgrades to
-- email/social, so photo_memos data never moves.
-- =====================================================================

create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text,
  avatar_url    text,
  settings      jsonb not null default '{}'::jsonb,
  onboarded_at  timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Insert is only allowed via the trigger below (with security definer); no
-- public insert policy needed. Delete cascades from auth.users.

-- updated_at auto-touch (reuses function from 0001)
drop trigger if exists profiles_touch on public.profiles;
create trigger profiles_touch
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- Auto-create profile row when a new auth.users row appears (covers both
-- anonymous and permanent sign-ins).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill: existing auth.users (e.g. anonymous sessions created before this
-- migration ran) get a profile row.
insert into public.profiles (id)
select id from auth.users
where id not in (select id from public.profiles)
on conflict (id) do nothing;
