import Foundation

@MainActor
final class MatchesViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var hasLoadedOnce = false

    let partnershipId: Int
    private var currentOffset = 0
    private var hasMore = true
    private var isFetchingMore = false
    private let pageSize = 20

    init(partnershipId: Int) {
        self.partnershipId = partnershipId
    }

    func fetchMatches(animated: Bool = true) async {
        let start = ContinuousClock.now
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        hasMore = true
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.fetchMatchesForPartnership(
                partnershipId: partnershipId,
                limit: pageSize,
                offset: 0
            )
            matches = response.matches
            hasMore = response.pagination?.hasMore ?? false
            currentOffset = response.matches.count
            hasLoadedOnce = true
            if animated {
                let elapsed = ContinuousClock.now - start
                let minDuration: Duration = .milliseconds(450)
                if elapsed < minDuration {
                    try? await Task.sleep(for: minDuration - elapsed)
                }
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

    func loadMoreIfNeeded(currentMatch: Match) async {
        guard hasMore, !isFetchingMore else { return }
        let thresholdIndex = matches.index(matches.endIndex, offsetBy: -5, limitedBy: matches.startIndex) ?? matches.startIndex
        guard let currentIndex = matches.firstIndex(where: { $0.id == currentMatch.id }),
              currentIndex >= thresholdIndex else { return }

        isFetchingMore = true
        defer { isFetchingMore = false }

        do {
            let response = try await APIService.shared.fetchMatchesForPartnership(
                partnershipId: partnershipId,
                limit: pageSize,
                offset: currentOffset
            )
            matches.append(contentsOf: response.matches)
            hasMore = response.pagination?.hasMore ?? false
            currentOffset += response.matches.count
        } catch {
            // Non-critical, will retry on next scroll
        }
    }
}
