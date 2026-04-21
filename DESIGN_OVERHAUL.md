# Watchd — Design Overhaul Plan

> **Zweck dieses Dokuments**: Vollständiger Überblick über den kompletten visuellen Overhaul der iOS-App. Jede Phase ist so beschrieben, dass sie ohne Rückfrage durchgeführt werden kann. Nach jeder Phase müssen die CLAUDE.md-Dateien (Backend + iOS) aktualisiert werden.
>
> **Start-Voraussetzung**: Freigabe dieses Plans durch den User. Danach beginnt Phase 0.
>
> **Status**: 📋 Plan steht, nicht freigegeben. Noch keine Phase gestartet.

---

## 1 Ausgangslage & Ziel

### Ist-Zustand
- iOS-App mit Netflix-Clone-Design: Background `#141414`, Primary `#E50914`, SF-Pro-Rounded-Fonts
- Navigation zentriert auf `HomeView` als Hub (keine TabBar)
- Ein einziges Design-Token-File: `Config/WatchdTheme.swift` (statisches enum)
- 16 SwiftUI-Views nutzen diese Tokens direkt: `WatchdTheme.primary`, `WatchdTheme.titleLarge()` etc.

### Soll-Zustand
- Drei deutlich differenzierte, nutzer-wählbare **Themes** (Kino Noir / Velvet Hour / Marquee Paper)
- **Bottom-Tab-Navigation** mit 3 Tabs: Räume / Favoriten / Profil
- **Theme-Switcher** in der Profil-Sektion mit Live-Preview und `@AppStorage`-Persistenz
- Alle Design-Entscheidungen durch den `impeccable`-Skill-Leitfaden legitimiert (keine AI-Monoculture-Fonts, OKLCH-Paletten, keine absolut verbotenen CSS-Patterns)
- Strikt iOS-Best-Practices: `@Environment`-Pattern, Dynamic Type, Reduce-Motion-Support, VoiceOver-freundlich, Display-P3-Farben

### Nicht-Ziele
- Backend-Änderungen (keine API-Anpassungen)
- Neue Features (nur visueller Overhaul + Tab-Navigation + Theme-Switcher)
- iOS-Version-Bump (bleibt iOS 16+)

---

## 2 Design-Brief (aus `shape`-Skill-Struktur)

### Feature-Summary
Kompletter visueller Overhaul der iOS-App Watchd — ersetzt den generischen Netflix-Klon durch drei distinktive, aus verschiedenen Use-Case-Kontexten abgeleitete Designrichtungen mit Bottom-Tab-Navigation und nutzer-wählbarem Theme.

### Primary User Action
Auth → Raum wählen → Swipen → Match erleben → Film entscheiden. Alles andere ist Support.

### Design-Direction (aus `impeccable`-Theme-Selection)
Theme wird aus dem **physischen Viewing-Kontext** abgeleitet, nicht aus Default-Reflexen:

| Theme | Kontext | Mood |
|-------|---------|------|
| **Kino Noir** (Default, dark warm) | Paar auf Couch, 21:30, warmes Abendlicht | warm editorial, kuratiert |
| **Velvet Hour** (dark cool) | Paar im Bett, Kopfhörer, 23:00 | nocturnal luxury, moody |
| **Marquee Paper** (light) | Sonntagmorgen, Kaffee, Überlegung für Filmabend | printed editorial, neighborly |

### Markenhaltung (alle drei)
- **Kuratiert**, nicht algorithmisch
- **Zu zweit**, nicht alleinig
- **Entscheidung**, nicht Endlosscroll
- **Warm**, nicht klinisch

### Anti-Goals
- Darf nicht wie Netflix/Disney+/Prime aussehen
- Keine generische AI-Ästhetik (keine Purple-Blue-Gradients, keine Cyan-on-Dark, keine Glassmorphism-als-Dekoration)
- Keine Fonts aus dem AI-Monoculture-Pool (siehe Phase 1)
- Keine Gradient-Text, keine Side-Stripe-Borders >1px, keine Modals wo Sheets/Inline-Disclosure gehen

---

## 3 Typografie-Entscheidungen

### Harte Regel aus `impeccable`
Der Skill verbietet explizit diese Fonts als **„reflex_fonts_to_reject"** (AI-Monoculture-Defaults):
`Fraunces · Newsreader · Lora · Crimson · Playfair Display · Cormorant · Syne · IBM Plex Mono/Sans/Serif · Space Mono · Space Grotesk · Inter · DM Sans · DM Serif Display/Text · Outfit · Plus Jakarta Sans · Instrument Sans · Instrument Serif`

Alle folgenden Fonts sind geprüft **nicht** auf dieser Liste.

### Font-Pairings pro Theme

#### Kino Noir — Brand-Worte: *warm · considered · patient*
- **Display: Redaction** (Titus Kaphar / Forest Young — OFL via redaction.us, multiple optical sizes 10/20/35/50/70)
- **Body: Geist** (Vercel — OFL, geometric Workhorse)
- Physischer-Objekt-Test: „Saalbroschüre im Programmkino, 1970er Offsetdruck"

