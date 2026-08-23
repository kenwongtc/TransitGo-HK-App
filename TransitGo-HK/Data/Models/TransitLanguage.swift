import SwiftUI

enum TransitLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case traditionalChinese = "繁體中文"
    case simplifiedChinese = "简体中文"

    var id: String { rawValue }

    var displayName: String { rawValue }

    init(preferenceValue: String) {
        self = Self(rawValue: preferenceValue) ?? .english
    }
}

private struct TransitLanguageKey: EnvironmentKey {
    static let defaultValue = TransitLanguage.english
}

extension EnvironmentValues {
    var transitLanguage: TransitLanguage {
        get { self[TransitLanguageKey.self] }
        set { self[TransitLanguageKey.self] = newValue }
    }
}
