-- Vardhman Sanskar Dham — App Hub
-- Run this whole file once in Supabase: Project → SQL Editor → New query → paste → Run

-- 1. TILES ---------------------------------------------------------------
-- Every tile (category root, standalone app, folder, or sub-tile) lives in
-- one table. A tile with url = NULL is a folder — it must have children.
-- A tile with url set is a leaf — tapping it navigates there.
-- parent_id = NULL means it's a top-level tile and must have a category.

create table if not exists tiles (
  id          uuid primary key default gen_random_uuid(),
  parent_id   uuid references tiles(id) on delete cascade,
  category    text,                         -- required when parent_id is null
  name        text not null,
  url         text,                         -- null = folder, set = leaf link
  icon        text not null default 'app-window',  -- lucide icon name
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists tiles_parent_idx on tiles(parent_id);
create index if not exists tiles_category_idx on tiles(category);

-- keep updated_at fresh
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists tiles_set_updated_at on tiles;
create trigger tiles_set_updated_at
before update on tiles
for each row execute function set_updated_at();

-- guard rails: root tiles need a category, non-root tiles must not have one
alter table tiles drop constraint if exists tiles_category_rule;
alter table tiles add constraint tiles_category_rule
  check (
    (parent_id is null and category is not null and length(trim(category)) > 0)
    or
    (parent_id is not null and category is null)
  );

-- a tile can't be its own ancestor at the DB level trivially, so this is
-- enforced in the admin UI (depth is walked before saving).

-- 2. ADMIN ALLOWLIST ------------------------------------------------------
-- Anyone can sign up via Supabase Auth, but only emails listed here can
-- write to tiles. Add admins manually after they sign up (see README).

create table if not exists admins (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text unique not null,
  created_at timestamptz not null default now()
);

-- 3. ROW LEVEL SECURITY ----------------------------------------------------
alter table tiles enable row level security;
alter table admins enable row level security;

-- Anyone (volunteers, no login) can read tiles to render the hub.
drop policy if exists "public read tiles" on tiles;
create policy "public read tiles" on tiles
  for select
  using (true);

-- Only allowlisted admins can write.
drop policy if exists "admin write tiles" on tiles;
create policy "admin write tiles" on tiles
  for all
  using (exists (select 1 from admins where admins.id = auth.uid()))
  with check (exists (select 1 from admins where admins.id = auth.uid()));

-- Admins can see the allowlist (so the admin page can show who has access).
drop policy if exists "admin read admins" on admins;
create policy "admin read admins" on admins
  for select
  using (exists (select 1 from admins a2 where a2.id = auth.uid()));

-- Nobody writes to admins from the client — you add admins via SQL Editor
-- (see README). This is deliberate: promoting someone to admin should be
-- a manual, auditable step, not a button in the app.
