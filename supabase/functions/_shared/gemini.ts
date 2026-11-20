const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
};
const MAX_BODY = 128 * 1024;

export function json(body: Record<string, unknown>, status = 200) {
  return Response.json(body, {
    status,
    headers: { ...cors, "Cache-Control": "no-store" },
  });
}

async function limitedJson(request: Request): Promise<unknown> {
  const reader = request.body?.getReader();
  if (!reader) throw new SyntaxError();
  let size = 0;
  let body = "";
  const decoder = new TextDecoder("utf-8", { fatal: true });
  while (true) {
    const { done, value } = await reader.read();
    if (done) return JSON.parse(body + decoder.decode());
    size += value.byteLength;
    if (size > MAX_BODY) {
      await reader.cancel();
      throw new RangeError();
    }
    body += decoder.decode(value, { stream: true });
  }
}

type Payload = Record<string, unknown>;
type Generate = (payload: Payload) => Promise<string | null>;

class GeminiError extends Error {
  constructor(readonly status: number) {
    super("Gemini request failed");
  }
}

export function geminiEndpoint(
  handle: (payload: Payload, generate: Generate) => Promise<Response>,
) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: cors });
    }
    if (request.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405);
    }
    const authorization = request.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) {
      return json({ error: "unauthorized" }, 401);
    }
    const url = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const key = Deno.env.get("GEMINI_API_KEY");
    const model = Deno.env.get("GEMINI_MODEL") || "gemini-2.5-flash-lite";
    if (!url || !anonKey || !key || !/^[a-zA-Z0-9._-]+$/.test(model)) {
      return json({ error: "not_configured" }, 503);
    }

    try {
      const user = await fetch(`${url}/auth/v1/user`, {
        headers: { apikey: anonKey, Authorization: authorization },
        signal: AbortSignal.timeout(8000),
      });
      if (!user.ok) {
        return json(
          { error: "session_invalid" },
          user.status >= 500 ? 503 : 401,
        );
      }
      const identity = await user.json();
      if (typeof identity.id !== "string" || identity.is_anonymous === true) {
        return json({ error: "unauthorized" }, 401);
      }
    } catch {
      return json({ error: "auth_unavailable" }, 503);
    }

    let payload: unknown;
    try {
      payload = await limitedJson(request);
    } catch (error) {
      return json(
        { error: "invalid_request" },
        error instanceof RangeError ? 413 : 400,
      );
    }
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
      return json({ error: "invalid_request" }, 400);
    }

    try {
      return await handle(payload as Payload, async (body) => {
        const response = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "x-goog-api-key": key,
            },
            body: JSON.stringify(body),
            signal: AbortSignal.timeout(45000),
          },
        );
        if (!response.ok) {
          throw new GeminiError(response.status === 429 ? 429 : 502);
        }
        const generated = await response.json();
        const candidate = generated.candidates?.[0];
        if (candidate?.finishReason !== "STOP") return null;
        return candidate.content?.parts
          ?.filter((part: { thought?: boolean }) => !part.thought)
          .map((part: { text?: string }) => part.text ?? "").join("") ?? null;
      });
    } catch (error) {
      return json(
        { error: "provider_unavailable" },
        error instanceof GeminiError ? error.status : 502,
      );
    }
  };
}
