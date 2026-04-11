// Supabase Edge Function: gocardless-webhook (SM-15)
//
// Handles GoCardless webhook events:
// - mandates: confirmed, cancelled, failed
// - payments: confirmed, paid_out, failed
//
// MANUAL: supabase secrets set GOCARDLESS_WEBHOOK_SECRET=xxx

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const GOCARDLESS_WEBHOOK_SECRET = Deno.env.get("GOCARDLESS_WEBHOOK_SECRET") ?? "";

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  try {
    const body = await req.text();

    // Verify webhook signature
    const signature = req.headers.get("Webhook-Signature") ?? "";
    if (GOCARDLESS_WEBHOOK_SECRET) {
      const isValid = await verifySignature(body, signature, GOCARDLESS_WEBHOOK_SECRET);
      if (!isValid) {
        return new Response("Invalid signature", { status: 498 });
      }
    }

    const payload = JSON.parse(body);
    const events = payload.events ?? [];

    for (const event of events) {
      const resourceType = event.resource_type;
      const action = event.action;

      switch (resourceType) {
        case "mandates":
          await handleMandateEvent(supabase, event, action);
          break;
        case "payments":
          await handlePaymentEvent(supabase, event, action);
          break;
      }
    }

    return new Response(JSON.stringify({ received: events.length }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Webhook processing failed", details: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

// ──────────────────────────────────────────────
// Mandate events
// ──────────────────────────────────────────────
async function handleMandateEvent(
  supabase: ReturnType<typeof createClient>,
  event: Record<string, unknown>,
  action: string
) {
  const links = event.links as Record<string, string> | undefined;
  const mandateId = links?.mandate;
  if (!mandateId) return;

  let newStatus: string;
  switch (action) {
    case "confirmed":
    case "active":
      newStatus = "active";
      break;
    case "cancelled":
    case "expired":
      newStatus = "cancelled";
      break;
    case "failed":
      newStatus = "failed";
      break;
    default:
      return; // Ignore other mandate actions
  }

  await supabase
    .from("payment_methods")
    .update({ status: newStatus, updated_at: new Date().toISOString() })
    .eq("provider_id", mandateId);
}

// ──────────────────────────────────────────────
// Payment events
// ──────────────────────────────────────────────
async function handlePaymentEvent(
  supabase: ReturnType<typeof createClient>,
  event: Record<string, unknown>,
  action: string
) {
  const links = event.links as Record<string, string> | undefined;
  const paymentId = links?.payment;
  if (!paymentId) return;

  let newStatus: string;
  switch (action) {
    case "confirmed":
    case "paid_out":
      newStatus = "completed";
      break;
    case "failed":
    case "charged_back":
      newStatus = "failed";
      break;
    case "submitted":
      newStatus = "processing";
      break;
    default:
      return;
  }

  const update: Record<string, unknown> = { status: newStatus };
  if (newStatus === "completed") {
    update.completed_at = new Date().toISOString();
  }
  if (newStatus === "failed") {
    const details = event.details as Record<string, string> | undefined;
    update.error_message = details?.description ?? "Payment failed";
  }

  await supabase
    .from("settlements")
    .update(update)
    .eq("provider_payment_id", paymentId);
}

// ──────────────────────────────────────────────
// Webhook signature verification (HMAC-SHA256)
// ──────────────────────────────────────────────
async function verifySignature(
  body: string,
  signatureHeader: string,
  secret: string
): Promise<boolean> {
  try {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const sig = await crypto.subtle.sign("HMAC", key, encoder.encode(body));
    const computed = Array.from(new Uint8Array(sig))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    return computed === signatureHeader;
  } catch {
    return false;
  }
}
