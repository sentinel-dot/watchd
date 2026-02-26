import SwiftUI

struct MovieDetailView: View {
    let match: Match

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

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero poster
                    heroPoster
                        .ignoresSafeArea(edges: .top)

                    // Content
                    VStack(alignment: .leading, spacing: 24) {
                        // Title + meta
                        VStack(alignment: .leading, spacing: 10) {
                            Text(match.movie.title)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))

                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.20))
                                    Text(String(format: "%.1f", match.movie.voteAverage))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                                }

                                if let year = match.movie.releaseYear {
                                    Text(year)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                }

                                matchBadge
                            }
                        }

                        Rectangle()
                            .fill(Color(red: 0.9, green: 0.88, blue: 0.86))
                            .frame(height: 1)

                        // Overview
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Inhalt")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Text(match.movie.overview)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(4)
                        }

                        // Streaming
                        Rectangle()
                            .fill(Color(red: 0.9, green: 0.88, blue: 0.86))
                            .frame(height: 1)
                        
                        streamingSection
                    }
                    .padding(24)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    // MARK: - Hero Poster

    @ViewBuilder
    private var heroPoster: some View {
        ZStack(alignment: .bottom) {
            if let url = match.movie.posterURL {
                AsyncImage(url: url) { phase in
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
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .clipped()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.9, green: 0.88, blue: 0.86),
                        Color(red: 0.85, green: 0.82, blue: 0.80)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(maxWidth: .infinity)
                .frame(height: 420)
            }

            LinearGradient(
                colors: [
                    .clear,
                    Color(red: 0.98, green: 0.96, blue: 0.94).opacity(0.3),
                    Color(red: 0.98, green: 0.96, blue: 0.94)
                ],
                startPoint: .init(x: 0.5, y: 0.3),
                endPoint: .bottom
            )
        }
        .frame(height: 420)
    }

    // MARK: - Match Badge

    private var matchBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "heart.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("Match")
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(red: 0.85, green: 0.30, blue: 0.25).opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Streaming Section

    private var streamingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !match.streamingOptions.isEmpty {
                Text("Wo schauen?")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    .textCase(.uppercase)
                    .tracking(0.5)

                StreamingBadgesGrid(options: match.streamingOptions)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Nicht auf Streaming-Diensten verfügbar")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
            }
        }
    }
}
