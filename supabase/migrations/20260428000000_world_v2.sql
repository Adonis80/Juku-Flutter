-- SM-21: Juku World v2 — Social Spaces
-- Pod presence, card drops, object gifting, catalog, seasonal events

-- World object catalog: purchasable items
create table if not exists world_object_catalog (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  category text not null default 'decoration' check (category in ('decoration', 'furniture', 'seasonal', 'sponsor')),
  juice_cost int not null default 10,
  icon_url text,
  seasonal boolean not null default false,
  available_from timestamptz,
  available_until timestamptz,
  max_supply int,
  total_purchased int not null default 0,
  created_at timestamptz not null default now()
);

alter table world_object_catalog enable row level security;

create policy "Anyone can read catalog"
  on world_object_catalog for select using (true);

-- User-owned world objects
create table if not exists world_objects (
  id uuid primary key default gen_random_uuid(),
  catalog_id uuid not null references world_object_catalog(id),
  owner_id uuid not null references profiles(id) on delete cascade,
  zone_id uuid,
  position_x float,
  position_y float,
  placed boolean not null default false,
  created_at timestamptz not null default now()
);

alter table world_objects enable row level security;

create policy "Users can read all placed objects"
  on world_objects for select using (placed or owner_id = auth.uid());

create policy "Users can manage own objects"
  on world_objects for all using (owner_id = auth.uid());

-- Jukumon cosmetics catalog
create table if not exists jukumon_cosmetics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  cosmetic_type text not null default 'skin' check (cosmetic_type in ('skin', 'hat', 'aura', 'trail')),
  min_rank text default 'bronze',
  juice_cost int not null default 20,
  icon_url text,
  created_at timestamptz not null default now()
);

alter table jukumon_cosmetics enable row level security;

create policy "Anyone can read cosmetics"
  on jukumon_cosmetics for select using (true);

-- VR zones / language pods
create table if not exists vr_zones (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  language text not null default 'general',
  description text,
  ambient_theme text not null default 'default',
  min_rank text default 'bronze',
  max_capacity int not null default 20,
  created_at timestamptz not null default now()
);

alter table vr_zones enable row level security;

create policy "Anyone can read zones"
  on vr_zones for select using (true);

-- Pod presence: who is currently in which zone
create table if not exists world_pod_presence (
  id uuid primary key default gen_random_uuid(),
  zone_id uuid not null references vr_zones(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  position_x float not null default 0,
  position_y float not null default 0,
  unique (zone_id, user_id)
);

alter table world_pod_presence enable row level security;

create policy "Anyone can read pod presence"
  on world_pod_presence for select using (true);

create policy "Users can manage own presence"
  on world_pod_presence for all using (user_id = auth.uid());

-- Card drops: cards dropped into the world for others to play
create table if not exists world_card_drops (
  id uuid primary key default gen_random_uuid(),
  zone_id uuid not null references vr_zones(id) on delete cascade,
  dropped_by uuid not null references profiles(id) on delete cascade,
  card_id uuid not null,
  card_title text not null,
  card_type text not null default 'flash',
  position_x float not null default 0.5,
  position_y float not null default 0.5,
  play_count int not null default 0,
  expires_at timestamptz not null default (now() + interval '24 hours'),
  created_at timestamptz not null default now()
);

alter table world_card_drops enable row level security;

create policy "Anyone can read card drops"
  on world_card_drops for select using (expires_at > now());

create policy "Users can manage own drops"
  on world_card_drops for all using (dropped_by = auth.uid());

-- Object gifts: send a purchased object to another user
create table if not exists world_object_gifts (
  id uuid primary key default gen_random_uuid(),
  object_id uuid not null references world_objects(id) on delete cascade,
  from_user_id uuid not null references profiles(id),
  to_user_id uuid not null references profiles(id),
  message text,
  claimed boolean not null default false,
  created_at timestamptz not null default now()
);

alter table world_object_gifts enable row level security;

create policy "Recipients and senders can read gifts"
  on world_object_gifts for select
  using (from_user_id = auth.uid() or to_user_id = auth.uid());

create policy "Users can send gifts"
  on world_object_gifts for insert
  with check (from_user_id = auth.uid());

create policy "Recipients can claim gifts"
  on world_object_gifts for update
  using (to_user_id = auth.uid());

-- Seed default language pods
insert into vr_zones (name, language, description, ambient_theme) values
  ('German Tavern', 'german', 'A rustic Bavarian tavern for German learners', 'accordion'),
  ('French Café', 'french', 'A Parisian café for French learners', 'musette'),
  ('Russian Library', 'russian', 'A grand library for Russian learners', 'balalaika'),
  ('Arabic Courtyard', 'arabic', 'An ornate tiled courtyard for Arabic learners', 'oud'),
  ('Mandarin Garden', 'mandarin', 'A bamboo garden for Mandarin learners', 'guqin'),
  ('General Lounge', 'general', 'Open to all languages', 'default')
on conflict do nothing;

-- Seed some starter objects
insert into world_object_catalog (name, description, category, juice_cost) values
  ('Study Desk', 'A classic wooden desk', 'furniture', 15),
  ('Bookshelf', 'Full of knowledge', 'furniture', 20),
  ('Globe', 'Spin to pick a language', 'decoration', 10),
  ('Lantern', 'Warm ambient light', 'decoration', 8),
  ('Plant Pot', 'A touch of green', 'decoration', 5),
  ('Trophy Case', 'Show off your achievements', 'furniture', 30),
  ('World Map', 'Pin your learning journey', 'decoration', 12),
  ('Bean Bag', 'Casual study spot', 'furniture', 10)
on conflict do nothing;
