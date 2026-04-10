import SwiftUI

struct FavoritesListView: View {
    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        ZStack {
            WatchdTheme.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.favorites.isEmpty && !viewModel.hasLoadedOnce {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if viewModel.favorites.isEmpty {
                            emptyFavorites
                        } else {
                            ForEach(viewModel.favorites) { favorite in
                                NavigationLink {
                                    MovieDetailView(favorite: favorite)
                                } label: {
                                    FavoriteRow(favorite: favorite, viewModel: viewModel)
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 0)
                                .background(WatchdTheme.backgroundCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .task {
                                    await viewModel.loadMoreIfNeeded(currentFavorite: favorite)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
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

    private var emptyFavorites: some View {
        VStack(spacing: 24) {
            Image(systemName: "star")
                .font(WatchdTheme.emptyStateIcon())
                .foregroundColor(WatchdTheme.textTertiary)

            VStack(spacing: 8) {
                Text("Keine Favoriten")
                    .font(WatchdTheme.titleLarge())
                    .foregroundColor(WatchdTheme.textPrimary)
                Text("Markiere Filme mit dem Stern als Favoriten, um sie hier zu sehen")
                    .font(WatchdTheme.caption())
                    .foregroundColor(WatchdTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
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
                        .font(WatchdTheme.iconTiny())
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
                            .font(WatchdTheme.iconMedium())
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
