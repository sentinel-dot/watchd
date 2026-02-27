import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var rooms: [Room] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var navigateToSwipe = false
    @Published var selectedRoom: Room?
    @Published var joinCode = ""
    @Published var showUpgradeAccount = false
    @Published var showCreateRoomSheet = false
    @Published var newRoomFilters: RoomFilters?
    @Published var newRoomName: String = ""
    @Published var roomToEdit: Room?
    @Published var showFiltersForRoom: Room?
    @Published var showLeaveConfirmation = false
    @Published var roomToLeave: Room?
    @Published var roomToRename: Room?
    @Published var renameRoomName: String = ""
    @Published var hasLoadedOnce = false

    init() {
        setupDeepLinkListener()
    }
    
    private func setupDeepLinkListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("joinRoomFromDeepLink"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let code = notification.userInfo?["code"] as? String {
                self?.joinCode = code
                Task { await self?.joinRoom() }
            }
        }
    }
    
    func loadRooms() async {
        let start = ContinuousClock.now
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let response = try await APIService.shared.getRooms()
            rooms = response.rooms.filter { $0.status != "dissolved" }
            hasLoadedOnce = true
            let elapsed = ContinuousClock.now - start
            let minDuration: Duration = .milliseconds(450)
            if elapsed < minDuration {
                try? await Task.sleep(for: minDuration - elapsed)
            }
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            hasLoadedOnce = true
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func loadArchivedRooms() async -> [Room] {
        do {
            let response = try await APIService.shared.getRooms()
            return response.rooms.filter { $0.status == "dissolved" }
        } catch {
            return []
        }
    }

    func createRoom(name: String? = nil, filters: RoomFilters? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let roomName = name?.isEmpty == false ? name : nil
            let response = try await APIService.shared.createRoom(name: roomName, filters: filters)
            await loadRooms()
            // Don't navigate to swipe view automatically
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func joinRoom() async {
        let trimmed = joinCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else {
            errorMessage = "Bitte gib einen Einladungscode ein."
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.joinRoom(code: trimmed)
            await loadRooms()
            selectedRoom = response.room
            joinCode = ""
            navigateToSwipe = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectRoom(_ room: Room) {
        selectedRoom = room
        navigateToSwipe = true
    }
    
    func updateRoomName(roomId: Int, name: String) async {
        errorMessage = nil
        do {
            _ = try await APIService.shared.updateRoomName(roomId: roomId, name: name)
            await loadRooms()
            roomToRename = nil
            renameRoomName = ""
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func leaveRoom(_ room: Room) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let response = try await APIService.shared.leaveRoom(roomId: room.id)
            await loadRooms()
            
            if response.lastMember {
                // Room was dissolved
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
