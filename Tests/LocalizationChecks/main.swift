import Foundation

@main
struct LocalizationChecks {
    static func main() throws {
        let app = Bundle(path: CommandLine.arguments[1])!
        let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
        let keys = try JSONDecoder().decode([String].self, from: data)
        for key in keys {
            assert(L10n.text(key, language: .english, bundle: app) == key)
            assert(L10n.text(key, language: .turkish, bundle: app) != key, "Missing Turkish key: \(key)")
        }
        assert(L10n.text("Paused for Spotify", language: .turkish, bundle: app) == "Spotify için duraklatıldı")
        assert(L10n.text("Could not change launch at login: detail", language: .turkish, bundle: app) == "Otomatik başlatma değiştirilemedi: detail")
        assert(L10n.text("Untranslated song title", language: .turkish, bundle: app) == "Untranslated song title")
        assert(AppLanguage(rawValue: "tr")?.code == "tr")
        assert(AppLanguage(rawValue: "en")?.code == "en")
        print("English/Turkish resources: \(keys.count) keys, dynamic messages and verbatim content: passed.")
    }
}
