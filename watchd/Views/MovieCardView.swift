import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    let dragOffset: CGSize
    let isTopCard: Bool

    @Environment(\.theme) private var theme
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
                posterImage(size: geo.size)

                VStack(alignment: .leading, spacing: 10) {
                    Spacer()

                    VStack(alignment: .leading, spacing: 10) {
                        Text(movie.title)
                            .font(theme.fonts.display(size: 30, weight: .regular))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        metaRow

                        Group {
                            if isOverviewExpanded {
                                ScrollView {
                                    Text(movie.overview)
                                        .font(theme.fonts.body(size: 14, weight: .regular))
                                        .italic()
                                        .foregroundColor(.white.opacity(0.92))
                                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                        .lineSpacing(4)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxHeight: 160)
                                .scrollIndicators(.hidden)
                                .transition(.opacity)
                            } else {
                                Text(movie.overview)
                                    .font(theme.fonts.body(size: 14, weight: .regular))
                                    .italic()
                                    .foregroundColor(.white.opacity(0.92))
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                    .lineSpacing(3)
                                    .lineLimit(3)
                                    .transition(.opacity)
                            }
                        }
                        .animation(theme.motion.easeOutQuart, value: isOverviewExpanded)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(theme.motion.easeOutQuart) {
                                isOverviewExpanded.toggle()
                            }
                        }

                        if !movie.streamingOptions.isEmpty {
                            StreamingPillsRow(options: movie.streamingOptions)
                                .padding(.top, 4)
                        } else {
                            Text("Nicht auf Streaming-Diensten")
                                .font(theme.fonts.microCaption)
                                .tracking(1.2)
                                .textCase(.uppercase)
                                .foregroundColor(.white.opacity(0.55))
                                .padding(.top, 6)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 22)
                    .background(theme.colors.heroBottomGradient)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isTopCard {
                    HStack {
                        overlayBadge(text: "Gefällt", color: theme.colors.success, rotation: -3)
                            .opacity(likeOpacity)
                            .padding(.leading, 24)
                            .padding(.top, 40)

                        Spacer()

                        overlayBadge(text: "Nein", color: theme.colors.error, rotation: 3)
                            .opacity(nopeOpacity)
                            .padding(.trailing, 24)
                            .padding(.top, 40)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var metaRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(theme.colors.rating)
                Text(String(format: "%.1f", movie.voteAverage))
                    .font(theme.fonts.body(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }

            if let year = movie.releaseYear {
                Text("·")
                    .font(theme.fonts.body(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                Text(year)
                    .font(theme.fonts.body(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
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
                        theme.colors.surfaceCard
                        ProgressView()
                            .tint(theme.colors.accent)
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
            theme.colors.surfaceCard
            Image(systemName: "film")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(theme.colors.textTertiary.opacity(0.4))
        }
        .frame(width: size.width, height: size.height)
    }

    private func overlayBadge(text: String, color: Color, rotation: Double) -> some View {
        Text(text)
            .font(theme.fonts.microCaption)
            .tracking(2.0)
            .textCase(.uppercase)
            .foregroundColor(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color.opacity(0.6), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Streaming Pills (typographic)

struct StreamingPillsRow: View {
    let options: [StreamingOption]
    @Environment(\.theme) private var theme

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
                    HStack(spacing: 6) {
                        if let url = option.package.iconURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable().scaledToFit()
                                default:
                                    Color.clear
                                }
                            }
                            .frame(width: 18, height: 18)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Text(option.package.clearName)
                            .font(theme.fonts.microCaption)
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.colors.overlayLight)
                    .clipShape(Capsule())
                }
            }
        }
    }
}
