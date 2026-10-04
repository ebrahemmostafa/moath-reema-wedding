-- Read access for responses.html (Moath & Reema RSVPs).
-- Self-contained: adds ONE private table and ONE function, both prefixed moath_reema_.
-- Does not touch auth, existing tables, or project settings.
-- Run once in Supabase Dashboard -> SQL Editor, AFTER rsvp.sql.

-- 1) Private table holding only the SHA-256 hash of the admin passcode.
--    RLS on + no grants = unreachable from the public API.
create table if not exists public.moath_reema_admin (
  id             int primary key default 1 check (id = 1),
  passcode_hash  text not null
);
alter table public.moath_reema_admin enable row level security;
revoke all on public.moath_reema_admin from anon, authenticated;

-- 2) Set the passcode: replace CHANGE_ME with a long passcode of your choice
--    (e.g. 4+ random words). Re-run just this statement to change it later.
insert into public.moath_reema_admin (id, passcode_hash)
values (1, encode(sha256(convert_to('CHANGE_ME', 'UTF8')), 'hex'))
on conflict (id) do update set passcode_hash = excluded.passcode_hash;

-- 3) Function the page calls. Returns the RSVPs only when the passcode matches.
create or replace function public.moath_reema_get_rsvps(passcode text)
returns setof public.moath_reema_rsvps
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.moath_reema_admin
    where id = 1
      and passcode_hash = encode(sha256(convert_to(coalesce(passcode, ''), 'UTF8')), 'hex')
  ) then
    perform pg_sleep(1);  -- slow down guessing
    raise exception 'invalid passcode' using errcode = '28P01';
  end if;

  return query
    select * from public.moath_reema_rsvps order by created_at desc;
end;
$$;

-- Functions are executable by PUBLIC by default; restrict to the site's anon role only.
revoke execute on function public.moath_reema_get_rsvps(text) from public, authenticated;
grant execute on function public.moath_reema_get_rsvps(text) to anon;
