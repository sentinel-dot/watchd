import SwiftUI

struct MatchesListView: View {
    let roomId: Int
    @StateObject private var viewModel: MatchesViewModel

    init(roomId: Int) {
        self.roomId = roomId
        _viewModel = StateObject(wrappedValue: MatchesViewModel(roomId: roomId))
    }

    var body: some View {
        ZStack {
            WatchdTheme.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.matches.isEmpty && !viewModel.hasLoadedOnce {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if viewModel.matches.isEmpty {
                            emptyMatches
                        } else {
                            ForEach(viewModel.matches) { match in
                                NavigationLink {
                                    MovieDetailView(match: match)
                                } label: {
                                    MatchRow(match: match)
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 0)
                                .background(WatchdTheme.backgroundCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Matches")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(WatchdTheme.background, for: .navigationBar)
        .alert("Fehler", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.fetchMatches()
        }
        .refreshable {
            do {
                await Task.detached { @MainActor in
                    await viewModel.fetchMatches()
                }.value
            } catch is CancellationError {
                // User hat Refresh abgebrochen – ignorieren
            }
        }
    }

    private var emptyMatches: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.slash")
                .font(WatchdTheme.emptyStateIcon())
                .foregroundColor(WatchdTheme.textTertiary)

            VStack(spacing: 8) {
                Text("Noch keine Matches")
                    .font(WatchdTheme.titleLarge())
                    .foregroundColor(WatchdTheme.textPrimary)
                Text("Weiter swipen für einen Match!")
                    .font(WatchdTheme.caption())
                    .foregroundColor(WatchdTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Match Row (Netflix-style)

private struct MatchRow: View {
    let match: Match
    @State private var isWatched: Bool
    @State private var isUpdating = false

    init(match: Match) {
        self.match = match
        self._isWatched = State(initialValue: match.isWatched)
    }

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: match.movie.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    WatchdTheme.backgroundInput
                }
            }
            .frame(width: 70, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(isWatched ? 0.5 : 1.0)

            VStack(alignment: .leading, spacing: 8) {
                Text(match.movie.title)
                    .font(WatchdTheme.bodyMedium())
                    .foregroundColor(WatchdTheme.textPrimary)
                    .lineLimit(2)
                    .strikethrough(isWatched, color: WatchdTheme.textTertiary)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(WatchdTheme.iconTiny())
                        .foregroundColor(WatchdTheme.rating)
                    Text(String(format: "%.1f", match.movie.voteAverage))
                        .font(WatchdTheme.caption())
                        .foregroundColor(WatchdTheme.textSecondary)
                    if let year = match.movie.releaseYear {
                        Text("•")
                            .foregroundColor(WatchdTheme.textTertiary)
                        Text(year)
                            .font(WatchdTheme.caption())
                            .foregroundColor(WatchdTheme.textTertiary)
                    }
                }

                providerIcons
            }

            Spacer()

            Button(action: { toggleWatched() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isWatched ? WatchdTheme.success.opacity(0.2) : WatchdTheme.backgroundInput)
                        .frame(width: 36, height: 36)

                    if isUpdating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.7)
                            .tint(WatchdTheme.textSecondary)
                    } else {
                        Image(systemName: isWatched ? "checkmark.circle.fill" : "circle")
                            .font(WatchdTheme.iconMedium())
                            .foregroundColor(isWatched ? WatchdTheme.success : WatchdTheme.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isUpdating)
        }
        .padding(14)
    }

    private func toggleWatched() {
        isUpdating = true
        let newState = !isWatched
        Task {
            do {
                let _ = try await APIService.shared.updateMatchWatched(matchId: match.id, watched: newState)
                await MainActor.run {
                    isWatched = newState
                    isUpdating = false
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            } catch {
                await MainActor.run { isUpdating = false }
            }
        }
    }

    @ViewBuilder
    private var providerIcons: some View {
        let providers = uniqueProviders(from: match.streamingOptions)
        if !providers.isEmpty {
            HStack(spacing: 6) {
                ForEach(providers.prefix(4)) { option in
                    AsyncImage(url: option.package.iconURL) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFit()
                        default:
                            WatchdTheme.backgroundInput
                        }
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        } else {
            Text("Nicht verfügbar")
                .font(WatchdTheme.labelUppercase())
                .foregroundColor(WatchdTheme.textTertiary)
        }
    }

    private func uniqueProviders(from options: [StreamingOption]) -> [StreamingOption] {
        var seen = Set<String>()
        return options.filter { seen.insert($0.package.clearName).inserted }
    }
}
