# Watchd — iOS App

Tinder-style Movie-Matching-App, iOS-Client. Zwei User adden sich gegenseitig als Partner via Share-Code und swipen gemeinsam auf Filme — bei Übereinstimmung gibt's einen Match (inkl. Streaming-Verfügbarkeit).

> **Backend-Doku**: Diese Datei deckt ausschließlich die iOS-App ab. Backend-Routen, API-Verträge, Socket.io-Events, JWT-Strategie, Env-Vars und Match-Flow-Logik sind im Backend-Repo (`watchd_backend-mac/CLAUDE.md`) dokumentiert.

> **Design-Kontext**: `.impeccable.md` im Repo-Root ist die kanonische Quelle für Zielgruppe, Markenhaltung, Aesthetic-Direction und Design-Prinzipien. Alle Design-Skills (`/impeccable`, `/typeset`, `/layout`, `/colorize`, `/animate`, `/critique`, `/polish`, `/audit`, `/delight`, `/clarify`, `/distill`, `/adapt`, `/quieter`, `/bolder`) lesen diese Datei zuerst. Implementation-Details (Hex-Werte, Font-Dateinamen, Motion-Kurven, Type-Scale) leben im Code unter `watchd/Config/` — `Theme.swift`, `Color+Tokens.swift`, `FontRegistry.swift`.

> **Diese Datei aktuell halten.** Nach jeder Änderung an Views, ViewModels, Services oder Xcode-Setup aktualisieren.

---

## Tech Layer

