import Foundation

/// Single source of truth for where the app and the widget share data.
///
/// The identifier lives in one place — the `APP_GROUP_ID` build setting on the
/// project — and is injected into both `Info.plist` files and both
/// `.entitlements` files, so there is only one string to change.
enum AppGroup {

    /// Used when the Info.plist lookup fails (e.g. an old build, or a preview).
    static let fallbackIdentifier = "group.com.yourname.EnglishWords"

    static let identifier: String = {
        let value = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
        if let value, !value.isEmpty, !value.hasPrefix("$(") {
            return value
        }
        return fallbackIdentifier
    }()

    /// True when the App Group container is actually available. If this is
    /// false the app still works, but the widget cannot see the words.
    static var isSharedContainerAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil
    }

    /// The shared container, falling back to the process's own Documents
    /// directory so nothing crashes if the App Group is misconfigured.
    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var storeURL: URL {
        containerURL.appendingPathComponent("words.json")
    }
}
