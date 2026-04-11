-- SM-20: White-Label Tenant Dashboard
-- Self-serve onboarding, branding, analytics, user management, moderation

-- Tenant admins: links users to tenants with roles
create table if not exists tenant_admins (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  role text not null default 'admin' check (role in ('owner', 'admin', 'moderator')),
  created_at timestamptz not null default now(),
  unique (tenant_id, user_id)
);

alter table tenant_admins enable row level security;

create policy "Tenant admins can read own tenant admins"
  on tenant_admins for select
  using (
    user_id = auth.uid()
    or tenant_id in (
      select tenant_id from tenant_admins where user_id = auth.uid()
    )
  );

create policy "Tenant owners can manage admins"
  on tenant_admins for all
  using (
    tenant_id in (
      select tenant_id from tenant_admins
      where user_id = auth.uid() and role = 'owner'
    )
  );

-- Tenant invites: invite codes for users to join a tenant
create table if not exists tenant_invites (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  email text,
  invite_code text not null unique default encode(gen_random_bytes(6), 'hex'),
  role text not null default 'member' check (role in ('member', 'moderator', 'admin')),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'revoked')),
  invited_by uuid not null references profiles(id),
  accepted_by uuid references profiles(id),
  created_at timestamptz not null default now(),
  accepted_at timestamptz
);

alter table tenant_invites enable row level security;

create policy "Tenant admins can manage invites"
  on tenant_invites for all
  using (
    tenant_id in (
      select tenant_id from tenant_admins where user_id = auth.uid()
    )
  );

create policy "Anyone can read invite by code"
  on tenant_invites for select
  using (true);

-- Tenant analytics snapshots: daily aggregated stats
create table if not exists tenant_analytics_snapshots (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  snapshot_date date not null default current_date,
  dau int not null default 0,
  total_plays int not null default 0,
  juice_in numeric not null default 0,
  juice_out numeric not null default 0,
  new_signups int not null default 0,
  total_cards int not null default 0,
  created_at timestamptz not null default now(),
  unique (tenant_id, snapshot_date)
);

alter table tenant_analytics_snapshots enable row level security;

create policy "Tenant admins can read analytics"
  on tenant_analytics_snapshots for select
  using (
    tenant_id in (
      select tenant_id from tenant_admins where user_id = auth.uid()
    )
  );

-- Tenant moderation queue: cards pending approval
create table if not exists tenant_moderation_queue (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  card_id uuid not null,
  card_type text not null,
  card_title text not null,
  submitted_by uuid not null references profiles(id),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references profiles(id),
  rejection_reason text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

alter table tenant_moderation_queue enable row level security;

create policy "Tenant admins can manage moderation"
  on tenant_moderation_queue for all
  using (
    tenant_id in (
      select tenant_id from tenant_admins where user_id = auth.uid()
    )
  );

create policy "Submitters can read own submissions"
  on tenant_moderation_queue for select
  using (submitted_by = auth.uid());

-- Add branding columns to tenants table if not present
do $$
begin
  if not exists (select 1 from information_schema.columns where table_name = 'tenants' and column_name = 'logo_url') then
    alter table tenants add column logo_url text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name = 'tenants' and column_name = 'primary_color') then
    alter table tenants add column primary_color text default '#7C3AED';
  end if;
  if not exists (select 1 from information_schema.columns where table_name = 'tenants' and column_name = 'secondary_color') then
    alter table tenants add column secondary_color text default '#EC4899';
  end if;
  if not exists (select 1 from information_schema.columns where table_name = 'tenants' and column_name = 'welcome_message') then
    alter table tenants add column welcome_message text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name = 'tenants' and column_name = 'plan') then
    alter table tenants add column plan text default 'starter' check (plan in ('starter', 'growth', 'enterprise'));
  end if;
  if not exists (select 1 from information_schema.columns where table_name = 'tenants' and column_name = 'custom_domain') then
    alter table tenants add column custom_domain text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name = 'tenants' and column_name = 'setup_complete') then
    alter table tenants add column setup_complete boolean default false;
  end if;
end $$;

-- RPC: accept tenant invite
create or replace function accept_tenant_invite(p_invite_code text)
returns uuid language plpgsql security definer as $$
declare
  v_invite tenant_invites%rowtype;
  v_tenant_id uuid;
begin
  select * into v_invite from tenant_invites
  where invite_code = p_invite_code and status = 'pending';

  if v_invite is null then
    raise exception 'Invalid or expired invite code';
  end if;

  -- Mark invite as accepted
  update tenant_invites
  set status = 'accepted', accepted_by = auth.uid(), accepted_at = now()
  where id = v_invite.id;

  -- Add user as tenant member (or upgrade role if already member)
  insert into tenant_admins (tenant_id, user_id, role)
  values (v_invite.tenant_id, auth.uid(), v_invite.role)
  on conflict (tenant_id, user_id) do update set role = v_invite.role;

  return v_invite.tenant_id;
end;
$$;
