-- RSVP table for the Moath & Reema wedding invitation.
-- Self-contained: creates ONE new table and its own policy only.
-- Does not alter any existing table, function, schema, or project setting.
-- Run once in Supabase Dashboard -> SQL Editor.

create table if not exists public.moath_reema_rsvps (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  name        text not null check (char_length(name) between 1 and 100),
  attending   text not null check (attending in ('yes', 'no')),
  message     text check (char_length(message) <= 1000)
);

-- Lock the table down: RLS on, no default privileges for public roles.
alter table public.moath_reema_rsvps enable row level security;
revoke all on public.moath_reema_rsvps from anon, authenticated;

-- The public site may only INSERT these three columns. No read, update or delete.
grant insert (name, attending, message) on public.moath_reema_rsvps to anon;

create policy "moath_reema_rsvps_anon_insert"
  on public.moath_reema_rsvps
  for insert
  to anon
  with check (true);
