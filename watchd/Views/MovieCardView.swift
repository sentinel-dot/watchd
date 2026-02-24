import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    let dragOffset: CGSize
    let isTopCard: Bool

    private var likeOpacity: Double {
        let progress = dragOffset.width / 80
        return max(0, min(1, Double(progress)))
    }

    private var nopeOpacity: Double {
        let progress = -dragOffset.width / 80
        return max(0, min(1, Double(progress)))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Poster
                posterImage(size: geo.size)

                // Bottom gradient + info
                VStack(alignment: .leading, spacing: 6) {
                    Spacer()

                    Text(movie.title)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .shadow(radius: 4)

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", movie.voteAverage))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)

                        if let year = movie.releaseYear {
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            Text(year)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    Text(movie.overview)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: false)

                    // Streaming pills
                    if !movie.streamingOptions.isEmpty {
                        StreamingPillsRow(options: movie.streamingOptions)
                            .padding(.top, 2)
                    }
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55), .black.opacity(0.85)],
                        startPoint: .init(x: 0.5, y: 0.2),
                        endPoint: .bottom
                    )
                )

                // LIKE / NOPE overlays
                if isTopCard {
                    HStack {
                        overlayBadge(text: "LIKE", color: .green, rotation: -15)
                            .opacity(likeOpacity)
                            .padding(.leading, 20)
                            .padding(.top, 40)

                        Spacer()

                        overlayBadge(text: "NOPE", color: .red, rotation: 15)
                            .opacity(nopeOpacity)
                            .padding(.trailing, 20)
                            .padding(.top, 40)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
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
                        Color(white: 0.15)
                        ProgressView()
                            .tint(.white)
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
                colors: [Color(white: 0.15), Color(white: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "film")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.2))
        }
        .frame(width: size.width, height: size.height)
    }

    private func overlayBadge(text: String, color: Color, rotation: Double) -> some View {
        Text(text)
            .font(.title.weight(.black))
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 3)
            )
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
            HStack(spacing: 6) {
                ForEach(displayOptions.prefix(5)) { option in
                    Text(option.package.clearName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
