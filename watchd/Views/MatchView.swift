import SwiftUI

struct MatchView: View {
    let match: SocketMatchEvent
    let roomId: Int
    let onDismiss: () -> Void

    @State private var showMatches = false

    var body: some View {
        NavigationStack {
            ZStack {
                WatchdTheme.background.ignoresSafeArea()

                ConfettiView()

                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 14) {
                            Text("🎉")
                                .font(WatchdTheme.placeholderPosterIcon())

                            Text("Es ist ein Match!")
                                .font(WatchdTheme.titleLarge())
                                .foregroundColor(WatchdTheme.primary)

                            Text("Ihr wollt beide diesen Film schauen")
                                .font(WatchdTheme.body())
                                .foregroundColor(WatchdTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 36)

                        posterSection
                            .padding(.bottom, 28)

                        streamingSection
                            .padding(.bottom, 32)

                        VStack(spacing: 14) {
                            Button(action: onDismiss) {
                                Text("Weiter swipen")
                                    .font(WatchdTheme.bodyMedium())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(WatchdTheme.primaryButtonGradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }

                            NavigationLink(destination: MatchesListView(roomId: roomId)) {
                                Text("Alle Matches anzeigen")
                                    .font(WatchdTheme.bodyMedium())
                                    .foregroundColor(WatchdTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(WatchdTheme.backgroundCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(WatchdTheme.separator, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 44)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(WatchdTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(WatchdTheme.titleMedium())
                            .foregroundColor(WatchdTheme.textTertiary)
                    }
                }
            }
        }
    }

    private var posterSection: some View {
        VStack(spacing: 16) {
            if let url = match.posterURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.4), radius: 24, y: 12)
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(WatchdTheme.backgroundCard)
                            .frame(width: 200, height: 320)
                    }
                }
            }

            Text(match.movieTitle)
                .font(WatchdTheme.titleMedium())
                .foregroundColor(WatchdTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var streamingSection: some View {
        VStack(spacing: 16) {
            if !match.streamingOptions.isEmpty {
                Text("VERFÜGBAR BEI")
                    .font(WatchdTheme.labelUppercase())
                    .foregroundColor(WatchdTheme.textTertiary)
                    .tracking(0.5)

                StreamingBadgesGrid(options: match.streamingOptions)
                    .padding(.horizontal, 32)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(WatchdTheme.chevron())
                    Text("Nicht auf Streaming-Diensten verfügbar")
                        .font(WatchdTheme.caption())
                }
                .foregroundColor(WatchdTheme.textTertiary)
            }
        }
    }
}

// MARK: - Streaming Badges Grid (Netflix-style)

struct StreamingBadgesGrid: View {
    let options: [StreamingOption]

    private var uniqueProviders: [StreamingOption] {
        var seen = Set<String>()
        return options.filter { seen.insert($0.package.clearName).inserted }
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(uniqueProviders.prefix(6)) { option in
                StreamingBadge(option: option)
            }
        }
    }
}

struct StreamingBadge: View {
    let option: StreamingOption

    private static let badgeHeight: CGFloat = 118

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: option.package.iconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                default:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(WatchdTheme.backgroundInput)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .foregroundColor(WatchdTheme.textTertiary.opacity(0.5))
                        )
                }
            }

            Text(option.package.clearName)
                .font(WatchdTheme.labelUppercase())
                .foregroundColor(WatchdTheme.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .frame(height: Self.badgeHeight)
        .background(WatchdTheme.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(WatchdTheme.separator, lineWidth: 1)
        )
    }
}

// MARK: - Confetti (Netflix red + accent colors)

struct ConfettiView: View {
    private let particles: [ConfettiParticle] = (0..<120).map { _ in ConfettiParticle() }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let cycleLength = particle.duration
                    let offsetTime = now + particle.startOffset
                    let progress = offsetTime.truncatingRemainder(dividingBy: cycleLength) / cycleLength

                    let x = particle.xRatio * size.width + sin(progress * .pi * 5 + particle.phase) * particle.wobble
                    let y = (progress * (size.height + 100)) - 50

                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: Angle(radians: progress * .pi * 4 * particle.spin))

                    let rect = CGRect(x: -particle.size / 2, y: -particle.size * 0.4,
                                      width: particle.size, height: particle.size * 0.7)
                    ctx.opacity = progress < 0.1 ? progress * 10 : (progress > 0.85 ? (1 - progress) * 6.67 : 1)
                    ctx.fill(Path(rect), with: .color(particle.color))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

struct ConfettiParticle {
    let xRatio: Double
    let size: Double
    let color: Color
    let duration: Double
    let phase: Double
    let spin: Double
    let wobble: Double
    let startOffset: Double

    private static let colors: [Color] = [
        WatchdTheme.primary,
        WatchdTheme.rating,
        WatchdTheme.success,
        Color(red: 0.30, green: 0.50, blue: 0.90),
        Color(red: 0.90, green: 0.40, blue: 0.60),
        WatchdTheme.textSecondary
    ]

    init() {
        xRatio = Double.random(in: 0...1)
        size = Double.random(in: 8...16)
        color = Self.colors.randomElement()!
        duration = Double.random(in: 3.0...5.0)
        phase = Double.random(in: 0...(2 * .pi))
        spin = Double.random(in: 0.6...2.8) * (Bool.random() ? 1.0 : -1.0)
        wobble = Double.random(in: 25...60)
        startOffset = Double.random(in: 0...5.0)
    }
}
