-- Grant admin access to the Harrison Jones admin account.
update public.profiles
set is_admin = true
where id = 'afc91f3a-4671-4c72-b90a-0508b742c9a3';
