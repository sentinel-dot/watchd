import SwiftUI

struct SwipeView: View {
    @StateObject private var viewModel: SwipeViewModel
    @StateObject private var favoritesVM = FavoritesViewModel()
    @State private var justFavoritedFeedback = false
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(partnership: Partnership) {
        _viewModel = StateObject(wrappedValue: SwipeViewModel(partnership: partnership))
    }

    private var partnerName: String {
        viewModel.partnership.partner?.name ?? "Partner"
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width - 48
            let cardHeight = geometry.size.height * 0.66

            ZStack(alignment: .top) {
                theme.colors.base.ignoresSafeArea()
                paperLineaturBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    if !networkMonitor.isConnected {
                        OfflineBanner()
                            .animation(.spring(), value: networkMonitor.isConnected)
                    }

                    Spacer(minLength: 32)

                    cardStack(cardWidth: cardWidth, cardHeight: cardHeight)

                    Spacer(minLength: 24)

                    actionButtons
                        .padding(.horizontal, 28)
                        .padding(.bottom, 44)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(theme.colors.base, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(partnerName)
                        .font(theme.fonts.body(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                    Text("zu zweit")
                        .font(theme.fonts.microCaption)
                        .tracking(1.0)
                        .textCase(.uppercase)
                        .foregroundColor(theme.colors.textTertiary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    MatchesListView(partnershipId: viewModel.partnership.id)
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.accent)
                }
                .accessibilityLabel("Matches anzeigen")
            }
        }
        .sheet(item: $viewModel.currentMatch) { match in
            MatchView(match: match, partnershipId: viewModel.partnership.id) {
                viewModel.currentMatch = nil
            }
        }
        .alert("Fehler", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Partner offline", isPresented: $viewModel.partnerLeft) {
            Button("OK") {}
        } message: {
            Text("\(partnerName) ist gerade nicht da. Du kannst weiter swipen — Matches gibt's nur, wenn ihr beide Ja sagt.")
        }
        .alert("Partnerschaft beendet", isPresented: $viewModel.partnershipEnded) {
            Button("Zur Übersicht") { dismiss() }
        } message: {
            Text("Diese Partnerschaft wurde beendet.")
        }
        .task {
            viewModel.startSocket()
            await viewModel.fetchFeed()
            await favoritesVM.loadFavorites()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.reconnectSocketIfNeeded()
            }
        }
        .disabled(!networkMonitor.isConnected)
    }

    // MARK: - Paper Lineatur

