import SwiftUI

// MARK: - Netflix-style Design System

enum WatchdTheme {
    // Backgrounds – Netflix dark
    static let background = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let backgroundElevated = Color(red: 0.14, green: 0.14, blue: 0.14)
    static let backgroundCard = Color(red: 0.18, green: 0.18, blue: 0.18)
    static let backgroundInput = Color(red: 0.22, green: 0.22, blue: 0.22)
    
    // Netflix Red
    static let primary = Color(red: 0.898, green: 0.035, blue: 0.078)  // #E50914
    static let primaryGradientEnd = Color(red: 0.75, green: 0.02, blue: 0.06)
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.72, green: 0.72, blue: 0.72)
    static let textTertiary = Color(red: 0.55, green: 0.55, blue: 0.55)
    static let textOnPrimary = Color.white
    
    // UI
    static let separator = Color(red: 0.28, green: 0.28, blue: 0.28)
    static let overlayDark = Color.black.opacity(0.75)
    static let overlayLight = Color.white.opacity(0.1)
    
    // Semantic
    static let success = Color(red: 0.22, green: 0.78, blue: 0.35)
    static let error = primary
    static let rating = Color(red: 0.95, green: 0.77, blue: 0.20)
    
    // Gradients
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [background, background.opacity(0.98)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var heroBottomGradient: LinearGradient {
        LinearGradient(
            colors: [
                .clear,
                Color.black.opacity(0.45),
                Color.black.opacity(0.7),
                Color.black.opacity(0.9),
                background
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryGradientEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Typography – Netflix-style weights
    /// Logo-Titel (z. B. „WATCHD“) – wirkt großgeschrieben
    static func logoTitle() -> Font { .system(size: 20, weight: .heavy, design: .rounded) }
    static func titleLarge() -> Font { .system(size: 28, weight: .bold) }
    static func titleMedium() -> Font { .system(size: 22, weight: .semibold) }
    static func titleSmall() -> Font { .system(size: 18, weight: .semibold) }
    static func body() -> Font { .system(size: 15, weight: .regular) }
    static func bodyMedium() -> Font { .system(size: 15, weight: .medium) }
    static func caption() -> Font { .system(size: 13, weight: .regular) }
    static func captionMedium() -> Font { .system(size: 12, weight: .medium) }
    static func labelUppercase() -> Font { .system(size: 11, weight: .semibold) }
}
