-- PersonalHub: categories + transactions FK
-- Phase 1.1: Wallet categories with system presets (Turkish UI names)

-- Categories: user_id NULL = system preset (shared, read-only to users)
create table if not exists categories (
  id         uuid        primary key default gen_random_uuid(),
  user_id    uuid        references auth.users on delete cascade,
  name       text        not null,
  kind       text        not null check (kind in ('income', 'expense')),
  icon       text,
  color      text,
  sort_order int         not null default 0,
  created_at timestamptz not null default now()
);

alter table categories enable row level security;

-- Everyone can read system presets (user_id is null) plus their own rows
create policy "categories_read"
  on categories for select
  using (user_id is null or auth.uid() = user_id);

-- Users may only create/modify/delete their own categories (never system rows)
create policy "categories_insert_own"
  on categories for insert
  with check (auth.uid() = user_id);

create policy "categories_update_own"
  on categories for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "categories_delete_own"
  on categories for delete
  using (auth.uid() = user_id);

create index categories_user_kind on categories (user_id, kind, sort_order);

-- Seed system presets (user_id NULL). Names are Turkish (UI language).
insert into categories (user_id, name, kind, icon, color, sort_order) values
  (null, 'Yemek',     'expense', 'restaurant',      '#FF7043',  1),
  (null, 'Market',    'expense', 'shopping_cart',   '#8D6E63',  2),
  (null, 'Ulasim',    'expense', 'directions_car',  '#42A5F5',  3),
  (null, 'Faturalar', 'expense', 'receipt_long',    '#EF5350',  4),
  (null, 'Eglence',   'expense', 'movie',           '#AB47BC',  5),
  (null, 'Saglik',    'expense', 'medical_services','#26A69A',  6),
  (null, 'Alisveris', 'expense', 'shopping_bag',    '#EC407A',  7),
  (null, 'Kira',      'expense', 'home',            '#5C6BC0',  8),
  (null, 'Diger',     'expense', 'more_horiz',      '#78909C',  9),
  (null, 'Maas',      'income',  'payments',        '#66BB6A', 10),
  (null, 'Ek Gelir',  'income',  'attach_money',    '#9CCC65', 11),
  (null, 'Hediye',    'income',  'card_giftcard',   '#FFCA28', 12),
  (null, 'Diger',     'income',  'more_horiz',      '#78909C', 13);

-- Link transactions to categories (replace free-text category column).
-- Safe to drop: no live transaction data yet (Phase 1.1 not shipped).
alter table transactions drop column if exists category;
alter table transactions add column if not exists category_id uuid
  references categories on delete set null;

create index if not exists transactions_category on transactions (category_id);
