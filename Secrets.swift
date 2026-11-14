import Foundation

/// Reads secrets from Info.plist / Secrets.plist. Never hardcode keys in source.
enum Secrets {
    private static let placeholder = "YOUR_API_KEY_HERE"

    static var anthropicAPIKey: String {
        plistValue("ANTHROPIC_API_KEY")
    }

    static var supabaseURL: URL? {
        var raw = plistValue("SUPABASE_URL")
        guard isUsable(raw) else { return nil }
        if raw.hasSuffix("/") { raw.removeLast() }
        if raw.hasSuffix("/rest/v1") {
            raw = String(raw.dropLast("/rest/v1".count))
        }
        return URL(string: raw)
    }

    static var supabaseAnonKey: String {
        plistValue("SUPABASE_ANON_KEY")
    }

    static var hasSupabaseConfig: Bool {
        supabaseURL != nil && isUsable(supabaseAnonKey)
    }

    private static func plistValue(_ key: String) -> String {
        if let fromFile = valueFromSecretsPlist(key), isUsable(fromFile) {
            return fromFile
        }
        return object(key) ?? ""
    }

    private static func object(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return isUsable(trimmed) ? trimmed : nil
    }

    private static func isUsable(_ raw: String) -> Bool {
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty
            && key != placeholder
            && !key.contains("YOUR_")
    }

    private static func valueFromSecretsPlist(_ key: String) -> String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dict = plist as? [String: Any],
              let value = dict[key] as? String
        else {
            return nil
        }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
