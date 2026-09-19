# My Words — English ↔ Sinhala vocabulary notebook

Save English words with their **definition** and **Sinhala meaning**, on a card
that keeps rotating through what you've saved.

Two versions live here, sharing the same five starter words:

| | Path | Home screen |
| --- | --- | --- |
| **iOS app** | `EnglishWords.xcodeproj` | A real WidgetKit widget — small, medium, large, and Lock Screen |
| **Web app** | [`docs/`](docs/) | Installable PWA — real icon, fullscreen, works offline |

The web version has no build step, no framework and no npm dependencies. It
needs no Apple Developer account and runs on any phone. The native version is
the only one that can draw a live widget tile on the Home Screen — that is not
something a web page is allowed to do.

---

# iOS app

A SwiftUI iPhone/iPad app plus a WidgetKit extension that rotates through your
saved words on the Home Screen and Lock Screen.

## Requirements

- Xcode 16 or newer
- iOS 17.0+ (uses `containerBackground`, `ContentUnavailableView`)

## Opening it

```
open EnglishWords.xcodeproj
```

Pick an iPhone simulator and press ⌘R. The app seeds five sample words on first
launch so the list and the widget are never blank.

## Before running on a real device

Three things need your own identifiers. All of them are in the project's build
settings — select the project in the navigator, then **Build Settings**.

| Setting | Where | Change to |
| --- | --- | --- |
| `APP_GROUP_ID` | Project level (both targets inherit it) | `group.<your-bundle-prefix>.EnglishWords` |
| `PRODUCT_BUNDLE_IDENTIFIER` | Target **EnglishWords** | `<your-bundle-prefix>.EnglishWords` |
| `PRODUCT_BUNDLE_IDENTIFIER` | Target **WordWidgetExtension** | `<your-bundle-prefix>.EnglishWords.WordWidget` |

The widget's bundle ID **must** stay prefixed by the app's bundle ID.

`APP_GROUP_ID` is defined once and referenced from four places — both
`Info.plist` files and both `.entitlements` files — so that is the only App
Group string to edit.

Then set your team under **Signing & Capabilities** for both targets.

> **Note on App Groups:** the Simulator runs this without any signing setup. On a
> physical device, App Groups is a paid Apple Developer Program capability — a
> free personal team cannot provision it. If the container is unavailable the app
> still works, but the widget shows an empty state and the list shows a warning
> banner.

## Adding the widget

Long-press the Home Screen → **Edit** → **Add Widget** → search **My Words**.
There's an in-app walkthrough behind the **?** button in the top-left.

Sizes:

| Family | Shows |
| --- | --- |
| Small | One word + Sinhala meaning + short definition |
| Medium | One word + meaning + definition + saved count |
| Large | Three words at a time |
| Lock Screen rectangular / inline | Compact one-line reminder |

Tapping the widget opens the app straight to that word via
`englishwords://word/<uuid>`.

## How the rotation works

`WordProvider` builds a timeline of 24 entries spaced 20 minutes apart — about
8 hours of rotation per refresh — from a per-timeline shuffle of your saved
words. Any add, edit, delete or favourite toggle calls
`WidgetCenter.shared.reloadAllTimelines()`, so the widget picks up changes
immediately rather than waiting for the next system refresh.

## Layout

```
Shared/                     compiled into BOTH targets
  AppGroup.swift            resolves the App Group id + shared file URL
  Word.swift                the model (tolerant Codable for schema changes)
  WordStorage.swift         load/save JSON + widget reload
  SampleData.swift          first-launch seed words
EnglishWords/               the app target
  EnglishWordsApp.swift     @main, reloads on foreground
  ContentView.swift         hosts the list, handles widget deep links
  WordListView.swift        search, favourites filter, swipe actions
  AddEditWordView.swift     add / edit / delete form
  WordDetailView.swift      full entry
  WidgetHelpView.swift      in-app widget setup guide + App Group diagnostics
  WordStore.swift           @MainActor ObservableObject over WordStorage
WordWidget/                 the widget extension target
  WordWidgetBundle.swift    @main WidgetBundle
  WordWidget.swift          TimelineProvider + all widget families
```

