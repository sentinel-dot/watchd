# Watchd — iOS App

A native SwiftUI app where two users swipe on movies Tinder-style and get a match notification (with streaming availability) when they both like the same film.

---

## Requirements

- Xcode 16+
- iOS 16+ deployment target
- A running instance of the Watchd backend

---

## Project Structure

```
watchd/
├── watchdApp.swift              # @main entry point, deep link handling
├── ContentView.swift            # Root: AuthView / HomeView switch
├── AppDelegate.swift            # APNs device-token registration
├── watchd.entitlements          # aps-environment, associated-domains
├── Vendor/                      # socket.io-client-swift 16.1.1 + Starscream 4.0.8
├── Config/
│   ├── APIConfig.swift          # Base URLs — edit here to change backend
│   └── WatchdTheme.swift        # Design system (colors, fonts, gradients)
├── Models/
│   ├── AuthModels.swift
│   ├── RoomModels.swift
│   ├── MovieModels.swift
│   └── MatchModels.swift
├── Services/
│   ├── APIService.swift         # URLSession async/await wrapper (actor)
│   ├── SocketService.swift      # Socket.io real-time match events
│   ├── KeychainHelper.swift     # JWT + user info storage
│   └── NetworkMonitor.swift     # NWPathMonitor online/offline state
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── HomeViewModel.swift
│   ├── SwipeViewModel.swift
│   ├── MatchesViewModel.swift
│   └── FavoritesViewModel.swift
└── Views/
    ├── AuthView.swift              # Login / Register / Guest / Forgot-Password
    ├── HomeView.swift              # Rooms list, create / join navigation
    ├── SwipeView.swift             # Main swipe screen (card stack)
    ├── MovieCardView.swift         # Individual draggable card
    ├── MatchView.swift             # Match modal + confetti + streaming
    ├── MatchesListView.swift       # All matches for the room
    ├── FavoritesListView.swift     # Favorited matches
    ├── MovieDetailView.swift       # Full movie detail + streaming info
    ├── CreateRoomSheet.swift       # New room: name + filters
    ├── RoomFiltersView.swift       # Edit filters on existing room
    ├── ArchivedRoomsView.swift     # Dissolved rooms, hard-delete
    ├── UpgradeAccountView.swift    # Guest → full account
    ├── GuestUpgradePromptSheet.swift # Prompt after N matches as guest
    ├── PasswordResetViews.swift    # Forgot + reset via deep-link token
    ├── LegalView.swift             # Privacy / imprint / terms
    ├── NativeTextField.swift       # UITextField wrapper
    └── SharedComponents.swift      # Reusable buttons, loaders, empty-states
```

---

## Changing the Backend URL

Debug-builds hit `http://localhost:3000`, release-builds (TestFlight / App Store) hit the Railway URL. Open `watchd/Config/APIConfig.swift` and update `backendBaseURL` — the computed `baseURL` / `socketURL` / `iconsBaseURL` derive from it automatically:

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

For device tests over LAN, replace `localhost` with your Mac's LAN IP (e.g. `http://192.168.1.42:3000`) in the `#if DEBUG` branch.

---

## First-time Setup in Xcode

### 1. Open the project

```bash
open watchd.xcodeproj
```

### 2. Socket.io — vendored source (no SPM step needed)

`socket.io-client-swift` (v16.1.1) and its dependency `Starscream` (v4.0.8) are vendored directly under `watchd/Vendor/`. Xcode 16's `PBXFileSystemSynchronizedRootGroup` picks them up automatically — **no SPM resolution step is required**. Just build and run.

### 3. Select a simulator or device

Choose an iPhone simulator (iOS 16+) or a connected device from the scheme selector.

### 4. Build & Run

Press **⌘R**.

---

## App Flow

```
AuthView (Login / Register / Guest / Forgot-Password)
    └── HomeView
            ├── Create Room → CreateRoomSheet (name + filters)
            │       └── "Start Swiping" → SwipeView
            ├── Join Room  → enter 6-char code → SwipeView
            ├── Edit filters → RoomFiltersView → stack regenerated
            ├── Favorites → FavoritesListView → MovieDetailView
            ├── Archived rooms → ArchivedRoomsView
            └── Settings: name, upgrade (guest), legal, logout
                                    │
SwipeView
    ├── Swipe right/left on movie cards (100pt threshold)
    ├── Socket events: match, partner_joined/left, room_dissolved, filters_updated
    ├── MatchView modal (confetti + streaming)
    │       ├── "Keep swiping" → back to SwipeView
    │       │       └── (guest, ≥3 matches, cooldown)
    │       │           → GuestUpgradePromptSheet → UpgradeAccountView
    │       └── "All matches" → MatchesListView → MovieDetailView
    └── Heart button → toggle favorite

Deep links:
  watchd://join/ROOMCODE              → auto-join room
  watchd://reset-password?token=TOKEN → ResetPasswordView sheet
```

For the full Xcode / signing / APNs setup see [`CLAUDE.md`](./CLAUDE.md) and [`docs/`](./docs/).

---

## Architecture

**MVVM** with Combine for reactive state:

| Layer | Responsibility |
|-------|---------------|
| `Models/` | `Codable` structs matching the REST API |
| `Services/APIService` | Typed async/await requests, auth header injection, error mapping |
| `Services/SocketService` | Socket.io lifecycle, `matchPublisher` PassthroughSubject |
| `Services/KeychainHelper` | Secure JWT storage via Security framework |
| `ViewModels/` | `@MainActor ObservableObject` with `@Published` state |
| `Views/` | Pure SwiftUI, no business logic |

---

## Notes

- The JWT token is stored in the device Keychain and injected automatically into every protected API request.
- The app uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16+) — any new `.swift` files added inside `watchd/` are compiled automatically without touching the project file.
- Swipe cards use `.animation(.interactiveSpring())` for a natural feel, with a 100 pt drag threshold.
- Confetti in the match modal is rendered with `Canvas` + `TimelineView` — no third-party libraries needed.
