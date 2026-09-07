import SwiftUI

struct WordDetailView: View {
    let word: Word

    @EnvironmentObject private var store: WordStore
    @State private var isEditing = false

    /// Always render the freshest copy, so edits show up immediately.
    private var current: Word {
        store.word(with: word.id) ?? word
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(current.english)
                        .font(.largeTitle.bold())
                    if !current.sinhala.isEmpty {
                        Text(current.sinhala)
                            .font(.title2)
                            .foregroundStyle(.tint)
                    }
                }

                if !current.definition.isEmpty {
                    section("Definition", current.definition)
                }

                if !current.example.isEmpty {
                    section("Example", current.example, italic: true)
                }

                Text("Added \(current.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(current.english)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleFavorite(current)
                } label: {
                    Image(systemName: current.isFavorite ? "star.fill" : "star")
                }
                .accessibilityLabel(current.isFavorite ? "Remove from favourites" : "Add to favourites")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) {
            AddEditWordView(mode: .edit(current))
        }
    }

    private func section(_ title: String, _ body: String, italic: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(body)
                .font(.body)
                .italic(italic)
        }
    }
}

#Preview {
    NavigationStack {
        WordDetailView(word: SampleData.words[0])
            .environmentObject(WordStore(seedIfEmpty: false))
    }
}
