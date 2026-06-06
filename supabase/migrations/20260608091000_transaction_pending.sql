-- PersonalHub: transaction draft flag (Phase 4). An SMS notification carrying
-- an NN.NN amount is auto-routed into the wallet as a `pending` draft the user
-- edits/commits or cancels. Pending rows are excluded from the balance until
-- committed (pending = false). Additive + idempotent; existing rows default to
-- false (already committed).

alter table transactions add column if not exists pending boolean not null default false;
