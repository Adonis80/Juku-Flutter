-- SM-9: Challenge Mode — send a card/deck to a friend with your score to beat.

create table skill_mode_challenges (
  id uuid primary key default gen_random_uuid(),
  -- Players
  challenger_id uuid references profiles(id) on delete cascade not null,
  challenged_id uuid references profiles(id) on delete cascade not null,
  -- Content — card or deck
  card_id uuid references skill_mode_cards(id) on delete cascade,
  deck_id uuid references skill_mode_decks(id) on delete cascade,
  language text not null,
  -- Challenger's score (set when challenge is created)
  challenger_score integer not null,
  challenger_time_ms integer not null,
  -- Challenged player's score (set when they complete)
  challenged_score integer,
  challenged_time_ms integer,
  -- State
  status text not null default 'pending', -- 'pending' | 'accepted' | 'completed' | 'declined' | 'expired'
  winner_id uuid references profiles(id) on delete set null,
  -- Message
  taunt_message text,                     -- optional trash talk
  -- Timing
  expires_at timestamptz default (now() + interval '48 hours'),
  accepted_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz default now(),
  -- Either card or deck must be set
  constraint challenge_target_check check (
    (card_id is not null and deck_id is null) or
    (card_id is null and deck_id is not null)
  )
);

-- RLS
alter table skill_mode_challenges enable row level security;

create policy "Players see own challenges" on skill_mode_challenges
  for select using (auth.uid() = challenger_id or auth.uid() = challenged_id);
create policy "Users can create challenges" on skill_mode_challenges
  for insert with check (auth.uid() = challenger_id);
create policy "Challenged player can update" on skill_mode_challenges
  for update using (auth.uid() = challenged_id or auth.uid() = challenger_id);

-- Indexes
create index on skill_mode_challenges (challenged_id, status) where status = 'pending';
create index on skill_mode_challenges (challenger_id);
create index on skill_mode_challenges (created_at desc);
