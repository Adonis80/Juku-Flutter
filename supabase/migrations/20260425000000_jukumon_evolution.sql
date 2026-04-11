-- SM-18: Jukumon Evolution v2
-- Tables: jukumon_evolutions, jukumon_variants

-- ============================================================
-- 1. jukumon_evolutions — user's current evolution state
-- ============================================================
CREATE TABLE IF NOT EXISTS jukumon_evolutions (
  user_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  dominant_skill text NOT NULL DEFAULT 'vocabulary'
    CHECK (dominant_skill IN ('pronunciation', 'vocabulary', 'grammar', 'listening')),
  evolution_stage integer NOT NULL DEFAULT 0 CHECK (evolution_stage BETWEEN 0 AND 5),
  -- Stage 0=egg, 1=hatch(L5), 2=growth(L15), 3=mature(L30), 4=peak(L50), 5=mythic(L100)
  last_calculated_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE jukumon_evolutions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view any evolution"
  ON jukumon_evolutions FOR SELECT
  USING (true);

CREATE POLICY "Users can upsert own evolution"
  ON jukumon_evolutions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own evolution"
  ON jukumon_evolutions FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================
-- 2. jukumon_variants — cosmetic variant ownership
-- ============================================================
CREATE TABLE IF NOT EXISTS jukumon_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  rarity text NOT NULL DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
  skill_branch text CHECK (skill_branch IN ('pronunciation', 'vocabulary', 'grammar', 'listening')),
  juice_cost integer NOT NULL DEFAULT 0,     -- 0 = earned, not purchased
  seasonal boolean NOT NULL DEFAULT false,
  available_from timestamptz,
  available_until timestamptz,
  visual_data jsonb NOT NULL DEFAULT '{}',   -- emoji, colors, glow, aura config
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE jukumon_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view variants"
  ON jukumon_variants FOR SELECT
  USING (true);

-- ============================================================
-- 3. user_jukumon_variants — which variants a user owns/equipped
-- ============================================================
CREATE TABLE IF NOT EXISTS user_jukumon_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  variant_id uuid NOT NULL REFERENCES jukumon_variants(id) ON DELETE CASCADE,
  equipped boolean NOT NULL DEFAULT false,
  purchased_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, variant_id)
);

CREATE INDEX idx_user_variants_user ON user_jukumon_variants(user_id);

ALTER TABLE user_jukumon_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own variants"
  ON user_jukumon_variants FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own variants"
  ON user_jukumon_variants FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own variants"
  ON user_jukumon_variants FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================
