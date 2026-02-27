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

    func removeFavorite(movieId: Int) async {
        do {
            let _ = try await APIService.shared.removeFavorite(movieId: movieId)
            favorites.removeAll { $0.movie.id == movieId }
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
                VStack(spacing: 24) {
                    Image(systemName: "star")
                        .font(.system(size: 56, weight: .light))
                        .foregroundColor(WatchdTheme.textTertiary)

                    VStack(spacing: 8) {
                        Text("Keine Favoriten")
                            .font(WatchdTheme.titleSmall())
                            .foregroundColor(WatchdTheme.textPrimary)
                        Text("Markiere Filme mit dem Stern als Favoriten, um sie hier zu sehen")
                            .font(WatchdTheme.caption())
                            .foregroundColor(WatchdTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                }
            } else {
                List {
                    ForEach(viewModel.favorites) { favorite in
                        NavigationLink {
                            MovieDetailView(favorite: favorite)
                        } label: {
                            FavoriteRow(favorite: favorite, viewModel: viewModel)
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

// MARK: - Favorite Row (gleiches Layout wie MatchRow)

private struct FavoriteRow: View {
    let favorite: Favorite
    @ObservedObject var viewModel: FavoritesViewModel
    @State private var showRemoveConfirmation = false
    @State private var isRemoving = false

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

                providerIcons
            }

            Spacer()

            Button(action: { showRemoveConfirmation = true }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(WatchdTheme.backgroundInput)
                        .frame(width: 36, height: 36)

                    if isRemoving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.7)
                            .tint(WatchdTheme.textSecondary)
                    } else {
                        Image(systemName: "star.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(WatchdTheme.rating)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isRemoving)
        }
        .padding(14)
        .alert("Aus Favoriten entfernen?", isPresented: $showRemoveConfirmation) {
            Button("Abbrechen", role: .cancel) {}
            Button("Entfernen", role: .destructive) {
                isRemoving = true
                Task {
                    await viewModel.removeFavorite(movieId: favorite.movie.id)
                    isRemoving = false
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
        } message: {
            Text("\"\(favorite.movie.title)\" wird aus deinen Favoriten entfernt.")
        }
    }

    @ViewBuilder
    private var providerIcons: some View {
        let providers = uniqueProviders(from: favorite.streamingOptions)
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

#Preview {
    NavigationStack {
        FavoritesListView()
    }
    .preferredColorScheme(.dark)
}
