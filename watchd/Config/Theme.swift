import SwiftUI

// MARK: - Theme

struct Theme: Equatable {
    let colors: ThemeColors
    let fonts: ThemeFonts
    let spacing: ThemeSpacing
    let motion: ThemeMotion

    static func == (lhs: Theme, rhs: Theme) -> Bool {
        lhs.colors == rhs.colors
    }
}

// MARK: - Einzige Instanz: Velvet Hour

extension Theme {
    static let velvetHour = Theme(
        colors: ThemeColors.velvetHour,
        fonts: ThemeFonts.velvetHour,
        spacing: ThemeSpacing.standard,
        motion: ThemeMotion.standard
    )
}

// MARK: - ThemeFonts

struct ThemeFonts: Equatable {
    let displayFontName: String?
    let bodyFontName: String?
    let monoFontName: String?
    let fallbackDisplayDesign: Font.Design
    let fallbackBodyDesign: Font.Design

    func display(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let name = displayFontName, FontRegistry.isRegistered(name) {
            return .custom(name, size: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: fallbackDisplayDesign)
    }

    func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let name = bodyFontName, FontRegistry.isRegistered(name) {
            return .custom(name, size: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: fallbackBodyDesign)
    }

    func mono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let name = monoFontName, FontRegistry.isRegistered(name) {
            return .custom(name, size: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: .monospaced)
    }

    // Semantische Convenience. Type-Scale ist das kanonische Raster der App.
    var displayHero: Font { display(size: 40, weight: .regular) }
    var titleLarge: Font { display(size: 28, weight: .regular) }
    var titleMedium: Font { body(size: 20, weight: .semibold) }
    var titleSmall: Font { body(size: 18, weight: .semibold) }
    var bodyRegular: Font { body(size: 15, weight: .regular) }
    var bodyMedium: Font { body(size: 15, weight: .medium) }
    var caption: Font { body(size: 13, weight: .regular) }
    var microCaption: Font { body(size: 11, weight: .semibold) }
}

extension ThemeFonts {
    // Velvet Hour — Bluu Next (dramatisch-schmal, High-Contrast-Serif) + Manrope
    static let velvetHour = ThemeFonts(
        displayFontName: "BluuNext-Bold",
        bodyFontName: "Manrope-Regular",
        monoFontName: nil,
        fallbackDisplayDesign: .serif,
        fallbackBodyDesign: .default
    )
}

// MARK: - ThemeSpacing

struct ThemeSpacing: Equatable {
    // 4pt-Skala, semantic tokens
    let xxs: CGFloat
    let xs: CGFloat
    let sm: CGFloat
    let md: CGFloat
    let lg: CGFloat
    let xl: CGFloat
    let xxl: CGFloat
    let xxxl: CGFloat

    static let standard = ThemeSpacing(
        xxs: 2, xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32, xxxl: 48
    )
}

// MARK: - ThemeMotion

struct ThemeMotion: Equatable {
    // Exponentielle Easings. Animationen laufen nur auf transform + opacity.
    let quickDuration: Double
    let standardDuration: Double
    let heroDuration: Double

    var easeOutQuart: Animation {
        .timingCurve(0.25, 1, 0.5, 1, duration: standardDuration)
    }

    var easeOutQuint: Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: standardDuration)
    }

    var easeOutExpo: Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: heroDuration)
    }

    var buttonPress: Animation {
        .timingCurve(0.25, 1, 0.5, 1, duration: quickDuration)
    }

    static let standard = ThemeMotion(
        quickDuration: 0.1,
        standardDuration: 0.3,
        heroDuration: 0.6
    )
}
