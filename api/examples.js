/* Example sentences from Tatoeba.
 *
 * Proxied rather than called from the page because Tatoeba sends no CORS
 * headers, so a browser cannot read it directly. No API key, no account and
 * no cost — this runs on Vercel's free tier.
 *
 * On a host without serverless functions (GitHub Pages) this simply isn't
 * there, and the page uses Wiktionary's examples instead. */

const WORD = /^[A-Za-z][A-Za-z '\-]{0,48}$/;

/* What Tatoeba's ordering gives on its own, and why neither is used alone:
 *   relevance  shortest first — "He's resilient.", which teaches nothing
 *   longest    whole paragraphs
 * Random ordering reaches the useful middle, and the "=" exact-form operator
 * stops its stemmer from answering "candid" with sentences about candidates.
 * Responses are CDN-cached for a week, so random is stable per word. */
const IDEAL_LENGTH = 60;
const MIN_WORDS = 4;
const MAX_WORDS = 25;
const MAX_CHARS = 140;

function search(query, sort) {
  const url = "https://tatoeba.org/en/api_v0/search?from=eng&sort=" + sort +
              "&query=" + encodeURIComponent(query);
  return fetch(url, {
    headers: { "User-Agent": "words-notebook (vocabulary app)" },
    signal: AbortSignal.timeout(6000),
  })
    .then((r) => (r.ok ? r.json() : { results: [] }))
    .then((d) => (d.results || []).filter((s) => s && s.lang === "eng" && typeof s.text === "string"))
    .catch(() => []);
}

export function usable(word) {
  // The word itself or a regular inflection of it — "meticulously" counts,
  // "candidate" does not.
  const esc = word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const held = new RegExp("\\b" + esc + "(s|es|d|ed|ing|ly|ness|er|est)?\\b", "i");
  const seen = new Set();
  return (text) => {
    const t = text.trim();
    const words = t.split(/\s+/).length;
    if (words < MIN_WORDS || words > MAX_WORDS || t.length > MAX_CHARS) return false;
    if (!held.test(t)) return false;
    const key = t.toLowerCase();
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  };
}

export default async function handler(req, res) {
  const word = String(req.query.word || "").trim();

  if (!WORD.test(word)) {
    return res.status(400).json({ error: "Give a single English word." });
  }

  try {
    const exact = "=" + word;
    let found = (await Promise.all([search(exact, "random"), search(exact, "relevance")])).flat();

    const keep = usable(word);
    let texts = found.map((s) => s.text.trim()).filter(keep);

    // Some words only appear inflected; widen to the stemmed search then.
    if (texts.length < 2) {
      const wider = await search(word, "random");
      texts = texts.concat(wider.map((s) => s.text.trim()).filter(keep));
    }

    const examples = texts
      .sort((a, b) => Math.abs(a.length - IDEAL_LENGTH) - Math.abs(b.length - IDEAL_LENGTH))
      .slice(0, 4);

    res.setHeader("Cache-Control", "public, s-maxage=604800, stale-while-revalidate=86400");
    return res.status(200).json({ word, examples });
  } catch (err) {
    return res.status(502).json({ error: "Example lookup failed." });
  }
}
