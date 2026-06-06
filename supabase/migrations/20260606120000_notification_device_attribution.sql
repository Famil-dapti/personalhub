-- Per-device notification attribution.
-- The same app runs on two phones under one account; record which phone
-- captured each notification so the archive can label/filter by device.
-- Additive + idempotent: existing rows keep NULL (captured before this change).

alter table notifications add column if not exists device_id   text;
alter table notifications add column if not exists device_name text;
