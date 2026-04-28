import SwiftUI

struct MatchView: View {
    let match: SocketMatchEvent
    let partnershipId: Int
    let onDismiss: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var revealStage: Int = 0
    @State private var bloomActive: Bool = false

    // Reveal stages: 0 nothing, 1 headline, 2 subtitle, 3 poster, 4 title+meta, 5 providers, 6 ctas
    private let stageDelays: [Double] = [0.0, 0.15, 0.30, 0.45, 0.60, 0.75]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.base.ignoresSafeArea()

                if !reduceMotion {
                    bloomLayer
                        .ignoresSafeArea()
                }

                ScrollView {
                    VStack(spacing: 0) {
                        headlineBlock
                            .padding(.top, 32)
                            .padding(.bottom, 32)

                        posterBlock
                            .padding(.bottom, 24)

                        titleBlock
                            .padding(.horizontal, 32)
                            .padding(.bottom, 24)

                        providersBlock
                            .padding(.horizontal, 28)
                            .padding(.bottom, 36)

                        actionsBlock
                            .padding(.horizontal, 28)
                            .padding(.bottom, 44)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(theme.colors.base, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.colors.textTertiary)
                    }
                    .accessibilityLabel("Schließen")
                }
            }
        }
        .onAppear(perform: triggerHeroMoment)
    }

    // MARK: - Hero orchestration

    private func triggerHeroMoment() {
        triggerSensoryFeedback()

        if reduceMotion {
            // Opacity-only reveal, alles sofort sichtbar
            revealStage = 6
            return
        }

        withAnimation(theme.motion.easeOutExpo) {
            bloomActive = true
        }

        for (index, delay) in stageDelays.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(theme.motion.easeOutQuart) {
                    if revealStage < index + 1 {
                        revealStage = index + 1
                    }
                }
            }
        }
    }

    private func triggerSensoryFeedback() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func isRevealed(stage: Int) -> Bool {
        reduceMotion || revealStage >= stage
    }

    // MARK: - Bloom

    private var bloomLayer: some View {
        GeometryReader { geo in
            RadialGradient(
                colors: [
                    theme.colors.accent.opacity(0.55),
                    theme.colors.accent.opacity(0.12),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: max(geo.size.width, geo.size.height) * 0.8
            )
            .scaleEffect(bloomActive ? 1.25 : 0.3)
            .opacity(bloomActive ? 0.0 : 0.85)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Headline

    private var headlineBlock: some View {
        VStack(spacing: 10) {
            Text("Match.")
                .font(theme.fonts.display(size: 56, weight: .regular))
                .italic()
                .foregroundColor(theme.colors.accent)
                .opacity(isRevealed(stage: 1) ? 1 : 0)
                .offset(y: isRevealed(stage: 1) ? 0 : 12)

            Text("Ihr wollt beide diesen Film schauen.")
                .font(theme.fonts.bodyRegular)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(isRevealed(stage: 2) ? 1 : 0)
                .offset(y: isRevealed(stage: 2) ? 0 : 8)
        }
    }

    // MARK: - Poster

    private var posterBlock: some View {
        Group {
            if let url = match.posterURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.5), radius: 30, y: 14)
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.colors.surfaceCard)
                            .frame(width: 210, height: 320)
                    }
                }
            }
        }
        .opacity(isRevealed(stage: 3) ? 1 : 0)
        .scaleEffect(isRevealed(stage: 3) ? 1.0 : 0.96)
    }

    // MARK: - Title Block

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text(match.movieTitle)
                .font(theme.fonts.titleLarge)
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(isRevealed(stage: 4) ? 1 : 0)
        .offset(y: isRevealed(stage: 4) ? 0 : 6)
    }

    // MARK: - Providers

    @ViewBuilder
    private var providersBlock: some View {
        if !match.streamingOptions.isEmpty {
            VStack(spacing: 14) {
                Text("Verfügbar bei")
                    .font(theme.fonts.microCaption)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(theme.colors.textTertiary)

                MatchProviderStrip(options: match.streamingOptions)
            }
            .opacity(isRevealed(stage: 5) ? 1 : 0)
            .offset(y: isRevealed(stage: 5) ? 0 : 8)
        } else {
            VStack(spacing: 8) {
                Text("Streaming-Infos folgen")
                    .font(theme.fonts.microCaption)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(theme.colors.textTertiary)
                Text("Für diesen Film liegen aktuell keine Streaming-Daten vor.")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(isRevealed(stage: 5) ? 1 : 0)
        }
    }

    // MARK: - CTAs

    private var actionsBlock: some View {
        VStack(spacing: 12) {
            Button(action: onDismiss) {
                Text("Weiter schauen")
                    .font(theme.fonts.bodyMedium)
                    .foregroundColor(theme.colors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(theme.colors.primaryButtonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            NavigationLink(destination: MatchesListView(partnershipId: partnershipId)) {
                Text("Alle Matches")
                    .font(theme.fonts.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.colors.separator, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .opacity(isRevealed(stage: 6) ? 1 : 0)
        .offset(y: isRevealed(stage: 6) ? 0 : 6)
    }
}

// MARK: - Provider Strip (Match hero)

private struct MatchProviderStrip: View {
    let options: [StreamingOption]
    @Environment(\.theme) private var theme

    private var uniqueProviders: [StreamingOption] {
        var seen = Set<String>()
        return options.filter { seen.insert($0.package.clearName).inserted }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(uniqueProviders.prefix(6)) { option in
                    ProviderChip(option: option)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

private struct ProviderChip: View {
    let option: StreamingOption
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: option.package.iconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                default:
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.colors.surfaceInput)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(theme.colors.textTertiary.opacity(0.5))
                        )
                }
            }

            Text(option.package.clearName)
                .font(theme.fonts.body(size: 13, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(theme.colors.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.colors.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
