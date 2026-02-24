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
            Color(red: 0.06, green: 0.06, blue: 0.12).ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.4)
            } else if viewModel.matches.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.2))
                    Text("No matches yet")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Keep swiping to find a match!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.3))
                }
            } else {
                List {
                    ForEach(viewModel.matches) { match in
                        NavigationLink {
                            MovieDetailView(match: match)
                        } label: {
                            MatchRow(match: match)
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Matches")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Error", isPresented: $viewModel.showError) {
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

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: match.movie.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color.white.opacity(0.1)
                }
            }
            .frame(width: 60, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                Text(match.movie.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    Text(String(format: "%.1f", match.movie.voteAverage))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    if let year = match.movie.releaseYear {
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        Text(year)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                providerIcons
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var providerIcons: some View {
        let providers = uniqueProviders(from: match.streamingOptions)
        if !providers.isEmpty {
            HStack(spacing: 4) {
                ForEach(providers.prefix(4)) { option in
                    AsyncImage(url: option.package.iconURL) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFit()
                        default:
                            Color.white.opacity(0.1)
                        }
                    }
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
        }
    }

    private func uniqueProviders(from options: [StreamingOption]) -> [StreamingOption] {
        var seen = Set<String>()
        return options.filter { seen.insert($0.package.clearName).inserted }
    }
}
