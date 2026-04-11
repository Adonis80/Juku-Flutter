// Supabase Edge Function: synthesize-speech (GL-3)
//
// Accepts: { text, language, voice_id? }
// Uses ElevenLabs API (BYOK) to synthesize speech from text.
// Returns: audio/mpeg binary stream.
//
// BYOK: User supplies their own ElevenLabs API key.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FALLBACK_ELEVENLABS_KEY = Deno.env.get("ELEVENLABS_API_KEY") ?? "";

// Default voices per language (ElevenLabs multilingual v2 voices).
const DEFAULT_VOICES: Record<string, string> = {
  de: "pNInz6obpgDQGcFmaJgB", // Adam — clear male German
  fr: "EXAVITQu4vr4xnSDxMaL", // Bella — warm female French
  ru: "onwK4e9ZLuTAKqWW03F9", // Daniel — male Russian
  zh: "XB0fDUnXU5powFXDhCwa", // Charlotte — female Mandarin
  ar: "pNInz6obpgDQGcFmaJgB", // Adam — Arabic
  en: "EXAVITQu4vr4xnSDxMaL", // Bella — English fallback
};

interface SpeechRequest {
  text: string;
  language: string;
  voice_id?: string;
}

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

    const body: SpeechRequest = await req.json();
    const { text, language, voice_id } = body;

    if (!text || !language) {
      return new Response(
        JSON.stringify({ error: "Missing text or language" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Get user's ElevenLabs key (BYOK).
    let elevenlabsKey = FALLBACK_ELEVENLABS_KEY;
    const { data: keyRow } = await supabase
      .from("ai_api_keys")
      .select("api_key_encrypted")
      .eq("user_id", user.id)
      .eq("provider", "elevenlabs")
      .eq("is_valid", true)
      .single();

    if (keyRow?.api_key_encrypted) {
      elevenlabsKey = keyRow.api_key_encrypted;
    }

    if (!elevenlabsKey) {
      return new Response(
        JSON.stringify({ error: "No ElevenLabs API key configured. Add your key in Settings." }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const selectedVoice = voice_id ?? DEFAULT_VOICES[language] ?? DEFAULT_VOICES["en"];

    // Call ElevenLabs TTS API.
    const ttsResponse = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${selectedVoice}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "xi-api-key": elevenlabsKey,
        },
        body: JSON.stringify({
          text,
          model_id: "eleven_multilingual_v2",
          voice_settings: {
            stability: 0.5,
            similarity_boost: 0.75,
            style: 0.3,
          },
        }),
      }
    );

    if (!ttsResponse.ok) {
      const errorText = await ttsResponse.text();

      if (ttsResponse.status === 401 && keyRow) {
        await supabase
          .from("ai_api_keys")
          .update({ is_valid: false, updated_at: new Date().toISOString() })
          .eq("user_id", user.id)
          .eq("provider", "elevenlabs");
      }

      return new Response(
        JSON.stringify({ error: "ElevenLabs API error", details: errorText }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Stream audio back directly.
    const audioBuffer = await ttsResponse.arrayBuffer();

    return new Response(audioBuffer, {
      headers: {
        "Content-Type": "audio/mpeg",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Internal error", details: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
