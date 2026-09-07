import SwiftUI

struct WordListView: View {
    @EnvironmentObject private var store: WordStore

    @State private var search = ""
    @State private var favoritesOnly = false
    @State private var isAdding = false
    @State private var showingWidgetHelp = false

    private var visible: [Word] {
        store.filtered(search: search, favoritesOnly: favoritesOnly)
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.words.isEmpty {
                    emptyLibrary
                } else if visible.isEmpty {
                    ContentUnavailableView.search(text: search)
                } else {
                    list
                }
            }
            .navigationTitle("My Words")
            .searchable(text: $search, prompt: "Search English, Sinhala or definition")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingWidgetHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("How to add the widget")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        favoritesOnly.toggle()
                    } label: {
                        Image(systemName: favoritesOnly ? "star.fill" : "star")
                    }
                    .accessibilityLabel(favoritesOnly ? "Showing favourites only" : "Show favourites only")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAdding = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add word")
                }
            }
            .sheet(isPresented: $isAdding) {
                AddEditWordView(mode: .add)
            }
            .sheet(isPresented: $showingWidgetHelp) {
                WidgetHelpView()
            }
        }
    }

    private var list: some View {
        List {
            if !store.sharedContainerAvailable {
                Section {
                    Label(
                        "The App Group isn't set up, so the widget can't read your words. See Help for the fix.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.orange)
                }
            }

            Section {
                ForEach(visible) { word in
                    NavigationLink(value: word) {
                        WordRow(word: word)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            store.toggleFavorite(word)
                        } label: {
                            Label("Favourite", systemImage: word.isFavorite ? "star.slash" : "star")
                        }
                        .tint(.yellow)
                    }
                }
                .onDelete { offsets in
                    store.delete(at: offsets, in: visible)
                }
            } footer: {
                Text("\(store.words.count) word\(store.words.count == 1 ? "" : "s") saved")
            }
        }
        .navigationDestination(for: Word.self) { word in
            WordDetailView(word: word)
        }
    }

    private var emptyLibrary: some View {
        ContentUnavailableView {
            Label("No words yet", systemImage: "character.book.closed")
        } description: {
            Text("Add an English word with its definition and Sinhala meaning. Your widget will start showing them right away.")
        } actions: {
            Button("Add your first word") { isAdding = true }
                .buttonStyle(.borderedProminent)
        }
    }
}

/// One row in the list: English on top, Sinhala beneath, definition as context.
struct WordRow: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(word.english)
                    .font(.headline)
                if word.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
            }
            if !word.sinhala.isEmpty {
                Text(word.sinhala)
                    .font(.subheadline)
                    .foregroundStyle(.tint)
            }
            if !word.definition.isEmpty {
                Text(word.definition)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    WordListView().environmentObject(WordStore(seedIfEmpty: false))
}
