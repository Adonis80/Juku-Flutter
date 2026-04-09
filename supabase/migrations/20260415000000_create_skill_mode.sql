-- ============================================================
-- Skill Mode — Full Schema Migration
-- Run in Supabase SQL Editor
-- ============================================================

-- ---- Core tables ----

create table skill_mode_cards (
  id uuid primary key default gen_random_uuid(),
  language text not null,
  foreign_text text not null,
  native_text text not null,
  romanization text,
  audio_url text,
  tile_type text not null default 'standard',
  card_type text not null default 'word',
  difficulty integer not null default 1,
  part_of_speech text,
  grammar_metadata jsonb default '{}',
  tile_config jsonb default '{}',
  sentence_tiles jsonb,
  native_word_order jsonb,
  foreign_word_order jsonb,
  tags text[] default '{}',
  created_at timestamptz default now()
);

create table skill_mode_user_cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade not null,
  card_id uuid references skill_mode_cards(id) on delete cascade not null,
  ease_factor numeric not null default 2.5,
  interval_days integer not null default 1,
  repetitions integer not null default 0,
  next_review_at timestamptz not null default now(),
  last_score_pct integer,
  hint_used_at timestamptz,
  transform_used_at timestamptz,
  mastery_proven boolean default false,
  suspended boolean default false,
  suspended_at timestamptz,
  unique(user_id, card_id)
);

create table skill_mode_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade not null,
  language text not null,
  cards_reviewed integer default 0,
  xp_earned integer default 0,
  combo_peak integer default 0,
  started_at timestamptz default now(),
  ended_at timestamptz
);

create table skill_mode_user_languages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade not null,
  language text not null,
  streak_days integer default 0,
  streak_freezes integer default 0,
  last_session_at timestamptz,
  unlocked_badges jsonb default '[]',
  unique(user_id, language)
);

-- ---- Deck / Creator Economy tables ----

