import SwiftUI

struct MatchView: View {
    let match: SocketMatchEvent
    let roomId: Int
    let onDismiss: () -> Void

    @State private var showMatches = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                ConfettiView()

                ScrollView {
                    VStack(spacing: 0) {
                        // Headline
                        VStack(spacing: 8) {
                            Text("🎉 It's a Match!")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                                )
                            Text("You both want to watch")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 24)

                        // Poster
                        posterSection
                            .padding(.bottom, 20)

                        // Streaming
                        if !match.streamingOptions.isEmpty {
                            streamingSection
                                .padding(.bottom, 28)
                        }

                        // Buttons
                        VStack(spacing: 12) {
                            NavigationLink(destination: MatchesListView(roomId: roomId)) {
                                Text("See All Matches")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            Button(action: onDismiss) {
                                Text("Keep Swiping")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.title3)
                    }
                }
            }
        }
    }

    // MARK: - Poster Section

    private var posterSection: some View {
        VStack(spacing: 12) {
            if let url = match.posterURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.5), radius: 16, y: 8)
                    default:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 180, height: 280)
                    }
                }
            }

            Text(match.movieTitle)
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Streaming Section

    private var streamingSection: some View {
        VStack(spacing: 12) {
            Text("Available on")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))

            StreamingBadgesGrid(options: match.streamingOptions)
                .padding(.horizontal, 24)
        }
    }
}

// MARK: - Streaming Badges Grid

struct StreamingBadgesGrid: View {
    let options: [StreamingOption]

    private var uniqueProviders: [StreamingOption] {
        var seen = Set<String>()
        return options.filter { seen.insert($0.package.clearName).inserted }
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(uniqueProviders.prefix(6)) { option in
                StreamingBadge(option: option)
            }
        }
    }
}

struct StreamingBadge: View {
    let option: StreamingOption

    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: option.package.iconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                default:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .foregroundColor(.white.opacity(0.4))
                        )
                }
            }

            Text(option.package.clearName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Confetti

struct ConfettiView: View {
    private let particles: [ConfettiParticle] = (0..<90).map { _ in ConfettiParticle() }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let cycleLength = particle.duration
                    let offsetTime = now + particle.startOffset
                    let progress = offsetTime.truncatingRemainder(dividingBy: cycleLength) / cycleLength

                    let x = particle.xRatio * size.width + sin(progress * .pi * 5 + particle.phase) * particle.wobble
                    let y = (progress * (size.height + 80)) - 40

                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: Angle(radians: progress * .pi * 4 * particle.spin))

                    let rect = CGRect(x: -particle.size / 2, y: -particle.size * 0.35,
                                      width: particle.size, height: particle.size * 0.65)
                    ctx.opacity = progress < 0.1 ? progress * 10 : (progress > 0.8 ? (1 - progress) * 5 : 1)
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

    private static let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .orange, .purple, .cyan]

    init() {
        xRatio = Double.random(in: 0...1)
        size = Double.random(in: 7...15)
        color = Self.colors.randomElement()!
        duration = Double.random(in: 2.5...4.5)
        phase = Double.random(in: 0...(2 * .pi))
        spin = Double.random(in: 0.5...2.5) * (Bool.random() ? 1.0 : -1.0)
        wobble = Double.random(in: 20...50)
        startOffset = Double.random(in: 0...4.5)
    }
}
