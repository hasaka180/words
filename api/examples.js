/* Example sentences from Tatoeba.
 *
 * Proxied rather than called from the page because Tatoeba sends no CORS
 * headers, so a browser cannot read it directly. No API key, no account and
 * no cost — this runs on Vercel's free tier.
 *
 * On a host without serverless functions (GitHub Pages) this simply isn't
 * there, and the page falls back to whatever examples dictionaryapi.dev
 * carried for the word. */

const WORD = /^[A-Za-z][A-Za-z '\-]{0,48}$/;

/* A learner wants a sentence with some context in it. Tatoeba's shortest hits
 * are things like "He's meticulous." — grammatical but useless — so aim for
 * sentences around this length and work outwards. */
const IDEAL_LENGTH = 60;

export default async function handler(req, res) {
  const word = String(req.query.word || "").trim();

  if (!WORD.test(word)) {
    return res.status(400).json({ error: "Give a single English word." });
  }

  const url = "https://tatoeba.org/en/api_v0/search?from=eng&sort=relevance&query=" +
    encodeURIComponent(word);

  try {
    const upstream = await fetch(url, {
      headers: { "User-Agent": "words-notebook (vocabulary app)" },
      signal: AbortSignal.timeout(8000),
    });

    if (!upstream.ok) {
      return res.status(502).json({ error: "Example lookup failed." });
    }

    const data = await upstream.json();

    // Only sentences that actually contain the word — a search for "candid"
    // otherwise matches "candidate".
    const held = new RegExp("\\b" + word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");

    const seen = new Set();
    const examples = (data.results || [])
      .filter((s) => s && s.lang === "eng" && typeof s.text === "string")
      .map((s) => s.text.trim())
      .filter((t) => {
        if (t.length < 18 || t.length > 140) return false;
        if (!held.test(t)) return false;
        const key = t.toLowerCase();
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      })
      .sort((a, b) => Math.abs(a.length - IDEAL_LENGTH) - Math.abs(b.length - IDEAL_LENGTH))
      .slice(0, 2);

    res.setHeader("Cache-Control", "public, s-maxage=604800, stale-while-revalidate=86400");
    return res.status(200).json({ word, examples });
  } catch (err) {
    return res.status(502).json({ error: "Example lookup failed." });
  }
}
