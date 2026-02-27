import SwiftUI

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [Favorite] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    func loadFavorites() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await APIService.shared.getFavorites()
            favorites = response.favorites
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func toggleFavorite(movieId: Int) async {
        do {
            if favorites.contains(where: { $0.movie.id == movieId }) {
                let _ = try await APIService.shared.removeFavorite(movieId: movieId)
                favorites.removeAll { $0.movie.id == movieId }
            } else {
                let _ = try await APIService.shared.addFavorite(movieId: movieId)
                await loadFavorites()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func isFavorite(movieId: Int) -> Bool {
        favorites.contains { $0.movie.id == movieId }
    }
}

struct FavoritesListView: View {
    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        ZStack {
            WatchdTheme.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.favorites.isEmpty {
                LoadingView(message: "Favoriten werden geladen...")
            } else if viewModel.favorites.isEmpty {
                EmptyStateView(
                    icon: "bookmark",
                    title: "Keine Favoriten",
                    message: "Markiere Filme als Favoriten um sie hier zu sehen"
                )
            } else {
                List {
                    ForEach(viewModel.favorites) { favorite in
                        FavoriteRow(favorite: favorite, viewModel: viewModel)
                            .listRowBackground(WatchdTheme.backgroundCard)
                            .listRowSeparator(.visible)
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Favoriten")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(WatchdTheme.background, for: .navigationBar)
        .alert("Fehler", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.loadFavorites()
        }
        .refreshable {
            await viewModel.loadFavorites()
        }
    }
}

private struct FavoriteRow: View {
    let favorite: Favorite
    @ObservedObject var viewModel: FavoritesViewModel

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: favorite.movie.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    WatchdTheme.backgroundInput
                }
            }
            .frame(width: 70, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 8) {
                Text(favorite.movie.title)
                    .font(WatchdTheme.bodyMedium())
                    .foregroundColor(WatchdTheme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(WatchdTheme.rating)
                    Text(String(format: "%.1f", favorite.movie.voteAverage))
                        .font(WatchdTheme.caption())
                        .foregroundColor(WatchdTheme.textSecondary)
                    if let year = favorite.movie.releaseYear {
                        Text("•")
                            .foregroundColor(WatchdTheme.textTertiary)
                        Text(year)
                            .font(WatchdTheme.caption())
                            .foregroundColor(WatchdTheme.textTertiary)
                    }
                }
            }

            Spacer()

            Button(action: {
                Task { await viewModel.toggleFavorite(movieId: favorite.movie.id) }
            }) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(WatchdTheme.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
    }
}

#Preview {
    NavigationStack {
        FavoritesListView()
    }
    .preferredColorScheme(.dark)
}
