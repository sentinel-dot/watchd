import SwiftUI

// @Environment(\.theme) var theme
// Views deklarieren ihre Theme-Abhängigkeit explizit. Der Theme-Wert
// wird am App-Root statisch via .environment(\.theme, .velvetHour) injected.

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .velvetHour
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
