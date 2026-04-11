-- SM-19: Juku Studio Pro
-- Tables: studio_ai_credits, creator_revenue_dashboard view

-- ============================================================
-- 1. studio_ai_credits — AI generation credit tracking
-- ============================================================
CREATE TABLE IF NOT EXISTS studio_ai_credits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  credits_remaining integer NOT NULL DEFAULT 10,  -- free tier: 10 credits
  credits_used integer NOT NULL DEFAULT 0,
  last_refill_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_studio_ai_credits_user ON studio_ai_credits(user_id);

ALTER TABLE studio_ai_credits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own AI credits"
  ON studio_ai_credits FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own AI credits"
  ON studio_ai_credits FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own AI credits"
  ON studio_ai_credits FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================
-- 2. RPC: use_ai_credit — deduct one AI generation credit
-- ============================================================
CREATE OR REPLACE FUNCTION use_ai_credit()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_remaining integer;
BEGIN
  -- Upsert credits row
  INSERT INTO studio_ai_credits (user_id)
  VALUES (v_user_id)
  ON CONFLICT DO NOTHING;

  SELECT credits_remaining INTO v_remaining
  FROM studio_ai_credits
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF v_remaining IS NULL OR v_remaining <= 0 THEN
    RETURN false;
  END IF;

  UPDATE studio_ai_credits
  SET credits_remaining = credits_remaining - 1,
      credits_used = credits_used + 1
  WHERE user_id = v_user_id;

  RETURN true;
END;
$$;

-- ============================================================
-- 3. RPC: buy_ai_credits — purchase AI credits with Juice
-- ============================================================
CREATE OR REPLACE FUNCTION buy_ai_credits(p_credit_count integer)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_cost integer;
  v_balance integer;
BEGIN
  -- 1 credit = 5 Juice
  v_cost := p_credit_count * 5;

  SELECT balance INTO v_balance
  FROM juice_wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF v_balance IS NULL OR v_balance < v_cost THEN
    RETURN false;
  END IF;

  UPDATE juice_wallets SET balance = balance - v_cost, updated_at = now() WHERE user_id = v_user_id;
  INSERT INTO juice_transactions (user_id, amount, type, reference) VALUES (v_user_id, v_cost, 'spend', 'ai_credits:' || p_credit_count);

  -- Upsert credits
  INSERT INTO studio_ai_credits (user_id, credits_remaining)
  VALUES (v_user_id, p_credit_count)
  ON CONFLICT (user_id)
  DO UPDATE SET credits_remaining = studio_ai_credits.credits_remaining + p_credit_count;

  RETURN true;
END;
$$;
