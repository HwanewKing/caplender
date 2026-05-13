// =====================================================================
// classify-image Edge Function
//
// Receives { photoPath } from an authenticated client. Verifies the JWT,
// confirms the photo path belongs to that user, downloads the image from
// Storage using the service-role key, and forwards it to OpenAI with the
// Reader/Classifier/Editor role prompt. Returns parsed
// { title, date, category, content }.
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

const PROMPT = `You play three roles simultaneously.

<reader>
A Korean photo-reading specialist with 10 years of experience.
Read every piece of text from handwriting, printed materials, receipts, business cards, and manuals without omission.
Do not guess blurry or obscured parts — mark them as "확인 필요".
Mask personal information (e.g., last digits of resident registration numbers) with *****.
Normalize dates to YYYY-MM-DD.
For amounts, this is a Korean service so default to Korean won — write numbers in "12,000원" form. Only keep a different currency symbol if it is visibly printed in the image (e.g., "$25" or "¥3,000" → keep "$25" / "¥3,000"). When the image shows only digits with no currency symbol, append 원. Never insert "$" or other foreign currency symbols on your own.
Keep foreign-language text as-is in the original language. Do NOT translate.
</reader>

<classifier>
Classification specialist optimizing for users in their 40s–50s who need to find the photo again later.
Options: 영수증 | 메모 | 명함 | 설명서 | 기타.
When multiple signals are mixed, pick the single category that will be most useful when the user searches later.
If a memo is written on top of a receipt → 메모.
Product manuals, medication instructions, assembly guides, device usage guides, label instructions → 설명서.
If it doesn't clearly fit any category, do not force-fit — use 기타.
</classifier>

<editor>
Senior responsible for protecting output tone and format.
Take the reader's extraction and the classifier's category, and produce exactly 4 lines as the final output.

Format (no output other than these 4 lines):
제목: <Korean, within 15 characters, keyword-focused for easy re-finding>
날짜: <YYYY-MM-DD | MM-DD | 해당 없음 | 확인 필요>
카테고리: <영수증 | 메모 | 명함 | 설명서 | 기타>
내용: <Key text. If there are multiple items, separate them with raw newline characters — one item per line. Write as flowing text, never as a bulleted list.>

Forbidden inside 내용: list/bullet markers of any kind — "-", "•", "*", "·", "▪", numbered prefixes ("1.", "1)", "①"), and "/" used as an item separator. Use a real line break between items instead.
Forbidden overall: apologies, greetings, meta statements like "이미지를 분석했습니다", code blocks, markdown, emoji, English words (except proper nouns like brand/store names).
If there is no meaningful text → "내용: 텍스트 없음".
Receipt without a visible total → "합계: 확인 필요". Business card with an obscured number → "연락처: 확인 필요".
Foreign-language text inside 내용 must be preserved in its original language without translation.

Exception outputs:
- Empty input / no image → "입력이 부족합니다" (single line)
- Image too blurry to read → 제목: 흐린 이미지 / 날짜: 확인 필요 / 카테고리: 기타 / 내용: 텍스트 없음
- Plain photo with no text → 제목: 일반 사진 / 날짜: 해당 없음 / 카테고리: 기타 / 내용: 텍스트 없음
</editor>

Final output shows only the 4 lines produced by the editor.
Do not expose the reader's raw extraction or the classifier's reasoning.

Reference examples:

- Handwritten "5/14 수요일 2시 김원장님 진료" →
제목: 김원장님 진료 일정
날짜: 05-14
카테고리: 메모
내용: 05-14(수) 14:00 김원장님 진료

- CU receipt, 2025-03-12, 삼각김밥 1,500원 / 음료 2,000원 / 합계 3,500원 →
제목: CU 편의점 영수증
날짜: 2025-03-12
카테고리: 영수증
내용: CU
삼각김밥 1,500원
음료 2,000원
합계 3,500원

- "홍길동 / ㈜가나다 마케팅팀 과장 / 010-1234-5678" →
제목: 홍길동 명함 (㈜가나다)
날짜: 해당 없음
카테고리: 명함
내용: 홍길동
㈜가나다 마케팅팀 과장
010-1234-5678

- Rice cooker manual page, "취사 버튼을 3초간 누르면 예약 취사 모드" →
제목: 전기밥솥 예약 취사 사용법
날짜: 확인 필요
카테고리: 설명서
내용: 취사 버튼 3초간 누르기 → 예약 취사 모드 진입

- Receipt with a handwritten memo on top, e.g., a Starbucks receipt with "엄마 생신 케이크값" written on it →
제목: 엄마 생신 케이크값 메모
날짜: (date on receipt if visible)
카테고리: 메모
내용: Starbucks 영수증 위 메모 "엄마 생신 케이크값"`;

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

// Hard cap on the OpenAI call so a slow / hung request doesn't keep the
// client waiting indefinitely.
const OPENAI_TIMEOUT_MS = 30_000;

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
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), OPENAI_TIMEOUT_MS);
    let oaiRes: Response;
    try {
      oaiRes = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        signal: ctrl.signal,
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
          // `gpt-4o-mini` and other Chat Completions models accept `max_tokens`.
          // Reasoning models (o1/o3) use `max_completion_tokens` instead — if
          // you switch the model in OPENAI_MODEL, change this accordingly.
          max_tokens: 800,
        }),
      });
    } catch (err) {
      if ((err as Error).name === "AbortError") {
        return json({ error: "OpenAI request timed out" }, 504);
      }
      throw err;
    } finally {
      clearTimeout(timer);
    }

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

// Parses the strict 제목:/날짜:/카테고리:/내용: format produced by the
// editor role. Date is returned as the raw string (YYYY-MM-DD | MM-DD |
// 해당 없음 | 확인 필요) so the client can decide whether to auto-fill the
// memo date field. Falls back to category="other" if no marker is found
// (e.g. when the model returned the "입력이 부족합니다" single-line
// exception output) — in that case the whole text is carried in `content`
// so the UI can surface it.
function parseResponse(text: string): {
  title: string;
  date: string;
  category: string;
  content: string;
} {
  const lines = text.split(/\r?\n/);
  let title = "";
  let date = "";
  let category = "other";
  let content = "";
  let mode: "title" | "date" | "category" | "content" | null = null;
  let sawMarker = false;

  const categoryMap: Record<string, string> = {
    "메모": "memo",
    "영수증": "receipt",
    "명함": "business_card",
    "설명서": "manual",
    "기타": "other",
  };

  for (const raw of lines) {
    const line = raw.trimEnd();
    if (line.startsWith("제목:")) {
      title = line.slice(3).trim();
      mode = "title";
      sawMarker = true;
    } else if (line.startsWith("날짜:")) {
      date = line.slice(3).trim();
      mode = "date";
      sawMarker = true;
    } else if (line.startsWith("카테고리:")) {
      const v = line.slice(5).trim();
      category = categoryMap[v] ?? "other";
      mode = "category";
      sawMarker = true;
    } else if (line.startsWith("내용:")) {
      content = line.slice(3).trim();
      mode = "content";
      sawMarker = true;
    } else if (mode === "content" && line.trim()) {
      content += (content ? "\n" : "") + line.trim();
    }
  }

  if (!sawMarker) {
    return {
      title: "",
      date: "",
      category: "other",
      content: text.trim(),
    };
  }

  return {
    title: title.trim(),
    date: date.trim(),
    category,
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
