import Foundation

@MainActor
final class MatchesViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var hasLoadedOnce = false

    let roomId: Int

    init(roomId: Int) {
        self.roomId = roomId
    }

    func fetchMatches() async {
        let start = ContinuousClock.now
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.getMatches(roomId: roomId)
            matches = response.matches
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
}
