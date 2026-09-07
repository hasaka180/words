import SwiftUI

@main
struct EnglishWordsApp: App {
    @StateObject private var store = WordStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.reload() }
        }
    }
}