## Storage

Words are stored as a single JSON array at
`<App Group container>/words.json`. It's a small, human-readable file that both
processes read directly — no database, no migration story beyond
`Word.init(from:)`, which decodes every field with `decodeIfPresent` so older
saved files keep loading after you add new fields.

## Typing Sinhala

Add the Sinhala keyboard on the device: **Settings › General › Keyboard ›
Keyboards › Add New Keyboard › සිංහල**. The app renders Sinhala with the system
font, which covers the script on iOS.

---

# Web app

An installable PWA in [`docs/`](docs/) — no build, no framework, no npm.

```
docs/
  index.html            the whole app: markup, CSS, JS
  manifest.webmanifest  name, icons, standalone display
  sw.js                 service worker — offline app shell + font cache
  icons/                192 / 512 / maskable / apple-touch / favicon
```

## Publishing it

Everything inside `docs/` uses relative paths, so it works under any origin or
sub-path — it only has to *be* the served root.

**GitHub Pages** — Settings › Pages, *Source*: **Deploy from a branch**, branch
`main`, folder **`/docs`**. Live at `https://<user>.github.io/words/`.

**Vercel** — [`vercel.json`](vercel.json) sets `outputDirectory` to `docs`, so
importing the repo needs no dashboard changes. (If you instead set *Root
Directory* to `docs` in project settings, that works too — Vercel then reads
config from inside `docs/` and ignores the root file.) Without one of the two,
Vercel serves the repo root, which has no `index.html`, and every URL 404s.

To run it locally: `python3 -m http.server -d docs 8000`. Open it over `http://`
rather than `file://` — service workers need an origin, so offline support is
inactive on a `file://` page (everything else still works).

## What it does differently

Design follows the Sri Lankan school exercise book: feint blue rules, a red
margin line down the left, blue-black ink, Sinhala set in Noto Serif/Sans
Sinhala. The fallback stack names **Sinhala Sangam MN**, which iOS and macOS
already ship, so the script still renders correctly when Google Fonts can't
load.

Beyond the iOS feature set it adds **Study mode** — the meaning stays blurred
until you tap the card, and rotation pauses so you get thinking time.

Keyboard: `←` `→` move through the deck, `S` shuffles, `N` adds a word.

## Filling words in automatically

Type an English word in the editor and the definition, Sinhala meaning and up to
two example sentences are looked up. Suggested fields are tinted and must be
checked before saving; a suggestion never overwrites text typed by hand, and the
moment a suggested field is edited it stops being touched.

Free sources, **no API keys and no account**. Each field fills the moment its
own source answers, and every source has a 7-second deadline, so one slow
service never holds up the others:

