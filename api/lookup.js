import Anthropic from "@anthropic-ai/sdk";
import { z } from "zod";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";

/* Looks up one English word and returns a definition, a Sinhala meaning and
   two example sentences.

   This exists because the free options are not good enough for a learner:
   dictionaryapi.dev has solid definitions but an example for maybe a third of
   words, and the free en->si translation endpoints get common words plainly
   wrong (they rendered "candid" as "humble" and "honest" as "policy"). A wrong
   Sinhala meaning is worse than a blank field, so the app asks a model that
   actually knows the language.

   Needs ANTHROPIC_API_KEY in the environment. Without it this returns 503 and
   the page falls back to dictionaryapi.dev for the definition alone. */

const Lookup = z.object({
  found: z.boolean().describe("false if this is not a real English word"),
  definition: z.string().describe("One clear sentence a learner can understand. Empty if not found."),
  sinhala: z.string().describe("The meaning in Sinhala script. Empty if not found."),
  examples: z.array(z.string()).describe("Two natural example sentences using the word."),
});

const SYSTEM = `You help a Sinhala speaker build an English vocabulary notebook.

For the word you are given, return:
- definition: one clear sentence in plain English, the kind a learner can read. No dictionary abbreviations.
- sinhala: the meaning in Sinhala script. Give the word or short phrase a Sinhala speaker would actually use, not a transliteration. Where one English word has no single Sinhala equivalent, give the closest term, then a semicolon and a brief gloss.
- examples: exactly two natural sentences that use the word, each showing a different typical context. Keep them short and everyday.

If the input is not a real English word (a typo, or nonsense), set found to false and leave the other fields empty. Do not invent an entry.`;

const WORD = /^[A-Za-z][A-Za-z '\-]{0,48}$/;

export default async function handler(req, res) {
  const word = String(req.query.word || "").trim();

  if (!WORD.test(word)) {
    return res.status(400).json({ error: "Give a single English word." });
  }

  if (!process.env.ANTHROPIC_API_KEY) {
    return res.status(503).json({ error: "Lookup is not configured on this deployment." });
  }

  try {
    const client = new Anthropic();

    const response = await client.messages.parse({
      model: "claude-opus-5",
      max_tokens: 2000,
      system: SYSTEM,
      messages: [{ role: "user", content: word }],
      // A dictionary lookup is not hard reasoning; low effort keeps the
      // response fast enough to land while the user is still typing.
      output_config: {
        effort: "low",
        format: zodOutputFormat(Lookup),
      },
    });

    if (response.stop_reason === "refusal") {
      return res.status(422).json({ error: "That word could not be looked up." });
    }

    const out = response.parsed_output;
    if (!out || !out.found) {
      return res.status(404).json({ error: "No entry for that word." });
    }

    // Definitions don't change, so let the CDN answer repeats instead of
    // paying for the same word twice.
    res.setHeader("Cache-Control", "public, s-maxage=604800, stale-while-revalidate=86400");

    return res.status(200).json({
      word,
      definition: out.definition || "",
      sinhala: out.sinhala || "",
      examples: (out.examples || []).filter(Boolean).slice(0, 2),
    });
  } catch (err) {
    const status = err && err.status;
    if (status === 429) return res.status(429).json({ error: "Too many lookups just now — try again in a moment." });
    if (status === 401) return res.status(503).json({ error: "Lookup is not configured on this deployment." });
    console.error("lookup failed:", err && err.message);
    return res.status(502).json({ error: "Lookup failed." });
  }
}
