import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [Favorite] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var hasLoadedOnce = false

    private var currentOffset = 0
    private var hasMore = true
    private var isFetchingMore = false
    private let pageSize = 20

    func loadFavorites(animated: Bool = true) async {
        let start = ContinuousClock.now
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        hasMore = true
        defer { isLoading = false }
        do {
            let response = try await APIService.shared.getFavorites(limit: pageSize, offset: 0)
            favorites = response.favorites
            hasMore = response.pagination?.hasMore ?? false
            currentOffset = response.favorites.count
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

    func loadMoreIfNeeded(currentFavorite: Favorite) async {
        guard hasMore, !isFetchingMore else { return }
        let thresholdIndex = favorites.index(favorites.endIndex, offsetBy: -5, limitedBy: favorites.startIndex) ?? favorites.startIndex
        guard let currentIndex = favorites.firstIndex(where: { $0.id == currentFavorite.id }),
              currentIndex >= thresholdIndex else { return }

        isFetchingMore = true
        defer { isFetchingMore = false }

        do {
            let response = try await APIService.shared.getFavorites(limit: pageSize, offset: currentOffset)
            favorites.append(contentsOf: response.favorites)
            hasMore = response.pagination?.hasMore ?? false
            currentOffset += response.favorites.count
        } catch {
            // Non-critical, will retry on next scroll
        }
    }

    func toggleFavorite(movieId: Int) async {
        do {
            if favorites.contains(where: { $0.movie.id == movieId }) {
                let _ = try await APIService.shared.removeFavorite(movieId: movieId)
                favorites.removeAll { $0.movie.id == movieId }
            } else {
                let _ = try await APIService.shared.addFavorite(movieId: movieId)
                await loadFavorites()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func removeFavorite(movieId: Int) async {
        do {
            let _ = try await APIService.shared.removeFavorite(movieId: movieId)
            favorites.removeAll { $0.movie.id == movieId }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func isFavorite(movieId: Int) -> Bool {
        favorites.contains { $0.movie.id == movieId }
    }
}
