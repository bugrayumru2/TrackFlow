import Foundation

enum AppLanguage: String, CaseIterable, Sendable {
    case system, english = "en", turkish = "tr"

    nonisolated static var selected: Self {
        Self(rawValue: UserDefaults.standard.string(forKey: "trackflowLanguage") ?? "system") ?? .system
    }

    nonisolated var code: String {
        switch self {
        case .english: return "en"
        case .turkish: return "tr"
        case .system:
            let supported = Locale.preferredLanguages.first { $0.hasPrefix("tr") || $0.hasPrefix("en") }
            return supported?.hasPrefix("tr") == true ? "tr" : "en"
        }
    }

    nonisolated var displayName: String {
        switch self {
        case .system: return L10n.text("System default")
        case .english: return "English"
        case .turkish: return "Türkçe"
        }
    }
}

enum L10n {
    nonisolated private static let mainBundles: [String: Bundle] = {
        var bundles: [String: Bundle] = [:]
        for code in ["en", "tr"] {
            if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
               let bundle = Bundle(path: path) { bundles[code] = bundle }
        }
        return bundles
    }()

    nonisolated static var locale: Locale { Locale(identifier: AppLanguage.selected.code) }

    nonisolated static func text(_ key: String, language: AppLanguage? = nil, bundle: Bundle = .main) -> String {
        let code = (language ?? .selected).code
        let localized: Bundle?
        if bundle.bundleURL == Bundle.main.bundleURL {
            localized = mainBundles[code]
        } else {
            localized = bundle.path(forResource: code, ofType: "lproj").flatMap { Bundle(path: $0) }
        }
        guard let localized else { return key }
        let value = localized.localizedString(forKey: key, value: key, table: "Localizable")
        if value != key || code == "en" { return value }
        // Runtime details remain verbatim; localize only the app-owned prefix.
        for (prefix, format) in [
            ("Paused for ", "Paused for %@"),
            ("Could not change launch at login: ", "Could not change launch at login: %@")
        ] where key.hasPrefix(prefix) {
            let translated = localized.localizedString(forKey: format, value: format, table: "Localizable")
            return String(format: translated, locale: Locale(identifier: code), String(key.dropFirst(prefix.count)))
        }
        return value
    }

    nonisolated static func format(_ key: String, _ value: Int) -> String {
        String(format: text(key), locale: locale, value)
    }
}
