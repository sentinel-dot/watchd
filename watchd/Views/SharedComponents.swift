import SwiftUI

struct LoadingView: View {
    var message: String = "Lädt..."
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(WatchdTheme.primary)
                .scaleEffect(1.3)
            
            Text(message)
                .font(WatchdTheme.bodyMedium())
                .foregroundColor(WatchdTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WatchdTheme.background)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(WatchdTheme.emptyStateIcon())
                .foregroundColor(WatchdTheme.textTertiary)
            
            Text(title)
                .font(WatchdTheme.titleLarge())
                .foregroundColor(WatchdTheme.textPrimary)
            
            Text(message)
                .font(WatchdTheme.body())
                .foregroundColor(WatchdTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(WatchdTheme.bodyMedium())
                        .foregroundColor(WatchdTheme.textOnPrimary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(WatchdTheme.primaryButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WatchdTheme.background)
    }
}

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(WatchdTheme.iconSmall())
            
            Text("Keine Internetverbindung")
                .font(WatchdTheme.bodyMedium())
            
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(WatchdTheme.primary)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview("Loading") {
    LoadingView()
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
    .preferredColorScheme(.dark)
}

// MARK: - Primary Button (Netflix CTA)

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(title)
                        .font(WatchdTheme.bodyMedium())
                        .foregroundColor(WatchdTheme.textOnPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(WatchdTheme.primaryButtonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .disabled(isLoading)
    }
}

#Preview("Offline Banner") {
    ZStack {
        WatchdTheme.background.ignoresSafeArea()
        VStack {
            OfflineBanner()
            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}
