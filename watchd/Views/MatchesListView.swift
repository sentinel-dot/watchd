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

            if viewModel.isLoading {
                LoadingView(message: "Matches werden geladen…")
            } else if viewModel.matches.isEmpty {
                VStack(spacing: 24) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 56, weight: .light))
                        .foregroundColor(WatchdTheme.textTertiary)

                    VStack(spacing: 8) {
                        Text("Noch keine Matches")
                            .font(WatchdTheme.titleSmall())
                            .foregroundColor(WatchdTheme.textPrimary)
                        Text("Weiter swipen für einen Match!")
                            .font(WatchdTheme.caption())
                            .foregroundColor(WatchdTheme.textSecondary)
                    }
                }
            } else {
                List {
                    ForEach(viewModel.matches) { match in
                        NavigationLink {
                            MovieDetailView(match: match)
                        } label: {
                            MatchRow(match: match)
                        }
                        .listRowBackground(WatchdTheme.backgroundCard)
                        .listRowSeparator(.visible)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
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
            await viewModel.fetchMatches()
        }
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
                        .font(.system(size: 11, weight: .semibold))
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
                            .font(.system(size: 18, weight: .medium))
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
