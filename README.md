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
├── Config/
│   └── APIConfig.swift          # Base URLs — edit here to change backend
├── Models/
│   ├── AuthModels.swift
│   ├── RoomModels.swift
│   ├── MovieModels.swift
│   └── MatchModels.swift
├── Services/
│   ├── APIService.swift         # URLSession async/await wrapper
│   ├── SocketService.swift      # Socket.io real-time match events
│   └── KeychainHelper.swift     # JWT token storage
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── HomeViewModel.swift
│   ├── SwipeViewModel.swift
│   └── MatchesViewModel.swift
└── Views/
    ├── AuthView.swift           # Login / Register
    ├── HomeView.swift           # Create / Join room
    ├── SwipeView.swift          # Main swipe screen
    ├── MovieCardView.swift      # Individual draggable card
    ├── MatchView.swift          # Match modal + confetti
    ├── MatchesListView.swift    # All matches for the room
    └── MovieDetailView.swift    # Full movie detail + streaming info
```

---

## Changing the Backend URL

Open `watchd/Config/APIConfig.swift` and update the two constants:

```swift
enum APIConfig {
    static let baseURL  = "http://192.168.178.31:3000/api"   // REST API
    static let socketURL = "http://192.168.178.31:3000"       // Socket.io
}
```

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
AuthView (Login / Register)
    └── HomeView
            ├── Create Room → shows 6-char invite code card (copy / share)
            │       └── "Start Swiping" → SwipeView
            └── Join Room  → enter friend's code → SwipeView
                                    │
                                    ├── Swipe right/left on movie cards
                                    ├── Socket listens for "match" events
                                    ├── MatchView modal (confetti + streaming)
                                    └── MatchesListView → MovieDetailView
```

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
