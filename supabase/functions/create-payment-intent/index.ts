// Supabase Edge Function: create-payment-intent (SM-15)
//
// Called by Flutter app to create a Stripe PaymentIntent for Juice top-up.
// Accepts: { amount_pence, juice_amount }
// Returns: { client_secret, payment_intent_id }
//
// Also handles: creating a Stripe SetupIntent for saving a card
// POST { action: "setup" } → { client_secret }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";

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

  if (!STRIPE_SECRET_KEY) {
    return jsonResponse({ error: "Stripe not configured" }, 500);
  }

  try {
    // Extract user from JWT
    const authHeader = req.headers.get("Authorization") ?? "";
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const body = await req.json();
    const action = body.action as string;

    if (action === "setup") {
      // Create SetupIntent to save a card for future use
      const customerId = await getOrCreateStripeCustomer(user.id, user.email ?? "");

      const res = await fetch("https://api.stripe.com/v1/setup_intents", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          customer: customerId,
          "payment_method_types[]": "card",
          "metadata[user_id]": user.id,
        }),
      });

      const data = await res.json();
      if (data.error) throw new Error(data.error.message);

      return jsonResponse({ client_secret: data.client_secret });
    }

    // Default: create PaymentIntent for immediate Juice top-up
    const amountPence = body.amount_pence as number;
    const juiceAmount = body.juice_amount as number;

    if (!amountPence || amountPence < 100 || !juiceAmount || juiceAmount < 1) {
      return jsonResponse({ error: "Invalid amount" }, 400);
    }

    const customerId = await getOrCreateStripeCustomer(user.id, user.email ?? "");

    const params: Record<string, string> = {
      amount: String(amountPence),
      currency: "gbp",
      customer: customerId,
      "metadata[user_id]": user.id,
      "metadata[juice_amount]": String(juiceAmount),
      "metadata[type]": "juice_topup",
    };

    // If user has a saved card, attach it
    const { data: savedMethod } = await supabase
      .from("payment_methods")
      .select("provider_id")
      .eq("user_id", user.id)
      .eq("type", "stripe_card")
      .eq("is_default", true)
      .eq("status", "active")
      .maybeSingle();

    if (savedMethod) {
      params.payment_method = savedMethod.provider_id;
    }

    const res = await fetch("https://api.stripe.com/v1/payment_intents", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams(params),
    });

    const data = await res.json();
    if (data.error) throw new Error(data.error.message);

    return jsonResponse({
      client_secret: data.client_secret,
      payment_intent_id: data.id,
    });
  } catch (err) {
    return jsonResponse({ error: String(err) }, 500);
  }
});

// ──────────────────────────────────────────────
// Get or create Stripe customer for this user
// ──────────────────────────────────────────────
async function getOrCreateStripeCustomer(
  userId: string,
  email: string
): Promise<string> {
  // Search for existing customer by metadata
  const searchRes = await fetch(
    `https://api.stripe.com/v1/customers/search?query=metadata['supabase_user_id']:'${userId}'`,
    { headers: { Authorization: `Bearer ${STRIPE_SECRET_KEY}` } }
  );
  const searchData = await searchRes.json();

  if (searchData.data?.length > 0) {
    return searchData.data[0].id;
  }

  // Create new customer
  const createRes = await fetch("https://api.stripe.com/v1/customers", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      email,
      "metadata[supabase_user_id]": userId,
    }),
  });

  const createData = await createRes.json();
  if (createData.error) throw new Error(createData.error.message);
  return createData.id;
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
