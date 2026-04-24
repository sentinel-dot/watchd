# Watchd — iOS App

Tinder-style Movie-Matching-App, iOS-Client. Zwei User swipen in einem gemeinsamen "Room" auf Filme und erhalten eine Match-Benachrichtigung wenn beide denselben Film liken.

> **Backend-Doku**: Diese Datei deckt ausschließlich die iOS-App ab. Backend-Routen, API-Verträge, Socket.io-Events, JWT-Strategie, Env-Vars und Match-Flow-Logik sind im Backend-Repo (`watchd_backend-mac/CLAUDE.md`) dokumentiert.

> **Design-Kontext**: `.impeccable.md` im Repo-Root ist die kanonische Quelle für Zielgruppe, Markenhaltung, Aesthetic-Direction und Design-Prinzipien. Alle Design-Skills (`/impeccable`, `/typeset`, `/layout`, `/colorize`, `/animate`, `/critique`, `/polish`, `/audit`, `/delight`, `/clarify`, `/distill`, `/adapt`, `/quieter`, `/bolder`) lesen diese Datei zuerst. Implementation-Details (Hex-Werte, Font-Dateinamen, Motion-Kurven, Type-Scale) leben im Code unter `watchd/Config/` — `Theme.swift`, `Color+Tokens.swift`, `FontRegistry.swift`.

> **Diese Datei aktuell halten.** Nach jeder Änderung an Views, ViewModels, Services oder Xcode-Setup aktualisieren.

---

## Tech Layer

