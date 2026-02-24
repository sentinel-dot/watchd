import Foundation

@MainActor
final class MatchesViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    let roomId: Int

    init(roomId: Int) {
        self.roomId = roomId
    }

    func fetchMatches() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.getMatches(roomId: roomId)
            matches = response.matches
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
