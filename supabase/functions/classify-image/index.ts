// =====================================================================
// classify-image Edge Function
//
// Receives { photoPath } from an authenticated client. Verifies the JWT,
// confirms the photo path belongs to that user, downloads the image from
// Storage using the service-role key, and forwards it to OpenAI gpt-5.4-nano
// with the PRD's classification prompt. Returns parsed { category, reason,
// content }.
//
// Required secrets (set via Dashboard → Edge Functions → Secrets, or
// `supabase secrets set KEY=VALUE`):
//   - OPENAI_API_KEY        (your platform.openai.com key)
//   - OPENAI_MODEL          (optional — defaults to "gpt-4o-mini")
//
// SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY are injected
// by the platform automatically.
// =====================================================================

// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const PROMPT = `You are an image classifier and text extractor.
Classify the attached image into EXACTLY ONE of these categories:
- memo (handwritten or printed note)
- receipt (purchase receipt / invoice)
- business_card (name card with contact info)
- other (anything that does not clearly fit the three above)

Then extract and organize all readable text from the image.

Respond in Korean using this exact format:
분류: <메모 | 영수증 | 명함 | 기타>
근거: <1-2 short sentences in Korean explaining the visual cues that led to this classification>
내용: <All readable text from the image, organized and cleaned up in Korean. If the category is "기타" and there is no meaningful text, write "텍스트 없음">

Do not output anything else.`;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "Authorization header missing" }, 401);

    const { photoPath } = (await req.json()) as { photoPath?: string };
    if (!photoPath || typeof photoPath !== "string") {
      return json({ error: "photoPath (string) is required" }, 400);
    }

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");

    if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
      return json({ error: "Supabase env vars missing in function runtime" }, 500);
    }
    if (!OPENAI_API_KEY) {
      return json({ error: "OPENAI_API_KEY secret not set" }, 500);
    }

    // Verify caller's JWT.
    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    const user = userData?.user;
    if (userErr || !user) {
      return json({ error: "Invalid token" }, 401);
    }

    // Path must belong to the caller (defense-in-depth — RLS already enforces).
    if (!photoPath.startsWith(`${user.id}/`)) {
      return json({ error: "Photo path does not belong to caller" }, 403);
    }

    // Download with service-role to bypass RLS for trusted server reads.
    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data: blob, error: dlErr } = await adminClient.storage
      .from("photo-memos")
      .download(photoPath);
    if (dlErr || !blob) {
      return json({ error: `Storage download failed: ${dlErr?.message}` }, 500);
    }

    const buf = new Uint8Array(await blob.arrayBuffer());
    const base64 = base64Encode(buf);
    const mimeType = blob.type || "image/jpeg";

    const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";

    console.log(
      "[classify-image] invoking OpenAI",
      JSON.stringify({ model, mimeType, bytes: buf.length, photoPath }),
    );

    // OpenAI Chat Completions with vision.
    const oaiRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: PROMPT },
          {
            role: "user",
            content: [
              {
                type: "image_url",
                image_url: { url: `data:${mimeType};base64,${base64}` },
              },
            ],
          },
        ],
        max_completion_tokens: 800,
      }),
    });

    if (!oaiRes.ok) {
      const errText = await oaiRes.text();
      console.error(
        "[classify-image] OpenAI error",
        oaiRes.status,
        errText,
      );
      return json({ error: `OpenAI ${oaiRes.status}: ${errText}` }, 502);
    }
    const oai = (await oaiRes.json()) as any;
    const content: string = oai?.choices?.[0]?.message?.content ?? "";
    const parsed = parseResponse(content);

    return json({ ...parsed, raw: content });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});

// Parses the strict 분류:/근거:/내용: format. Resilient to extra whitespace
// and multi-line bodies. Falls back to category="other" if parse fails.
function parseResponse(text: string): {
  category: string;
  reason: string;
  content: string;
} {
  const lines = text.split(/\r?\n/);
  let category = "other";
  let reason = "";
  let content = "";
  let mode: "category" | "reason" | "content" | null = null;

  const categoryMap: Record<string, string> = {
    "메모": "memo",
    "영수증": "receipt",
    "명함": "business_card",
    "기타": "other",
  };

  for (const raw of lines) {
    const line = raw.trimEnd();
    if (line.startsWith("분류:")) {
      const v = line.slice(3).trim();
      category = categoryMap[v] ?? "other";
      mode = "category";
    } else if (line.startsWith("근거:")) {
      reason = line.slice(3).trim();
      mode = "reason";
    } else if (line.startsWith("내용:")) {
      content = line.slice(3).trim();
      mode = "content";
    } else if (mode === "reason" && line.trim()) {
      reason += (reason ? "\n" : "") + line;
    } else if (mode === "content" && line.trim()) {
      content += (content ? "\n" : "") + line;
    }
  }

  return {
    category,
    reason: reason.trim(),
    content: content.trim(),
  };
}

// Chunked base64 encoder — avoids stack overflow on large images that would
// hit String.fromCharCode(...spread) limits.
function base64Encode(bytes: Uint8Array): string {
  let binary = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(
      ...bytes.subarray(i, Math.min(i + chunk, bytes.length)),
    );
  }
  return btoa(binary);
}
