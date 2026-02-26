import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    let dragOffset: CGSize
    let isTopCard: Bool
    
    @State private var isOverviewExpanded = false

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
                // Poster with rounded corners
                posterImage(size: geo.size)

                // Bottom gradient + info overlay (full width = poster width)
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()

                    VStack(alignment: .leading, spacing: 6) {
                        Text(movie.title)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.20))
                                Text(String(format: "%.1f", movie.voteAverage))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            if let year = movie.releaseYear {
                                Text("•")
                                    .foregroundColor(.white.opacity(0.5))
                                Text(year)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }

                        Text(movie.overview)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(isOverviewExpanded ? nil : 3)
                            .padding(.top, 2)
                            .animation(nil, value: isOverviewExpanded)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isOverviewExpanded.toggle()
                                }
                            }

                        // Streaming options
                        if !movie.streamingOptions.isEmpty {
                            StreamingPillsRow(options: movie.streamingOptions)
                                .padding(.top, 6)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 11, weight: .medium))
                                Text("Nicht auf Streaming-Diensten verfügbar")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 6)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [
                                .clear,
                                .black.opacity(0.5),
                                .black.opacity(0.8),
                                .black.opacity(0.95),
                                .black.opacity(0.98)
                            ],
                            startPoint: .init(x: 0.5, y: 0),
                            endPoint: .bottom
                        )
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Swipe feedback overlays
                if isTopCard {
                    HStack {
                        overlayBadge(text: "GEFÄLLT", color: Color(red: 0.2, green: 0.7, blue: 0.4), rotation: -12)
                            .opacity(likeOpacity)
                            .padding(.leading, 28)
                            .padding(.top, 50)

                        Spacer()

                        overlayBadge(text: "NEIN", color: Color(red: 0.85, green: 0.30, blue: 0.25), rotation: 12)
                            .opacity(nopeOpacity)
                            .padding(.trailing, 28)
                            .padding(.top, 50)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
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
                        Color(red: 0.9, green: 0.88, blue: 0.86)
                        ProgressView()
                            .tint(Color(red: 0.85, green: 0.30, blue: 0.25))
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
            LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.88, blue: 0.86),
                    Color(red: 0.85, green: 0.82, blue: 0.80)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "film")
                .font(.system(size: 70, weight: .light))
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6).opacity(0.3))
        }
        .frame(width: size.width, height: size.height)
    }

    private func overlayBadge(text: String, color: Color, rotation: Double) -> some View {
        Text(text)
            .font(.system(size: 32, weight: .black, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: color.opacity(0.4), radius: 12, y: 6)
            .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Streaming Pills

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
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                }
            }
        }
    }
}
