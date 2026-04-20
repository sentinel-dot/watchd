import SwiftUI

struct GuestUpgradePromptSheet: View {
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            WatchdTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "lock.shield")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundColor(WatchdTheme.primary)

                Text("Sichere deine Matches")
                    .font(WatchdTheme.titleLarge())
                    .foregroundColor(WatchdTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Du bist gerade als Gast eingeloggt. Wenn du dich ausloggst oder die App neu installierst, gehen alle Matches und Favoriten verloren. Leg ein Konto an, um sie dauerhaft zu sichern — dauert 20 Sekunden.")
                    .font(WatchdTheme.body())
                    .foregroundColor(WatchdTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onUpgrade) {
                        Text("Jetzt sichern")
                            .font(WatchdTheme.bodyMedium())
                            .foregroundColor(WatchdTheme.textOnPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(WatchdTheme.primaryButtonGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Button(action: onDismiss) {
                        Text("Später")
                            .font(WatchdTheme.bodyMedium())
                            .foregroundColor(WatchdTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}