create table skill_mode_decks (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid references profiles(id) on delete cascade not null,
  title text not null,
  description text,
  language text not null,
  difficulty text,
  tags text[] default '{}',
  cover_url text,
  card_skin text default 'default',
  skin_primary_color text,
  skin_accent_color text,
  published boolean default false,
  play_count integer default 0,
  completion_count integer default 0,
  creator_target_score integer,
  is_daily_deck boolean default false,
  daily_deck_date date,
  is_limited_edition boolean default false,
  limited_until timestamptz,
  is_collab boolean default false,
  collab_creator_id uuid references profiles(id) on delete set null,
  creator_xp_earned integer default 0,
  creator_juice_earned integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Cards belong to a deck (null = system card)
alter table skill_mode_cards add column deck_id uuid references skill_mode_decks(id) on delete cascade;

create table skill_mode_deck_plays (
  id uuid primary key default gen_random_uuid(),
  deck_id uuid references skill_mode_decks(id) on delete cascade not null,
  player_id uuid references profiles(id) on delete cascade not null,
  score_pct integer,
  cards_completed integer default 0,
  fully_mastered boolean default false,
  is_first_master boolean default false,
  played_at timestamptz default now()
);

create view skill_mode_deck_leaderboard as
  select
    dp.deck_id,
    dp.player_id,
    p.username,
    p.photo_url,
    max(dp.score_pct) as best_score,
    count(*) as play_count,
    bool_or(dp.fully_mastered) as mastered,
    min(case when dp.fully_mastered then dp.played_at end) as mastered_at
  from skill_mode_deck_plays dp
  join profiles p on p.id = dp.player_id
  group by dp.deck_id, dp.player_id, p.username, p.photo_url;

create table skill_mode_creator_stats (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade not null unique,
  creator_xp integer default 0,
  creator_level integer default 1,
  creator_rank text default 'apprentice',
  total_deck_plays integer default 0,
  total_tips_received integer default 0,
  total_learners integer default 0,
  is_native_speaker boolean default false,
  is_verified_educator boolean default false,
  updated_at timestamptz default now()
);

create table skill_mode_daily_challenges (
  id uuid primary key default gen_random_uuid(),
  deck_id uuid references skill_mode_decks(id) on delete cascade not null,
  challenge_date date not null unique,
  top_score_player_id uuid references profiles(id) on delete set null,
  top_score integer,
  total_plays integer default 0,
  created_at timestamptz default now()
);

create table skill_mode_deck_wars (
  id uuid primary key default gen_random_uuid(),
  deck_a_id uuid references skill_mode_decks(id) on delete cascade not null,
  deck_b_id uuid references skill_mode_decks(id) on delete cascade not null,
  language text not null,
  topic text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  winner_deck_id uuid references skill_mode_decks(id) on delete set null,
  deck_a_plays integer default 0,
  deck_b_plays integer default 0,
  deck_a_avg_score numeric default 0,
  deck_b_avg_score numeric default 0
);

-- ---- Music Mode tables (stubs for v0.4+) ----

create table skill_mode_songs (
  id uuid primary key default gen_random_uuid(),
  uploader_id uuid references profiles(id) on delete set null,
  title text not null,
  artist text not null,
  language text not null,
  genre text,
  difficulty text,
  duration_secs integer,
  audio_url text,
  vocals_url text,
  instrumental_url text,
  cover_url text,
  demucs_quality text default 'pending',
  learner_count integer default 0,
  created_at timestamptz default now()
);

create table skill_mode_lyrics (
  id uuid primary key default gen_random_uuid(),
  song_id uuid references skill_mode_songs(id) on delete cascade not null,
  line_index integer not null,
  foreign_text text not null,
  start_ms integer not null,
  end_ms integer not null,
  is_colloquial boolean default false,
  standard_form text,
  card_id uuid references skill_mode_cards(id) on delete set null
);

create table skill_mode_translations (
  id uuid primary key default gen_random_uuid(),
  lyric_id uuid references skill_mode_lyrics(id) on delete cascade not null,
  translator_id uuid references profiles(id) on delete cascade not null,
  native_text text not null,
  status text default 'community_draft',
  upvotes integer default 0,
  is_first_accepted boolean default false,
  created_at timestamptz default now()
);

-- ---- RLS ----

alter table skill_mode_cards enable row level security;
alter table skill_mode_user_cards enable row level security;
alter table skill_mode_sessions enable row level security;
alter table skill_mode_user_languages enable row level security;
alter table skill_mode_decks enable row level security;
alter table skill_mode_deck_plays enable row level security;
alter table skill_mode_creator_stats enable row level security;
alter table skill_mode_daily_challenges enable row level security;
alter table skill_mode_deck_wars enable row level security;
alter table skill_mode_songs enable row level security;
alter table skill_mode_lyrics enable row level security;
alter table skill_mode_translations enable row level security;

create policy "Cards readable by all authenticated" on skill_mode_cards
  for select using (auth.role() = 'authenticated');

create policy "Users manage their own SR state" on skill_mode_user_cards
  for all using (auth.uid() = user_id);

create policy "Users manage their own sessions" on skill_mode_sessions
  for all using (auth.uid() = user_id);

create policy "Users manage their own language progress" on skill_mode_user_languages
  for all using (auth.uid() = user_id);

create policy "Published decks visible to all" on skill_mode_decks
  for select using (published = true or auth.uid() = creator_id);

create policy "Creators manage own decks" on skill_mode_decks
  for all using (auth.uid() = creator_id);

create policy "Anyone can record a deck play" on skill_mode_deck_plays
  for insert with check (auth.uid() = player_id);

create policy "Players see their own plays" on skill_mode_deck_plays
  for select using (auth.uid() = player_id);

create policy "Creator stats readable by all" on skill_mode_creator_stats
  for select using (true);

create policy "Users manage own creator stats" on skill_mode_creator_stats
  for all using (auth.uid() = user_id);

create policy "Daily challenges readable by all" on skill_mode_daily_challenges
  for select using (true);

create policy "Deck wars readable by all" on skill_mode_deck_wars
  for select using (true);

create policy "Songs readable by authenticated" on skill_mode_songs
  for select using (auth.role() = 'authenticated');

create policy "Users upload their own songs" on skill_mode_songs
  for insert with check (auth.uid() = uploader_id);

create policy "Lyrics readable by authenticated" on skill_mode_lyrics
  for select using (auth.role() = 'authenticated');

create policy "Translations readable by authenticated" on skill_mode_translations
  for select using (auth.role() = 'authenticated');

create policy "Users submit their own translations" on skill_mode_translations
  for insert with check (auth.uid() = translator_id);

-- ---- Indexes ----

create index on skill_mode_user_cards (user_id, next_review_at);
create index on skill_mode_cards (language, difficulty);
create index on skill_mode_sessions (user_id, started_at desc);
create index on skill_mode_decks (language, published, play_count desc);
create index on skill_mode_decks (creator_id);
create index on skill_mode_decks (daily_deck_date) where is_daily_deck = true;
create index on skill_mode_deck_plays (deck_id, score_pct desc);
create index on skill_mode_deck_plays (player_id);