    private var paperLineaturBackground: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let lineColor = theme.colors.textTertiary.opacity(0.04)
                let spacing: CGFloat = 44
                var y: CGFloat = 0
                while y < size.height {
                    let path = Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                    y += spacing
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func cardStack(cardWidth: CGFloat, cardHeight: CGFloat) -> some View {
        ZStack {
            if viewModel.isLoading && viewModel.movies.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(theme.colors.accent)
                        .scaleEffect(1.3)
                    Text("Filme werden kuratiert …")
                        .font(theme.fonts.caption)
                        .italic()
                        .foregroundColor(theme.colors.textSecondary)
                }
                .frame(width: cardWidth, height: cardHeight)
            } else if viewModel.movies.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Alles gesichtet.")
                        .font(theme.fonts.titleLarge)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("Für heute ist der Stapel durch. Komm später wieder — oder passt eure Filter an.")
                        .font(theme.fonts.bodyRegular)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)
                .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
            } else {
                ForEach(Array(viewModel.movies.prefix(3).enumerated().reversed()), id: \.element.id) { index, movie in
                    let isTop = index == 0
                    let depth = CGFloat(index)

                    MovieCardView(
                        movie: movie,
                        dragOffset: isTop ? viewModel.dragOffset : .zero,
                        isTopCard: isTop
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .scaleEffect(isTop ? 1.0 : 1.0 - depth * 0.08)
                    .offset(y: isTop ? 0 : depth * 24)
                    .opacity(isTop ? 1.0 : 1.0 - depth * 0.3)
                    .rotationEffect(isTop ? .degrees(Double(viewModel.dragOffset.width) / 25) : .zero)
                    .offset(
                        x: isTop ? viewModel.dragOffset.width : 0,
                        y: isTop ? viewModel.dragOffset.height * 0.2 : 0
                    )
                    .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7), value: viewModel.dragOffset)
                    .gesture(isTop ? swipeGesture : nil)
                    .zIndex(isTop ? 1 : 0)
                    .shadow(color: .black.opacity(isTop ? 0.45 : 0.2), radius: isTop ? 28 : 14, y: isTop ? 14 : 7)
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

    // MARK: - Action Buttons

    private var actionButtons: some View {
        let disabled = viewModel.movies.isEmpty
        let favoriteMovie = viewModel.movies.first
        let isFav = favoritesVM.isFavorite(movieId: favoriteMovie?.id ?? 0)

        return VStack(spacing: 10) {
            HStack {
                actionButton(
                    label: "Skip",
                    icon: "xmark",
                    tint: theme.colors.textSecondary,
                    filled: false,
                    size: 60,
                    accessibility: "Überspringen",
                    action: {
                        Task { await viewModel.handleDragEnd(CGSize(width: -150, height: 0)) }
                    }
                )
                .opacity(disabled ? 0.35 : 1.0)
                .disabled(disabled)

                Spacer()

                favoriteButton(movie: favoriteMovie, isFav: isFav)
                    .opacity(disabled ? 0.35 : 1.0)
                    .disabled(disabled)

                Spacer()

                Button {
                    Task { await viewModel.handleDragEnd(CGSize(width: 150, height: 0)) }
                } label: {
                    ZStack {
                        Circle()
                            .fill(theme.colors.primaryButtonGradient)
                            .frame(width: 68, height: 68)
                            .shadow(color: theme.colors.accent.opacity(0.35), radius: 14, y: 6)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(theme.colors.textOnAccent)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Gefällt uns")
                .opacity(disabled ? 0.35 : 1.0)
                .disabled(disabled)
            }

            HStack {
                Text("Skip")
                    .font(theme.fonts.microCaption)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(theme.colors.textTertiary)
                    .frame(width: 60, alignment: .center)
                Spacer()
                Text(isFav ? "Gemerkt" : "Merken")
                    .font(theme.fonts.microCaption)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(isFav ? theme.colors.rating : theme.colors.textTertiary)
                    .frame(width: 52, alignment: .center)
                Spacer()
                Text("Gefällt")
                    .font(theme.fonts.microCaption)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(width: 68, alignment: .center)
            }
        }
    }

    private func actionButton(
        label: String,
        icon: String,
        tint: Color,
        filled: Bool,
        size: CGFloat,
        accessibility: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(filled ? tint : Color.clear)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(tint.opacity(filled ? 0 : 0.5), lineWidth: 1)
                    )
                Image(systemName: icon)
                    .font(.system(size: size * 0.35, weight: .medium))
                    .foregroundColor(filled ? theme.colors.base : tint)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility)
    }

    private func favoriteButton(movie: Movie?, isFav: Bool) -> some View {
        Button {
            guard let movie else { return }
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
            ZStack {
                Circle()
                    .fill(isFav ? theme.colors.rating.opacity(0.18) : Color.clear)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(isFav ? theme.colors.rating : theme.colors.textTertiary.opacity(0.5),
                                    lineWidth: isFav ? 1.5 : 1)
                    )
                Image(systemName: isFav ? "star.fill" : "star")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isFav ? theme.colors.rating : theme.colors.textSecondary)
                    .scaleEffect(justFavoritedFeedback && !reduceMotion ? 1.2 : 1.0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFav ? "Aus Merkliste entfernen" : "Für später merken")
        .animation(theme.motion.easeOutQuart, value: isFav)
        .animation(theme.motion.easeOutQuart, value: justFavoritedFeedback)
    }
}
