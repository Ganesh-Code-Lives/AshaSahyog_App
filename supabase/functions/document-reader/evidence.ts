const normalize = (text: string) => text.replace(/\s+/gu, " ").trim();

// Return only text that occurs contiguously in the supplied document.
export function verifiedExcerpt(
  document: string,
  excerpt: unknown,
): string | null {
  if (typeof excerpt !== "string") return null;
  const text = normalize(excerpt);
  if (!text || text.length > 1200) return null;
  const source = normalize(document);
  const index = source.indexOf(text);
  return index === -1 ? null : source.slice(index, index + text.length);
}
