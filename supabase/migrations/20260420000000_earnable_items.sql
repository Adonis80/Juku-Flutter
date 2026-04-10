-- SM-11: Streak Freeze + XP Booster earnable items.

create table skill_mode_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade not null,
  item_type text not null,              -- 'streak_freeze' | 'xp_booster'
  -- Quantity
  quantity integer default 1,
  -- XP Booster specific
  multiplier numeric default 2.0,       -- e.g. 2.0 = double XP
  duration_mins integer default 60,     -- how long the boost lasts
  -- Activation state
  is_active boolean default false,
  activated_at timestamptz,
  expires_at timestamptz,
  -- How earned
  earned_via text not null,             -- 'streak_milestone' | 'level_up' | 'challenge_win' | 'purchase'
  -- Timestamps
  created_at timestamptz default now()
);

alter table skill_mode_items enable row level security;

create policy "Users see own items" on skill_mode_items
  for select using (auth.uid() = user_id);
create policy "Users manage own items" on skill_mode_items
  for all using (auth.uid() = user_id);

create index on skill_mode_items (user_id, item_type);
create index on skill_mode_items (user_id, is_active) where is_active = true;
