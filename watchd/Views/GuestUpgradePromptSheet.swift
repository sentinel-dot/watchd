import SwiftUI

struct GuestUpgradePromptSheet: View {
    @Environment(\.theme) private var theme
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            theme.colors.base.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "lock.shield")
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(theme.colors.accent)

                Text("Sichere deine Matches")
                    .font(theme.fonts.titleLarge)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Du bist gerade als Gast eingeloggt. Wenn du dich ausloggst oder die App neu installierst, gehen alle Matches und Favoriten verloren. Leg ein Konto an, um sie dauerhaft zu sichern — dauert 20 Sekunden.")
                    .font(theme.fonts.bodyRegular)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onUpgrade) {
                        Text("Jetzt sichern")
                            .font(theme.fonts.bodyMedium)
                            .foregroundColor(theme.colors.textOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.colors.primaryButtonGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Button(action: onDismiss) {
                        Text("Später")
                            .font(theme.fonts.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
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
