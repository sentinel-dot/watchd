# Watchd — iOS App

Tinder-style Movie-Matching-App, iOS-Client. Zwei User swipen in einem gemeinsamen "Room" auf Filme und erhalten eine Match-Benachrichtigung wenn beide denselben Film liken.

> **Backend-Doku**: Diese Datei deckt ausschließlich die iOS-App ab. Backend-Routen, API-Verträge, Socket.io-Events, JWT-Strategie, Env-Vars und Match-Flow-Logik sind im Backend-Repo (`watchd_backend-mac/CLAUDE.md`) dokumentiert.

> **Diese Datei aktuell halten.** Nach jeder Änderung an Views, ViewModels, Services oder Xcode-Setup aktualisieren.

---

## Tech Layer

- **Framework**: SwiftUI (iOS 16+, Xcode 16+)
- **Architektur**: MVVM — alle ViewModels `@MainActor ObservableObject`
- **Netzwerk**: `URLSession` actor (`APIService`), Socket.io (vendored, v16.1.1)
- **Storage**: Keychain (`com.watchd.app`) — Keys: `jwt_token`, `jwt_refresh_token`, `user_id`, `user_name`, `user_email`, `is_guest`
- **Theme**: Netflix-style — Background `#141414`, Primary Red `#E50914`
- **Socket.io**: `socket.io-client-swift` v16.1.1 + `Starscream` v4.0.8 sind unter `watchd/Vendor/` vendored — kein SPM-Schritt nötig. Xcode 16 `PBXFileSystemSynchronizedRootGroup` nimmt neue `.swift`-Dateien automatisch auf

---

## Projektstruktur

```
watchd/watchd/
├── watchdApp.swift       # @main; deep link handling; environment objects: AuthViewModel, NetworkMonitor
├── ContentView.swift     # Root: AuthView (nicht auth) / HomeView (auth); ResetPassword-Sheet
├── AppDelegate.swift     # APNs-Token → hex → POST /users/me/device-token; foreground notifications
├── Config/
│   ├── APIConfig.swift   # Base URLs (Debug: localhost:3000, Release: Railway); #if DEBUG
│   └── WatchdTheme.swift # Design System (Farben, Fonts, Gradients)
├── Models/               # Codable structs (snake_case → camelCase via keyDecodingStrategy)
│   ├── AuthModels.swift  # Auth requests/responses, User struct
│   ├── MovieModels.swift # Movie, StreamingOption, SwipeRequest/Response, MatchInfo
│   ├── RoomModels.swift  # Room, RoomFilters, RoomMember, join/leave/detail responses
│   └── MatchModels.swift # Match, MatchMovie, Favorite, SocketMatchEvent, FavoritesResponse
├── Services/
│   ├── APIService.swift      # actor — thread-safe async/await URLSession; Auto-refresh bei 401
│   │                         # isRefreshing-Flag verhindert parallele Refreshes; Timeout: 30s
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
│   ├── MatchesViewModel.swift # fetchMatches() paginiert; mehr laden bei letzten 5; min 450ms
│   └── FavoritesViewModel.swift # loadFavorites(), toggleFavorite(), removeFavorite(), isFavorite()
│                                 # paginiert; mehr laden bei letzten 5; min 450ms
└── Views/
    ├── AuthView.swift             # Login / Register / Guest / Forgot-Password Entry-Screen
    ├── HomeView.swift             # Room-Liste, Navigation zu Swipe / Archiv / Einstellungen
    ├── SwipeView.swift            # Karten-Stack (3 gestaffelt), Drag-Gesture, Match-Modal-Trigger
    ├── MatchView.swift            # Vollbild-Match mit Konfetti + Streaming-Optionen
    ├── MatchesListView.swift      # Paginiert, watched togglen, Detail-Navigation
    ├── FavoritesListView.swift    # Paginiert, toggleFavorite, Detail-Navigation
    ├── MovieDetailView.swift      # Film-Details + Streaming-Anbieter
    ├── MovieCardView.swift        # Einzelne Swipe-Karte (Poster, Titel, Rating, Herz-Button)
    ├── CreateRoomSheet.swift      # Neuer Room: Name + Filter (Genres, Jahre, Streaming)
    ├── RoomFiltersView.swift      # Filter-Editor für bestehenden Room → Stack neu generieren
    ├── ArchivedRoomsView.swift    # Liste + Hard-Delete archivierter Rooms
    ├── UpgradeAccountView.swift   # Guest → Vollkonto (Email + Password hinzufügen)
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
└── AUTH → HomeView
    ├── Room-Karte → SwipeView
    │   ├── Karten-Stack (3 Karten, gestaffelt): Drag ±100pt
    │   ├── Right-Swipe → Matchmaking → Socket.io match → MatchView Modal
    │   │   └── MatchView: Konfetti + Streaming-Optionen
    │   │       ├── "Weiter swipen" → zurück zur SwipeView
    │   │       └── "Alle Matches" → MatchesListView
    │   ├── Herz-Button (Karte) → Favorit togglen
    │   ├── Toolbar-Herz → MatchesListView → MovieDetailView
    │   └── Socket Events: partner_joined/left, room_dissolved, filters_updated
    ├── Room erstellen → CreateRoomSheet (Name + Filter) → SwipeView
    ├── Room beitreten → JoinRoomSheet (6-char Code) → SwipeView
    ├── Filter bearbeiten → RoomFiltersView → Stack neu generieren
    ├── Favoriten → FavoritesListView → MovieDetailView
    ├── Archivierte Rooms → ArchivedRoomsView
    └── Einstellungen: Name, Upgrade (Guest), Legal, Logout

Deep Links:
  watchd://join/ROOMCODE              → auto-join (oder Code für Post-Login queuen)
  watchd://reset-password?token=TOKEN → ResetPasswordView Sheet
```

