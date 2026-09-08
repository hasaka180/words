/* Cross-device sync through a shared code.
 *
 * There are no accounts: the code IS the key. Two devices holding the same
 * code read and write the same list. That also means anyone holding the code
 * can read the words, which is why the app generates a long random code rather
 * than letting people choose a memorable one.
 *
 * Storage is Upstash Redis over its REST API — free tier, no card. Set
 * UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN in the Vercel project.
 * Without them this answers 503 and the app carries on device-local. */

const CODE = /^[a-z0-9]{16}$/;
const MAX_BYTES = 512 * 1024;
const TTL_SECONDS = 60 * 60 * 24 * 365;   // a year untouched means an abandoned code
const EMPTY = { words: [], deleted: {}, updatedAt: 0 };

function store() {
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) return null;
  return { url: url.replace(/\/+$/, ""), token };
}

export default async function handler(req, res) {
  const s = store();
  if (!s) {
    return res.status(503).json({ error: "Sync is not configured on this deployment." });
  }

  const code = String(req.query.code || "").toLowerCase();
  if (!CODE.test(code)) {
    return res.status(400).json({ error: "Bad sync code." });
  }

  const key = "words:" + code;
  const headers = { Authorization: "Bearer " + s.token };
  res.setHeader("Cache-Control", "no-store");

  try {
    if (req.method === "GET") {
      const r = await fetch(s.url + "/get/" + key, {
        headers,
        signal: AbortSignal.timeout(8000),
      });
      if (!r.ok) throw new Error("upstream " + r.status);

      const body = await r.json();
      if (body.error) throw new Error(body.error);
      if (!body.result) return res.status(200).json(EMPTY);

      let doc;
      try {
        doc = JSON.parse(body.result);
      } catch (e) {
        return res.status(200).json(EMPTY);   // corrupt row: start clean
      }
      return res.status(200).json({
        words: Array.isArray(doc.words) ? doc.words : [],
        deleted: doc.deleted && typeof doc.deleted === "object" ? doc.deleted : {},
        updatedAt: doc.updatedAt || 0,
      });
    }

    if (req.method === "POST") {
      const doc = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
      if (!doc || !Array.isArray(doc.words)) {
        return res.status(400).json({ error: "Expected a word list." });
      }

      const payload = JSON.stringify({
        words: doc.words.slice(0, 5000),
        deleted: doc.deleted && typeof doc.deleted === "object" ? doc.deleted : {},
        updatedAt: Date.now(),
      });

      if (payload.length > MAX_BYTES) {
        return res.status(413).json({ error: "Too many words to sync." });
      }

      const r = await fetch(s.url + "/set/" + key + "?EX=" + TTL_SECONDS, {
        method: "POST",
        headers,
        body: payload,
        signal: AbortSignal.timeout(8000),
      });
      if (!r.ok) throw new Error("upstream " + r.status);

      const body = await r.json();
      if (body.error) throw new Error(body.error);

      return res.status(200).json({ ok: true, updatedAt: Date.now() });
    }

    res.setHeader("Allow", "GET, POST");
    return res.status(405).json({ error: "Use GET or POST." });
  } catch (err) {
    return res.status(502).json({ error: "Sync store unreachable." });
  }
}
