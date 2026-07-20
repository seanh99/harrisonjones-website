-- pgcrypto's functions (crypt, gen_salt, gen_random_bytes) live in the
-- "extensions" schema on Supabase, not "public". The functions below
-- restrict search_path to "public" for security, which hid pgcrypto.
-- Widen search_path to include "extensions" so hashing works.

create or replace function public.admin_create_client(p_username text, p_password text, p_display_name text default null)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  new_id uuid;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  insert into public.clients (username, password_hash, display_name)
  values (p_username, crypt(p_password, gen_salt('bf')), p_display_name)
  returning id into new_id;
  return new_id;
end;
$$;

create or replace function public.admin_update_client_password(p_client_id uuid, p_new_password text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  update public.clients set password_hash = crypt(p_new_password, gen_salt('bf')) where id = p_client_id;
end;
$$;

create or replace function public.client_login(p_username text, p_password text)
returns table(token text, expires_at timestamptz, display_name text)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_client public.clients%rowtype;
  v_token text;
  v_expires timestamptz;
begin
  select * into v_client from public.clients where username = p_username;
  if not found or v_client.password_hash <> crypt(p_password, v_client.password_hash) then
    raise exception 'invalid credentials';
  end if;
  v_token := encode(gen_random_bytes(32), 'hex');
  v_expires := now() + interval '30 days';
  insert into public.client_sessions (token, client_id, expires_at) values (v_token, v_client.id, v_expires);
  return query select v_token, v_expires, v_client.display_name;
end;
$$;
