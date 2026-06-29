import Foundation

enum LocalStore {
    private static let legacySnapshotKey = "feiyu.local.snapshot"

    static var hasSavedData: Bool {
        legacySnapshotKeyHasData || AuthStore.currentSessionEmail != nil
    }

    private static var legacySnapshotKeyHasData: Bool {
        UserDefaults.standard.data(forKey: legacySnapshotKey) != nil
    }

    static func snapshotKey(for email: String) -> String {
        "feiyu.local.snapshot.\(AuthStore.normalizeEmail(email))"
    }

    static func load(for email: String) -> AppSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: snapshotKey(for: email)) else { return nil }
        return try? JSONDecoder().decode(AppSnapshot.self, from: data)
    }

    static func save(_ snapshot: AppSnapshot, for email: String) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: snapshotKey(for: email))
    }

    static func loadLegacy() -> AppSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: legacySnapshotKey) else { return nil }
        return try? JSONDecoder().decode(AppSnapshot.self, from: data)
    }

    static func clearLegacy() {
        UserDefaults.standard.removeObject(forKey: legacySnapshotKey)
    }

    static func clear(for email: String) {
        UserDefaults.standard.removeObject(forKey: snapshotKey(for: email))
    }

    @available(*, deprecated, message: "Use clear(for:) or clearLegacy()")
    static func clear() {
        UserDefaults.standard.removeObject(forKey: legacySnapshotKey)
        if let email = AuthStore.currentSessionEmail {
            clear(for: email)
        }
    }

    static func makeFirstLaunchAlias() -> String {
        MockData.aliasPool.randomElement() ?? "飞语旅人"
    }
}
