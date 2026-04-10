-- SM-8: Duo Battle — real-time race on the same cards, who answers faster.

-- Duo battle matches
create table skill_mode_duo_battles (
  id uuid primary key default gen_random_uuid(),
  -- Players
  player_a_id uuid references profiles(id) on delete cascade not null,
  player_b_id uuid references profiles(id) on delete cascade,
  -- Config
  language text not null,
  card_count integer not null default 10,
  deck_id uuid references skill_mode_decks(id) on delete set null,
  -- State
  status text not null default 'waiting', -- 'waiting' | 'matched' | 'countdown' | 'active' | 'finished' | 'abandoned'
  -- Scores
  player_a_score integer default 0,
  player_b_score integer default 0,
  player_a_time_ms integer default 0,    -- total time for all cards
  player_b_time_ms integer default 0,
  player_a_cards_done integer default 0,
  player_b_cards_done integer default 0,
  winner_id uuid references profiles(id) on delete set null,
  is_draw boolean default false,
  -- Card list (shared between both players)
  card_ids text[] not null default '{}',
  -- Timing
  matched_at timestamptz,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz default now(),
  -- Auto-expire waiting matches after 2 minutes
  expires_at timestamptz default (now() + interval '2 minutes')
);

-- Per-card results in a duo battle
create table skill_mode_duo_rounds (
  id uuid primary key default gen_random_uuid(),
  battle_id uuid references skill_mode_duo_battles(id) on delete cascade not null,
  player_id uuid references profiles(id) on delete cascade not null,
  card_id uuid not null,
  round_index integer not null,          -- 0-based card position
  -- Result
  correct boolean default false,
  time_ms integer not null,              -- time to answer this card
  score integer default 0,              -- points earned this round
  created_at timestamptz default now()
);

-- Duo battle stats per user
create table skill_mode_duo_stats (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade not null unique,
  total_battles integer default 0,
  wins integer default 0,
  losses integer default 0,
  draws integer default 0,
  win_streak integer default 0,
  best_win_streak integer default 0,
  total_xp_earned integer default 0,
  elo_rating integer default 1000,       -- simple Elo for matchmaking
  updated_at timestamptz default now()
);

-- RLS
alter table skill_mode_duo_battles enable row level security;
alter table skill_mode_duo_rounds enable row level security;
alter table skill_mode_duo_stats enable row level security;

-- Battles: players can see their own battles, insert (create/join)
create policy "Players see own battles" on skill_mode_duo_battles
  for select using (auth.uid() = player_a_id or auth.uid() = player_b_id);
create policy "Waiting battles visible for matchmaking" on skill_mode_duo_battles
  for select using (status = 'waiting');
create policy "Anyone can create a battle" on skill_mode_duo_battles
  for insert with check (auth.uid() = player_a_id);
create policy "Players can update own battles" on skill_mode_duo_battles
  for update using (auth.uid() = player_a_id or auth.uid() = player_b_id);

-- Rounds: players see their own
create policy "Players see own rounds" on skill_mode_duo_rounds
  for select using (auth.uid() = player_id);
create policy "Players insert own rounds" on skill_mode_duo_rounds
  for insert with check (auth.uid() = player_id);

-- Stats: readable by all, users manage own
create policy "Duo stats readable by all" on skill_mode_duo_stats
  for select using (true);
create policy "Users manage own duo stats" on skill_mode_duo_stats
  for all using (auth.uid() = user_id);

-- Indexes
create index on skill_mode_duo_battles (status, language, created_at) where status = 'waiting';
create index on skill_mode_duo_battles (player_a_id);
create index on skill_mode_duo_battles (player_b_id);
create index on skill_mode_duo_rounds (battle_id, round_index);
create index on skill_mode_duo_stats (elo_rating desc);

-- Enable realtime on battles table for live updates
alter publication supabase_realtime add table skill_mode_duo_battles;
