import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var currentRoom: Room?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var navigateToSwipe = false
    @Published var joinCode = ""

    func createRoom() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.createRoom()
            currentRoom = response.room
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
            currentRoom = response.room
            joinCode = ""
            navigateToSwipe = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startSwiping() {
        navigateToSwipe = true
    }
}
