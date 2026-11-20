import { verifiedExcerpt } from "./evidence.ts";

Deno.test("returns only a contiguous source excerpt", () => {
  const source = "Page 1\nApplication closes on\n12 May.\nApply online.";
  if (
    verifiedExcerpt(source, "Application closes on 12 May.") !==
      "Application closes on 12 May."
  ) {
    throw new Error("Expected a whitespace-normalized source excerpt");
  }
  for (
    const invalid of [
      "Application closes on 20 May.",
      "12 May. online.",
      "",
      null,
    ]
  ) {
    if (verifiedExcerpt(source, invalid) !== null) {
      throw new Error("Accepted unsupported evidence");
    }
  }
});
