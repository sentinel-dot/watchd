import SwiftUI

struct MovieDetailView: View {
    private let match: Match?
    private let favorite: Favorite?

    @Environment(\.theme) private var theme

    init(match: Match) {
        self.match = match
        self.favorite = nil
    }

    init(favorite: Favorite) {
        self.match = nil
        self.favorite = favorite
    }

    private var movie: MatchMovie {
        match?.movie ?? favorite!.movie
    }

    private var streamingOptions: [StreamingOption] {
        match?.streamingOptions ?? favorite!.streamingOptions
    }

    private var showMatchBadge: Bool { match != nil }

    var body: some View {
        ZStack {
            theme.colors.base.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroPoster
                        .ignoresSafeArea(edges: .top)

                    VStack(alignment: .leading, spacing: 28) {
                        titleBlock

                        pullQuoteOverview

                        streamingSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(theme.colors.base, for: .navigationBar)
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroPoster: some View {
        ZStack(alignment: .bottom) {
            if let url = movie.posterURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    default:
                        theme.colors.surfaceCard
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 440)
            } else {
                theme.colors.surfaceCard
                    .frame(maxWidth: .infinity)
                    .frame(height: 440)
            }

            LinearGradient(
                colors: [
                    .clear,
                    theme.colors.base.opacity(0.35),
                    theme.colors.base
                ],
                startPoint: .init(x: 0.5, y: 0.35),
                endPoint: .bottom
            )
        }
    }

    // MARK: - Title Block

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(movie.title)
                .font(theme.fonts.displayHero)
                .foregroundColor(theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.rating)
                    Text(String(format: "%.1f", movie.voteAverage))
                        .font(theme.fonts.body(size: 13, weight: .semibold))
                        .foregroundColor(theme.colors.textSecondary)
                }

                if let year = movie.releaseYear {
                    dotSeparator
                    Text(year)
                        .font(theme.fonts.body(size: 13, weight: .regular))
                        .foregroundColor(theme.colors.textSecondary)
                }

                if showMatchBadge {
                    dotSeparator
                    metaBadge(text: "Match", color: theme.colors.accent)
                }

                if favorite != nil {
                    dotSeparator
                    metaBadge(text: "Favorit", color: theme.colors.rating)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var dotSeparator: some View {
        Text("·")
            .font(theme.fonts.body(size: 13, weight: .regular))
            .foregroundColor(theme.colors.textTertiary)
    }

    private func metaBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(theme.fonts.microCaption)
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundColor(color)
    }

    // MARK: - Pull Quote Overview

    private var pullQuoteOverview: some View {
        HStack(alignment: .top, spacing: 16) {
            Rectangle()
                .fill(theme.colors.accent)
                .frame(width: 2)

            Text(movie.overview)
                .font(theme.fonts.body(size: 16, weight: .regular))
                .italic()
                .foregroundColor(theme.colors.textSecondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Streaming Section

    private var streamingSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Wo schauen")
                .font(theme.fonts.titleMedium)
                .foregroundColor(theme.colors.textPrimary)

            if !streamingOptions.isEmpty {
                VStack(spacing: 0) {
                    let providers = uniqueProviders(streamingOptions)
                    ForEach(Array(providers.enumerated()), id: \.element.id) { index, option in
                        StreamingListRow(option: option)
                        if index < providers.count - 1 {
                            Rectangle()
                                .fill(theme.colors.separator)
                                .frame(height: 1)
                        }
                    }
                }
            } else {
                Text("Für diesen Film liegen aktuell keine Streaming-Daten vor.")
                    .font(theme.fonts.bodyRegular)
                    .foregroundColor(theme.colors.textTertiary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func uniqueProviders(_ options: [StreamingOption]) -> [StreamingOption] {
        var seen = Set<String>()
        return options.filter { seen.insert($0.package.clearName).inserted }
    }
}

// MARK: - Streaming List Row

private struct StreamingListRow: View {
    let option: StreamingOption
    @Environment(\.theme) private var theme

    private var monetizationLabel: String {
        switch option.monetizationType.uppercased() {
        case "FLATRATE": return "Abo"
        case "FREE": return "Gratis"
        case "RENT": return "Leihen"
        case "BUY": return "Kaufen"
        case "ADS": return "Werbe-Abo"
        default: return option.monetizationType.capitalized
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: option.package.iconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                default:
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.colors.surfaceInput)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(theme.colors.textTertiary.opacity(0.5))
                        )
                }
            }

            Text(option.package.clearName)
                .font(theme.fonts.body(size: 15, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Text(monetizationLabel)
                .font(theme.fonts.microCaption)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(theme.colors.textTertiary)
        }
        .padding(.vertical, 14)
    }
}
