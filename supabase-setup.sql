-- Like Terms: saved puzzle progress for logged-in players.
-- Run this ONCE in Supabase: SQL Editor -> New query -> paste -> Run.
-- It lives in the Battleship project (same logins as InterviewReady) but only adds its own table (lt_progress);
-- no other tables are touched.

create table if not exists public.lt_progress (
  user_id    uuid        primary key default auth.uid() references auth.users (id) on delete cascade,
  data       jsonb       not null,            -- every puzzle's state: guesses, solved groups, mistakes, time
  updated_at timestamptz not null default now(),
  constraint lt_data_size check (pg_column_size(data) < 200000)  -- keep each player's save under ~200 KB
);

-- Row Level Security: each player can only see and change THEIR OWN progress.
alter table public.lt_progress enable row level security;

drop policy if exists "lt: read own"   on public.lt_progress;
drop policy if exists "lt: add own"    on public.lt_progress;
drop policy if exists "lt: change own" on public.lt_progress;
drop policy if exists "lt: delete own" on public.lt_progress;

create policy "lt: read own"   on public.lt_progress for select to authenticated using (user_id = auth.uid());
create policy "lt: add own"    on public.lt_progress for insert to authenticated with check (user_id = auth.uid());
create policy "lt: change own" on public.lt_progress for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "lt: delete own" on public.lt_progress for delete to authenticated using (user_id = auth.uid());

-- Logged-out visitors (anon) get NO access at all.
revoke all on public.lt_progress from anon;
grant select, insert, update, delete on public.lt_progress to authenticated;
