-- SM-13: Song Translation Competitions
-- Time-limited events where users compete to translate song lyrics.
-- Community voting determines winners. Prizes in XP + Juice.

-- Competition events
create table skill_mode_translation_competitions (
  id uuid primary key default gen_random_uuid(),
  song_id uuid references skill_mode_songs(id) on delete cascade not null,
  title text not null,
  description text,
  target_language text not null default 'en',
  status text not null default 'upcoming', -- 'upcoming' | 'active' | 'voting' | 'completed'
  starts_at timestamptz not null,
  submission_deadline timestamptz not null,
  voting_deadline timestamptz not null,
  ends_at timestamptz not null,
  max_entries integer default 50,
  entry_count integer default 0,
  vote_count integer default 0,
  prize_pool_juice integer default 100,
  xp_first integer default 200,
  xp_second integer default 100,
  xp_third integer default 50,
  xp_participation integer default 15,
  created_by uuid references profiles(id) on delete set null,
  winner_entry_id uuid,  -- set after voting ends
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Competition entries (one per user per competition)
create table skill_mode_competition_entries (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid references skill_mode_translation_competitions(id) on delete cascade not null,
  translator_id uuid references profiles(id) on delete cascade not null,
  translations jsonb not null default '[]', -- [{line_index, source_text, translated_text, notes}]
  style_note text, -- translator's creative note about their approach
  submitted_at timestamptz default now(),
  total_votes integer default 0,
  quality_score numeric default 0, -- weighted vote score
  rank integer, -- set after voting ends
  prize_juice integer default 0,
  prize_xp integer default 0,
  unique(competition_id, translator_id)
);

-- Community votes on entries (one vote per voter per entry)
create table skill_mode_competition_votes (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid references skill_mode_translation_competitions(id) on delete cascade not null,
  entry_id uuid references skill_mode_competition_entries(id) on delete cascade not null,
  voter_id uuid references profiles(id) on delete cascade not null,
  score integer not null check (score between 1 and 5), -- 1–5 star rating
  voted_at timestamptz default now(),
  unique(entry_id, voter_id)
);

-- RLS
alter table skill_mode_translation_competitions enable row level security;
alter table skill_mode_competition_entries enable row level security;
alter table skill_mode_competition_votes enable row level security;

-- Competitions: everyone can read, only admins/creators create
create policy "Competitions visible to all" on skill_mode_translation_competitions
  for select using (true);
create policy "Authenticated users create competitions" on skill_mode_translation_competitions
  for insert with check (auth.uid() = created_by);
create policy "Creators manage own competitions" on skill_mode_translation_competitions
  for update using (auth.uid() = created_by);

-- Entries: visible to all after submission, users manage own
create policy "Entries visible to all" on skill_mode_competition_entries
  for select using (true);
create policy "Users submit own entries" on skill_mode_competition_entries
  for insert with check (auth.uid() = translator_id);
create policy "Users update own entries" on skill_mode_competition_entries
  for update using (auth.uid() = translator_id);

-- Votes: voters see own, can cast
create policy "Users see own votes" on skill_mode_competition_votes
  for select using (auth.uid() = voter_id);
create policy "Users cast votes" on skill_mode_competition_votes
  for insert with check (auth.uid() = voter_id);

-- Indexes
create index idx_competitions_status on skill_mode_translation_competitions (status, starts_at desc);
create index idx_competitions_song on skill_mode_translation_competitions (song_id);
create index idx_competition_entries_comp on skill_mode_competition_entries (competition_id, quality_score desc);
create index idx_competition_entries_translator on skill_mode_competition_entries (translator_id);
create index idx_competition_votes_entry on skill_mode_competition_votes (entry_id);
create index idx_competition_votes_voter on skill_mode_competition_votes (voter_id, competition_id);
