import WidgetKit
import SwiftUI

// MARK: - Timeline

struct WordEntry: TimelineEntry {
    let date: Date
    /// The words to show. Index 0 is the headline word; the large family uses
    /// the rest to fill the card.
    let words: [Word]
    /// Total number of saved words, for the footer count.
    let total: Int

    var primary: Word? { words.first }

    static let placeholder = WordEntry(
        date: Date(),
        words: SampleData.words,
        total: SampleData.words.count
    )

    /// Shown before the user has saved anything.
    static func empty(at date: Date = Date()) -> WordEntry {
        WordEntry(date: date, words: [], total: 0)
    }
}

struct WordProvider: TimelineProvider {

    /// How often the shown word changes.
    private static let rotation: TimeInterval = 20 * 60
    /// How far ahead each timeline is built (24 × 20 min = 8 hours).
    private static let entryCount = 24
    /// How many words a single entry carries (the large family shows 3).
    private static let wordsPerEntry = 3

    func placeholder(in context: Context) -> WordEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> Void) {
        let saved = WordStorage.load()
        if context.isPreview || saved.isEmpty {
            completion(.placeholder)
        } else {
            completion(WordEntry(date: Date(), words: window(of: saved, startingAt: 0), total: saved.count))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        let saved = WordStorage.load()

        guard !saved.isEmpty else {
            // Nothing saved yet: show the empty state and check back in an hour.
            completion(Timeline(entries: [.empty()], policy: .after(Date().addingTimeInterval(3600))))
            return
        }

        // Shuffle once per timeline so the order feels fresh on every refresh,
        // but stays stable while a single timeline plays out.
        let pool = saved.shuffled()
        let now = Date()

        var entries: [WordEntry] = []
        for step in 0..<Self.entryCount {
            let date = now.addingTimeInterval(Double(step) * Self.rotation)
            let start = (step * Self.wordsPerEntry) % pool.count
            entries.append(
                WordEntry(date: date, words: window(of: pool, startingAt: start), total: saved.count)
            )
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// Up to `wordsPerEntry` words starting at `start`, wrapping around.
    private func window(of pool: [Word], startingAt start: Int) -> [Word] {
        guard !pool.isEmpty else { return [] }
        let count = min(Self.wordsPerEntry, pool.count)
        return (0..<count).map { pool[(start + $0) % pool.count] }
    }
}

// MARK: - Views

struct WordWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WordEntry

    var body: some View {
        Group {
            if let word = entry.primary {
                layout(for: word)
                    // Tapping opens the app straight to this word.
                    .widgetURL(URL(string: "englishwords://word/\(word.id.uuidString)"))
            } else {
                EmptyStateView()
            }
        }
        .containerBackground(for: .widget) {
            if family == .accessoryRectangular || family == .accessoryInline {
                Color.clear
            } else {
                LinearGradient(
                    colors: [Color("WidgetBackground"), Color("WidgetBackground").opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    /// The right card for the current widget family.
    @ViewBuilder
    private func layout(for word: Word) -> some View {
        switch family {
        case .systemSmall:
            SmallWordView(word: word)
        case .systemLarge:
            LargeWordView(entry: entry)
        case .accessoryRectangular:
            RectangularWordView(word: word)
        case .accessoryInline:
            Text("\(word.english) — \(word.displaySinhala)")
        default:
            MediumWordView(word: word, total: entry.total)
        }
    }
}

private struct SmallWordView: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(word.english)
                .font(.headline)
                .minimumScaleFactor(0.7)
                .lineLimit(2)

            Text(word.displaySinhala)
                .font(.subheadline)
                .foregroundStyle(.tint)
                .minimumScaleFactor(0.7)
                .lineLimit(3)

            Spacer(minLength: 0)

            Text(word.displayDefinition)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MediumWordView: View {
    let word: Word
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(word.english)
                    .font(.title2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                if word.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }

            Text(word.displaySinhala)
                .font(.headline)
                .foregroundStyle(.tint)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(word.displayDefinition)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer(minLength: 0)

            Text("\(total) word\(total == 1 ? "" : "s") saved")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LargeWordView: View {
    let entry: WordEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Words")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(Array(entry.words.enumerated()), id: \.element.id) { index, word in
                if index > 0 { Divider().opacity(0.4) }
                VStack(alignment: .leading, spacing: 3) {
                    Text(word.english)
                        .font(.headline)
                        .lineLimit(1)
                    Text(word.displaySinhala)
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                        .lineLimit(1)
                    Text(word.displayDefinition)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            Text("\(entry.total) word\(entry.total == 1 ? "" : "s") saved")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RectangularWordView: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(word.english)
                .font(.headline)
                .lineLimit(1)
            Text(word.displaySinhala)
                .font(.caption)
                .lineLimit(1)
            Text(word.displayDefinition)
                .font(.caption2)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "character.book.closed")
                .font(.title2)
                .foregroundStyle(.tint)
            Text("No words yet")
                .font(.headline)
            Text("Open the app to add one.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Widget

struct WordWidget: Widget {
    let kind = "WordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordProvider()) { entry in
            WordWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Words")
        .description("Keeps showing your saved English words with their definitions and Sinhala meanings.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

#Preview(as: .systemMedium) {
    WordWidget()
} timeline: {
    WordEntry(date: .now, words: SampleData.words, total: SampleData.words.count)
}
