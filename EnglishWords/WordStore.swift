import Foundation
import SwiftUI

/// The app-side observable wrapper around `WordStorage`.
/// Every mutation persists to the App Group container and refreshes the widget.
@MainActor
final class WordStore: ObservableObject {

    @Published private(set) var words: [Word] = []

    /// Set when the App Group container is unreachable, so the UI can warn that
    /// the widget will not update.
    let sharedContainerAvailable: Bool

    init(seedIfEmpty: Bool = true) {
        sharedContainerAvailable = AppGroup.isSharedContainerAvailable
        var loaded = WordStorage.load()
        if loaded.isEmpty && seedIfEmpty && !UserDefaults.standard.bool(forKey: Self.seededKey) {
            loaded = SampleData.words
            UserDefaults.standard.set(true, forKey: Self.seededKey)
            WordStorage.save(loaded)
            WordStorage.reloadWidgets()
        }
        words = Self.sorted(loaded)
    }

    private static let seededKey = "com.englishwords.didSeedSamples"

    private static func sorted(_ words: [Word]) -> [Word] {
        words.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Reading

    func word(with id: UUID) -> Word? {
        words.first { $0.id == id }
    }

    /// Filtered + sorted view used by the list screen.
    func filtered(search: String, favoritesOnly: Bool) -> [Word] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return words.filter { word in
            if favoritesOnly && !word.isFavorite { return false }
            guard !query.isEmpty else { return true }
            return word.english.lowercased().contains(query)
                || word.definition.lowercased().contains(query)
                || word.sinhala.lowercased().contains(query)
                || word.example.lowercased().contains(query)
        }
    }

    // MARK: - Writing

    func add(_ word: Word) {
        words.insert(word, at: 0)
        persist()
    }

    func update(_ word: Word) {
        guard let index = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[index] = word
        words = Self.sorted(words)
        persist()
    }

    func delete(_ word: Word) {
        words.removeAll { $0.id == word.id }
        persist()
    }

    func delete(at offsets: IndexSet, in visible: [Word]) {
        let ids = offsets.map { visible[$0].id }
        words.removeAll { ids.contains($0.id) }
        persist()
    }

    func toggleFavorite(_ word: Word) {
        guard let index = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[index].isFavorite.toggle()
        persist()
    }

    /// Re-read from disk — used when returning from the background in case the
    /// list changed elsewhere.
    func reload() {
        words = Self.sorted(WordStorage.load())
    }

    private func persist() {
        WordStorage.save(words)
        WordStorage.reloadWidgets()
    }
}
