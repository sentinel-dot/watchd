import SwiftUI

struct SwipeView: View {
    @StateObject private var viewModel: SwipeViewModel
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

                ZStack(alignment: .top) {
                    cardStack

                    if viewModel.swipeCount > 0 {
                        HStack {
                            Text("\(viewModel.swipeCount) Filme bewertet")
                                .font(WatchdTheme.captionMedium())
                                .foregroundColor(WatchdTheme.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(WatchdTheme.backgroundCard)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(WatchdTheme.separator, lineWidth: 1)
                                )
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                }

                Spacer(minLength: 20)

                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle("watchd")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(WatchdTheme.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    MatchesListView(roomId: viewModel.room.id)
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16, weight: .semibold))
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
                        .font(.system(size: 56, weight: .light))
                        .foregroundColor(WatchdTheme.textTertiary)

                    VStack(spacing: 8) {
                        Text("Keine weiteren Filme")
                            .font(WatchdTheme.titleSmall())
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
        HStack(spacing: 20) {
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
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(WatchdTheme.textPrimary)
                }
            }
            .disabled(viewModel.movies.isEmpty)
            .opacity(viewModel.movies.isEmpty ? 0.4 : 1.0)

            Spacer()

            Button {
                Task { await viewModel.handleDragEnd(CGSize(width: 150, height: 0)) }
            } label: {
                ZStack {
                    Circle()
                        .fill(WatchdTheme.primaryButtonGradient)
                        .frame(width: 72, height: 72)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .disabled(viewModel.movies.isEmpty)
            .opacity(viewModel.movies.isEmpty ? 0.4 : 1.0)
        }
    }
}
