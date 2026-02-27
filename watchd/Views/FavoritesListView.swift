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
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.94),
                    Color(red: 0.96, green: 0.93, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
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
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Favoriten")
        .navigationBarTitleDisplayMode(.large)
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
            
            VStack(alignment: .leading, spacing: 8) {
                Text(favorite.movie.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.20))
                    Text(String(format: "%.1f", favorite.movie.voteAverage))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                    if let year = favorite.movie.releaseYear {
                        Text("•")
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        Text(year)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.toggleFavorite(movieId: favorite.movie.id)
                }
            }) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
    }
}

#Preview {
    NavigationStack {
        FavoritesListView()
    }
}
