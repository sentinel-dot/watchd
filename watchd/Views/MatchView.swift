import SwiftUI

struct MatchView: View {
    let match: SocketMatchEvent
    let roomId: Int
    let onDismiss: () -> Void

    @State private var showMatches = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Sophisticated light background
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.94),
                        Color(red: 0.96, green: 0.93, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ConfettiView()

                ScrollView {
                    VStack(spacing: 0) {
                        // Celebration header
                        VStack(spacing: 12) {
                            Text("🎉")
                                .font(.system(size: 72))
                            
                            Text("Es ist ein Match!")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                            
                            Text("Ihr wollt beide diesen Film schauen")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 36)

                        // Movie poster
                        posterSection
                            .padding(.bottom, 28)

                        // Streaming section
                        streamingSection
                            .padding(.bottom, 32)

                        // Action buttons
                        VStack(spacing: 14) {
                            Button(action: onDismiss) {
                                Text("Weiter swipen")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.85, green: 0.30, blue: 0.25),
                                                Color(red: 0.90, green: 0.40, blue: 0.35)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: Color(red: 0.85, green: 0.30, blue: 0.25).opacity(0.3), radius: 20, y: 8)
                            }

                            NavigationLink(destination: MatchesListView(roomId: roomId)) {
                                Text("Alle Matches anzeigen")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: Color.black.opacity(0.06), radius: 16, y: 6)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 44)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            .font(.system(size: 24, weight: .medium))
                    }
                }
            }
        }
    }

    // MARK: - Poster Section

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
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: Color.black.opacity(0.15), radius: 24, y: 12)
                    default:
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                            .frame(width: 200, height: 320)
                            .shadow(color: Color.black.opacity(0.08), radius: 20, y: 10)
                    }
                }
            }

            Text(match.movieTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Streaming Section

    private var streamingSection: some View {
        VStack(spacing: 16) {
            if !match.streamingOptions.isEmpty {
                Text("Verfügbar bei")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    .textCase(.uppercase)
                    .tracking(0.5)

                StreamingBadgesGrid(options: match.streamingOptions)
                    .padding(.horizontal, 32)
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

// MARK: - Streaming Badges Grid

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

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: option.package.iconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                default:
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.9, green: 0.88, blue: 0.86))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6).opacity(0.4))
                        )
                }
            }

            Text(option.package.clearName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, y: 4)
        )
    }
}

// MARK: - Confetti

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
        Color(red: 0.85, green: 0.30, blue: 0.25),
        Color(red: 0.95, green: 0.77, blue: 0.20),
        Color(red: 0.20, green: 0.70, blue: 0.40),
        Color(red: 0.30, green: 0.50, blue: 0.90),
        Color(red: 0.90, green: 0.40, blue: 0.60),
        Color(red: 0.60, green: 0.35, blue: 0.75)
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
