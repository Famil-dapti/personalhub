-- PersonalHub: per-user app settings (Phase 4). Currently holds the optional
-- Groq API key used for the AI fallback parser. One row per user (the client
-- uses the user's id as the row id so both phones converge on the same row);
-- the server-authoritative `updated_at` trigger feeds the offline delta-pull
-- watermark (LWW anchored to server clock). Additive + idempotent.
--
-- The key is stored under RLS like all other user data (anon key + RLS only;
-- no service_role in the client). It is the user's own key and only readable
-- by them.

create table if not exists user_settings (
  id           uuid        primary key default gen_random_uuid(),
  user_id      uuid        not null references auth.users on delete cascade,
  groq_api_key text,
  updated_at   timestamptz not null default now(),
  unique (user_id)
);

alter table user_settings enable row level security;

drop policy if exists "users_own_user_settings" on user_settings;
create policy "users_own_user_settings"
  on user_settings for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Server-authoritative updated_at (reuses set_updated_at() from offline_sync) --
drop trigger if exists user_settings_set_updated_at on user_settings;
create trigger user_settings_set_updated_at
  before insert or update on user_settings
  for each row execute function set_updated_at();

-- Delta-pull index -----------------------------------------------------------
create index if not exists user_settings_updated_at on user_settings (user_id, updated_at);
