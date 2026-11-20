import { handleDocumentReader } from "./handler.ts";

const document = "Page 1\nApplication closes on 12 May.";
const envNames = ["SUPABASE_URL", "SUPABASE_ANON_KEY", "GEMINI_API_KEY"];

Deno.test("authenticates requests and only returns grounded question answers", async () => {
  const saved = envNames.map((name) => Deno.env.get(name));
  const originalFetch = globalThis.fetch;
  Deno.env.set("SUPABASE_URL", "https://supabase.example.test");
  Deno.env.set("SUPABASE_ANON_KEY", "test-anon");
  Deno.env.set("GEMINI_API_KEY", "test-secret");
  let providerCalls = 0;
  let output = "Application closes on 12 May.";
  globalThis.fetch = async (input, init) => {
    const url = new URL(String(input));
    if (url.hostname === "supabase.example.test") {
      return new Headers(init?.headers).get("Authorization") === "Bearer valid"
        ? Response.json({ id: "test-user" })
        : Response.json({}, { status: 401 });
    }
    if (url.hostname !== "generativelanguage.googleapis.com") {
      throw new Error("Unexpected upstream request");
    }
    providerCalls++;
    if (new Headers(init?.headers).get("x-goog-api-key") !== "test-secret") {
      throw new Error("Server credential missing");
    }
    return Response.json({
      candidates: [{
        finishReason: "STOP",
        content: { parts: [{ text: JSON.stringify({ text: output }) }] },
      }],
    });
  };

  const request = (token: string, action = "question", text = document) =>
    new Request("https://reader.example.test", {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
      body: JSON.stringify({
        document: text,
        language: "hi",
        action,
        question: "When does the application close?",
      }),
    });

  try {
    const denied = await handleDocumentReader(request("invalid"));
    if (denied.status !== 401 || providerCalls !== 0) {
      throw new Error("Unauthorized request reached Gemini");
    }

    const answered = await handleDocumentReader(request("valid"));
    if ((await answered.json()).text !== output) {
      throw new Error("Valid evidence was rejected");
    }

    output = "Application closes on 20 May.";
    const ungrounded = await handleDocumentReader(request("valid"));
    if ((await ungrounded.json()).notFound !== true) {
      throw new Error("Unsupported answer escaped verification");
    }

    output = "आवेदन 12 मई को बंद होता है।";
    const translation = await handleDocumentReader(
      request("valid", "translate"),
    );
    if ((await translation.json()).text !== output) {
      throw new Error("Translation was not returned");
    }
    output = "You can apply until 12 May.";
    const simplified = await handleDocumentReader(request("valid", "simplify"));
    if ((await simplified.json()).text !== output) {
      throw new Error("Simplified text was not returned");
    }

    const oversized = await handleDocumentReader(
      request("valid", "translate", "a".repeat(30001)),
    );
    if (oversized.status !== 413) {
      throw new Error("Size limit was not enforced");
    }
  } finally {
    globalThis.fetch = originalFetch;
    for (const [index, name] of envNames.entries()) {
      const value = saved[index];
      if (value === undefined) Deno.env.delete(name);
      else Deno.env.set(name, value);
    }
  }
});
