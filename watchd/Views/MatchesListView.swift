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
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.94),
                    Color(red: 0.96, green: 0.93, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color(red: 0.85, green: 0.30, blue: 0.25))
                    .scaleEffect(1.5)
            } else if viewModel.matches.isEmpty {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.9, green: 0.88, blue: 0.86))
                            .frame(width: 100, height: 100)
                        Image(systemName: "heart.slash")
                            .font(.system(size: 44, weight: .light))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                    
                    VStack(spacing: 6) {
                        Text("Noch keine Matches")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        Text("Weiter swipen für einen Match!")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
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
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Matches")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(red: 0.98, green: 0.96, blue: 0.94), for: .navigationBar)
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

// MARK: - Match Row

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
                    LinearGradient(
                        colors: [
                            Color(red: 0.9, green: 0.88, blue: 0.86),
                            Color(red: 0.85, green: 0.82, blue: 0.80)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: 70, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
            .opacity(isWatched ? 0.5 : 1.0)

            VStack(alignment: .leading, spacing: 8) {
                Text(match.movie.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .lineLimit(2)
                    .strikethrough(isWatched, color: Color(red: 0.5, green: 0.5, blue: 0.5))

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.20))
                    Text(String(format: "%.1f", match.movie.voteAverage))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                    if let year = match.movie.releaseYear {
                        Text("•")
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        Text(year)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                }

                providerIcons
            }

            Spacer()
            
            Button(action: {
                toggleWatched()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isWatched ? Color(red: 0.2, green: 0.7, blue: 0.3).opacity(0.15) : Color(red: 0.9, green: 0.88, blue: 0.86))
                        .frame(width: 32, height: 32)
                    
                    if isUpdating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: isWatched ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(isWatched ? Color(red: 0.2, green: 0.7, blue: 0.3) : Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isUpdating)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
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
                await MainActor.run {
                    isUpdating = false
                }
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
                            Color(red: 0.9, green: 0.88, blue: 0.86)
                        }
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        } else {
            Text("Nicht verfügbar")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
        }
    }

    private func uniqueProviders(from options: [StreamingOption]) -> [StreamingOption] {
        var seen = Set<String>()
        return options.filter { seen.insert($0.package.clearName).inserted }
    }
}