- **Framework**: SwiftUI (iOS 16+, Xcode 16+)
- **Architektur**: MVVM — alle ViewModels `@MainActor ObservableObject`
- **Netzwerk**: `URLSession` actor (`APIService`), Socket.io (vendored, v16.1.1)
- **Storage**: Keychain (`com.watchd.app`) — Keys: `jwt_token`, `jwt_refresh_token`, `user_id`, `user_name`, `user_email`, `is_guest`; UserDefaults-Key `selectedThemeId` für die Theme-Wahl
- **Theme**: Einziges Theme — **Velvet Hour** (cool dark — Base #14101E, Champagne-Accent #D3A26B, Bluu Next Display + Manrope Body). Struct-basiert (`Config/Theme.swift`) mit `@Environment(\.theme)`-Pattern, projektweit statisch injiziert (`watchdApp`: `.environment(\.theme, .velvetHour)` + `.preferredColorScheme(.dark)`). Kein ThemeManager, kein Switcher. OKLCH-designed, sRGB-shipped. Design-Kontext: `.impeccable.md`
- **Socket.io**: `socket.io-client-swift` v16.1.1 + `Starscream` v4.0.8 sind unter `watchd/Vendor/` vendored — kein SPM-Schritt nötig. Xcode 16 `PBXFileSystemSynchronizedRootGroup` nimmt neue `.swift`-Dateien automatisch auf

---

## Projektstruktur

```
watchd/docs/
├── apns-end-to-end-setup.md   # Apple-Portal -> Xcode -> Railway -> Device-Test fuer Match-Pushes
└── signing-provisioning.md    # Team ID, Bundle ID, Automatic Signing, Provisioning-Refresh

watchd/watchd/
├── watchdApp.swift       # @main; deep link handling; environment objects: AuthViewModel, NetworkMonitor
├── ContentView.swift     # Root: AuthView (nicht auth) / HomeView (auth); ResetPassword-Sheet
├── AppDelegate.swift     # APNs-Token → hex → POST /users/me/device-token; foreground notifications
├── Config/
│   ├── APIConfig.swift          # Base URLs (Debug: localhost:3000, Release: Railway); #if DEBUG
│   ├── Theme.swift              # struct Theme (kein ThemeID, kein id-Feld) +
│   │                            # einzige Instanz Theme.velvetHour;
│   │                            # ThemeFonts.velvetHour (BluuNext + Manrope)
│   ├── Color+Tokens.swift       # VelvetHourPalette enum + ThemeColors.velvetHour;
│   │                            # sRGB-Hex mit OKLCH-Source-Kommentaren
│   ├── ThemeEnvironment.swift   # @Environment(\.theme) EnvironmentKey + Extension
│   ├── ThemeManager.swift       # Leer-Stub (entfernt — kein Switching mehr nötig)
│   └── FontRegistry.swift       # registerAll() via CTFontManagerRegisterFontsForURL;
│                                # nur BluuNext + Manrope (6 Dateien); loggt fehlende
│                                # Font-Dateien, kein Crash — Fallback auf Systemfonts
├── Models/               # Codable structs (snake_case → camelCase via keyDecodingStrategy)
│   ├── AuthModels.swift  # Auth requests/responses, User struct
│   ├── MovieModels.swift # Movie, StreamingOption, SwipeRequest/Response, MatchInfo
│   ├── RoomModels.swift  # Room, RoomFilters, RoomMember, join/leave/detail responses
│   └── MatchModels.swift # Match, MatchMovie, Favorite, SocketMatchEvent, FavoritesResponse
├── Services/
│   ├── APIService.swift      # actor — thread-safe async/await URLSession; Auto-refresh bei 401
│   │                         # isRefreshing-Flag verhindert parallele Refreshes; Timeout: 30s
│   │                         # URLError.cancelled + Task.isCancelled → CancellationError
│   │                         # (sonst zeigt pull-to-refresh den „Abgebrochen"-Alert)
│   │                         # urlCache = nil + requestCachePolicy =
│   │                         # .reloadIgnoringLocalCacheData — sonst hält URLCache
│   │                         # GET /api/rooms heuristisch stale (Room-Status ändert
│   │                         # sich Socket-seitig ohne Cache-Control-Header)
│   ├── KeychainHelper.swift  # JWT + User-Info Storage via Security framework
│   ├── NetworkMonitor.swift  # @MainActor ObservableObject; NWPathMonitor → @Published isConnected
│   └── SocketService.swift   # @MainActor Singleton; Publishers: matchPublisher,
│                             # filtersUpdatedPublisher, partnerLeftPublisher,
│                             # partnerJoinedPublisher, roomDissolvedPublisher
│                             # Lazy connect — nur beim Betreten der SwipeView
├── ViewModels/
│   ├── AuthViewModel.swift    # Singleton (AuthViewModel.shared); loadSession() aus Keychain;
│   │                          # login, register, guestLogin, upgradeAccount, updateName,
│   │                          # logout, deleteAccount; requestPushPermissionIfNeeded();
│   │                          # setupUnauthorizedListener() reagiert auf 401s
│   ├── HomeViewModel.swift    # loadRooms(), loadArchivedRooms(), createRoom, joinRoom,
│   │                          # selectRoom, updateRoomName, leaveRoom; min 450ms Ladeanimation
│   ├── SwipeViewModel.swift   # fetchFeed(roomId, page) — paginiert (20/page), lazy load bei ≤5
│   │                          # handleDrag + commitSwipe — 100pt Threshold, 0.25s fly-out
│   │                          # Subscriptions: match, filtersUpdated, partnerLeft, roomDissolved
│   │                          # reconnectSocketIfNeeded() beim App-Foreground
│   │                          # Guest-Upgrade-Prompt: zählt Matches in UserDefaults
│   │                          # pro userId (guestMatchesSinceLastPrompt_<userId>),
│   │                          # triggert showUpgradePrompt wenn Gast + Counter ≥3
│   │                          # + letzter Prompt ≥3 Tage her. Per-User-Namespacing
│   │                          # verhindert dass der Zustand eines vorherigen Gast-
│   │                          # Accounts den nächsten auf dem gleichen Gerät blockiert
│   ├── MatchesViewModel.swift # fetchMatches() paginiert; mehr laden bei letzten 5; min 450ms
│   └── FavoritesViewModel.swift # loadFavorites(), toggleFavorite(), removeFavorite(), isFavorite()
│                                 # paginiert; mehr laden bei letzten 5; min 450ms
├── Fonts/                 # OFL-Font-Dateien für Velvet Hour: BluuNext-Bold/-BoldItalic +
│                          # Manrope-Regular/Medium/SemiBold/Bold (6 Dateien, alle im Bundle).
│                          # README.md listet Quellen + erwartete Dateinamen (= PostScript-
│                          # Name). Fehlen Files → Fallback auf Systemfonts, kein Crash
└── Views/
    ├── AuthView.swift             # Login / Register / Guest / Forgot-Password Entry-Screen
    ├── MainTabView.swift          # Auth-Root: 3-Tab-Container (Räume / Favoriten / Profil),
    │                              # pro Tab eigene NavigationStack; UITabBarAppearance wird
    │                              # beim Init + bei Theme-Wechsel getintet. TabBar wird in
    │                              # SwipeView via .toolbar(.hidden, for: .tabBar) versteckt
    ├── RoomsView.swift            # Räume-Tab (ex-HomeView). Editorial-Header („Guten Abend,"
    │                              # + Name in displayHero, dezentes Gast-Caps-Badge).
    │                              # Asymmetrische Room-Rows: Nº-Numeral (display-serif),
    │                              # Raumname (titleMedium), Status-Dot + caps-Meta,
    │                              # Code in tracked-Caps. Menü via contextMenu + swipeActions
    │                              # (kein Gear-Strip mehr). Bottom-CTAs: Coral-primary
    │                              # „Neuen Raum eröffnen" + textlicher „Code eingeben"-Link
    ├── ProfileView.swift          # Profil-Tab (List-basiert): Konto (Name, Email, Guest-
    │                              # Upgrade), Archiv, Rechtliches, Abmelden/Konto-löschen.
    │                              # Kein Design-/Theme-Switcher mehr (Velvet Hour ist fix)
    ├── SwipeView.swift            # Karten-Stack (3 gestaffelt, Back-Cards scale 0.92 / y24
    │                              # / opacity-fade) mit Drag-Gesture, Match-Modal-Trigger.
    │                              # Papier-Lineatur im Hintergrund (Canvas, 44pt-Raster,
    │                              # cream @ 0.04). Toolbar: Raumname + partner-presence
    │                              # („zu zweit" / „wartet auf Partner") statt WATCHD-Logo.
    │                              # Drei differenzierte Action-Buttons (Skip/Merken/Gefällt)
    │                              # mit caps-Labels darunter
    ├── MatchView.swift            # Hero-Moment (ersetzt Konfetti): radialer Accent-Bloom
    │                              # (RadialGradient, scale 0.3→1.25 + opacity-fade, 600ms
    │                              # easeOutExpo) + .success UINotificationFeedbackGenerator
    │                              # + 6-Stufen-Staggered-Reveal (Headline→Subtitle→Poster→
    │                              # Title→Providers→CTAs, je 150ms). Headline „Match." in
    │                              # display-serif italic Accent. Provider als horizontaler
    │                              # ProviderChip-Strip (nicht mehr 3×-Grid). Reduce-Motion:
    │                              # alle Delays auf 0, kein Bloom, nur Opacity-Reveal
    ├── MatchesListView.swift      # Paginiert, watched togglen, Detail-Navigation
    ├── FavoritesListView.swift    # Paginiert, toggleFavorite, Detail-Navigation
    ├── MovieDetailView.swift      # Film-Details editorial: displayHero-Title, Meta-Zeile
    │                              # (Rating·Jahr·Match/Favorit-caps-Badges), Pull-Quote-
    │                              # Overview (2pt Accent-Rule links, italic bodyRegular),
    │                              # Streaming als typografische StreamingListRow-Liste
    │                              # (Icon 32pt + Name + Monetization-caps-Label)
    ├── MovieCardView.swift        # Swipe-Karte: Display-Serif-Title (30pt), Meta-Zeile
    │                              # (Rating · Jahr), Italic-Pull-Quote-Overview (3 Zeilen,
    │                              # tap-to-expand). Overlay-Badges „Gefällt"/„Nein" als
    │                              # dünner caps-Text auf Accent-Rahmen, 3° Rotation
    ├── CreateRoomSheet.swift      # Neuer Room: Name + Filter (Genres, Jahre, Streaming)
    ├── RoomFiltersView.swift      # Filter-Editor für bestehenden Room → Stack neu generieren
    ├── ArchivedRoomsView.swift    # Liste + Hard-Delete archivierter Rooms
    ├── UpgradeAccountView.swift   # Guest → Vollkonto (Email + Password hinzufügen)
    ├── GuestUpgradePromptSheet.swift # Sheet nach N Matches als Gast — "Jetzt sichern" /
    │                                  # "Später"; ruft UpgradeAccountView bei Confirm
    ├── PasswordResetViews.swift   # Forgot-Password-Request + Reset via Deep-Link-Token
    ├── LegalView.swift            # Datenschutz / Impressum / AGB
    ├── NativeTextField.swift      # UIViewRepresentable Wrapper für bessere Keyboard-Handles
    └── SharedComponents.swift     # Wiederverwendbare UI-Bausteine (Buttons, Loader, Empty-States)
```

---

## App-Flow

```
App Launch → ContentView
├── NICHT AUTH → AuthView
│   ├── Login (email + password)
│   ├── Register-Sheet
│   ├── Passwort vergessen → Reset-Mail → deep link → ResetPasswordView
│   └── Guest Login (anonymer dt. Name)
└── AUTH → MainTabView (3 Tabs, jeder mit eigener NavigationStack)
    ├── Tab "Räume" → RoomsView
    │   ├── Room-Karte → SwipeView (TabBar hidden)
    │   │   ├── Karten-Stack (3 Karten, gestaffelt): Drag ±100pt
    │   │   ├── Right-Swipe → Matchmaking → Socket.io match → MatchView Sheet
    │   │   │   └── MatchView: Radial-Bloom + Staggered-Reveal + Streaming-Optionen
    │   │   │       ├── "Weiter swipen" → zurück zur SwipeView
    │   │   │       │   └── (Gast, ≥3 Matches, Cooldown abgelaufen)
    │   │   │       │       → GuestUpgradePromptSheet
    │   │   │       │         ├── "Jetzt sichern" → UpgradeAccountView
    │   │   │       │         └── "Später" → zurück zur SwipeView
    │   │   │       └── "Alle Matches" → MatchesListView
    │   │   ├── Herz-Button (Karte) → Favorit togglen
    │   │   ├── Toolbar-Herz → MatchesListView → MovieDetailView
    │   │   └── Socket Events: partner_joined/left, room_dissolved, filters_updated
    │   ├── Room erstellen → CreateRoomSheet (Name + Filter) → SwipeView
    │   ├── Room beitreten → JoinRoomSheet (6-char Code) → SwipeView
    │   └── Filter bearbeiten → RoomFiltersView → Stack neu generieren
    ├── Tab "Favoriten" → FavoritesListView (global, roomId-entkoppelt) → MovieDetailView
    └── Tab "Profil" → ProfileView
        ├── Konto: Name editieren, Email anzeigen, Guest → "Konto sichern" → UpgradeAccountView
        ├── Archiv → ArchivedRoomsView
        ├── Rechtliches → Datenschutz / Nutzungsbedingungen / Impressum / Datenquellen
        └── Session:
            ├── Abmelden → (Gast: 3-Button-Alert "Konto sichern" | "Trotzdem abmelden" | "Abbrechen")
            └── Konto löschen → Destructive-Alert

Deep Links:
  watchd://join/ROOMCODE              → auto-join (oder Code für Post-Login queuen)
  watchd://reset-password?token=TOKEN → ResetPasswordView Sheet
```

---

## Backend-URL konfigurieren

`watchd/Config/APIConfig.swift` bearbeiten. Es gibt **eine** Base-URL (`backendBaseURL`), aus der `baseURL` / `socketURL` / `iconsBaseURL` computed werden:

```swift
enum APIConfig {
    #if DEBUG
    private static let backendBaseURL = "http://localhost:3000"
    #else
    private static let backendBaseURL = "https://watchd.up.railway.app"
    #endif

    static var baseURL:      String { "\(backendBaseURL)/api" }
    static var socketURL:    String { backendBaseURL }
    static var iconsBaseURL: String { backendBaseURL }
    static let tmdbImageBase = "https://image.tmdb.org/t/p/w780"
}
```

Für Device-Tests im LAN die `localhost`-Zeile auf die Mac-LAN-IP ändern (z. B. `http://192.168.1.42:3000`).

---

## Push Notifications

Kanonische Runbooks:

- `docs/apns-end-to-end-setup.md` fuer Apple Developer Portal -> Railway -> Device-Test
- `docs/signing-provisioning.md` fuer Team ID, Bundle ID, Automatic Signing und Profile-Refresh

### iOS-Setup (einmalig pro Xcode-Projekt)

1. **Push Capability aktivieren** — Target → Signing & Capabilities → `+ Capability` → "Push Notifications". Erzeugt `watchd.entitlements` mit `aps-environment`. **Ohne das schlägt `registerForRemoteNotifications()` lautlos fehl.**
2. **Background Mode "Remote notifications"** aktivieren (falls Silent-Push benötigt)

### Runtime-Flow

`AuthViewModel.requestPushPermissionIfNeeded()` wird nach Login aufgerufen:
- `.authorized` → sofort `registerForRemoteNotifications()` (Token refresh)
- `.notDetermined` → erst Permission-Request, dann registrieren

`AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken` wandelt Token zu Hex und postet an `POST /api/users/me/device-token`.

### APNs Sandbox vs Production

- Debug-Build auf Xcode-Gerät → Backend muss `APNS_PRODUCTION=false` (Sandbox-Endpoint)
- TestFlight / App Store → `APNS_PRODUCTION=true` (Production-Endpoint)
- **Falsche Kombination schlägt lautlos fehl** — keine Fehlermeldung auf Client oder Server

Aktueller Repo-Stand:

- `watchd/watchd/watchd.entitlements` enthält `aps-environment = development`
- `watchd.xcodeproj` nutzt `DEVELOPMENT_TEAM = RNK5A8AP8B`
- Bundle ID ist `com.milinkovic.watchd`

## Signing & Provisioning

- Signing läuft aktuell über `Automatically manage signing`
- Provisioning- und Team-Wechsel sind in `docs/signing-provisioning.md` dokumentiert
- Bei Bundle-ID- oder Team-Wechsel immer danach `docs/apns-end-to-end-setup.md` erneut gegenprüfen

---

## Code-Standards

- Alle `async`-Aufrufe laufen auf `@MainActor` — kein `DispatchQueue.main.async`
- Alle ViewModels sind `@MainActor ObservableObject` mit `@Published` State
- API-Antworten werden mit `keyDecodingStrategy = .convertFromSnakeCase` dekodiert — Model-Properties also camelCase, Backend-Felder snake_case
- Neue `.swift`-Dateien in `watchd/watchd/` werden von Xcode 16 automatisch erfasst — **kein Projektfile-Edit nötig, keinen Drag-to-Project-Schritt**
- Socket.io-Verbindung ist **lazy** — nur beim Betreten einer SwipeView wird connected; beim Verlassen disconnect. Spart Akku + hält Socket-Count niedrig
- **TabBar-Hide in Immersive-Screens** via `.toolbar(.hidden, for: .tabBar)` — aktuell in `SwipeView`. Sheets überlagern die TabBar automatisch, brauchen den Modifier nicht. Neue Immersive-Views explizit ergänzen
- Ladeanimationen haben **min 450 ms Dauer** (HomeViewModel, MatchesViewModel, FavoritesViewModel) — verhindert Flackern bei schnellen Requests
- Min 450 ms und 100 pt Drag-Threshold sind bewusste UX-Werte, nicht zufällig — beim Ändern testen
- Theme-Zugriff in allen Views: `@Environment(\.theme) var theme`, dann `theme.colors.X` / `theme.fonts.X` / `theme.spacing.X` / `theme.motion.X`. Kein ThemeManager, kein Switcher — Theme ist statisch Velvet Hour
- Neue Font-Dateien **nicht** in Info.plist eintragen — Target nutzt `GENERATE_INFOPLIST_FILE = YES`. Stattdessen File-Name in `FontRegistry.bundledFonts` aufnehmen (Name = PostScript-Name); `CTFontManagerRegisterFontsForURL` zieht sie beim App-Launch
- Design-Tokens kommen **ausschließlich** aus dem aktiven Theme — keine hardcoded Farben/Fonts in neuen Views, keine Fonts aus der `reflex_fonts_to_reject`-Liste (Inter, DM Sans, Fraunces, Playfair etc.)
- `toolbarColorScheme` in allen Views hardcoded `.dark` — Velvet Hour ist dauerhaft dark, kein dynamischer Wert nötig

---

## Häufige Fehler vermeiden

- NICHT: Neue Swift-Dateien manuell zum Xcode-Projekt hinzufügen (PBXFileSystemSynchronizedRootGroup erfasst sie automatisch — manuelles Hinzufügen erzeugt Duplikat-Errors)
- NICHT: `APIConfig.swift` hardcoded URLs von `localhost` auf Railway ändern, ohne `#if DEBUG` — sonst funktioniert Dev-Build nicht mehr
- NICHT: Push-Capability vergessen beim neuen Provisioning-Profile — `registerForRemoteNotifications()` schlägt dann lautlos fehl, User kriegt nie Match-Push
- NICHT: Socket.io eager connecten (direkt beim App-Start) — nur beim Betreten der SwipeView, sonst unnötige Connections für User, die gerade nicht swipen
- NICHT: `WatchdTheme.X`-Call-Sites reanimieren — der Shim wurde in Phase 4 gelöscht; alle Views greifen über `@Environment(\.theme)` zu
- NICHT: Konfetti, Partikel-Effekte oder Gamifizierungs-Overlays in `MatchView` reintragen — das kanonische Muster ist radialer Accent-Bloom + staggered Reveal + `.success`-Haptik (Duolingo-Rhythmus, nicht -Optik; siehe `.impeccable.md` §3 Design-Prinzip 5)
- NICHT: Animationen ohne `@Environment(\.accessibilityReduceMotion)`-Gate bauen — Bloom, Stagger und Button-Press müssen bei Reduce-Motion auf Opacity-only fallen
- NICHT: Fonts aus der `reflex_fonts_to_reject`-Liste (Inter, DM Sans, Space Grotesk, Fraunces, Playfair Display, Instrument Sans/Serif etc.) ergänzen — AI-Monokultur, explizit im `impeccable`-Skill verboten
- NICHT: `Info.plist → UIAppFonts` pflegen — Target hat keine Plist-Datei (`GENERATE_INFOPLIST_FILE = YES`); Fonts werden in `FontRegistry.bundledFonts` eingetragen
- IMMER: Nach Models-Änderung checken dass Backend-API tatsächlich die erwartete Response-Shape liefert (siehe Backend-Repo `watchd_backend-mac/CLAUDE.md` → API-Routen)
- IMMER: Diese CLAUDE.md updaten wenn neue Views / ViewModels / Services dazukommen oder umbenannt werden

---

## Zusammenarbeit

- **Mentor-Modus**: Als kritischer, ehrlicher Mentor agieren. Nicht defaultmäßig zustimmen. Schwächen, blinde Flecken und falsche Annahmen aktiv identifizieren
- **Planung zuerst**: Vor Änderungen >~50 Zeilen kurzen Plan vorlegen und Freigabe abwarten
- **Kein Scope-Creep**: Nur das Geforderte — keine Bonus-Refactors, keine ungefragten Kommentare
- **Definition of Done**: Build grün in Xcode + CLAUDE.md aktualisiert + kein neuer Scope eingeschlichen
