import SwiftUI

/// In-app instructions for putting the widget on the Home Screen.
struct WidgetHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Add the widget") {
                    step(1, "Go to the Home Screen and touch and hold an empty area until the icons jiggle.")
                    step(2, "Tap the **Edit** button in the top-left, then **Add Widget**.")
                    step(3, "Search for **My Words** and pick a size.")
                    step(4, "Tap **Add Widget**, then **Done**.")
                }

                Section("Sizes") {
                    bullet("Small", "One word with its Sinhala meaning.")
                    bullet("Medium", "One word with meaning and definition.")
                    bullet("Large", "Three words at a time.")
                    bullet("Lock Screen", "A compact one-line reminder.")
                }

                Section {
                    Text("The widget rotates through your saved words roughly every 20 minutes, and refreshes as soon as you add or edit a word. Tapping it opens that word here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("If the widget stays empty") {
                    Text("The app and the widget share data through an App Group. In Xcode, both targets need the **same** App Group identifier — it is set once in the project's `APP_GROUP_ID` build setting. On a real device this capability requires a paid Apple Developer account; the Simulator works without one.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    LabeledContent("App Group", value: AppGroup.identifier)
                        .font(.footnote)
                    LabeledContent(
                        "Status",
                        value: AppGroup.isSharedContainerAvailable ? "Connected" : "Not available"
                    )
                    .font(.footnote)
                    .foregroundStyle(AppGroup.isSharedContainerAvailable ? .green : .orange)
                }
            }
            .navigationTitle("Home Screen Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .background(.tint, in: Circle())
                .foregroundStyle(.white)
            Text(.init(text))
                .font(.subheadline)
        }
    }

    private func bullet(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WidgetHelpView()
}
