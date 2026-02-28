import SwiftUI

struct SwipeView: View {
    @StateObject private var viewModel: SwipeViewModel
    @StateObject private var favoritesVM = FavoritesViewModel()
    @State private var justFavoritedFeedback = false
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 48
    private let cardHeight: CGFloat = UIScreen.main.bounds.height * 0.65

    init(room: Room) {
        _viewModel = StateObject(wrappedValue: SwipeViewModel(room: room))
    }

    var body: some View {
        ZStack(alignment: .top) {
            WatchdTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if !networkMonitor.isConnected {
                    OfflineBanner()
                        .animation(.spring(), value: networkMonitor.isConnected)
                }

                Spacer(minLength: 40)

                cardStack

                Spacer(minLength: 20)

                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(WatchdTheme.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("WATCHD")
                    .font(WatchdTheme.logoTitle())
                    .foregroundColor(WatchdTheme.textPrimary)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.swipeCount > 0 {
                    Text("\(viewModel.swipeCount) bewertet")
                        .font(WatchdTheme.captionMedium())
                        .foregroundColor(WatchdTheme.textSecondary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    MatchesListView(roomId: viewModel.room.id)
                } label: {
                    Image(systemName: "heart.fill")
                        .font(WatchdTheme.iconSmall())
                        .foregroundColor(WatchdTheme.primary)
                }
            }
        }
        .sheet(item: $viewModel.currentMatch) { match in
            MatchView(match: match, roomId: viewModel.room.id) {
                viewModel.currentMatch = nil
            }
        }
        .alert("Fehler", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.fetchFeed()
            await favoritesVM.loadFavorites()
            viewModel.startSocket()
        }
        .disabled(!networkMonitor.isConnected)
    }

    @ViewBuilder
    private var cardStack: some View {
        ZStack {
            if viewModel.isLoading && viewModel.movies.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(WatchdTheme.primary)
                        .scaleEffect(1.5)
                    Text("Filme werden geladen…")
                        .font(WatchdTheme.bodyMedium())
                        .foregroundColor(WatchdTheme.textSecondary)
                }
                .frame(width: cardWidth, height: cardHeight)
            } else if viewModel.movies.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "film.stack")
                        .font(WatchdTheme.emptyStateIcon())
                        .foregroundColor(WatchdTheme.textTertiary)

                    VStack(spacing: 8) {
                        Text("Keine weiteren Filme")
                            .font(WatchdTheme.titleLarge())
                            .foregroundColor(WatchdTheme.textPrimary)
                        Text("Schau später nochmal vorbei")
                            .font(WatchdTheme.caption())
                            .foregroundColor(WatchdTheme.textSecondary)
                    }
                }
                .frame(width: cardWidth, height: cardHeight)
            } else {
                ForEach(Array(viewModel.movies.prefix(3).enumerated().reversed()), id: \.element.id) { index, movie in
                    let isTop = index == 0

                    MovieCardView(
                        movie: movie,
                        dragOffset: isTop ? viewModel.dragOffset : .zero,
                        isTopCard: isTop
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .scaleEffect(isTop ? 1.0 : 1.0 - CGFloat(index) * 0.04)
                    .offset(y: isTop ? 0 : CGFloat(index) * 12)
                    .rotationEffect(isTop ? .degrees(Double(viewModel.dragOffset.width) / 25) : .zero)
                    .offset(
                        x: isTop ? viewModel.dragOffset.width : 0,
                        y: isTop ? viewModel.dragOffset.height * 0.2 : 0
                    )
                    .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7), value: viewModel.dragOffset)
                    .gesture(isTop ? swipeGesture : nil)
                    .zIndex(isTop ? 1 : 0)
                    .shadow(color: .black.opacity(isTop ? 0.4 : 0.2), radius: isTop ? 24 : 12, y: isTop ? 12 : 6)
                }
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                viewModel.handleDragChange(value.translation)
            }
            .onEnded { value in
                Task { await viewModel.handleDragEnd(value.translation) }
            }
    }

    private var actionButtons: some View {
        HStack(spacing: 24) {
            // Ablehnen
            Button {
                Task { await viewModel.handleDragEnd(CGSize(width: -150, height: 0)) }
            } label: {
                ZStack {
                    Circle()
                        .fill(WatchdTheme.backgroundCard)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(WatchdTheme.separator, lineWidth: 1)
                        )
                    Image(systemName: "xmark")
                        .font(WatchdTheme.titleLarge())
                        .foregroundColor(WatchdTheme.textPrimary)
                }
            }
            .disabled(viewModel.movies.isEmpty)
            .opacity(viewModel.movies.isEmpty ? 0.4 : 1.0)

            Spacer()

            // Favorit (Mitte) – kleinerer Stern, weiche Animation, klares Feedback
            Button {
                guard let movie = viewModel.movies.first else { return }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                if !favoritesVM.isFavorite(movieId: movie.id) {
                    justFavoritedFeedback = true
                    Task {
                        try? await Task.sleep(nanoseconds: 800_000_000)
                        await MainActor.run { justFavoritedFeedback = false }
                    }
                }
                Task {
                    await favoritesVM.toggleFavorite(movieId: movie.id)
                }
            } label: {
                let isFav = favoritesVM.isFavorite(movieId: viewModel.movies.first?.id ?? 0)
                ZStack {
                    Circle()
                        .fill(
                            isFav
                                ? WatchdTheme.rating.opacity(0.25)
                                : WatchdTheme.backgroundCard
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(
                                    isFav ? WatchdTheme.rating : WatchdTheme.separator,
                                    lineWidth: isFav ? 2 : 1
                                )
                        )
                    Image(systemName: isFav ? "star.fill" : "star")
                        .font(WatchdTheme.titleMedium())
                        .foregroundColor(isFav ? WatchdTheme.rating : WatchdTheme.textPrimary)
                        .scaleEffect(justFavoritedFeedback ? 1.25 : 1.0)
                }
            }
            .disabled(viewModel.movies.isEmpty)
            .opacity(viewModel.movies.isEmpty ? 0.4 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: favoritesVM.isFavorite(movieId: viewModel.movies.first?.id ?? 0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: justFavoritedFeedback)
            .overlay(alignment: .top) {
                if justFavoritedFeedback {
                    Text("Favorisiert")
                        .font(WatchdTheme.captionMedium())
                        .foregroundColor(WatchdTheme.rating)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .offset(y: -36)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }

            Spacer()

            // Gefällt mir (Swipe Right)
            Button {
                Task { await viewModel.handleDragEnd(CGSize(width: 150, height: 0)) }
            } label: {
                ZStack {
                    Circle()
                        .fill(WatchdTheme.primaryButtonGradient)
                        .frame(width: 72, height: 72)
                    Image(systemName: "heart.fill")
                        .font(WatchdTheme.titleLarge())
                        .foregroundColor(.white)
                }
            }
            .disabled(viewModel.movies.isEmpty)
            .opacity(viewModel.movies.isEmpty ? 0.4 : 1.0)
        }
    }
}
