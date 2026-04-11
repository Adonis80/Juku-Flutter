-- SM-15: Payment v2 — Hybrid Stripe + GoCardless
-- Tables: payment_methods, juice_ledger, settlements
-- + RPC: credit_juice (for Stripe top-up callback)

-- ============================================================
-- 1. payment_methods — stored card (Stripe) or bank (GoCardless)
-- ============================================================
CREATE TABLE IF NOT EXISTS payment_methods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('stripe_card', 'gocardless_mandate')),
  -- Stripe: pm_xxx payment method ID. GoCardless: MD_xxx mandate ID.
  provider_id text NOT NULL,
  label text NOT NULL DEFAULT '',          -- e.g. "Visa ****4242" or "Barclays ****1234"
  is_default boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'pending', 'cancelled', 'failed')),
  metadata jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_payment_methods_user ON payment_methods(user_id);

ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own payment methods"
  ON payment_methods FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own payment methods"
  ON payment_methods FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own payment methods"
  ON payment_methods FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own payment methods"
  ON payment_methods FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 2. juice_ledger — weekly tip accumulations per user
-- ============================================================
CREATE TABLE IF NOT EXISTS juice_ledger (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  week_start date NOT NULL,                -- Monday of the settlement week
  tips_sent integer NOT NULL DEFAULT 0,    -- total Juice sent as tips this week
  tips_received integer NOT NULL DEFAULT 0,-- total Juice received as tips this week
  purchases integer NOT NULL DEFAULT 0,    -- Juice purchased (Stripe top-ups)
  spent integer NOT NULL DEFAULT 0,        -- Juice spent (boosts, world items, etc.)
  net_balance integer NOT NULL DEFAULT 0,  -- computed: purchases + tips_received - tips_sent - spent
  settled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, week_start)
);

CREATE INDEX idx_juice_ledger_week ON juice_ledger(week_start, settled);
CREATE INDEX idx_juice_ledger_user ON juice_ledger(user_id, week_start DESC);

ALTER TABLE juice_ledger ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own ledger"
  ON juice_ledger FOR SELECT
  USING (auth.uid() = user_id);

-- Service role only for inserts/updates (Edge Function)
CREATE POLICY "Service role manages ledger"
  ON juice_ledger FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================
-- 3. settlements — weekly settlement records
-- ============================================================
CREATE TABLE IF NOT EXISTS settlements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  ledger_id uuid NOT NULL REFERENCES juice_ledger(id),
  week_start date NOT NULL,
  amount_pence integer NOT NULL,           -- positive = payout to user, negative = charge
  method_type text NOT NULL CHECK (method_type IN ('stripe_card', 'gocardless_mandate')),
  payment_method_id uuid REFERENCES payment_methods(id),
  provider_payment_id text,                -- Stripe pi_xxx or GoCardless PM_xxx
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

CREATE INDEX idx_settlements_user ON settlements(user_id, week_start DESC);
CREATE INDEX idx_settlements_status ON settlements(status) WHERE status IN ('pending', 'processing');

ALTER TABLE settlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own settlements"
  ON settlements FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Service role manages settlements"
  ON settlements FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================
-- 4. RPC: credit_juice — called after Stripe payment success
-- ============================================================
CREATE OR REPLACE FUNCTION credit_juice(
  p_user_id uuid,
  p_amount integer,
  p_reference text
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Upsert wallet (create if not exists)
  INSERT INTO juice_wallets (user_id, balance)
  VALUES (p_user_id, p_amount)
  ON CONFLICT (user_id)
  DO UPDATE SET
    balance = juice_wallets.balance + p_amount,
    updated_at = now();

  -- Record transaction
  INSERT INTO juice_transactions (user_id, amount, type, reference)
  VALUES (p_user_id, p_amount, 'purchase', p_reference);

  -- Update weekly ledger
  INSERT INTO juice_ledger (user_id, week_start, purchases, net_balance)
  VALUES (
    p_user_id,
    date_trunc('week', now())::date,
    p_amount,
    p_amount
  )
  ON CONFLICT (user_id, week_start)
  DO UPDATE SET
    purchases = juice_ledger.purchases + p_amount,
    net_balance = juice_ledger.net_balance + p_amount,
    updated_at = now();

  RETURN true;
END;
$$;

-- ============================================================
-- 5. Update spend_juice to also track in ledger
-- ============================================================
CREATE OR REPLACE FUNCTION spend_juice(
  p_amount integer,
  p_reference text
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_balance integer;
BEGIN
  -- Lock the wallet row
  SELECT balance INTO v_balance
  FROM juice_wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF v_balance IS NULL OR v_balance < p_amount THEN
    RETURN false;
  END IF;

  UPDATE juice_wallets
  SET balance = balance - p_amount, updated_at = now()
  WHERE user_id = v_user_id;

  INSERT INTO juice_transactions (user_id, amount, type, reference)
  VALUES (v_user_id, p_amount, 'spend', p_reference);

  -- Update weekly ledger
  INSERT INTO juice_ledger (user_id, week_start, spent, net_balance)
  VALUES (
    v_user_id,
    date_trunc('week', now())::date,
    p_amount,
    -p_amount
  )
  ON CONFLICT (user_id, week_start)
  DO UPDATE SET
    spent = juice_ledger.spent + p_amount,
    net_balance = juice_ledger.net_balance - p_amount,
    updated_at = now();

  RETURN true;
END;
$$;
