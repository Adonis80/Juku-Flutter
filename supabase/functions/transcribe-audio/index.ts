// Supabase Edge Function: transcribe-audio (GL-3)
//
// Accepts: multipart form with audio file + language
// Uses OpenAI Whisper API (BYOK) to transcribe speech to text.
// Returns: { text, language, duration_ms }
//
// BYOK: User supplies their own OpenAI API key via ai_api_keys table.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FALLBACK_OPENAI_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

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

  try {
    // Get user from auth header.
    const authHeader = req.headers.get("authorization") ?? "";
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    // Try to get user's own OpenAI key (BYOK).
    let openaiKey = FALLBACK_OPENAI_KEY;
    const { data: keyRow } = await supabase
      .from("ai_api_keys")
      .select("api_key_encrypted")
      .eq("user_id", user.id)
      .eq("provider", "openai")
      .eq("is_valid", true)
      .single();

    if (keyRow?.api_key_encrypted) {
      openaiKey = keyRow.api_key_encrypted;
    }

    if (!openaiKey) {
      return new Response(
        JSON.stringify({ error: "No OpenAI API key configured. Add your key in Settings." }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Parse multipart form data.
    const formData = await req.formData();
    const audioFile = formData.get("audio") as File | null;
    const language = (formData.get("language") as string) ?? "de";

    if (!audioFile) {
      return new Response(
        JSON.stringify({ error: "No audio file provided" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Call OpenAI Whisper API.
    const whisperForm = new FormData();
    whisperForm.append("file", audioFile, "audio.wav");
    whisperForm.append("model", "whisper-1");
    whisperForm.append("language", language);
    whisperForm.append("response_format", "verbose_json");

    const whisperResponse = await fetch(
      "https://api.openai.com/v1/audio/transcriptions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${openaiKey}`,
        },
        body: whisperForm,
      }
    );

    if (!whisperResponse.ok) {
      const errorText = await whisperResponse.text();

      // Mark key as invalid if auth fails.
      if (whisperResponse.status === 401 && keyRow) {
        await supabase
          .from("ai_api_keys")
          .update({ is_valid: false, updated_at: new Date().toISOString() })
          .eq("user_id", user.id)
          .eq("provider", "openai");
      }

      return new Response(
        JSON.stringify({ error: "Whisper API error", details: errorText }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const result = await whisperResponse.json();

    return new Response(
      JSON.stringify({
        text: result.text ?? "",
        language: result.language ?? language,
        duration_ms: Math.round((result.duration ?? 0) * 1000),
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Internal error", details: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
