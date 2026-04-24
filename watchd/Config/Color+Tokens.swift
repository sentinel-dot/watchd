import SwiftUI

// Palette-Tokens — Velvet Hour (einziges Theme der App).
// Werte sind in OKLCH designed und auf sRGB gemappt.
// Die OKLCH-Source ist als Kommentar darüber dokumentiert — Änderungen
// dort zuerst ableiten, dann nach sRGB-Hex konvertieren.

extension Color {
    // Hex-Convenience für Theme-Tokens. Nur für 6-stellige RGB-Hex-Werte.
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Velvet Hour (cool dark — nocturnal luxury)

enum VelvetHourPalette {
    // oklch(15% 0.025 310)
    static let base = Color(hex: 0x14101E)
    // oklch(19% 0.03 310)
    static let surfaceElevated = Color(hex: 0x1B1525)
    // oklch(23% 0.045 320)
    static let surfaceCard = Color(hex: 0x231A2F)
    // oklch(27% 0.05 325)
    static let surfaceInput = Color(hex: 0x2A2035)
    // oklch(89% 0.012 80)
    static let ivory = Color(hex: 0xE8E3DA)
    // oklch(75% 0.014 80) — muted ivory
    static let ivoryMuted = Color(hex: 0xC4BFB5)
    // oklch(55% 0.015 80) — dim ivory
    static let ivoryDim = Color(hex: 0x8A8479)
    // oklch(30% 0.08 340) — Plum secondary surface
    static let plum = Color(hex: 0x452339)
    // oklch(72% 0.09 65) — Champagne primary action
    static let champagne = Color(hex: 0xD3A26B)
    // oklch(58% 0.08 60) — Champagne deep (gradient end)
    static let champagneDeep = Color(hex: 0xA97A47)
    // oklch(66% 0.12 15) — Rose match-accent
    static let rose = Color(hex: 0xC26A7A)
    // oklch(68% 0.10 160)
    static let success = Color(hex: 0x5AA285)
    // oklch(60% 0.16 20)
    static let error = Color(hex: 0xC25240)
    // oklch(30% 0.02 310) — separator
    static let separator = Color(hex: 0x2E2439)
}

// MARK: - ThemeColors

struct ThemeColors: Equatable {
    // 60 / 30 / 10
    let base: Color
    let accent: Color
    let accentDeep: Color

    // Surfaces (Base-Ableitungen)
    let surfaceElevated: Color
    let surfaceCard: Color
    let surfaceInput: Color

    // Text
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let textOnAccent: Color

    // UI-Chrome
    let separator: Color
    let overlayDark: Color
    let overlayLight: Color

    // Semantic
    let success: Color
    let error: Color
    let rating: Color

    // Gradients (computed)
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [base, base.opacity(0.98)],
            startPoint: .top, endPoint: .bottom
        )
    }

    var heroBottomGradient: LinearGradient {
        LinearGradient(
            colors: [
                .clear,
                Color.black.opacity(0.45),
                Color.black.opacity(0.7),
                Color.black.opacity(0.9),
                base
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentDeep],
            startPoint: .leading, endPoint: .trailing
        )
    }
}

extension ThemeColors {
    static let velvetHour = ThemeColors(
        base: VelvetHourPalette.base,
        accent: VelvetHourPalette.champagne,
        accentDeep: VelvetHourPalette.champagneDeep,
        surfaceElevated: VelvetHourPalette.surfaceElevated,
        surfaceCard: VelvetHourPalette.surfaceCard,
        surfaceInput: VelvetHourPalette.surfaceInput,
        textPrimary: VelvetHourPalette.ivory,
        textSecondary: VelvetHourPalette.ivoryMuted,
        textTertiary: VelvetHourPalette.ivoryDim,
        textOnAccent: VelvetHourPalette.base,
        separator: VelvetHourPalette.separator,
        overlayDark: Color.black.opacity(0.78),
        overlayLight: VelvetHourPalette.ivory.opacity(0.08),
        success: VelvetHourPalette.success,
        error: VelvetHourPalette.error,
        rating: Color(hex: 0xDFB785)
    )
}
