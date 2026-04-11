-- SM-17: Juku Challenges — Daily Viral Loop
-- Tables: daily_challenges, challenge_attempts, weekly_challenge_leaderboards

-- ============================================================
-- 1. daily_challenges — one challenge card per day per language
-- ============================================================
CREATE TABLE IF NOT EXISTS daily_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_date date NOT NULL,
  language text NOT NULL DEFAULT 'de',      -- e.g. 'de', 'fr', 'ru', 'ar', 'zh'
  card_data jsonb NOT NULL DEFAULT '{}',    -- the card content (question, options, answer, etc.)
  card_type text NOT NULL DEFAULT 'text_flash', -- tile type from Skill Mode
  difficulty integer NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(challenge_date, language)
);

CREATE INDEX idx_daily_challenges_date ON daily_challenges(challenge_date DESC);

ALTER TABLE daily_challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view daily challenges"
  ON daily_challenges FOR SELECT
  USING (true);

CREATE POLICY "Service role manages challenges"
  ON daily_challenges FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================
-- 2. challenge_attempts — one attempt per user per day
-- ============================================================
CREATE TABLE IF NOT EXISTS challenge_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  challenge_id uuid NOT NULL REFERENCES daily_challenges(id) ON DELETE CASCADE,
  score integer NOT NULL DEFAULT 0,         -- 0-100 accuracy score
  time_ms integer NOT NULL DEFAULT 0,       -- time to complete in milliseconds
  correct boolean NOT NULL DEFAULT false,
  answers jsonb DEFAULT '[]',               -- sequence of answers for the result grid
  streak_count integer NOT NULL DEFAULT 0,  -- current streak at time of attempt
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, challenge_id)
);

CREATE INDEX idx_challenge_attempts_challenge ON challenge_attempts(challenge_id, score DESC);
CREATE INDEX idx_challenge_attempts_user ON challenge_attempts(user_id, created_at DESC);

ALTER TABLE challenge_attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view challenge attempts"
  ON challenge_attempts FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own attempts"
  ON challenge_attempts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 3. RPC: submit_challenge_attempt — atomic attempt + streak
-- ============================================================
CREATE OR REPLACE FUNCTION submit_challenge_attempt(
  p_challenge_id uuid,
  p_score integer,
  p_time_ms integer,
  p_correct boolean,
  p_answers jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_streak integer := 0;
  v_yesterday_attempt boolean;
  v_rank integer;
  v_total integer;
  v_xp integer;
  v_has_freeze boolean;
BEGIN
  -- Check if already attempted
  IF EXISTS (
    SELECT 1 FROM challenge_attempts
    WHERE user_id = v_user_id AND challenge_id = p_challenge_id
  ) THEN
    RETURN jsonb_build_object('error', 'already_attempted');
  END IF;

  -- Calculate streak
  -- Check yesterday's challenge
  SELECT EXISTS (
    SELECT 1 FROM challenge_attempts ca
    JOIN daily_challenges dc ON dc.id = ca.challenge_id
    WHERE ca.user_id = v_user_id
      AND dc.challenge_date = CURRENT_DATE - 1
  ) INTO v_yesterday_attempt;

  IF v_yesterday_attempt THEN
    -- Continue streak: get yesterday's streak count + 1
    SELECT COALESCE(MAX(ca.streak_count), 0) + 1
    INTO v_streak
    FROM challenge_attempts ca
    JOIN daily_challenges dc ON dc.id = ca.challenge_id
    WHERE ca.user_id = v_user_id
      AND dc.challenge_date = CURRENT_DATE - 1;
  ELSE
    -- Check if user has a streak freeze (SM-11 integration)
    SELECT EXISTS (
      SELECT 1 FROM skill_mode_user_items
      WHERE user_id = v_user_id
        AND item_id IN (SELECT id FROM skill_mode_earnable_items WHERE item_type = 'streak_freeze')
        AND activated_at IS NOT NULL
        AND activated_at > now() - interval '48 hours'
    ) INTO v_has_freeze;

    IF v_has_freeze THEN
      -- Freeze protects streak — get last known streak
      SELECT COALESCE(MAX(ca.streak_count), 0)
      INTO v_streak
      FROM challenge_attempts ca
      WHERE ca.user_id = v_user_id;
      v_streak := v_streak + 1;
    ELSE
      v_streak := 1; -- Streak reset
    END IF;
  END IF;

  -- Insert attempt
  INSERT INTO challenge_attempts (user_id, challenge_id, score, time_ms, correct, answers, streak_count)
  VALUES (v_user_id, p_challenge_id, p_score, p_time_ms, p_correct, p_answers, v_streak);

  -- Calculate rank
  SELECT COUNT(*) + 1 INTO v_rank
  FROM challenge_attempts
  WHERE challenge_id = p_challenge_id AND score > p_score;

  SELECT COUNT(*) INTO v_total
  FROM challenge_attempts
  WHERE challenge_id = p_challenge_id;

  -- Award XP (10 base + 5 per correct + streak bonus)
  v_xp := 10;
  IF p_correct THEN v_xp := v_xp + 5; END IF;
  IF v_streak >= 7 THEN v_xp := v_xp + 5; END IF;
  IF v_streak >= 30 THEN v_xp := v_xp + 10; END IF;

  INSERT INTO xp_events (user_id, event_type, xp_amount)
  VALUES (v_user_id, 'daily_challenge', v_xp);

  RETURN jsonb_build_object(
    'streak', v_streak,
    'rank', v_rank,
    'total', v_total,
    'xp_earned', v_xp,
    'percentile', ROUND(((v_total - v_rank)::numeric / GREATEST(v_total, 1)) * 100)
  );
END;
$$;
