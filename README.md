# Battleship

Two-player Battleship. No login — one player starts a game and gets a four-letter
room code, the other types it in. State lives in a single Supabase row and both
clients follow it over realtime.

## Rules

- 10&times;10 grid each, coordinates A1–J10.
- Five ships: Carrier 6, Battleship 5, Cruiser 4, Submarine 3, Destroyer 2 (20 cells).
- Ships sit horizontally or vertically, may touch, may not overlap.
- Players place their own fleets, then alternate — **one shot per turn**.
- Sink all five enemy ships to win.

Placement: click a ship in the tray to pick it up, move over your own grid for a
preview, click to drop it. `R` or right-click rotates. Click a placed ship to pick
it back up. `Random` fills the board for you.

## Setup

1. Create a Supabase project, then run [`schema.sql`](schema.sql) in its SQL editor.
2. Copy the credentials in:

   ```
   cp .env.example .env
   ```

   Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY` from
   **Project Settings → API**.
3. Start it:

   ```
   npm start
   ```

   Then open http://localhost:3100 in two browser windows — start a game in one,
   join with the code in the other.

## Deploying to Netlify

`netlify.toml` publishes `public/` with no build step. Set `SUPABASE_URL` and
`SUPABASE_ANON_KEY` as site environment variables; `netlify/functions/config.js`
serves them to the browser at `/config`, the same way `server.js` does locally.

## Layout

| Path | What it is |
| --- | --- |
| `public/index.html` | The whole client — board, placement, turns, realtime |
| `server.js` | Static server + `/config` for local dev |
| `netlify/functions/config.js` | The `/config` route on Netlify |
| `schema.sql` | The `games` table, its RLS policies, and realtime |

## A note on cheating

Ship positions are stored in the `games` row, and the anon role can read that row.
The fog of war is enforced by the client, not the database — a player who opens
devtools can find the other fleet. That was a deliberate call to keep the game to
one table and no server logic. Making it airtight would mean moving shots into a
Postgres function that returns only hit/miss/sunk, with RLS hiding the opponent's
`*_ships` column.

## Seats

A seat is claimed with a random token kept in `localStorage`, so a refresh puts you
back in your own seat. The second seat is claimed with
`update … where p2_token is null`, so two people racing for the same code can't both
take it. A third person gets turned away.
