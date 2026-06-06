-- PersonalHub: Media Cleaner (Phase 3) per-device aggregate counters.
-- This is the ONLY media data synced to the server; individual photo decisions
-- stay local on the device. One stats row per (user, device); the client upserts
-- by the client-generated primary key `id`. The server-authoritative `updated_at`
-- trigger feeds the offline delta-pull watermark (LWW anchored to server clock).
-- Additive + idempotent (safe to re-run).

create table if not exists media_stats (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references auth.users on delete cascade,
  device_id   text        not null,
  device_name text,
  total       integer     not null default 0,
  decided     integer     not null default 0,
  kept        integer     not null default 0,
  deleted     integer     not null default 0,
  updated_at  timestamptz not null default now(),
  unique (user_id, device_id)
);

alter table media_stats enable row level security;

drop policy if exists "users_own_media_stats" on media_stats;
create policy "users_own_media_stats"
  on media_stats for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Server-authoritative updated_at (reuses set_updated_at() from offline_sync) ---
drop trigger if exists media_stats_set_updated_at on media_stats;
create trigger media_stats_set_updated_at
  before insert or update on media_stats
  for each row execute function set_updated_at();

-- Delta-pull index -----------------------------------------------------------
create index if not exists media_stats_updated_at on media_stats (user_id, updated_at);