#### Velvet Hour — Brand-Worte: *nocturnal · intimate · heavy*
- **Display: Bluu Next** (Velvetyne — OFL, dramatisch-schmal, High-Contrast-Serif mit Italic)
- **Body: Manrope** (OFL, humanistische Geometrische)
- Physischer-Objekt-Test: „Seidenetikett im Innenfutter eines Samtmantels"

#### Marquee Paper — Brand-Worte: *printed · opinionated · neighborly*
- **Display: EB Garamond** (OFL, alt-stilistische Serif)
- **Body: Work Sans** (OFL, Grotesk humanist)
- **Accent: Fragment Mono** (OFL, für Room-Codes und uppercase Labels)
- Physischer-Objekt-Test: „Kinoclub-Flyer auf Zeitungspapier"

### Type-Scale (fix, app-UI-konform per `typeset`)
5 Steps, Ratio ~1.3:
| Role | Size (pt) | Weight (Display / Body) |
|------|-----------|-------------------------|
| Caption | 11 | Regular |
| Secondary | 13 | Medium |
| Body | 15 | Regular |
| Subheading | 20 | Semibold / Medium |
| Heading | 28 | Bold / Regular-Italic (je Theme) |
| Display (Auth, Match) | 40 | Display-Font |

**Dynamic Type**: über `@ScaledMetric` für Body/Caption wo Lesbarkeit kritisch (Detail-Views, Matches-List). Auth/Match/Display-Sizes bleiben fix (Composition würde sonst bei XXXL-Setting brechen).

### Font-Lizenz-Nachweis
Alle Fonts SIL Open Font License (OFL) oder vergleichbar kommerziell nutzbar.
Download-Quellen in Phase 1 dokumentiert.

---

## 4 Farb-Entscheidungen

### Regeln aus `impeccable`
- **OKLCH-designed, sRGB/Display-P3-shipped** (SwiftUI-native, keine Runtime-Konvertierung)
- Neutrals getintet Richtung Brand-Hue (Chroma 0.005-0.015, subtil aber wirksam)
- 60/30/10-Verteilung (Base / Secondary / Accent)
- Kein pure-Black (`#000`), kein pure-White (`#FFF`)
- Kein AI-Palette-Reflex (Cyan-on-Dark, Purple-Blue-Gradient, Neon-on-Dark)
- Accent sparsam — seine Kraft kommt aus Seltenheit

### Palette pro Theme

Jeder Wert als Kommentar mit OKLCH-Source, darunter sRGB-Hex für SwiftUI `Color(.sRGB, ...)` oder `Color(.displayP3, ...)`.

#### Kino Noir (warm dark)
```
Base       oklch(18% 0.012 40)   → sRGB #1A1512   (60% — Backgrounds)
Cream      oklch(88% 0.025 70)   → sRGB #EDE0CE   (30% — Text, Cards on Base)
Forest     oklch(36% 0.04 150)   → sRGB #3C4F3C   (chips, secondary surfaces)
Coral      oklch(64% 0.16 25)    → sRGB #D65A3C   (10% — Primary Action, sparsam)
Amber      oklch(78% 0.12 75)    → sRGB #DFB160   (Rating-Stars)
Success    oklch(65% 0.14 155)   → sRGB #4A9560
Error      oklch(58% 0.18 15)    → sRGB #C4422D
```

#### Velvet Hour (cool dark, moody)
```
Base       oklch(15% 0.025 310)  → sRGB #14101E   (60%)
Ivory      oklch(89% 0.012 80)   → sRGB #E8E3DA   (30%)
Plum       oklch(30% 0.08 340)   → sRGB #452339   (secondary surfaces)
Champagne  oklch(72% 0.09 65)    → sRGB #D3A26B   (10% — Primary Action)
Rose       oklch(66% 0.12 15)    → sRGB #C26A7A   (Romance, sparsam — Match-Akzent)
Success    oklch(68% 0.10 160)   → sRGB #5AA285
Error      oklch(60% 0.16 20)    → sRGB #C25240
```

#### Marquee Paper (warm light)
```
Paper      oklch(95% 0.012 75)   → sRGB #F4EFE6   (60% — Background)
Ink        oklch(18% 0.008 60)   → sRGB #1A1715   (30% — Text)
Forest     oklch(35% 0.04 150)   → sRGB #394F40   (chips, tags)
Signal     oklch(55% 0.17 30)    → sRGB #C93C1F   (10% — CTA, sparsam)
MonoGrey   oklch(60% 0.005 70)   → sRGB #8C847A   (Fragment-Mono-Labels)
Success    oklch(52% 0.14 155)   → sRGB #3D7C52
Error      oklch(52% 0.18 20)    → sRGB #B3422A
```

### Kontrast-Verifikation
Pro Theme WCAG-AA (4.5:1 für Body, 3:1 für UI-Kontraste) verifiziert bei:
- Body-Text auf Base
- Primary-Action-Text auf Accent
- Secondary-Text auf Base
- Link-Text auf Base

Tool: Xcode Accessibility Inspector oder WebAIM Contrast Checker (sRGB-Werte).

---

## 5 Motion-Entscheidungen

