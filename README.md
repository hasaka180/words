# My Words — English ↔ Sinhala vocabulary notebook

Save English words with their **definition** and **Sinhala meaning**, on a card
that keeps rotating through what you've saved.

Two versions live here, sharing the same five starter words:

| | Path | Home screen |
| --- | --- | --- |
| **iOS app** | `EnglishWords.xcodeproj` | A real WidgetKit widget — small, medium, large, and Lock Screen |
| **Web app** | [`web/index.html`](web/index.html) | Add to Home Screen: its own icon, opens straight to a word |

The web version is a single file with no build step and no dependencies beyond
Google Fonts. It needs no Apple Developer account and runs on any phone. The
native version is the only one that can draw a live widget tile on the Home
Screen — that is not something a web page is allowed to do.

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

Open `web/index.html` — no build, no server, no install. It stores words in the
Claude Artifacts document store when running as a published artifact, and falls
back to `localStorage` anywhere else, so it works opened as a plain file too.

Design follows the Sri Lankan school exercise book: feint blue rules, a red
margin line down the left, blue-black ink, Sinhala set in Noto Serif/Sans
Sinhala so the script renders properly instead of falling back to tofu.

Beyond the iOS feature set it adds **Study mode** — the meaning stays blurred
until you tap the card, and rotation pauses so you get thinking time.

Keyboard: `←` `→` move through the deck, `S` shuffles, `N` adds a word.

## Ideas for next

- iCloud sync via `NSUbiquitousKeyValueStore` or CloudKit
- Spaced-repetition review mode with a "quiz me" widget
- Bulk import from CSV
- An `AppIntent`-configurable widget so a Home Screen widget can be pinned to
  favourites only
