-- SM-16: Juku Live — real-time broadcast sessions with Juice gifting
-- Tables: live_sessions, live_gifts

-- ============================================================
-- 1. live_sessions — host broadcasts to viewers
-- ============================================================
CREATE TABLE IF NOT EXISTS live_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL DEFAULT '',
  language text,                           -- e.g. 'de', 'fr', 'ar'
  status text NOT NULL DEFAULT 'live' CHECK (status IN ('live', 'ended')),
  current_card_index integer NOT NULL DEFAULT 0,
  module_id uuid,                          -- optional: Skill Mode module being played
  viewer_count integer NOT NULL DEFAULT 0,
  total_gifts_juice integer NOT NULL DEFAULT 0,
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz
);

CREATE INDEX idx_live_sessions_status ON live_sessions(status) WHERE status = 'live';
CREATE INDEX idx_live_sessions_host ON live_sessions(host_id);

ALTER TABLE live_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view live sessions"
  ON live_sessions FOR SELECT
  USING (true);

CREATE POLICY "Host can insert own sessions"
  ON live_sessions FOR INSERT
  WITH CHECK (auth.uid() = host_id);

CREATE POLICY "Host can update own sessions"
  ON live_sessions FOR UPDATE
  USING (auth.uid() = host_id);

-- ============================================================
-- 2. live_gifts — Juice gifts sent during live sessions
-- ============================================================
CREATE TABLE IF NOT EXISTS live_gifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES live_sessions(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  host_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  gift_type text NOT NULL CHECK (gift_type IN ('wave', 'fire', 'crown')),
  juice_amount integer NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_live_gifts_session ON live_gifts(session_id);
CREATE INDEX idx_live_gifts_sender ON live_gifts(sender_id);

ALTER TABLE live_gifts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view gifts in live sessions"
  ON live_gifts FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can send gifts"
  ON live_gifts FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- ============================================================
-- 3. RPC: send_live_gift — atomic gift + juice transfer
-- ============================================================
CREATE OR REPLACE FUNCTION send_live_gift(
  p_session_id uuid,
  p_host_id uuid,
  p_gift_type text,
  p_juice_amount integer
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sender_id uuid := auth.uid();
  v_balance integer;
BEGIN
  -- Check sender has enough Juice
  SELECT balance INTO v_balance
  FROM juice_wallets
  WHERE user_id = v_sender_id
  FOR UPDATE;

  IF v_balance IS NULL OR v_balance < p_juice_amount THEN
    RETURN false;
  END IF;

  -- Deduct from sender
  UPDATE juice_wallets
  SET balance = balance - p_juice_amount, updated_at = now()
  WHERE user_id = v_sender_id;

  -- Credit to host
  INSERT INTO juice_wallets (user_id, balance)
  VALUES (p_host_id, p_juice_amount)
  ON CONFLICT (user_id)
  DO UPDATE SET
    balance = juice_wallets.balance + p_juice_amount,
    updated_at = now();

  -- Record gift
  INSERT INTO live_gifts (session_id, sender_id, host_id, gift_type, juice_amount)
  VALUES (p_session_id, v_sender_id, p_host_id, p_gift_type, p_juice_amount);

  -- Record transactions
  INSERT INTO juice_transactions (user_id, amount, type, reference)
  VALUES
    (v_sender_id, p_juice_amount, 'spend', 'live_gift:' || p_session_id),
    (p_host_id, p_juice_amount, 'purchase', 'live_gift_received:' || p_session_id);

  -- Update session totals
  UPDATE live_sessions
  SET total_gifts_juice = total_gifts_juice + p_juice_amount
  WHERE id = p_session_id;

  RETURN true;
END;
$$;
