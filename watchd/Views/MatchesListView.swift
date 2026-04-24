import SwiftUI

struct MatchesListView: View {
    @Environment(\.theme) private var theme
    let roomId: Int
    @StateObject private var viewModel: MatchesViewModel

    init(roomId: Int) {
        self.roomId = roomId
        _viewModel = StateObject(wrappedValue: MatchesViewModel(roomId: roomId))
    }

    var body: some View {
        ZStack {
            theme.colors.base.ignoresSafeArea()

            if viewModel.isLoading && viewModel.matches.isEmpty && !viewModel.hasLoadedOnce {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(theme.colors.accent)
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
                                .background(theme.colors.surfaceCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .task {
                                    await viewModel.loadMoreIfNeeded(currentMatch: match)
                                }
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
        .toolbarBackground(theme.colors.base, for: .navigationBar)
        .alert("Fehler", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.fetchMatches()
        }
        .refreshable {
            await viewModel.fetchMatches()
        }
    }

    private var emptyMatches: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.slash")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(theme.colors.textTertiary)

            VStack(spacing: 8) {
                Text("Noch keine Matches")
                    .font(theme.fonts.titleLarge)
                    .foregroundColor(theme.colors.textPrimary)
                Text("Weiter swipen für einen Match!")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Match Row

private struct MatchRow: View {
    @Environment(\.theme) private var theme
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
                    theme.colors.surfaceInput
                }
            }
            .frame(width: 70, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(isWatched ? 0.5 : 1.0)

            VStack(alignment: .leading, spacing: 8) {
                Text(match.movie.title)
                    .font(theme.fonts.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(2)
                    .strikethrough(isWatched, color: theme.colors.textTertiary)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.colors.rating)
                    Text(String(format: "%.1f", match.movie.voteAverage))
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    if let year = match.movie.releaseYear {
                        Text("•")
                            .foregroundColor(theme.colors.textTertiary)
                        Text(year)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.colors.textTertiary)
                    }
                }

                providerIcons
            }

            Spacer()

            Button(action: { toggleWatched() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isWatched ? theme.colors.success.opacity(0.2) : theme.colors.surfaceInput)
                        .frame(width: 36, height: 36)

                    if isUpdating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.7)
                            .tint(theme.colors.textSecondary)
                    } else {
                        Image(systemName: isWatched ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(isWatched ? theme.colors.success : theme.colors.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isUpdating)
        }
        .padding(14)
        // Sync local state when parent model updates (e.g. after pull-to-refresh)
        .onChange(of: match.isWatched) { _, newValue in
            isWatched = newValue
        }
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
                            theme.colors.surfaceInput
                        }
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        } else {
            Text("Nicht verfügbar")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundColor(theme.colors.textTertiary)
        }
    }

    private func uniqueProviders(from options: [StreamingOption]) -> [StreamingOption] {
        var seen = Set<String>()
        return options.filter { seen.insert($0.package.clearName).inserted }
    }
}