### Regeln aus `animate`
- Nur `transform` + `opacity` animieren (GPU-beschleunigt)
- Exponentielle Easing-Kurven: `ease-out-quart` / `ease-out-quint` / `ease-out-expo`
- **Kein** Bounce, **kein** Elastic (feel dated)
- Exit-Dauer ~75% von Enter
- `prefers-reduced-motion` respektieren (iOS: `UIAccessibility.isReduceMotionEnabled`)
- Hero-Moment: eine gut orchestrierte Animation > viele Micro-Interactions

### Motion-Tokens (SwiftUI)
```swift
Animation.timingCurve(0.25, 1, 0.5, 1, duration: 0.3)   // ease-out-quart — default transitions
Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.3)  // ease-out-quint — snappier UI
Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.6)   // ease-out-expo — hero reveals
```

### Anwendungen
| Ort | Dauer | Kurve | Begründung |
|-----|-------|-------|------------|
| Swipe-Card fly-out | 250ms | ease-out-quart | bestehend, nur Easing umstellen |
| Tab-Switch Crossfade | 200ms | ease-out-quart | fast state change |
| Match-View Hero-Bloom | 600ms | ease-out-expo | **Hero-Moment** — radialer opacity+scale-Bloom |
| Match-Content Staggered Reveal | 100/200/300ms delays | ease-out-quart | Title → Rating → Providers |
| Theme-Crossfade beim Switchen | 300ms | ease-out-quart | |
| Button-Press Feedback | 100ms | ease-out-quart | scale 0.97 → 1.0 |
| Room-Card Entrance (List) | 400ms stagger 50ms | ease-out-expo | App-Launch & Refresh |

### Reduce-Motion-Fallback
Bei `isReduceMotionEnabled == true`: alle Durations auf 0.01s, Scale/Transform weglassen, nur Opacity-Transitions behalten.

---

## 6 iOS-Architektur für das Theme-System

### Entscheidung: `Environment`-Pattern statt Singleton
SwiftUI-idiomatisch. Views deklarieren Theme-Abhängigkeit explizit.

```swift
// Config/Theme.swift
struct Theme: Equatable {
    let id: ThemeID           // .kinoNoir, .velvetHour, .marqueePaper
    let colors: ThemeColors
    let fonts: ThemeFonts
    let spacing: ThemeSpacing // 4pt-Skala, semantic tokens
    let motion: ThemeMotion   // pre-defined Animations
}

struct ThemeColors {
    let base: Color           // 60% surface
    let secondary: Color      // 30% text/surface
    let accent: Color         // 10% primary action
    let depth: Color          // tertiary surfaces
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let success: Color
    let error: Color
    let rating: Color
    let separator: Color
    let overlay: Color
    // ...
}

struct ThemeFonts {
    let display: (CGFloat, Font.Weight) -> Font
    let body: (CGFloat, Font.Weight) -> Font
    let mono: ((CGFloat, Font.Weight) -> Font)?  // nil außer Marquee Paper
    // Convenience:
    let titleLarge: Font       // 28pt
    let titleMedium: Font      // 20pt
    let bodyRegular: Font      // 15pt
    let caption: Font          // 13pt
    let microCaption: Font     // 11pt
    let displayHero: Font      // 40pt
}

// Config/ThemeEnvironment.swift
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .kinoNoir
}
extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// Config/ThemeManager.swift — reactive switching
@MainActor
final class ThemeManager: ObservableObject {
    @AppStorage("selectedThemeId") private var storedId: String = ThemeID.kinoNoir.rawValue
    @Published var current: Theme = .kinoNoir

    init() { self.current = Theme.from(id: ThemeID(rawValue: storedId) ?? .kinoNoir) }

    func switchTo(_ id: ThemeID) {
        withAnimation(.timingCurve(0.25, 1, 0.5, 1, duration: 0.3)) {
            self.current = Theme.from(id: id)
            self.storedId = id.rawValue
        }
    }
}
```

### View-Zugriff
```swift
struct MyView: View {
    @Environment(\.theme) var theme
    var body: some View {
        Text("Hallo").font(theme.fonts.titleLarge).foregroundStyle(theme.colors.textPrimary)
    }
}
```

### App-Root-Injection
```swift
@main struct WatchdApp: App {
    @StateObject private var themeManager = ThemeManager()
    init() { FontRegistry.registerAll() }  // einmaliger Call beim Launch
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.theme, themeManager.current)
                .environmentObject(themeManager)           // für ProfileView-Switcher
                .preferredColorScheme(themeManager.current.colorScheme)  // .dark oder .light
        }
    }
}
```

### Übergangs-Shim (nur Phase 1, wird in Phase 4 gelöscht)
`WatchdTheme.swift` wird umgeschrieben zu einem Shim, der auf `ThemeManager.shared.current` delegiert — damit die 16 bestehenden Views kompilieren, während wir Screen für Screen auf `@Environment(\.theme)` umstellen.

---

## 7 Bottom-Tab-Navigation

### Struktur
```
MainTabView (TabView)
├── Tab 1: Räume      (house.fill)        → RoomsView (ex-HomeView)
├── Tab 2: Favoriten  (heart.fill)        → FavoritesListView (global)
└── Tab 3: Profil     (person.fill)       → ProfileView
```

