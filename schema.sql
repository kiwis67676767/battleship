-- Battleship schema. Run this in the Supabase SQL editor.
-- No authentication: a game is reachable by its 4-letter room code, and the
-- anon role may read, create and update games. Seats are claimed with a random
-- token the client keeps in localStorage.
--
-- Ship positions are stored in this table and are readable by the anon role,
-- so the fog of war is a courtesy of the client, not a guarantee. This is a
-- deliberate choice: play with people you trust.

create table if not exists public.games (
  code       text        primary key check (code ~ '^[A-Z]{4}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  turn       smallint    not null default 1 check (turn in (1, 2)),
  winner     smallint    check (winner in (1, 2)),
  p1_token   text        not null,
  p2_token   text,
  -- Each fleet is a json array of {id, name, len, r, c, dir}; null until that
  -- player finishes placing. Shots are json arrays of 0-99 cell indexes.
  p1_ships   jsonb,
  p2_ships   jsonb,
  p1_shots   jsonb       not null default '[]'::jsonb,
  p2_shots   jsonb       not null default '[]'::jsonb
);

create index if not exists games_created_at_idx on public.games (created_at desc);

-- Keep updated_at honest so stale games are easy to find.
create or replace function public.games_touch() returns trigger
  language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists games_touch on public.games;
create trigger games_touch before update on public.games
  for each row execute function public.games_touch();

alter table public.games enable row level security;

-- Anyone (no login) can find a game by code, start one, and play it.
drop policy if exists "anon can read games" on public.games;
create policy "anon can read games"
  on public.games for select to anon using (true);

drop policy if exists "anon can create games" on public.games;
create policy "anon can create games"
  on public.games for insert to anon with check (true);

drop policy if exists "anon can play games" on public.games;
create policy "anon can play games"
  on public.games for update to anon using (true) with check (true);

-- No delete policy exists, so games are append-only from the client.

-- Broadcast moves to the other player.
alter publication supabase_realtime add table public.games;

-- Optional housekeeping: drop games nobody has touched in a day.
-- delete from public.games where updated_at < now() - interval '1 day';