---

## Backend-URL konfigurieren

`watchd/Config/APIConfig.swift` bearbeiten:

```swift
enum APIConfig {
    #if DEBUG
    static let baseURL   = "http://192.168.178.31:3000/api"   // lokaler Dev-Server
    static let socketURL = "http://192.168.178.31:3000"
    #else
    static let baseURL   = "https://watchd.up.railway.app/api"
    static let socketURL = "https://watchd.up.railway.app"
    #endif
}
```

---

## Push Notifications

### iOS-Setup (einmalig pro Xcode-Projekt)

1. **Push Capability aktivieren** — Target → Signing & Capabilities → `+ Capability` → "Push Notifications". Erzeugt `watchd.entitlements` mit `aps-environment`. **Ohne das schlägt `registerForRemoteNotifications()` lautlos fehl.**
2. **Background Mode "Remote notifications"** aktivieren (falls Silent-Push benötigt)

### Runtime-Flow

`AuthViewModel.requestPushPermissionIfNeeded()` wird nach Login aufgerufen:
- `.authorized` → sofort `registerForRemoteNotifications()` (Token refresh)
- `.notDetermined` → erst Permission-Request, dann registrieren

`AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken` wandelt Token zu Hex und postet an `POST /api/users/me/device-token`.

### APNs Sandbox vs Production

- Debug-Build auf Xcode-Gerät → Backend muss `APNS_PRODUCTION=false` (Sandbox-Key)
- TestFlight / App Store → `APNS_PRODUCTION=true` (Production-Key)
- **Falsche Kombination schlägt lautlos fehl** — keine Fehlermeldung auf Client oder Server

---

## Code-Standards

- Alle `async`-Aufrufe laufen auf `@MainActor` — kein `DispatchQueue.main.async`
- Alle ViewModels sind `@MainActor ObservableObject` mit `@Published` State
- API-Antworten werden mit `keyDecodingStrategy = .convertFromSnakeCase` dekodiert — Model-Properties also camelCase, Backend-Felder snake_case
- Neue `.swift`-Dateien in `watchd/watchd/` werden von Xcode 16 automatisch erfasst — **kein Projektfile-Edit nötig, keinen Drag-to-Project-Schritt**
- Socket.io-Verbindung ist **lazy** — nur beim Betreten einer SwipeView wird connected; beim Verlassen disconnect. Spart Akku + hält Socket-Count niedrig
- Ladeanimationen haben **min 450 ms Dauer** (HomeViewModel, MatchesViewModel, FavoritesViewModel) — verhindert Flackern bei schnellen Requests
- Min 450 ms und 100 pt Drag-Threshold sind bewusste UX-Werte, nicht zufällig — beim Ändern testen

---

## Häufige Fehler vermeiden

- NICHT: Neue Swift-Dateien manuell zum Xcode-Projekt hinzufügen (PBXFileSystemSynchronizedRootGroup erfasst sie automatisch — manuelles Hinzufügen erzeugt Duplikat-Errors)
- NICHT: `APIConfig.swift` hardcoded URLs von `localhost` auf Railway ändern, ohne `#if DEBUG` — sonst funktioniert Dev-Build nicht mehr
- NICHT: Push-Capability vergessen beim neuen Provisioning-Profile — `registerForRemoteNotifications()` schlägt dann lautlos fehl, User kriegt nie Match-Push
- NICHT: Socket.io eager connecten (direkt beim App-Start) — nur beim Betreten der SwipeView, sonst unnötige Connections für User, die gerade nicht swipen
- IMMER: Nach Models-Änderung checken dass Backend-API tatsächlich die erwartete Response-Shape liefert (siehe Backend-Repo `watchd_backend-mac/CLAUDE.md` → API-Routen)
- IMMER: Diese CLAUDE.md updaten wenn neue Views / ViewModels / Services dazukommen oder umbenannt werden

---

## Zusammenarbeit

- **Mentor-Modus**: Als kritischer, ehrlicher Mentor agieren. Nicht defaultmäßig zustimmen. Schwächen, blinde Flecken und falsche Annahmen aktiv identifizieren
- **Planung zuerst**: Vor Änderungen >~50 Zeilen kurzen Plan vorlegen und Freigabe abwarten
- **Kein Scope-Creep**: Nur das Geforderte — keine Bonus-Refactors, keine ungefragten Kommentare
- **Definition of Done**: Build grün in Xcode + CLAUDE.md aktualisiert + kein neuer Scope eingeschlichen
