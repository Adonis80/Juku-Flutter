// Supabase Edge Function: create-gocardless-redirect (SM-15)
//
// Creates a GoCardless redirect flow for Direct Debit mandate setup.
// User is sent to GoCardless hosted page → completes mandate → redirected back.
// Accepts: {} (user extracted from JWT)
// Returns: { redirect_url }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const GOCARDLESS_ACCESS_TOKEN = Deno.env.get("GOCARDLESS_ACCESS_TOKEN") ?? "";
const GOCARDLESS_BASE_URL = Deno.env.get("GOCARDLESS_SANDBOX") === "true"
  ? "https://api-sandbox.gocardless.com"
  : "https://api.gocardless.com";

// Deep link back to app after mandate setup
const SUCCESS_REDIRECT = "pro.juku.app://callback?mandate=success";

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

  if (!GOCARDLESS_ACCESS_TOKEN) {
    return jsonResponse({ error: "GoCardless not configured" }, 500);
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

    // Get user's profile for pre-filling the mandate form
    const { data: profile } = await supabase
      .from("profiles")
      .select("display_name, username")
      .eq("id", user.id)
      .maybeSingle();

    // Create redirect flow
    const res = await fetch(`${GOCARDLESS_BASE_URL}/redirect_flows`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${GOCARDLESS_ACCESS_TOKEN}`,
        "Content-Type": "application/json",
        "GoCardless-Version": "2015-07-06",
      },
      body: JSON.stringify({
        redirect_flows: {
          description: "Juku Juice — Direct Debit for tips & settlements",
          session_token: user.id,
          success_redirect_url: SUCCESS_REDIRECT,
          scheme: "bacs", // UK Direct Debit (use "ach" for US, "sepa_core" for EU)
        },
      }),
    });

    const data = await res.json();
    if (data.error) throw new Error(JSON.stringify(data.error));

    const redirectUrl = data.redirect_flows.redirect_url;

    return jsonResponse({ redirect_url: redirectUrl });
  } catch (err) {
    return jsonResponse({ error: String(err) }, 500);
  }
});

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
