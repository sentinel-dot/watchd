import Foundation
import Combine
import SwiftUI

@MainActor
final class SwipeViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var dragOffset: CGSize = .zero
    @Published var currentMatch: SocketMatchEvent?
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var swipeCount = 0
    @Published var partnerLeft = false
    @Published var partnershipEnded = false

    let partnership: Partnership
    private var lastPosition = 0
    private var isFetching = false
    private var hasMorePages = true
    private var cancellables = Set<AnyCancellable>()

    init(partnership: Partnership) {
        self.partnership = partnership

        SocketService.shared.matchPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.currentMatch = event
            }
            .store(in: &cancellables)

        SocketService.shared.partnerFiltersUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    self.movies.removeAll()
                    self.lastPosition = 0
                    self.hasMorePages = true
                    await self.fetchFeed()
                }
            }
            .store(in: &cancellables)

        SocketService.shared.partnerLeftPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.partnerLeft = true
            }
            .store(in: &cancellables)

        SocketService.shared.partnershipEndedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] partnershipId in
                guard let self = self, self.partnership.id == partnershipId else { return }
                self.partnershipEnded = true
            }
            .store(in: &cancellables)
    }

    // MARK: - Socket

    func startSocket() {
        guard let token = KeychainHelper.load(forKey: KeychainHelper.tokenKey) else { return }
        SocketService.shared.connect(token: token, partnershipId: partnership.id)
    }

    func reconnectSocketIfNeeded() {
        guard let token = KeychainHelper.load(forKey: KeychainHelper.tokenKey) else { return }
        if !SocketService.shared.isConnected {
            SocketService.shared.connect(token: token, partnershipId: partnership.id)
        }
    }

    // MARK: - Feed

    func fetchFeed() async {
        guard !isFetching, hasMorePages else { return }
        isFetching = true
        if movies.isEmpty { isLoading = true }
        defer { isFetching = false; isLoading = false }

        do {
            let response = try await APIService.shared.fetchFeedForPartnership(
                partnershipId: partnership.id,
                afterPosition: lastPosition
            )
            movies.append(contentsOf: response.movies)
            if response.movies.isEmpty {
                hasMorePages = false
            } else {
                lastPosition = response.lastPosition
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Swiping

    func handleDragChange(_ translation: CGSize) {
        dragOffset = translation
    }

    func handleDragEnd(_ translation: CGSize) async {
        let threshold: CGFloat = 100
        if translation.width > threshold {
            await commitSwipe(direction: "right")
        } else if translation.width < -threshold {
            await commitSwipe(direction: "left")
        } else {
            withAnimation(.interactiveSpring()) {
                dragOffset = .zero
            }
        }
    }

    private func commitSwipe(direction: String) async {
        guard let movie = movies.first else { return }
        let swipedId = movie.id
        let animationDuration: TimeInterval = 0.25

        let flyX: CGFloat = direction == "right" ? 600 : -600
        withAnimation(.easeOut(duration: animationDuration)) {
            dragOffset = CGSize(width: flyX, height: 50)
        }

        if direction == "right" {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        let swipeStarted = Date()

        do {
            let response = try await APIService.shared.swipeForPartnership(
                movieId: swipedId,
                partnershipId: partnership.id,
                direction: direction
            )

            let remaining = animationDuration - Date().timeIntervalSince(swipeStarted)
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }

            movies.removeFirst()
            dragOffset = .zero
            swipeCount += 1

            if let match = response.match, match.isMatch, currentMatch == nil {
                currentMatch = SocketMatchEvent(
                    movieId: match.movieId ?? swipedId,
                    movieTitle: match.movieTitle ?? "",
                    posterPath: match.posterPath,
                    streamingOptions: match.streamingOptions ?? []
                )
            }

            if movies.count <= 5 {
                Task { await fetchNextPage() }
            }
        } catch {
            withAnimation(.interactiveSpring()) {
                dragOffset = .zero
            }
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func fetchNextPage() async {
        await fetchFeed()
    }
}
