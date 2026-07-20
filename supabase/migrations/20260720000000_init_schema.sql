-- ============================================================
-- Harrison Jones — Client Portal schema
-- ============================================================

create extension if not exists pgcrypto;

-- ---------------- Tables ----------------

-- Extends auth.users for the admin account(s)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

-- Custom client accounts (not Supabase Auth users — admin sets username/password directly)
create table public.clients (
  id uuid primary key default gen_random_uuid(),
  username text not null unique,
  password_hash text not null,
  display_name text,
  created_at timestamptz not null default now()
);

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  link text not null,
  created_at timestamptz not null default now()
);

create table public.client_projects (
  client_id uuid not null references public.clients(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  primary key (client_id, project_id)
);

-- Session tokens for client logins (clients are not Supabase Auth users)
create table public.client_sessions (
  token text primary key,
  client_id uuid not null references public.clients(id) on delete cascade,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

-- Catalog of images available for the homepage hero rotation
create table public.hero_images (
  id uuid primary key default gen_random_uuid(),
  filename text not null unique,
  format text not null default 'vertical' check (format in ('vertical','square','horizontal','panoramic')),
  caption text not null default 'Private Residence',
  is_active boolean not null default false,
  sort_order integer not null default 0
);

-- ---------------- New-user trigger ----------------

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------- Admin helper ----------------

create function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and is_admin = true
  );
$$;

-- ---------------- RLS ----------------

alter table public.profiles enable row level security;
alter table public.clients enable row level security;
alter table public.projects enable row level security;
alter table public.client_projects enable row level security;
alter table public.client_sessions enable row level security;
alter table public.hero_images enable row level security;

create policy "read own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "admin manage clients" on public.clients
  for all using (public.is_admin()) with check (public.is_admin());

create policy "admin manage projects" on public.projects
  for all using (public.is_admin()) with check (public.is_admin());

create policy "admin manage client_projects" on public.client_projects
  for all using (public.is_admin()) with check (public.is_admin());

create policy "admin manage sessions" on public.client_sessions
  for all using (public.is_admin()) with check (public.is_admin());

create policy "admin manage hero_images" on public.hero_images
  for all using (public.is_admin()) with check (public.is_admin());

create policy "public read active hero_images" on public.hero_images
  for select using (is_active = true);

-- ---------------- RPC functions ----------------
-- (Only where password hashing or anonymous/session-based access is required —
--  everything else goes through plain table queries protected by RLS above.)

create or replace function public.admin_create_client(p_username text, p_password text, p_display_name text default null)
returns uuid
language plpgsql
security definer
set search_path = public
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
set search_path = public
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
set search_path = public
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

create or replace function public.client_my_projects(p_token text)
returns table(id uuid, name text, link text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client_id uuid;
begin
  select client_id into v_client_id from public.client_sessions
    where token = p_token and expires_at > now();
  if not found then
    raise exception 'invalid or expired session';
  end if;
  return query
    select p.id, p.name, p.link
    from public.projects p
    join public.client_projects cp on cp.project_id = p.id
    where cp.client_id = v_client_id
    order by p.name;
end;
$$;

create or replace function public.client_logout(p_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.client_sessions where token = p_token;
end;
$$;

grant execute on function public.client_login(text, text) to anon, authenticated;
grant execute on function public.client_my_projects(text) to anon, authenticated;
grant execute on function public.client_logout(text) to anon, authenticated;
grant execute on function public.admin_create_client(text, text, text) to authenticated;
grant execute on function public.admin_update_client_password(uuid, text) to authenticated;