- **Framework**: SwiftUI (iOS 16+, Xcode 16+)
- **Architektur**: MVVM — alle ViewModels `@MainActor ObservableObject`
- **Netzwerk**: `URLSession` actor (`APIService`), Socket.io (vendored, v16.1.1)
- **Storage**: Keychain (`com.watchd.app`) — Keys: `jwt_token`, `jwt_refresh_token`, `user_id`, `user_name`, `user_email`. (`is_guest` wurde in Phase 6 entfernt; `clearAll` löscht den Legacy-Eintrag aus älteren Installationen mit weg.) Kein UserDefaults für Theme-Wahl mehr — Velvet Hour ist statisch
- **Theme**: Einziges Theme — **Velvet Hour** (cool dark — Base #14101E, Champagne-Accent #D3A26B, Bluu Next Display + Manrope Body). Struct-basiert (`Config/Theme.swift`) mit `@Environment(\.theme)`-Pattern, projektweit statisch injiziert (`watchdApp`: `.environment(\.theme, .velvetHour)` + `.preferredColorScheme(.dark)`). Kein ThemeManager, kein Switcher. OKLCH-designed, sRGB-shipped. Design-Kontext: `.impeccable.md`
- **Socket.io**: `socket.io-client-swift` v16.1.1 + `Starscream` v4.0.8 sind unter `watchd/Vendor/` vendored — kein SPM-Schritt nötig. Xcode 16 `PBXFileSystemSynchronizedRootGroup` nimmt neue `.swift`-Dateien automatisch auf

---

## Projektstruktur

```
watchd/docs/
├── apns-end-to-end-setup.md   # Apple-Portal -> Xcode -> Railway -> Device-Test fuer Match-Pushes
└── signing-provisioning.md    # Team ID, Bundle ID, Automatic Signing, Provisioning-Refresh

watchd/watchd/
├── watchdApp.swift       # @main; deep-link `watchd://reset-password` handler;
│                         # environment objects: AuthViewModel, NetworkMonitor
├── ContentView.swift     # Root: AuthView (nicht auth) / MainTabView (auth); ResetPassword-Sheet
├── AppDelegate.swift     # APNs-Token → hex → POST /users/me/device-token; foreground notifications
├── AppNavigation.swift   # App-interne Navigation-Events + queued Deep-Link/Push-Ziele
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
│   ├── AuthModels.swift          # Auth requests/responses, User struct (isPasswordResettable:
│   │                             # Bool — false für Apple-Only-Accounts, steuert „Passwort
│   │                             # vergessen"-Sichtbarkeit). AppleAuthRequest: identityToken,
│   │                             # nonce, authorizationCode, name
│   ├── MovieModels.swift         # Movie, StreamingOption, SwipeResponse/SwipeInfo, MatchInfo
│   │                             # (SwipeRequest entfernt — APIService nutzt inline struct)
│   ├── PartnershipModels.swift   # Partnership, PartnerUser, PartnershipFilters,
│   │                             # PartnershipsListResponse, PartnershipDetailResponse,
│   │                             # PartnershipFiltersResponse, PartnershipDeletedResponse,
│   │                             # AddPartnerRequest, ShareCodeResponse,
│   │                             # PartnershipRequest/Accepted/EndedSocketEvent.
│   │                             # Felder partner / createdAt / requesterId / addresseeId
│   │                             # bewusst Optional, weil request- und accept-Routes
│   │                             # ohne Timestamps liefern (Backend-Realität)
│   └── MatchModels.swift         # Match (partnershipId statt roomId), MatchMovie, Favorite,
│                                 # SocketMatchEvent, FavoritesResponse
├── Services/
│   ├── APIService.swift      # actor — thread-safe async/await URLSession; Auto-refresh bei 401
│   │                         # isRefreshing-Flag verhindert parallele Refreshes; Timeout: 30s
│   │                         # URLError.cancelled + Task.isCancelled → CancellationError
│   │                         # (sonst zeigt pull-to-refresh den „Abgebrochen"-Alert)
│   │                         # urlCache = nil + requestCachePolicy =
│   │                         # .reloadIgnoringLocalCacheData — sonst cached URLCache
│   │                         # GET-Antworten heuristisch (Partnership-Status ändert
│   │                         # sich Socket-seitig ohne Cache-Control-Header).
│   │                         # 401-Handling: nur bei requiresAuth:true → unauthorizedError-
│   │                         # Notification + Logout. Bei requiresAuth:false (login/register)
│   │                         # fällt 401 durch zum Server-Fehlertext-Parsing — verhindert
│   │                         # „Sitzung abgelaufen"-Meldung bei falschen Credentials.
│   │                         # Auth: login, register, appleSignIn, forgotPassword, resetPassword
│   │                         # Partnership-Methoden: fetchPartnerships,
│   │                         # fetchPartnership, requestPartnership, acceptPartnership,
│   │                         # declinePartnership, cancelPartnershipRequest,
│   │                         # deletePartnership, updatePartnershipFilters,
│   │                         # fetchShareCode, regenerateShareCode,
│   │                         # fetchFeedForPartnership, fetchNextMovieForPartnership,
│   │                         # swipeForPartnership, fetchMatchesForPartnership.
│   │                         # Alte Room-Methoden komplett entfernt (Phase 7).
│   │                         # guestLogin / upgradeAccount in Phase 6 entfernt
│   ├── AppleAuthHelper.swift # Utility: randomNonceString() (SecRandomCopyBytes → URL-safe charset),
│   │                         # sha256(_:) (CryptoKit SHA256 → hex). Nonce-Flow: raw nonce lokal
│   │                         # speichern, SHA256(rawNonce) an Apple senden, rawNonce an Backend
│   ├── KeychainHelper.swift  # JWT + User-Info Storage via Security framework
│   │                         # Keys: jwt_token, jwt_refresh_token, user_id, user_name,
│   │                         # user_email, apple_user_id
│   ├── NetworkMonitor.swift  # @MainActor ObservableObject; NWPathMonitor → @Published isConnected
│   └── SocketService.swift   # @MainActor Singleton.
│                             # Connect-API: connect(token:partnershipId:) (partnershipId
│                             # optional; ohne Wert nur user:<userId>-Channel für
│                             # Request/Accepted-Pushes).
│                             # Publishers: matchPublisher, partnerFiltersUpdatedPublisher
│                             # (PartnershipFilters), partnerLeftPublisher,
│                             # partnerJoinedPublisher, partnershipRequestPublisher,
│                             # partnershipAcceptedPublisher, partnershipEndedPublisher.
│                             # Lifecycle: connect() bei Login/Session-Restore (AuthViewModel);
│                             # disconnect() bei Logout/deleteAccount/unauthorizedError.
│                             # SwipeView upgraded auf user+partnership Channel (partnershipId).
│                             # Reconnect bei App-Foreground via SwipeViewModel.reconnectSocketIfNeeded()
├── ViewModels/
│   ├── AuthViewModel.swift       # Singleton (AuthViewModel.shared); loadSession() aus Keychain;
│   │                             # login, register, signInWithApple, updateName, logout, deleteAccount;
│   │                             # requestPushPermissionIfNeeded();
│   │                             # setupUnauthorizedListener() reagiert auf 401s.
│   │                             # Socket-Lifecycle: connect() in loadSession() + persistSession();
│   │                             # disconnect() in logout() + deleteAccount() + handleUnauthorized().
│   │                             # Phase 6: guestLogin / upgradeAccount entfernt (Gast-Zugang weg)
│   ├── PartnersViewModel.swift   # loadPartnerships() liefert {incoming, outgoing, active};
│   │                             # acceptRequest / declineRequest / cancelRequest /
│   │                             # deletePartnership / updateFilters mit optimistic update;
│   │                             # subscribt partnershipRequest / partnershipAccepted /
│   │                             # partnershipEnded; min 450ms Ladeanimation (animated:false
│   │                             # für Socket-Refreshes). Ersetzt HomeViewModel
│   ├── AddPartnerViewModel.swift # Code-Eingabe-Sheet: codeInput normalisiert (uppercase,
│   │                             # Crockford-Base32 strip, max 8 Zeichen) via
│   │                             # AddPartnerViewModel.normalize(...); submit(onSuccess:) ruft
│   │                             # requestPartnership und liefert die neue Partnership zurück
│   ├── SwipeViewModel.swift      # init(partnership:), fetchFeed(afterPosition) — paginiert
│   │                             # (20/page), lazy load bei ≤5; handleDrag + commitSwipe —
│   │                             # 100pt Threshold, 0.25s fly-out;
│   │                             # Subscriptions: match, partnerFiltersUpdated, partnerLeft,
│   │                             # partnershipEnded; reconnectSocketIfNeeded() beim
│   │                             # App-Foreground. Phase 6: Guest-Upgrade-Prompt komplett raus
│   ├── MatchesViewModel.swift    # init(partnershipId:); fetchMatches(animated:) paginiert; mehr
│   │                             # laden bei letzten 5; min 450ms nur bei animated:true (initial)
│   └── FavoritesViewModel.swift  # loadFavorites(animated:), toggleFavorite(), removeFavorite(),
│                                  # isFavorite(); paginiert; mehr laden bei letzten 5;
│                                  # min 450ms nur bei animated:true (initial)
├── Fonts/                 # OFL-Font-Dateien für Velvet Hour: BluuNext-Bold/-BoldItalic +
│                          # Manrope-Regular/Medium/SemiBold/Bold (6 Dateien, alle im Bundle).
│                          # README.md listet Quellen + erwartete Dateinamen (= PostScript-
│                          # Name). Fehlen Files → Fallback auf Systemfonts, kein Crash
└── Views/
    ├── AuthView.swift             # Premium Auth-Landing im Velvet-Hour-Stil. Oben: natives
    │                              # SwiftUI-Logo (BluuNext Bold „W" weiß + „atchd" Accent,
    │                              # 76/50pt, kein PNG). Darunter: rotierendes Hero-Wort
    │                              # (Zu zweit/Swipen/Match finden/Filmabend) in BluuNext 46pt.
    │                              # AuthActionDock: echter SignInWithAppleButton (Phase 9 aktiv,
    │                              # nonce-Flow via AppleAuthHelper, ASAuthorizationAppleIDCredential),
    │                              # Google-Button zeigt „Noch nicht verfügbar"-Alert (Phase 10).
    │                              # Login/Register als Sheets ohne Nº-Labels und ohne Italic-Titel.
    │                              # AuthField: persistente Label-Zeile, Passwort-Placeholder
    │                              # „••••••••", E-Mail-Placeholder „deine@email.de", iOS-semantic
    │                              # textContentTypes, Accessibility-Hints.
    │                              # LoginSheetView + RegisterView: .onAppear löscht
    │                              # authVM.errorMessage — verhindert Fehler-Bleeding zwischen
    │                              # Sheets (z. B. Login-Fehler erscheint im Register-Sheet)
    ├── MainTabView.swift          # Auth-Root: 3-Tab-Container (Partner / Favoriten / Profil),
    │                              # pro Tab eigene NavigationStack; UITabBarAppearance getintet.
    │                              # TabBar wird in SwipeView via .toolbar(.hidden, for: .tabBar)
    │                              # versteckt
    ├── PartnersView.swift         # Partners-Tab (ersetzt RoomsView). Section-List:
    │                              # • Eingehende Anfragen (cond, max 3 + Overflow-Link)
    │                              # • Partner (immer, max 3 + Overflow-Link, Empty-State)
    │                              # • Ausstehend (cond, gedimmt, max 3 + Overflow-Link)
    │                              # Bottom-CTA „Partner hinzufügen" → AddPartnerSheet.
    │                              # PartnerCard: contextMenu + swipeActions (Filter ändern /
    │                              # Partner entfernen) + Confirm-Alert
    ├── AddPartnerSheet.swift      # Code-Eingabe-Sheet: NativeTextField mit AddPartnerVM-
    │                              # Normalisierung (uppercase + Crockford-Filter + 8-char-Trim),
    │                              # primary „Anfrage senden" — disabled bis Code 8 Zeichen
    ├── PartnerFiltersView.swift   # Filter-Editor (Genres, Jahre, Streaming, Rating, Laufzeit).
    │                              # Toolbar-Title = Partner-Name. Enthält
    │                              # PartnershipFilterOptionsView, GenreOption, StreamingService.
    │                              # API: PATCH /partnerships/:id/filters → Stack-Regen
    ├── PendingRequestsView.swift  # Overflow: alle eingehenden Anfragen (Accept/Decline pro Row)
    ├── OutgoingRequestsView.swift # Overflow: alle ausgehenden Anfragen (Cancel pro Row)
    ├── AllPartnersView.swift      # Overflow: alle aktiven Partner (Tap → SwipeView,
    │                              # contextMenu + swipeActions analog PartnersView)
    ├── ProfileView.swift          # Profil-Tab (List-basiert): Konto (Name, Email),
    │                              # Dein Code (Mono-Display, Copy-Button, Code-erneuern mit
    │                              # Confirm-Alert), Rechtliches, Abmelden, Konto löschen.
    │                              # Kein Archiv mehr, kein Guest-Upgrade mehr
    ├── SwipeView.swift            # init(partnership:). Karten-Stack mit Drag-Gesture,
    │                              # Match-Modal-Trigger. Toolbar: Partner-Name + „zu zweit"-
    │                              # caps-Label. Drei Action-Buttons (Skip/Merken/Gefällt).
    │                              # Alerts: partnerLeft („Partner offline"), partnershipEnded
    │                              # („Partnerschaft beendet" → dismiss). Kein Guest-Upgrade
    │                              # mehr
    ├── MatchView.swift            # Hero-Moment: radialer Accent-Bloom + 6-Stufen-Staggered-
    │                              # Reveal + .success-Haptik. CTAs: „Weiter schauen" + „Alle
    │                              # Matches" (NavigationLink zu MatchesListView mit
    │                              # partnershipId)
    ├── MatchesListView.swift      # init(partnershipId:). Paginiert, watched togglen,
    │                              # Detail-Navigation
    ├── FavoritesListView.swift    # Paginiert, toggleFavorite, Detail-Navigation
    ├── MovieDetailView.swift      # Film-Details editorial: displayHero-Title, Meta-Zeile,
    │                              # Pull-Quote-Overview, Streaming als StreamingListRow
    ├── MovieCardView.swift        # Swipe-Karte: Display-Serif-Title, Meta-Zeile,
    │                              # Italic-Pull-Quote-Overview (3 Zeilen, tap-to-expand),
    │                              # Overlay-Badges „Gefällt"/„Nein"
    ├── PasswordResetViews.swift   # Forgot-Password-Request + Reset via Deep-Link-Token
    ├── LegalView.swift            # Datenschutz / Impressum / AGB
    ├── NativeTextField.swift      # UIViewRepresentable Wrapper für bessere Keyboard-Handles
    ├── KeyboardWarmupView.swift   # UIViewRepresentable — primeIfNeeded() reduziert First-Tap-Lag
    └── SharedComponents.swift     # Wiederverwendbare UI-Bausteine (Buttons, Loader,
                                   # Empty-States, OfflineBanner, PrimaryButton)
```

---

## App-Flow

```
App Launch → ContentView
├── NICHT AUTH → AuthView
│   ├── Premium Landing: natives Watchd-Logo oben (BluuNext) + rotierendes Hero-Wort + Apple Sign-In (aktiv) + Google-Dock (Phase 10)
│   ├── Anmelden-Sheet (email + password)
│   ├── Registrieren-Sheet
│   └── Passwort vergessen → Reset-Mail → deep link → ResetPasswordView
└── AUTH → MainTabView (3 Tabs, jeder mit eigener NavigationStack)
    ├── Tab "Partner" → PartnersView (Section-List)
    │   ├── Eingehende Anfragen → Accept (→ active) / Decline / Overflow → PendingRequestsView
    │   ├── Partner-Karte (active) → SwipeView(partnership:) (TabBar hidden)
    │   │   ├── Karten-Stack (3 Karten, gestaffelt): Drag ±100pt
    │   │   ├── Right-Swipe → Matchmaking → Socket.io match → MatchView Sheet
    │   │   │   └── MatchView: Radial-Bloom + Staggered-Reveal + Streaming-Optionen
    │   │   │       ├── "Weiter schauen" → zurück zur SwipeView
    │   │   │       └── "Alle Matches" → MatchesListView
    │   │   ├── Herz-Button (Karte) → Favorit togglen
    │   │   ├── Toolbar-Herz → MatchesListView → MovieDetailView
    │   │   └── Socket Events: partner_joined/left, partnership_ended, filters_updated
    │   ├── ContextMenu/SwipeActions: Filter ändern → PartnerFiltersView,
    │   │                              Partner entfernen → Confirm-Alert
    │   ├── Ausstehende Anfragen (gedimmt) → Cancel / Overflow → OutgoingRequestsView
    │   ├── Bottom-CTA „Partner hinzufügen" → AddPartnerSheet (Code-Eingabe)
    │   └── Overflow „Alle Partner" → AllPartnersView
    ├── Tab "Favoriten" → FavoritesListView (global, partnership-entkoppelt) → MovieDetailView
    └── Tab "Profil" → ProfileView
        ├── Konto: Name editieren, Email anzeigen
        ├── Dein Code: 8-stelliger Code, Copy-Button, Code erneuern (Confirm-Alert)
        ├── Rechtliches: Datenschutz / Nutzungsbedingungen / Impressum / Datenquellen
        └── Session: Abmelden | Konto löschen (Destructive-Alert)

Deep Links:
  watchd://reset-password?token=TOKEN → ResetPasswordView Sheet
  watchd://add/CODE → AddPartnerSheet mit Code-Prefill; queued bis nach Login
  https://watchd.up.railway.app/add/CODE → Universal Link auf denselben Add-Partner-Flow
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
- Socket.io-Verbindung ist an den **Auth-Lifecycle** gebunden — `connect()` in `AuthViewModel.loadSession()` und `persistSession()` (Login/Register), `disconnect()` in `logout()`, `deleteAccount()`, `handleUnauthorized()`. Damit sind Partnership-Events (Request, Accepted, Ended) immer erreichbar, egal auf welchem Tab. SwipeView upgraded auf user+partnership-Channel via `SwipeViewModel.startSocket()` — beim Verlassen der SwipeView bleibt der user-Channel aktiv
- **TabBar-Hide in Immersive-Screens** via `.toolbar(.hidden, for: .tabBar)` — aktuell in `SwipeView`. Sheets überlagern die TabBar automatisch, brauchen den Modifier nicht. Neue Immersive-Views explizit ergänzen
- Ladeanimationen haben **min 450 ms Dauer beim initialen Load** (PartnersViewModel, MatchesViewModel, FavoritesViewModel) — verhindert Flackern. Pull-to-Refresh übergibt `animated: false` und überspringt die Mindestdauer; iOS-native Spinner hat eigene ~300 ms Dismiss-Animation
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
- NICHT: Socket-Verbindung in View-`onAppear` oder `task` managen — Lifecycle gehört in `AuthViewModel`, nicht in Views oder ViewModels außer `SwipeViewModel` (der den partnership-Channel braucht)
- NICHT: `WatchdTheme.X`-Call-Sites reanimieren — der Shim wurde in Phase 4 gelöscht; alle Views greifen über `@Environment(\.theme)` zu
- NICHT: Konfetti, Partikel-Effekte oder Gamifizierungs-Overlays in `MatchView` reintragen — das kanonische Muster ist radialer Accent-Bloom + staggered Reveal + `.success`-Haptik (Duolingo-Rhythmus, nicht -Optik; siehe `.impeccable.md` §3 Design-Prinzip 5)
- NICHT: Animationen ohne `@Environment(\.accessibilityReduceMotion)`-Gate bauen — Bloom, Stagger und Button-Press müssen bei Reduce-Motion auf Opacity-only fallen
- NICHT: Fonts aus der `reflex_fonts_to_reject`-Liste (Inter, DM Sans, Space Grotesk, Fraunces, Playfair Display, Instrument Sans/Serif etc.) ergänzen — AI-Monokultur, explizit im `impeccable`-Skill verboten
- NICHT: `Info.plist → UIAppFonts` pflegen — Target hat keine Plist-Datei (`GENERATE_INFOPLIST_FILE = YES`); Fonts werden in `FontRegistry.bundledFonts` eingetragen
- IMMER: Nach Models-Änderung checken dass Backend-API tatsächlich die erwartete Response-Shape liefert (siehe Backend-Repo `watchd_backend-mac/CLAUDE.md` → API-Routen)
- IMMER: Diese CLAUDE.md updaten wenn neue Views / ViewModels / Services dazukommen oder umbenannt werden

---

## Offene Punkte

| Status        | Thema                                                                                                                                                                                                  |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **in Arbeit** | Partnerships-Refactor: Rooms → persistente Partnerschaften, Gast-Zugang weg, Share-Codes mit Double-Opt-In, Apple Sign-In. Plan + Phasen im Parent-Repo `docs/partnerships-refactor-plan.md`. Branch: `refactor/partnerships`. **Phasen 5–9 fertig** (Phase 9 am 2026-05-03): Apple Sign-In implementiert — Backend: `POST /api/auth/apple` (JWT-Verify, 3-step find-or-create, Auth-Code-Exchange für apple_refresh_token, fire-and-forget Revocation bei delete-account); iOS: `AppleAuthHelper` (nonce + SHA256), `AppleAuthRequest`, `APIService.appleSignIn`, `AuthViewModel.signInWithApple`, echter `SignInWithAppleButton` in `AuthActionDock`. 127/127 Tests grün. Phase 10 (Google Sign-In) als nächstes. |

---

## Zusammenarbeit

- **Mentor-Modus**: Als kritischer, ehrlicher Mentor agieren. Nicht defaultmäßig zustimmen. Schwächen, blinde Flecken und falsche Annahmen aktiv identifizieren
- **Planung zuerst**: Vor Änderungen >~50 Zeilen kurzen Plan vorlegen und Freigabe abwarten
- **Kein Scope-Creep**: Nur das Geforderte — keine Bonus-Refactors, keine ungefragten Kommentare
- **Definition of Done**: Build grün in Xcode + CLAUDE.md aktualisiert + kein neuer Scope eingeschlichen