### TabBar-Verhalten
- **Pill-Style** mit `.ultraThinMaterial`-Background, Floating (Safe-Area-Inset)
- **Versteckt** in: `SwipeView` (immersive Swipe-Experience), `MatchView`, alle Sheets (Create/Filters/Upgrade)
  - SwiftUI: `.toolbar(.hidden, for: .tabBar)`
- **Icon-Treatment** themeabhängig:
  - Active: `accent`-Farbe, filled-SFSymbol
  - Inactive: `textTertiary`, outline-SFSymbol
- **Haptic-Feedback** bei Tab-Wechsel (`.sensoryFeedback(.selection, trigger:)` ab iOS 17, sonst `UISelectionFeedbackGenerator()`)

### Begründung für genau 3 Tabs
- Matches sind **pro Room** — kein globaler Tab sinnvoll
- Swipen ist **kontextuell im Room** — kein eigener Tab
- 4+ Tabs würde Scheinbeschäftigung erzeugen

---

## 8 iOS Best Practices Checkliste (gilt durchgängig)

| Thema | Regel |
|-------|-------|
| Fonts | Via `Info.plist` → `UIAppFonts` registriert, **nicht** Runtime-`UIFont.register()` |
| Farben | `Color(.sRGB, red:green:blue:)` oder `Color(.displayP3, ...)` auf modernen Geräten; nie hardcoded String-Namen |
| State | ViewModels `@MainActor ObservableObject`, Theme via `@Environment`, Switcher via `@EnvironmentObject` |
| Persistenz | `@AppStorage("selectedThemeId")` für Theme-Wahl; Keychain für Auth (bestehend) |
| Dynamic Type | `@ScaledMetric` für body/caption in Detail-Views, Lists; fix in Auth/Match/Display |
| Reduce Motion | `@Environment(\.accessibilityReduceMotion) var reduceMotion` → konditionale Animation |
| VoiceOver | `.accessibilityLabel`, `.accessibilityHint`, `.accessibilityAddTraits(.isButton)` auf Custom-Interactives |
| Color-Scheme | `.preferredColorScheme(theme.colorScheme)` pro Theme — iOS-Chrome folgt |
| Haptics | `.sensoryFeedback(_:trigger:)` ab iOS 17, Fallback `UIImpactFeedbackGenerator` |
| Safe Area | `.safeAreaInset` für TabBar-Floating, nie hardcoded Insets |
| Performance | Nur `transform`/`opacity` animieren, keine layout-props |
| Dark/Light Chrome | Status-Bar-Style über Theme-ColorScheme automatisch, nicht manuell setzen |
| Bundle-Size | Alle 7 Fonts bundeln ist OK (~1.2 MB von iOS-Standard 10-50 MB Apps) |
| Testing | Physisches Gerät für Haptics, Reduce-Motion, Dynamic-Type-XXL |

---

## 9 Phasen-Plan

Jede Phase ist einzeln abschließbar. Nach Abschluss: Xcode-Build grün + CLAUDE.md beider Repos aktualisiert + `.impeccable.md` aktualisiert falls Design-Decisions präzisiert + `/done`-Skill.

---

### 🧭 Phase 0 — Design Context etablieren

**Scope**: 1 neues Dokument, keine App-Code-Änderung.

**Aktionen**:
1. Run `/impeccable teach` (Skill-Interview-Flow)
2. Aus Interview + bereits bekanntem Kontext ableiten: `.impeccable.md` im iOS-Repo-Root
3. Struktur gemäß `impeccable teach` Step 3:
   - Users: Paar (dt.sprachig, 25–45), Abend-Nutzung, Entscheidungs-Kontext
   - Brand Personality: 3-Wort-Definition je Theme + Umbrella
   - Aesthetic Direction: je Theme (warm-editorial / cool-luxury / light-printed)
   - Design Principles (3-5): Kuratiert-nicht-Algorithmisch / Zu-zweit-nicht-Allein / Abendruhe / Entscheidung-nicht-Endlos / ggf. Haptisch-präsent
4. Ergebnis: `.impeccable.md` ist vorhanden, alle weiteren Design-Skill-Calls erfüllen die Mandatory-Preparation

**Skills**: `/impeccable teach` (einzig genutzter Skill in Phase 0)

**CLAUDE.md-Updates**:
- `watchd/CLAUDE.md`: Verweis auf `.impeccable.md` als kanonische Design-Kontext-Quelle ergänzen
- `watchd-coding/CLAUDE.md` (Backend-Parent): Hinweis in „Offene Punkte" → neue „Design Overhaul"-Zeile

**Dauer-Schätzung**: 1 Session (Interview + Dokument)

---

### 🎨 Phase 1 — Theme-Foundation + Kino Noir aktiv

**Scope**: ~500 Zeilen, 6 neue Swift-Files, 7 Font-Files, Info.plist-Änderung, Shim für Altcode.

