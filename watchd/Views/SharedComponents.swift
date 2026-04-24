import SwiftUI

struct LoadingView: View {
    @Environment(\.theme) private var theme
    var message: String = "Lädt..."

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(theme.colors.accent)
                .scaleEffect(1.3)

            Text(message)
                .font(theme.fonts.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.base)
    }
}

struct EmptyStateView: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(theme.colors.textTertiary)

            Text(title)
                .font(theme.fonts.titleLarge)
                .foregroundColor(theme.colors.textPrimary)

            Text(message)
                .font(theme.fonts.bodyRegular)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(theme.fonts.bodyMedium)
                        .foregroundColor(theme.colors.textOnAccent)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(theme.colors.primaryButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.base)
    }
}

struct OfflineBanner: View {
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 16, weight: .semibold))

            Text("Keine Internetverbindung")
                .font(theme.fonts.bodyMedium)

            Spacer()
        }
        .foregroundColor(theme.colors.textOnAccent)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(theme.colors.accent)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Primary Button

struct PrimaryButton: View {
    @Environment(\.theme) private var theme
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(theme.colors.textOnAccent)
                } else {
                    Text(title)
                        .font(theme.fonts.bodyMedium)
                        .foregroundColor(theme.colors.textOnAccent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.colors.primaryButtonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .disabled(isLoading)
    }
}

#Preview("Loading") {
    LoadingView()
        .environment(\.theme, .velvetHour)
        .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "film",
        title: "Keine Matches",
        message: "Swipe durch Filme und finde gemeinsame Favoriten mit deinem Partner",
        actionTitle: "Los geht's",
        action: {}
    )
    .environment(\.theme, .velvetHour)
    .preferredColorScheme(.dark)
}

#Preview("Offline Banner") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            OfflineBanner()
            Spacer()
        }
    }
    .environment(\.theme, .velvetHour)
    .preferredColorScheme(.dark)
}
