import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: WordStore

    /// Set when the app is opened by tapping the widget.
    @State private var deepLinkedWord: Word?

    var body: some View {
        WordListView()
            .onOpenURL { url in
                if let word = Self.word(for: url, in: store) {
                    deepLinkedWord = word
                }
            }
            .sheet(item: $deepLinkedWord) { word in
                NavigationStack {
                    WordDetailView(word: word)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Done") { deepLinkedWord = nil }
                            }
                        }
                }
            }
    }

    /// Parses `englishwords://word/<uuid>` as sent by the widget.
    private static func word(for url: URL, in store: WordStore) -> Word? {
        guard url.scheme == "englishwords", url.host == "word" else { return nil }
        let idString = url.lastPathComponent
        guard let id = UUID(uuidString: idString) else { return nil }
        return store.word(with: id)
    }
}

#Preview {
    ContentView().environmentObject(WordStore(seedIfEmpty: false))
}
