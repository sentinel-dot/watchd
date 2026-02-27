import Foundation
import Combine
import SwiftUI

@MainActor
final class SwipeViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var dragOffset: CGSize = .zero
    @Published var currentMatch: SocketMatchEvent?
    @Published var roomMembers: [RoomMember] = []
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var swipeCount = 0

    let room: Room
    private var currentPage = 1
    private var isFetching = false
    private var hasMorePages = true
    private var cancellables = Set<AnyCancellable>()

    init(room: Room) {
        self.room = room
        
        SocketService.shared.matchPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.currentMatch = event
            }
            .store(in: &cancellables)
        
        SocketService.shared.filtersUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    self.movies.removeAll()
                    self.currentPage = 1
                    self.hasMorePages = true
                    await self.fetchFeed()
                }
            }
            .store(in: &cancellables)
        
        SocketService.shared.partnerLeftPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Partner has left - could show a notification
            }
            .store(in: &cancellables)
        
        SocketService.shared.roomDissolvedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomId in
                guard let self = self, self.room.id == roomId else { return }
                // Room was dissolved - could show a message
            }
            .store(in: &cancellables)
    }

    // MARK: - Socket

    func startSocket() {
        guard let token = KeychainHelper.load(forKey: KeychainHelper.tokenKey) else { return }
        SocketService.shared.connect(token: token, roomId: room.id)
    }

    // MARK: - Feed

    func fetchFeed() async {
        guard !isFetching, hasMorePages else { return }
        isFetching = true
        if movies.isEmpty { isLoading = true }
        defer { isFetching = false; isLoading = false }

        do {
            let response = try await APIService.shared.getMovieFeed(roomId: room.id, page: currentPage)
            movies.append(contentsOf: response.movies)
            if response.movies.isEmpty {
                hasMorePages = false
            } else {
                currentPage += 1
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func fetchRoomMembers() async {
        do {
            let detail = try await APIService.shared.getRoom(id: room.id)
            roomMembers = detail.members
        } catch {
            // Non-critical — swallowed silently
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

        let flyX: CGFloat = direction == "right" ? 600 : -600
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: flyX, height: 50)
        }

        if direction == "right" {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }

        try? await Task.sleep(nanoseconds: 250_000_000)

        movies.removeFirst()
        dragOffset = .zero
        swipeCount += 1

        if movies.count <= 5 {
            Task { await fetchNextPage() }
        }

        do {
            _ = try await APIService.shared.submitSwipe(movieId: swipedId, roomId: room.id, direction: direction)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func fetchNextPage() async {
        await fetchFeed()
    }
}
