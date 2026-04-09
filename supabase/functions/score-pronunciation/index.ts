// Supabase Edge Function: score-pronunciation (SM-4.1)
//
// Accepts: { tempAudioPath, referenceText, language }
// 1. Downloads WAV from R2 temp path
// 2. POSTs to Azure Pronunciation Assessment API
// 3. Returns: { overallScore, grade, phonemes: [{phoneme, score, tileIndex}] }
// 4. Deletes temp file from R2
//
// MANUAL (Dhayan): supabase secrets set AZURE_SPEECH_KEY=... AZURE_SPEECH_REGION=uksouth

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const AZURE_SPEECH_KEY = Deno.env.get("AZURE_SPEECH_KEY") ?? "";
const AZURE_SPEECH_REGION = Deno.env.get("AZURE_SPEECH_REGION") ?? "uksouth";
const R2_ACCOUNT_ID = Deno.env.get("CLOUDFLARE_R2_ACCOUNT_ID") ?? "";
const R2_ACCESS_KEY = Deno.env.get("CLOUDFLARE_R2_ACCESS_KEY") ?? "";
const R2_SECRET_KEY = Deno.env.get("CLOUDFLARE_R2_SECRET_KEY") ?? "";
const R2_BUCKET = "skill-mode-audio";

interface PronunciationRequest {
  tempAudioPath: string;
  referenceText: string;
  language: string; // e.g. 'de-DE', 'en-US'
}

interface PhonemeResult {
  phoneme: string;
  score: number;
  tileIndex: number;
}

interface PronunciationResult {
  overallScore: number;
  grade: string;
  phonemes: PhonemeResult[];
}

serve(async (req: Request) => {
  // CORS headers.
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
    const body: PronunciationRequest = await req.json();
    const { tempAudioPath, referenceText, language } = body;

    if (!tempAudioPath || !referenceText || !language) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    if (!AZURE_SPEECH_KEY) {
      return new Response(
        JSON.stringify({ error: "Azure Speech key not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // 1. Download WAV from R2.
    const r2Url = `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com/${R2_BUCKET}/${tempAudioPath}`;
    const audioResponse = await fetch(r2Url, {
      headers: {
        Authorization: `Bearer ${R2_ACCESS_KEY}`,
      },
    });

    if (!audioResponse.ok) {
      return new Response(
        JSON.stringify({ error: "Failed to download audio from R2" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const audioBuffer = await audioResponse.arrayBuffer();

    // 2. Call Azure Pronunciation Assessment API.
    const azureUrl = `https://${AZURE_SPEECH_REGION}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=${language}`;

    // Pronunciation assessment config as a Base64-encoded JSON header.
    const pronunciationConfig = {
      ReferenceText: referenceText,
      GradingSystem: "HundredMark",
      Granularity: "Phoneme",
      Dimension: "Comprehensive",
      EnableMiscue: true,
    };

    const configBase64 = btoa(JSON.stringify(pronunciationConfig));

    const azureResponse = await fetch(azureUrl, {
      method: "POST",
      headers: {
        "Ocp-Apim-Subscription-Key": AZURE_SPEECH_KEY,
        "Content-Type": "audio/wav",
        "Pronunciation-Assessment": configBase64,
      },
      body: audioBuffer,
    });

    if (!azureResponse.ok) {
      const errorText = await azureResponse.text();
      return new Response(
        JSON.stringify({
          error: "Azure API error",
          details: errorText,
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const azureResult = await azureResponse.json();

    // 3. Parse Azure response into our format.
    const nbest = azureResult.NBest?.[0];
    const overallScore = Math.round(
      nbest?.PronunciationAssessment?.PronScore ?? 0
    );

    const grade = getGrade(overallScore);

    // Map phonemes to tile indices (word-level → tile mapping).
    const phonemes: PhonemeResult[] = [];
    const words = nbest?.Words ?? [];

    for (let tileIndex = 0; tileIndex < words.length; tileIndex++) {
      const word = words[tileIndex];
      const wordPhonemes = word.Phonemes ?? [];

      for (const p of wordPhonemes) {
        phonemes.push({
          phoneme: p.Phoneme ?? "",
          score: Math.round(p.PronunciationAssessment?.AccuracyScore ?? 0),
          tileIndex,
        });
      }
    }

    const result: PronunciationResult = {
      overallScore,
      grade,
      phonemes,
    };

    // 4. Delete temp file from R2 (best-effort).
    try {
      await fetch(r2Url, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${R2_ACCESS_KEY}`,
        },
      });
    } catch {
      // Non-blocking cleanup.
    }

    return new Response(JSON.stringify(result), {
      headers: {
        "Content-Type": "application/json",
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

function getGrade(score: number): string {
  if (score >= 90) return "perfect";
  if (score >= 70) return "good";
  if (score >= 50) return "almost";
  return "try_again";
}
