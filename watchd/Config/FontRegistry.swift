import CoreText
import Foundation
import os

// Registriert gebundelte Font-Dateien rein programmatisch.
// Grund: Das Xcode-Target nutzt GENERATE_INFOPLIST_FILE = YES, es gibt keine
// Info.plist zum Eintragen von UIAppFonts. CTFontManagerRegisterFontsForURL
// ersetzt den Plist-Mechanismus vollständig.
//
// Fehlt eine Font-Datei, wird das geloggt und ThemeFonts fällt auf Systemfonts
// zurück (serif für Display, default für Body). Kein Crash.

enum FontRegistry {
    private static let log = Logger(subsystem: "com.watchd.app", category: "FontRegistry")

    // Velvet Hour — Bluu Next (Display) + Manrope (Body)
    // Name = Bundle-Resource-Name ohne Extension. Muss dem PostScript-Name
    // entsprechen, damit `Font.custom(name:)` zieht.
    private static let bundledFonts: [(resource: String, ext: String, postScript: String)] = [
        ("BluuNext-Bold", "otf", "BluuNext-Bold"),
        ("BluuNext-BoldItalic", "otf", "BluuNext-BoldItalic"),
        ("Manrope-Regular", "ttf", "Manrope-Regular"),
        ("Manrope-Medium", "ttf", "Manrope-Medium"),
        ("Manrope-SemiBold", "ttf", "Manrope-SemiBold"),
        ("Manrope-Bold", "ttf", "Manrope-Bold")
    ]

    private static var registered: Set<String> = []
    private static var didRun = false

    static func registerAll() {
        guard !didRun else { return }
        didRun = true

        for font in bundledFonts {
            guard let url = Bundle.main.url(forResource: font.resource, withExtension: font.ext) else {
                log.notice("Font-File fehlt im Bundle: \(font.resource).\(font.ext, privacy: .public) — Fallback auf Systemfont.")
                continue
            }

            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)

            if success {
                registered.insert(font.postScript)
                log.debug("Font registriert: \(font.postScript, privacy: .public)")
            } else {
                let message = error?.takeRetainedValue().localizedDescription ?? "unknown"
                log.error("Font-Registrierung fehlgeschlagen: \(font.postScript, privacy: .public) — \(message, privacy: .public)")
            }
        }

        log.info("FontRegistry: \(registered.count, privacy: .public) von \(bundledFonts.count, privacy: .public) Fonts registriert.")
    }

    static func isRegistered(_ postScriptName: String) -> Bool {
        registered.contains(postScriptName)
    }
}
