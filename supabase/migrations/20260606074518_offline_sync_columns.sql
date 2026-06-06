-- PersonalHub: Phase 1.2 offline-sync columns
-- Adds an `updated_at` watermark (server-maintained) and `deleted_at` soft-delete
-- tombstones to the synced tables. Delta pull reads rows where updated_at > watermark;
-- soft-deletes propagate as tombstones. Last-write-wins is anchored to the server clock
-- via the BEFORE INSERT/UPDATE trigger. Fully idempotent (safe to re-run).

-- transactions ---------------------------------------------------------------
alter table transactions add column if not exists updated_at timestamptz not null default now();
alter table transactions add column if not exists deleted_at timestamptz;

-- categories -----------------------------------------------------------------
alter table categories add column if not exists updated_at timestamptz not null default now();
alter table categories add column if not exists deleted_at timestamptz;

-- Server-authoritative updated_at (ignores client clock skew for LWW) ---------
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists transactions_set_updated_at on transactions;
create trigger transactions_set_updated_at
  before insert or update on transactions
  for each row execute function set_updated_at();

drop trigger if exists categories_set_updated_at on categories;
create trigger categories_set_updated_at
  before insert or update on categories
  for each row execute function set_updated_at();

-- Delta-pull indexes ---------------------------------------------------------
create index if not exists transactions_updated_at on transactions (user_id, updated_at);
create index if not exists categories_updated_at on categories (updated_at);
