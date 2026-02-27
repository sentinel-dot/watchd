import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    let dragOffset: CGSize
    let isTopCard: Bool
    @StateObject private var favoritesVM = FavoritesViewModel()

    @State private var isOverviewExpanded = false
    @State private var isFavorite = false

    private var likeOpacity: Double {
        let progress = dragOffset.width / 100
        return max(0, min(1, Double(progress)))
    }

    private var nopeOpacity: Double {
        let progress = -dragOffset.width / 100
        return max(0, min(1, Double(progress)))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                posterImage(size: geo.size)

                VStack {
                    HStack {
                        Spacer()
                        Button(action: { toggleFavorite() }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 44, height: 44)

                                Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(16)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Spacer()

                    VStack(alignment: .leading, spacing: 6) {
                        Text(movie.title)
                            .font(WatchdTheme.titleMedium())
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(WatchdTheme.rating)
                                Text(String(format: "%.1f", movie.voteAverage))
                                    .font(WatchdTheme.captionMedium())
                                    .foregroundColor(.white)
                            }

                            if let year = movie.releaseYear {
                                Text("•")
                                    .foregroundColor(.white.opacity(0.5))
                                Text(year)
                                    .font(WatchdTheme.caption())
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }

                        Text(movie.overview)
                            .font(WatchdTheme.caption())
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(isOverviewExpanded ? nil : 3)
                            .padding(.top, 2)
                            .animation(nil, value: isOverviewExpanded)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isOverviewExpanded.toggle()
                                }
                            }

                        if !movie.streamingOptions.isEmpty {
                            StreamingPillsRow(options: movie.streamingOptions)
                                .padding(.top, 6)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 11, weight: .medium))
                                Text("Nicht auf Streaming-Diensten verfügbar")
                                    .font(WatchdTheme.labelUppercase())
                            }
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 6)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(WatchdTheme.heroBottomGradient)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isTopCard {
                    HStack {
                        overlayBadge(text: "GEFÄLLT", color: WatchdTheme.success, rotation: -12)
                            .opacity(likeOpacity)
                            .padding(.leading, 28)
                            .padding(.top, 50)

                        Spacer()

                        overlayBadge(text: "NEIN", color: WatchdTheme.primary, rotation: 12)
                            .opacity(nopeOpacity)
                            .padding(.trailing, 28)
                            .padding(.top, 50)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func posterImage(size: CGSize) -> some View {
        if let url = movie.posterURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                case .failure:
                    placeholderPoster(size: size)
                case .empty:
                    ZStack {
                        WatchdTheme.backgroundCard
                        ProgressView()
                            .tint(WatchdTheme.primary)
                    }
                    .frame(width: size.width, height: size.height)
                @unknown default:
                    placeholderPoster(size: size)
                }
            }
        } else {
            placeholderPoster(size: size)
        }
    }

    private func placeholderPoster(size: CGSize) -> some View {
        ZStack {
            WatchdTheme.backgroundCard
            Image(systemName: "film")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(WatchdTheme.textTertiary.opacity(0.4))
        }
        .frame(width: size.width, height: size.height)
    }

    private func overlayBadge(text: String, color: Color, rotation: Double) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: color.opacity(0.5), radius: 10, y: 4)
            .rotationEffect(.degrees(rotation))
    }

    private func toggleFavorite() {
        isFavorite.toggle()
        Task {
            await favoritesVM.toggleFavorite(movieId: movie.id)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}

// MARK: - Streaming Pills (Netflix-style)

struct StreamingPillsRow: View {
    let options: [StreamingOption]

    private var flatrate: [StreamingOption] {
        options.filter { $0.monetizationType.uppercased() == "FLATRATE" }
    }

    private var displayOptions: [StreamingOption] {
        var seen = Set<String>()
        return (flatrate.isEmpty ? options : flatrate).filter { seen.insert($0.package.clearName).inserted }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(displayOptions.prefix(5)) { option in
                    Text(option.package.clearName)
                        .font(WatchdTheme.labelUppercase())
                        .foregroundColor(WatchdTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(WatchdTheme.overlayLight)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
