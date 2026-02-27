import SwiftUI

struct MovieDetailView: View {
    let match: Match

    var body: some View {
        ZStack {
            WatchdTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroPoster
                        .ignoresSafeArea(edges: .top)

                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(match.movie.title)
                                .font(WatchdTheme.titleLarge())
                                .foregroundColor(WatchdTheme.textPrimary)

                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(WatchdTheme.rating)
                                    Text(String(format: "%.1f", match.movie.voteAverage))
                                        .font(WatchdTheme.bodyMedium())
                                        .foregroundColor(WatchdTheme.textSecondary)
                                }

                                if let year = match.movie.releaseYear {
                                    Text(year)
                                        .font(WatchdTheme.body())
                                        .foregroundColor(WatchdTheme.textTertiary)
                                }

                                matchBadge
                            }
                        }

                        Rectangle()
                            .fill(WatchdTheme.separator)
                            .frame(height: 1)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("INHALT")
                                .font(WatchdTheme.labelUppercase())
                                .foregroundColor(WatchdTheme.textTertiary)
                                .tracking(0.5)
                            Text(match.movie.overview)
                                .font(WatchdTheme.body())
                                .foregroundColor(WatchdTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(4)
                        }

                        Rectangle()
                            .fill(WatchdTheme.separator)
                            .frame(height: 1)

                        streamingSection
                    }
                    .padding(24)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(WatchdTheme.background, for: .navigationBar)
    }

    @ViewBuilder
    private var heroPoster: some View {
        ZStack(alignment: .bottom) {
            if let url = match.movie.posterURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        WatchdTheme.backgroundCard
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .clipped()
            } else {
                WatchdTheme.backgroundCard
                    .frame(maxWidth: .infinity)
                    .frame(height: 420)
            }

            LinearGradient(
                colors: [
                    .clear,
                    WatchdTheme.background.opacity(0.4),
                    WatchdTheme.background
                ],
                startPoint: .init(x: 0.5, y: 0.3),
                endPoint: .bottom
            )
        }
        .frame(height: 420)
    }

    private var matchBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "heart.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("Match")
                .font(WatchdTheme.captionMedium())
        }
        .foregroundColor(WatchdTheme.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(WatchdTheme.primary.opacity(0.2))
        .clipShape(Capsule())
    }

    private var streamingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !match.streamingOptions.isEmpty {
                Text("WO SCHAUEN?")
                    .font(WatchdTheme.labelUppercase())
                    .foregroundColor(WatchdTheme.textTertiary)
                    .tracking(0.5)

                StreamingBadgesGrid(options: match.streamingOptions)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Nicht auf Streaming-Diensten verfügbar")
                        .font(WatchdTheme.caption())
                }
                .foregroundColor(WatchdTheme.textTertiary)
            }
        }
    }
}