**Neue Files**:
```
watchd/watchd/Config/
├── Theme.swift               # struct Theme + 3 Instanzen + ThemeID enum
├── ThemeManager.swift        # @MainActor ObservableObject + @AppStorage
├── ThemeEnvironment.swift    # EnvironmentKey + Extension
├── FontRegistry.swift        # registerAll() beim App-Launch
└── Color+Tokens.swift        # sRGB Color-Token-Helper mit OKLCH-Kommentaren

watchd/watchd/Fonts/
├── Redaction_35-Regular.otf
├── Redaction_35-Italic.otf
├── Geist-VariableFont.ttf
├── BluuNext-Bold.otf
├── BluuNext-BoldItalic.otf
├── Manrope-VariableFont.ttf
├── EBGaramond-VariableFont.ttf
├── EBGaramond-Italic-VariableFont.ttf
├── WorkSans-VariableFont.ttf
├── WorkSans-Italic-VariableFont.ttf
└── FragmentMono-Regular.ttf
```

**Geänderte Files**:
- `watchd/Info.plist` → `UIAppFonts`-Array mit allen 11 Font-Dateinamen
- `watchd/watchd/Config/WatchdTheme.swift` → **Shim** (alle static-Members delegieren auf `ThemeManager.shared.current`)
- `watchd/watchd/watchdApp.swift` → `FontRegistry.registerAll()` in init, `.environment(\.theme, ...)` und `.environmentObject(themeManager)` am Root

**Aktionen**:
1. Font-Files aus OFL-Quellen herunterladen (Redaction, Geist, Bluu Next, Manrope, EB Garamond, Work Sans, Fragment Mono)
2. In Xcode: Font-Dateien in `Fonts/`-Ordner legen (Xcode 16 erfasst automatisch), `Info.plist` → `UIAppFonts` erweitern
3. `Theme.swift`: struct + ThemeID-Enum + 3 statische Instanzen (aber nur `kinoNoir` voll ausgebaut in Phase 1; `velvetHour` und `marqueePaper` placeholder-gleich wie Noir, werden in Phase 5 befüllt)
4. `Color+Tokens.swift`: sRGB-Color-Tokens mit OKLCH-Doc-Kommentar darüber
5. `ThemeManager.swift`: `@AppStorage("selectedThemeId")` + `switchTo(_:)`
6. `ThemeEnvironment.swift`: `EnvironmentKey` + `EnvironmentValues`-Extension
7. `FontRegistry.swift`: registriert alle 7 Fonts via `CTFontManagerRegisterFontsForURL` (falls `UIAppFonts` allein nicht reicht — idiomatisch beides haben)
8. `WatchdTheme.swift` umschreiben zu Shim: `static var primary: Color { ThemeManager.shared.current.colors.accent }` etc.
9. `watchdApp.swift` → `@StateObject var themeManager`, Font-Registration, Environment-Injection, `.preferredColorScheme(themeManager.current.colorScheme)`
10. Build grün halten — bestehende 16 Views müssen ohne Änderung weiter kompilieren (via Shim)

**Skills**:
- `/typeset` zur Validierung der Type-Skala und Font-Hierarchie
- `/colorize` zur Verifikation der Palette (Kontrast, 60-30-10, semantische Farben)
- `/impeccable` review pass nach Implementation

**Verifikation**:
- [ ] `npm run typecheck` nicht anwendbar (iOS) — Xcode-Build grün
- [ ] App startet, zeigt Kino-Noir-Palette auf allen bestehenden Screens
- [ ] Fonts laden (optisch prüfen: Display-Text sichtbar Redaction, Body sichtbar Geist)
- [ ] Keine Regression in Navigation/Funktionalität
- [ ] Shim funktioniert: keine fehlerhaften Color-References im Log

**CLAUDE.md-Updates (beide)**:
- **Theme-Sektion** komplett neu: 3 Themes vorgestellt, Default Kino Noir, Fonts pro Theme, OKLCH-Design-Ansatz
- **Projektstruktur-Baum**: `Config/` erweitert um Theme/ThemeManager/ThemeEnvironment/FontRegistry/Color+Tokens, `Fonts/`-Verzeichnis dokumentiert
- **Code-Standards**: „Theme-Zugriff via `@Environment(\.theme)`; `WatchdTheme.X` nur noch als Übergangs-Shim (wird in Phase 4 gelöscht)"
- **Häufige Fehler vermeiden**: „NICHT: Fonts aus `reflex_fonts_to_reject`-Liste ergänzen; NICHT: neue Call-Sites für `WatchdTheme.X` — neue Views direkt `@Environment(\.theme)`"

**Dauer-Schätzung**: 2-3 Sessions

---

### 🧱 Phase 2 — TabBar-Shell + ProfileView

**Scope**: ~300 Zeilen, 2 neue Views, HomeView rename, FavoritesListView entkoppelt.

**Neue Files**:
```
watchd/watchd/Views/
├── MainTabView.swift     # 3-Tab-Container mit Floating Pill-Style
└── ProfileView.swift     # Name, Upgrade, Archiv, Legal, Logout, Theme-Switcher (disabled in Phase 2)
```

