import SwiftUI

struct MovieDetailView: View {
    let match: Match

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.12).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero poster
                    heroPoster
                        .ignoresSafeArea(edges: .top)

                    // Content
                    VStack(alignment: .leading, spacing: 20) {
                        // Title + meta
                        VStack(alignment: .leading, spacing: 8) {
                            Text(match.movie.title)
                                .font(.title.weight(.bold))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                Label(String(format: "%.1f", match.movie.voteAverage), systemImage: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.subheadline.weight(.semibold))

                                if let year = match.movie.releaseYear {
                                    Text(year)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.6))
                                }

                                matchBadge
                            }
                        }

                        Divider().background(Color.white.opacity(0.1))

                        // Overview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Overview")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            Text(match.movie.overview)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Streaming
                        if !match.streamingOptions.isEmpty {
                            Divider().background(Color.white.opacity(0.1))
                            streamingSection
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
                        Color.white.opacity(0.1)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .clipped()
            } else {
                Color.white.opacity(0.1)
                    .frame(maxWidth: .infinity)
                    .frame(height: 380)
            }

            LinearGradient(
                colors: [.clear, Color(red: 0.06, green: 0.06, blue: 0.12)],
                startPoint: .init(x: 0.5, y: 0.4),
                endPoint: .bottom
            )
        }
        .frame(height: 380)
    }

    // MARK: - Match Badge

    private var matchBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.caption2)
            Text("Matched")
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(.pink)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.pink.opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - Streaming Section

    private var streamingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where to Watch")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))

            StreamingBadgesGrid(options: match.streamingOptions)
        }
    }
}
