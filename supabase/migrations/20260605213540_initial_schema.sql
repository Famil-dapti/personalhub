-- PersonalHub: initial schema
-- Phase 0: Wallet + Notification Archiver tables
-- CI/CD test: 2026-06-06

-- Transactions (Wallet)
create table if not exists transactions (
  id              uuid        primary key default gen_random_uuid(),
  user_id         uuid        not null references auth.users on delete cascade,
  amount          numeric     not null,
  currency        text        not null default 'AZN',
  category        text,
  description     text,
  source          text        not null default 'manual',
  notification_id uuid,
  created_at      timestamptz not null default now()
);

alter table transactions enable row level security;

create policy "users_own_transactions"
  on transactions for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index transactions_user_created_at on transactions (user_id, created_at desc);

-- Notifications (Archiver)
create table if not exists notifications (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references auth.users on delete cascade,
  app_package text,
  app_name    text,
  title       text,
  body        text,
  posted_at   timestamptz,
  is_transaction bool      not null default false,
  raw_json    jsonb,
  created_at  timestamptz not null default now()
);

alter table notifications enable row level security;

create policy "users_own_notifications"
  on notifications for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index notifications_user_posted_at on notifications (user_id, posted_at desc);
