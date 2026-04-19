import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const ANTHROPIC_ENDPOINT = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";
const RATE_LIMIT = 30; // max requests per user per hour
const MAX_TOKENS_CAP = 8192;
const ALLOWED_MODELS = ["claude-haiku-4-5-20251001"];

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function errorResponse(status: number, message: string): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json" },
  });
}

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return errorResponse(405, "Method not allowed");
  }

  // ---------- authenticate via Supabase JWT ----------
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return errorResponse(401, "Missing or invalid Authorization header");
  }

  const jwt = authHeader.substring(7);

  // User-context client: verifies the JWT and gives us auth.getUser()
  const supabaseUser = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const {
    data: { user },
    error: authError,
  } = await supabaseUser.auth.getUser(jwt);

  if (authError || !user) {
    return errorResponse(401, "Invalid or expired token");
  }

  const userId = user.id;

  // ---------- service-role client for DB writes ----------
  const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // ---------- rate limiting: 30 req / hour ----------
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();

  const { count, error: countError } = await supabaseAdmin
    .from("ai_usage_logs")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .gte("created_at", oneHourAgo);

  if (countError) {
    console.error("Rate limit check failed:", countError.message);
    return errorResponse(500, "Rate limit check failed");
  }

  if ((count ?? 0) >= RATE_LIMIT) {
    return errorResponse(
      429,
      `Rate limit exceeded. Maximum ${RATE_LIMIT} AI requests per hour.`
    );
  }

  // ---------- parse request body ----------
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return errorResponse(400, "Invalid JSON body");
  }

  const {
    model,
    messages,
    system,
    max_tokens,
    temperature,
    stream,
  } = body as {
    model?: string;
    messages?: unknown[];
    system?: string;
    max_tokens?: number;
    temperature?: number;
    stream?: boolean;
  };

  if (!messages || !Array.isArray(messages) || messages.length === 0) {
    return errorResponse(400, "messages array is required");
  }

  // ---------- model whitelist ----------
  const resolvedModel = model ?? "claude-haiku-4-5-20251001";
  if (!ALLOWED_MODELS.includes(resolvedModel)) {
    return errorResponse(400, `Model not allowed: ${resolvedModel}`);
  }

  // ---------- build Anthropic request ----------
  const clampedMaxTokens = Math.min(max_tokens ?? 1024, MAX_TOKENS_CAP);

  const anthropicBody: Record<string, unknown> = {
    model: resolvedModel,
    max_tokens: clampedMaxTokens,
    messages,
  };

  if (system) anthropicBody.system = system;
  if (temperature !== undefined) anthropicBody.temperature = temperature;
  if (stream) anthropicBody.stream = true;

  // ---------- forward to Anthropic ----------
  const anthropicResponse = await fetch(ANTHROPIC_ENDPOINT, {
    method: "POST",
    headers: {
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": ANTHROPIC_VERSION,
      "content-type": "application/json",
    },
    body: JSON.stringify(anthropicBody),
  });

  // ---------- log usage (non-blocking) ----------
  // For streaming, we log before reading the stream; token counts updated later if needed.
  let tokensIn: number | null = null;
  let tokensOut: number | null = null;

  if (!stream && anthropicResponse.ok) {
    // Clone so we can read body twice (once for logging, once for client)
    const cloned = anthropicResponse.clone();
    const responseData = await cloned.json();

    tokensIn = responseData?.usage?.input_tokens ?? null;
    tokensOut = responseData?.usage?.output_tokens ?? null;

    // Log asynchronously — don't block the response
    supabaseAdmin
      .from("ai_usage_logs")
      .insert({
        user_id: userId,
        endpoint: "/ai-proxy",
        model: resolvedModel,
        tokens_in: tokensIn,
        tokens_out: tokensOut,
      })
      .then(({ error }) => {
        if (error) console.error("Failed to log AI usage:", error.message);
      });

    // Return Anthropic's response transparently
    return new Response(JSON.stringify(responseData), {
      status: anthropicResponse.status,
      headers: {
        ...corsHeaders,
        "content-type": "application/json",
      },
    });
  }

  // For streaming or error responses: log what we can, pass through
  supabaseAdmin
    .from("ai_usage_logs")
    .insert({
      user_id: userId,
      endpoint: "/ai-proxy",
      model: resolvedModel,
      tokens_in: null,
      tokens_out: null,
    })
    .then(({ error }) => {
      if (error) console.error("Failed to log AI usage:", error.message);
    });

  // Pass through the response (including SSE streams) as-is
  return new Response(anthropicResponse.body, {
    status: anthropicResponse.status,
    headers: {
      ...corsHeaders,
      "content-type":
        anthropicResponse.headers.get("content-type") ?? "application/json",
    },
  });
});
