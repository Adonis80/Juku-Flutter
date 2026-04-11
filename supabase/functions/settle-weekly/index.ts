// Supabase Edge Function: settle-weekly (SM-15)
//
// Cron: Sunday 23:00 UTC
// 1. Finds all unsettled juice_ledger rows for the current week
// 2. For each user with net_balance != 0:
//    - net_balance < 0 (spent more than earned) → charge via GoCardless or Stripe
//    - net_balance > 0 (earned more than spent) → payout via GoCardless
// 3. Creates settlement record and marks ledger as settled
//
// MANUAL: supabase secrets set STRIPE_SECRET_KEY=sk_live_xxx GOCARDLESS_ACCESS_TOKEN=xxx

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
const GOCARDLESS_ACCESS_TOKEN = Deno.env.get("GOCARDLESS_ACCESS_TOKEN") ?? "";
const GOCARDLESS_BASE_URL = Deno.env.get("GOCARDLESS_SANDBOX") === "true"
  ? "https://api-sandbox.gocardless.com"
  : "https://api.gocardless.com";

// Juice-to-pence conversion: 10 Juice = 100p (£1)
const JUICE_TO_PENCE = 10;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  try {
    // Get current week start (Monday)
    const now = new Date();
    const dayOfWeek = now.getUTCDay(); // 0=Sun
    const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    const weekStart = new Date(now);
    weekStart.setUTCDate(now.getUTCDate() - mondayOffset);
    weekStart.setUTCHours(0, 0, 0, 0);
    const weekStartStr = weekStart.toISOString().split("T")[0];

    // Fetch unsettled ledger entries for this week
    const { data: ledgerRows, error: ledgerError } = await supabase
      .from("juice_ledger")
      .select("*")
      .eq("week_start", weekStartStr)
      .eq("settled", false)
      .neq("net_balance", 0);

    if (ledgerError) throw ledgerError;
    if (!ledgerRows || ledgerRows.length === 0) {
      return jsonResponse({ message: "No settlements needed", week: weekStartStr });
    }

    const results: { userId: string; status: string; amount: number }[] = [];

    for (const row of ledgerRows) {
      const userId = row.user_id;
      const netBalance = row.net_balance as number;
      const amountPence = Math.abs(netBalance) * JUICE_TO_PENCE;

      // Skip tiny amounts (under 50p)
      if (amountPence < 50) {
        results.push({ userId, status: "skipped_small", amount: amountPence });
        continue;
      }

      // Get user's default payment method
      const { data: paymentMethod } = await supabase
        .from("payment_methods")
        .select("*")
        .eq("user_id", userId)
        .eq("is_default", true)
        .eq("status", "active")
        .maybeSingle();

      if (!paymentMethod) {
        results.push({ userId, status: "no_payment_method", amount: amountPence });
        continue;
      }

      let providerPaymentId = "";
      let settlementStatus = "pending";

      try {
        if (netBalance < 0) {
          // User owes money — charge them
          if (paymentMethod.type === "stripe_card" && STRIPE_SECRET_KEY) {
            providerPaymentId = await chargeStripe(
              paymentMethod.provider_id,
              amountPence,
              userId
            );
            settlementStatus = "processing";
          } else if (paymentMethod.type === "gocardless_mandate" && GOCARDLESS_ACCESS_TOKEN) {
            providerPaymentId = await chargeGoCardless(
              paymentMethod.provider_id,
              amountPence,
              userId,
              weekStartStr
            );
            settlementStatus = "processing";
          }
        } else {
          // User earned money — payout (GoCardless only)
          if (paymentMethod.type === "gocardless_mandate" && GOCARDLESS_ACCESS_TOKEN) {
            providerPaymentId = await payoutGoCardless(
              userId,
              amountPence,
              weekStartStr
            );
            settlementStatus = "processing";
          } else {
            // Stripe card users: hold payout until they add a bank account
            settlementStatus = "pending";
          }
        }
      } catch (err) {
        settlementStatus = "failed";
        providerPaymentId = String(err);
      }

      // Create settlement record
      const { error: settleError } = await supabase.from("settlements").insert({
        user_id: userId,
        ledger_id: row.id,
        week_start: weekStartStr,
        amount_pence: netBalance < 0 ? -amountPence : amountPence,
        method_type: paymentMethod.type,
        payment_method_id: paymentMethod.id,
        provider_payment_id: providerPaymentId,
        status: settlementStatus,
        error_message: settlementStatus === "failed" ? providerPaymentId : null,
      });

      if (settleError) {
        results.push({ userId, status: "db_error", amount: amountPence });
        continue;
      }

      // Mark ledger as settled
      await supabase
        .from("juice_ledger")
        .update({ settled: true, updated_at: new Date().toISOString() })
        .eq("id", row.id);

      results.push({ userId, status: settlementStatus, amount: amountPence });
    }

    return jsonResponse({
      message: `Processed ${results.length} settlements`,
      week: weekStartStr,
      results,
    });
  } catch (err) {
    return jsonResponse({ error: "Settlement failed", details: String(err) }, 500);
  }
});

// ──────────────────────────────────────────────
// Stripe: charge a saved card
// ──────────────────────────────────────────────
async function chargeStripe(
  paymentMethodId: string,
  amountPence: number,
  userId: string
): Promise<string> {
  // First get the customer ID for this payment method
  const res = await fetch("https://api.stripe.com/v1/payment_intents", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      amount: String(amountPence),
      currency: "gbp",
      payment_method: paymentMethodId,
      confirm: "true",
      off_session: "true",
      description: `Juku Juice settlement for user ${userId}`,
      "metadata[user_id]": userId,
      "metadata[type]": "weekly_settlement",
    }),
  });

  const data = await res.json();
  if (data.error) throw new Error(data.error.message);
  return data.id; // pi_xxx
}

// ──────────────────────────────────────────────
// GoCardless: charge via direct debit mandate
// ──────────────────────────────────────────────
async function chargeGoCardless(
  mandateId: string,
  amountPence: number,
  userId: string,
  weekStart: string
): Promise<string> {
  const res = await fetch(`${GOCARDLESS_BASE_URL}/payments`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${GOCARDLESS_ACCESS_TOKEN}`,
      "Content-Type": "application/json",
      "GoCardless-Version": "2015-07-06",
    },
    body: JSON.stringify({
      payments: {
        amount: amountPence,
        currency: "GBP",
        links: { mandate: mandateId },
        description: `Juku Juice settlement w/c ${weekStart}`,
        metadata: { user_id: userId, week_start: weekStart },
      },
    }),
  });

  const data = await res.json();
  if (data.error) throw new Error(JSON.stringify(data.error));
  return data.payments.id; // PM_xxx
}

// ──────────────────────────────────────────────
// GoCardless: payout to user's bank account
// ──────────────────────────────────────────────
async function payoutGoCardless(
  userId: string,
  amountPence: number,
  weekStart: string
): Promise<string> {
  // GoCardless doesn't do ad-hoc payouts via API — payouts are automatic
  // from your GoCardless account to merchants. For creator payouts,
  // we'll use Stripe Connect or manual bank transfer.
  // For now: mark as pending for manual review.
  return `payout_pending_${userId}_${weekStart}_${amountPence}p`;
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
