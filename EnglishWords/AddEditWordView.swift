import SwiftUI

struct AddEditWordView: View {
    enum Mode: Equatable {
        case add
        case edit(Word)
    }

    let mode: Mode

    @EnvironmentObject private var store: WordStore
    @Environment(\.dismiss) private var dismiss

    @State private var english = ""
    @State private var sinhala = ""
    @State private var definition = ""
    @State private var example = ""
    @State private var isFavorite = false

    @FocusState private var englishFocused: Bool

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("English word") {
                    TextField("e.g. Resilient", text: $english)
                        .focused($englishFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.title3.weight(.semibold))
                }

                Section {
                    TextField("සිංහල අර්ථය", text: $sinhala, axis: .vertical)
                        .lineLimit(1...4)
                } header: {
                    Text("Sinhala meaning")
                } footer: {
                    Text("Tip: add the Sinhala keyboard in Settings › General › Keyboard to type here.")
                }

                Section("Definition") {
                    TextField("What does it mean in English?", text: $definition, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section("Example sentence (optional)") {
                    TextField("Use it in a sentence", text: $example, axis: .vertical)
                        .lineLimit(1...5)
                }

                Section {
                    Toggle(isOn: $isFavorite) {
                        Label("Favourite", systemImage: "star")
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if case .edit(let word) = mode {
                                store.delete(word)
                            }
                            dismiss()
                        } label: {
                            Label("Delete word", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Word" : "New Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        if case .edit(let word) = mode {
            english = word.english
            sinhala = word.sinhala
            definition = word.definition
            example = word.example
            isFavorite = word.isFavorite
        } else {
            englishFocused = true
        }
    }

    private func save() {
        func clean(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        switch mode {
        case .add:
            store.add(
                Word(
                    english: clean(english),
                    definition: clean(definition),
                    sinhala: clean(sinhala),
                    example: clean(example),
                    isFavorite: isFavorite
                )
            )
        case .edit(let original):
            var updated = original
            updated.english = clean(english)
            updated.definition = clean(definition)
            updated.sinhala = clean(sinhala)
            updated.example = clean(example)
            updated.isFavorite = isFavorite
            store.update(updated)
        }
        dismiss()
    }
}

#Preview {
    AddEditWordView(mode: .add).environmentObject(WordStore(seedIfEmpty: false))
}
