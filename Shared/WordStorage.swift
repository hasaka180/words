import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Plain, process-agnostic read/write of the shared word list.
/// The widget extension uses this directly; the app goes through `WordStore`.
enum WordStorage {

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func load() -> [Word] {
        guard let data = try? Data(contentsOf: AppGroup.storeURL) else { return [] }
        return (try? decoder.decode([Word].self, from: data)) ?? []
    }

    @discardableResult
    static func save(_ words: [Word]) -> Bool {
        guard let data = try? encoder.encode(words) else { return false }
        do {
            try data.write(to: AppGroup.storeURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// Tell every installed widget to rebuild its timeline.
    static func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