-- 4. RPC: calculate_dominant_skill — from last 30 days sessions
-- ============================================================
CREATE OR REPLACE FUNCTION calculate_dominant_skill(p_user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_skill text;
BEGIN
  -- Count XP events by type in last 30 days to determine dominant skill
  -- pronunciation = speak events, vocabulary = card reviews, grammar = conjugation, listening = audio
  SELECT
    CASE
      WHEN COALESCE(SUM(CASE WHEN event_type LIKE '%pronunciation%' OR event_type LIKE '%speak%' THEN xp_amount ELSE 0 END), 0) >=
           GREATEST(
             COALESCE(SUM(CASE WHEN event_type LIKE '%card%' OR event_type LIKE '%deck%' THEN xp_amount ELSE 0 END), 0),
             COALESCE(SUM(CASE WHEN event_type LIKE '%conjugation%' OR event_type LIKE '%grammar%' THEN xp_amount ELSE 0 END), 0),
             COALESCE(SUM(CASE WHEN event_type LIKE '%audio%' OR event_type LIKE '%listen%' OR event_type LIKE '%song%' THEN xp_amount ELSE 0 END), 0)
           )
      THEN 'pronunciation'
      WHEN COALESCE(SUM(CASE WHEN event_type LIKE '%conjugation%' OR event_type LIKE '%grammar%' THEN xp_amount ELSE 0 END), 0) >=
           GREATEST(
             COALESCE(SUM(CASE WHEN event_type LIKE '%card%' OR event_type LIKE '%deck%' THEN xp_amount ELSE 0 END), 0),
             COALESCE(SUM(CASE WHEN event_type LIKE '%audio%' OR event_type LIKE '%listen%' OR event_type LIKE '%song%' THEN xp_amount ELSE 0 END), 0)
           )
      THEN 'grammar'
      WHEN COALESCE(SUM(CASE WHEN event_type LIKE '%audio%' OR event_type LIKE '%listen%' OR event_type LIKE '%song%' THEN xp_amount ELSE 0 END), 0) >=
           COALESCE(SUM(CASE WHEN event_type LIKE '%card%' OR event_type LIKE '%deck%' THEN xp_amount ELSE 0 END), 0)
      THEN 'listening'
      ELSE 'vocabulary'
    END
  INTO v_skill
  FROM xp_events
  WHERE user_id = p_user_id
    AND created_at > now() - interval '30 days';

  RETURN v_skill;
END;
$$;

-- ============================================================
-- 5. RPC: check_evolution — check and trigger evolution if ready
-- ============================================================
CREATE OR REPLACE FUNCTION check_evolution(p_user_id uuid, p_level integer)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_stage integer;
  v_new_stage integer;
  v_skill text;
  v_evolved boolean := false;
BEGIN
  -- Determine target stage from level
  v_new_stage := CASE
    WHEN p_level >= 100 THEN 5
    WHEN p_level >= 50 THEN 4
    WHEN p_level >= 30 THEN 3
    WHEN p_level >= 15 THEN 2
    WHEN p_level >= 5 THEN 1
    ELSE 0
  END;

  -- Get current stage
  SELECT evolution_stage INTO v_current_stage
  FROM jukumon_evolutions
  WHERE user_id = p_user_id;

  -- Calculate dominant skill
  v_skill := calculate_dominant_skill(p_user_id);

  IF v_current_stage IS NULL THEN
    -- First time: create evolution record
    INSERT INTO jukumon_evolutions (user_id, dominant_skill, evolution_stage)
    VALUES (p_user_id, v_skill, v_new_stage);
    v_evolved := v_new_stage > 0;
  ELSIF v_new_stage > v_current_stage THEN
    -- Evolution triggered!
    UPDATE jukumon_evolutions
    SET evolution_stage = v_new_stage,
        dominant_skill = v_skill,
        last_calculated_at = now()
    WHERE user_id = p_user_id;
    v_evolved := true;
  ELSE
    -- Update skill but no evolution
    UPDATE jukumon_evolutions
    SET dominant_skill = v_skill,
        last_calculated_at = now()
    WHERE user_id = p_user_id;
  END IF;

  RETURN jsonb_build_object(
    'evolved', v_evolved,
    'stage', v_new_stage,
    'skill', v_skill,
    'previous_stage', COALESCE(v_current_stage, 0)
  );
END;
$$;

-- ============================================================
-- 6. RPC: purchase_variant — buy a cosmetic variant with Juice
-- ============================================================
CREATE OR REPLACE FUNCTION purchase_variant(p_variant_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_cost integer;
  v_balance integer;
BEGIN
  -- Get variant cost
  SELECT juice_cost INTO v_cost
  FROM jukumon_variants
  WHERE id = p_variant_id;

  IF v_cost IS NULL THEN RETURN false; END IF;
  IF v_cost = 0 THEN RETURN false; END IF; -- Can't purchase free variants

  -- Check balance
  SELECT balance INTO v_balance
  FROM juice_wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF v_balance IS NULL OR v_balance < v_cost THEN RETURN false; END IF;

  -- Already owned?
  IF EXISTS (SELECT 1 FROM user_jukumon_variants WHERE user_id = v_user_id AND variant_id = p_variant_id) THEN
    RETURN false;
  END IF;

  -- Deduct Juice
  UPDATE juice_wallets SET balance = balance - v_cost, updated_at = now() WHERE user_id = v_user_id;
  INSERT INTO juice_transactions (user_id, amount, type, reference) VALUES (v_user_id, v_cost, 'spend', 'variant:' || p_variant_id);

  -- Grant variant
  INSERT INTO user_jukumon_variants (user_id, variant_id) VALUES (v_user_id, p_variant_id);

  RETURN true;
END;
$$;