| Field | Source | Fallback |
| --- | --- | --- |
| Sinhala | Google's Chrome-dictionary endpoint (`clients5.google.com`) | `translate.googleapis.com` |
| Explanation | [Datamuse](https://www.datamuse.com/api/) (Wiktionary senses, ~0.3s) | Wiktionary REST API |
| Examples | [Tatoeba](https://tatoeba.org) via [`api/examples.js`](api/examples.js) | Wiktionary's usage examples |

The status line under the word field says what was found and what to add by
hand.

### Words saved before lookup worked

When saved words are missing a Sinhala meaning, explanation or examples, a
banner above the list offers to **fill them in**. It looks each word up and
fills *empty fields only* — nothing typed by hand is replaced — then syncs.
Words are looked up one at a time with a short pause, so Google's endpoint
doesn't read the run as a flood; pressing the button again stops it. Each word
is marked as tried, so one that no source knows doesn't keep the banner up.

To replace text that's already there, open the word and use **Look up again**:
it overwrites the fields with fresh suggestions, and nothing changes until you
press Save.

### Picking the simplest explanation

Dictionaries list many senses. The app takes the first *everyday* one: a
leading grammar tag such as *(transitive)* is stripped and the sense kept, but
a register or subject tag — *(archaic)*, *(dated)*, *(psychology)* — marks a
specialised sense, which is skipped. Long definitions keep their core and their
short synonyms, so *grief* becomes "Emotional pain; sorrow; sadness." rather
than a 130-character sentence.

### Picking example sentences

Tatoeba ranks by relevance, which puts two-word stubs like "He's resilient."
first, and its longest-first order returns whole paragraphs. The proxy uses
random order to reach the useful middle, the `=word` exact-form operator so
*candid* doesn't return sentences about candidates, and keeps 4–25 word
sentences nearest 60 characters. Results are CDN-cached for a week, so each
word's examples are stable.

### The translation caveat

Both Google endpoints are undocumented and rate-limited by IP. In testing,
`translate.googleapis.com` started answering with an HTML "Sorry…" page after a
burst of requests and stayed blocked for days, while the `clients5` endpoint
kept answering. The app treats any non-JSON reply as a miss and falls through.
They're called from the browser, not the server, so each person's requests come
from their own address. Either can change without notice.

Single-word translation also can't know which sense you mean: *set* comes back
as කට්ටලය ("a set, a collection") even when the explanation picked is the verb.
Check suggestions before saving — that's why they're tinted.

### Why not the other free options

Sampled before settling on the above: MyMemory's en→si gave *candid → "humble"*,
*honest → "policy"*, *meticulous → "excellent"* and *resilient →* a phrase
closer to its opposite — four wrong out of five. Every public Lingva instance
returned HTTP 500. dictionaryapi.dev has good definitions but took ~20 seconds per
request when last tested, so it was dropped.

## Syncing across devices

Off by default. Open **Sync** in the footer and turn it on: the app generates a
16-character code, and any device that enters the same code shares the same
list. There is no account and no password — **the code is the key**, so anyone
holding it can read the words.

Every sync pulls the other side, merges, then pushes the result, so two devices
converge no matter which one changed. Per word the newer edit wins; deletions
carry a tombstone so a word deleted on one device is not handed back by the
other, and a word re-added *after* a deletion survives. Tombstones are dropped
after 30 days. Syncs run on load, ~1.5s after any change, and when the tab
regains focus.

### Setting it up

Needs a free [Upstash](https://upstash.com) Redis database — sign in with
GitHub, no card:

1. Create a Redis database (any region; pick the one nearest you).
2. Copy **`UPSTASH_REDIS_REST_URL`** and **`UPSTASH_REDIS_REST_TOKEN`** from its
   REST API section.
3. Add both in Vercel under *Settings › Environment Variables*, then redeploy.

Without them [`api/sync.js`](api/sync.js) answers 503 and the app stays
device-local — the Sync button reports it rather than failing silently. GitHub
Pages cannot run the function at all, so sync is Vercel-only; Export/Import
still works everywhere.

Stored rows expire after a year untouched, and one list is capped at 5,000 words
and 512 KB.

## Where the words live

`localStorage`, on the one device — nothing is sent anywhere, and there is no
account. Two consequences worth knowing:

- They do **not** sync between devices. Two phones are two notebooks.
- iOS evicts site data for websites left unused for 7 days. Adding the app to
  the Home Screen exempts it from that, which is the main reason to install it
  rather than keep a tab open.

**Export** writes a JSON file; **Import** reads one back, merging by word id
instead of replacing. The export uses the same field names as the Swift model,
so the two versions can exchange word lists.

## Ideas for next

- iCloud sync via `NSUbiquitousKeyValueStore` or CloudKit
- Spaced-repetition review mode with a "quiz me" widget
- Bulk import from CSV
- An `AppIntent`-configurable widget so a Home Screen widget can be pinned to
  favourites only