**Geänderte Files**:
- `watchd/watchd/Views/HomeView.swift` → Datei-Rename zu `RoomsView.swift`; entfernt die Settings-/Archiv-/Upgrade-Sektion (zieht nach ProfileView)
- `watchd/watchd/Views/FavoritesListView.swift` → nicht mehr mit `roomId`-Parameter gekoppelt, nutzt direkt `GET /api/matches/favorites/list`
- `watchd/watchd/ContentView.swift` → routet auf `MainTabView` statt `HomeView` im auth-Zweig
- `watchd/watchd/ViewModels/FavoritesViewModel.swift` → `loadFavorites()` ohne roomId-Parameter (globale Favoritenliste)

**Aktionen**:
1. `MainTabView.swift`: `TabView` mit 3 Tabs, custom Pill-Overlay mit `.ultraThinMaterial`, `.toolbar(.hidden, for: .tabBar)` über Bindings konfiguriert
2. `ProfileView.swift`: Sections: „Konto" (Name, Email/Upgrade falls Gast), „Design" (Theme-Switcher-Placeholder mit „bald verfügbar"-Badge, aktiviert in Phase 5), „Archiv" (Link zu ArchivedRoomsView), „Rechtliches" (Link zu LegalView), „Abmelden" (destructive)
3. `HomeView.swift` → `RoomsView.swift` — nur Room-Liste + Create/Join-Buttons. Delete all settings-related code.
4. `FavoritesListView.swift` — Room-Filter-UI entfernen, globale Liste
5. `ContentView.swift` — `if auth { MainTabView() } else { AuthView() }`
6. Alle weiterhin `WatchdTheme.X`-Calls bleiben via Shim funktional

**Skills**:
- `/layout` für TabBar-Composition + ProfileView-Section-Rhythmus (Abstände, Gruppierungen, visuelle Hierarchie)

**Verifikation**:
- [ ] Xcode-Build grün
- [ ] Alle 3 Tabs erreichbar, Icons tauschen bei Active-State
- [ ] TabBar versteckt sich in SwipeView/MatchView/Sheets
- [ ] Favoriten-Tab zeigt globale Favoriten (über mehrere Rooms hinweg)
- [ ] ProfileView-Logout funktioniert wie vorher
- [ ] Archivierte Rooms weiterhin erreichbar via ProfileView → Archiv-Link

**CLAUDE.md-Updates (beide)**:
- **Projektstruktur-Baum**: `HomeView.swift` → `RoomsView.swift`, neu: `MainTabView.swift`, `ProfileView.swift`
- **App-Flow-Diagramm** komplett neu: Root ist MainTabView, Tabs sind Räume/Favoriten/Profil, darunter Sub-Navigation
- **Views-Beschreibungen**: `HomeView` entfernt, `RoomsView`/`MainTabView`/`ProfileView` hinzu
- **Code-Standards**: „TabBar-Hide in Immersive-Screens via `.toolbar(.hidden, for: .tabBar)`"

**Dauer-Schätzung**: 1-2 Sessions

---

### 🎬 Phase 3 — Core-Screens Redesign

**Scope**: ~800 Zeilen, 5 Views komplett durchkomponiert.

**Redesignte Views**:
- `RoomsView.swift` (ex-HomeView): asymmetrische Room-Cards (keine identische Grid), Create/Join als Editorial-CTA statt Button-Leiste
- `SwipeView.swift`: Card-Stack mit stärkerem Tiefen-Layering, neue Overlay-Badges in Theme-Accent, Grid-Linien-Hintergrund (subtil)
- `MovieCardView.swift`: Letterboxd-style Card — Poster + Title-Treatment in Display-Font + Meta-Zeile + Herz-Button
- `MovieDetailView.swift`: Editorial-Layout — Hero-Poster oben, Pull-Quote-Style-Overview, Provider-Grid als typografisch klare Liste
- `MatchView.swift`: **Hero-Moment** — Konfetti weg, dafür radialer Bloom (opacity+scale, 600ms ease-out-expo) + staggered Reveal (Title 0ms, Rating 100ms, Providers 200ms delay)

**Aktionen pro View**:
1. Alle `WatchdTheme.X`-Calls in diesen 5 Files → `@Environment(\.theme) var theme` + `theme.colors.X` / `theme.fonts.X`
2. Layout nach `/layout`-Skill-Regeln: asymmetrisch wo angebracht, 4pt-Skala durchgängig, kein Card-in-Card, keine Hero-Metric-Templates
3. Motion via Theme-Motion-Tokens (keine hardcoded `withAnimation(.easeInOut)`)
4. VoiceOver-Labels auf Custom-Interactives (Swipe-Cards, Herz-Button, Match-Actions)
5. Reduce-Motion-Fallback auf allen Animationen

**Skills**:
- `/impeccable` als erste Runde (distinktive Komposition etablieren)
- `/layout` für Spatial-Composition auf jeder View
- `/animate` speziell für MatchView-Bloom
- `/delight` für gezielte Micro-Momente (Match, Favoriten-Toggle)

**Verifikation**:
- [ ] Xcode-Build grün
- [ ] Optisch: jede View fühlt sich wie „Kino Noir" an, nicht wie Netflix-Klon
- [ ] Match-Bloom performt @ 60fps (Xcode Instruments Framerate-Monitor)
- [ ] VoiceOver liest sinnvolle Labels vor
- [ ] Reduce-Motion-Setting reduziert Animationen auf Opacity-only

**CLAUDE.md-Updates (beide)**:
- **Views-Beschreibungen**: Motion-Doku für MatchView (Bloom statt Konfetti), RoomsView-Composition-Note
- **Projektstruktur**: Views-Liste aktualisiert mit Kurz-Beschreibungen
- **Häufige Fehler**: „NICHT: Konfetti in MatchView reintragen — Bloom-Pattern ist kanonisch"

**Dauer-Schätzung**: 3-4 Sessions

---

### 🧩 Phase 4 — Flankierende Screens + Shim-Entfernung

**Scope**: ~500 Zeilen, 8 Views.

**Redesignte Views**:
- `AuthView.swift`
- `CreateRoomSheet.swift`
- `RoomFiltersView.swift`
- `UpgradeAccountView.swift`
- `ArchivedRoomsView.swift`
- `PasswordResetViews.swift`
- `LegalView.swift`
- `SharedComponents.swift`

**Aktionen**:
1. Alle verbleibenden `WatchdTheme.X`-Calls → `@Environment(\.theme)`
2. `WatchdTheme.swift` komplett löschen (Shim weg, keine Caller mehr)
3. Microcopy-Pass: konsistente dt. Ansprache, keine dopplungen mit visible UI, Empty-States „lehren" das Interface
4. `SharedComponents.swift` theme-agnostic — alle Components lesen `@Environment(\.theme)`

**Skills**:
- `/clarify` für Microcopy-Review (Fehlermeldungen, Empty-States, Button-Labels)
- `/polish` für Alignment/Spacing-Details

**Verifikation**:
- [ ] Xcode-Build grün ohne `WatchdTheme` in Codebase (grep -r "WatchdTheme" watchd/ ergibt 0 Hits)
- [ ] Alle 16 Views funktional
- [ ] Auth-Flow, Password-Reset, Upgrade-Flow jeweils durchgespielt
- [ ] Microcopy einheitlich und klar

**CLAUDE.md-Updates (beide)**:
- **Code-Standards**: „`WatchdTheme`-Shim entfernt, nur noch `@Environment(\.theme)`"
- **Häufige Fehler**: Alte `WatchdTheme`-Warnung ersetzen durch neue `@Environment(\.theme)`-Regel

**Dauer-Schätzung**: 2-3 Sessions

---

### 🎭 Phase 5 — Multi-Theme-Switcher aktivieren

**Scope**: ~350 Zeilen, 2 zusätzliche Theme-Instanzen voll ausgebaut, Switcher-UI, Live-Preview.

**Aktionen**:
1. `Theme.swift`: `velvetHour` und `marqueePaper` vollständig mit allen Colors/Fonts/Motion-Tokens
2. Pro Theme: `colorScheme` property (`.dark` für Noir+Velvet, `.light` für Marquee)
3. `ProfileView.swift`: Theme-Switcher-Section aktivieren:
   - 3 große Preview-Cards (je 120pt hoch) mit Mini-Poster-Mockup + Display-Font-Sample + Body-Font-Sample + Accent-Farbpunkt
   - Selected-Indicator (Outline-Ring in Accent-Farbe)
   - Tap → `themeManager.switchTo(.velvetHour)` → 300ms crossfade, `@AppStorage` persistiert
4. App-wide Cross-fade: beim Theme-Wechsel via `withAnimation` in `ThemeManager.switchTo` — alle Environment-Consumer re-rendern automatisch
5. Pro Theme verifizieren: alle 16 Views optisch + funktional korrekt

**Skills**:
- `/critique` — Stress-Test der 3 Themes im Vergleich (Persona-based Testing je Use-Case)
- `/audit` — P0-P3 Audit über A11y + Performance + Theming-Consistency + Responsive
- `/polish` — finale Feinheiten

**Verifikation**:
- [ ] Theme-Switch in ProfileView funktioniert live (keine App-Restart-Pflicht)
- [ ] Nach App-Kill-Restart: letztes Theme bleibt aktiv (`@AppStorage`)
- [ ] Alle 3 Themes: 16 Views durchklickbar, keine kaputten Farb-/Font-References
- [ ] WCAG-AA-Kontrast in allen 3 Themes verifiziert
- [ ] Kein Font-Loading-Flash beim Switch (alle Fonts sind von Phase 1 an registriert)
- [ ] Color-Scheme passt (Noir+Velvet = dark Chrome, Marquee = light Chrome inkl. Status-Bar)
- [ ] `/critique`-Report-Score pro Theme ≥ 7/10
- [ ] `/audit`-Report: keine P0, ≤ 2 P1-Issues

**CLAUDE.md-Updates (beide)**:
- **Theme-Sektion** final: alle 3 Themes vollständig mit Farben/Fonts dokumentiert, Default-Theme genannt
- **App-Flow-Diagramm**: ProfileView → Design-Section → Theme-Switcher erwähnt
- **Projektstruktur**: letzte Ergänzungen (falls neue Helper-Files)
- **Code-Standards**: UserDefaults-Key `selectedThemeId` dokumentiert
- **Offene Punkte**: Design-Overhaul-Zeile als **erledigt** markieren

**Dauer-Schätzung**: 2-3 Sessions

---

## 10 Rollback-Strategie

Jede Phase liegt im eigenen Git-Branch. Falls eine Phase nach Merge Probleme bringt:
- **Phase 1-4**: `git revert <merge-commit>` → Shim macht alte Views wieder funktional (solange Phase 4 noch nicht gemerged)
- **Phase 4 (Shim-Löschung) Rollback**: erfordert Revert von Phase 4 **und** evtl. Phase 3 — Shim-Löschung ist der Point-of-no-return
- **Phase 5**: Theme-Switcher disabled per Feature-Flag (`@AppStorage("themeswitcherEnabled")` Default false) — kein Code-Revert nötig

---

## 11 Testing-Strategie

### Automatisch (bestehende Testsuite)
Keine neuen Tests nötig — Design-Changes sind UI-only, Backend/ViewModels/Services unverändert.

### Manuell pro Phase
- Physisches Gerät (iPhone, mind. iOS 16)
- Haptics-Test
- Dynamic Type (XS, M, XXXL) in Settings → Accessibility
- Reduce Motion in Settings → Accessibility → Motion
- VoiceOver-Durchlauf auf Auth, Rooms, Swipe, Match
- Both orientations (falls relevant — aktuell Portrait-locked)
- Dark/Light-System-Setting (unabhängig vom Theme-`colorScheme`-Override)

### Pro Theme (Phase 5)
- 16 Views durchklicken je Theme
- WCAG-Kontrast-Check mit WebAIM-Tool
- 60fps-Check in Xcode Instruments auf SwipeView + MatchView

---

## 12 Offene Punkte & Abhängigkeiten

### Offene Punkte (keine blockierend)
- App-Icon-Redesign — aktuell wahrscheinlich Netflix-inspirierte Rot-Ästhetik, sollte zu Kino Noir passen. **Nicht Teil dieses Overhauls**, in Post-MVP offen (so wie in CLAUDE.md dokumentiert).
- Launch-Screen — aktuell Standard-Launch-Screen, sollte zumindest Kino-Noir-Palette zeigen. **Kann als Bonus in Phase 1** mitgenommen werden (nur Storyboard-Farbe tauschen).
- Settings-Bundle (iOS Settings-App) — falls vorhanden, Theme-Umschaltung auch dort exposen? Post-MVP, nicht kritisch.

### Abhängigkeiten
- **Keine Backend-Änderungen nötig** — alle Endpoints bleiben
- **Kein neuer Dependency in SPM/Cocoapods** — alles mit SwiftUI-Boardmitteln machbar
- **Xcode 16+** bleibt Anforderung (bereits erfüllt)

---

## 13 Erfolgskriterien

Der Overhaul gilt als abgeschlossen wenn:
- [ ] Alle 5 Phasen durchlaufen und gemerged
- [ ] `/critique` gibt jedem der 3 Themes ≥ 7/10
- [ ] `/audit` findet keine P0-Issues, ≤ 2 P1-Issues
- [ ] `.impeccable.md` existiert und ist aktuell
- [ ] Beide `CLAUDE.md`-Dateien spiegeln den Endzustand
- [ ] Das Design besteht den „AI Slop Test" aus `impeccable`: würde jemand bei Anblick der App sofort denken „das ist AI-generiert"? Wenn ja → zurück zu `/impeccable` für Überarbeitung

---

## 14 Dokumentations-Disziplin (Wiederholung, weil kritisch)

**Nach jeder Phase, ohne Ausnahme:**
1. Diese `DESIGN_OVERHAUL.md` aktualisieren — Phase als ✅ markieren, lessons learned in „offene Punkte" wenn relevant
2. `watchd/CLAUDE.md` — iOS-spezifische Änderungen eintragen
3. `watchd-coding/CLAUDE.md` (Backend-Parent, deckt auch iOS ab) — wenn iOS-Änderung die gemeinsame Doku betrifft
4. `.impeccable.md` — falls Design-Principles während der Phase präzisiert wurden
5. `/done`-Skill für Definition-of-Done-Check

Keine Phase gilt als fertig, solange diese 5 Schritte nicht erfolgt sind.

---

## Status-Tabelle

| Phase | Status | Abgeschlossen am |
|-------|--------|------------------|
| 0 — Design Context | ⏳ Noch nicht gestartet | — |
| 1 — Theme-Foundation + Kino Noir | ⏳ Noch nicht gestartet | — |
| 2 — TabBar-Shell + ProfileView | ⏳ Noch nicht gestartet | — |
| 3 — Core-Screens Redesign | ⏳ Noch nicht gestartet | — |
| 4 — Flankierende Screens + Shim-Entfernung | ⏳ Noch nicht gestartet | — |
| 5 — Multi-Theme-Switcher aktivieren | ⏳ Noch nicht gestartet | — |

---

*Plan-Version 1.0 — erstellt 2026-04-21. Wird mit jeder Phase aktualisiert.*
