import SwiftUI

struct UpgradeAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                WatchdTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(WatchdTheme.iconLarge())
                                .foregroundColor(WatchdTheme.primary)
                            Text("Konto erstellen")
                                .font(WatchdTheme.titleLarge())
                                .foregroundColor(WatchdTheme.textPrimary)
                            Text("Sichere deine Daten mit einem Konto")
                                .font(WatchdTheme.body())
                                .foregroundColor(WatchdTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 12)

                        VStack(spacing: 18) {
                            AuthField(icon: "envelope.fill", placeholder: "E-Mail", text: $email, keyboardType: .emailAddress)
                            AuthField(icon: "lock.fill", placeholder: "Passwort", text: $password, isSecure: true)
                            AuthField(icon: "lock.fill", placeholder: "Passwort bestätigen", text: $confirmPassword, isSecure: true)

                            if let error = errorMessage {
                                Text(error)
                                    .font(WatchdTheme.caption())
                                    .foregroundColor(WatchdTheme.primary)
                                    .multilineTextAlignment(.center)
                            }

                            PrimaryButton(title: "Konto erstellen", isLoading: isLoading) {
                                Task { await upgradeAccount() }
                            }
                            .padding(.top, 4)
                        }
                        .padding(28)
                        .background(WatchdTheme.backgroundCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            Text("Deine Vorteile:")
                                .font(WatchdTheme.bodyMedium())
                                .foregroundColor(WatchdTheme.textPrimary)

                            VStack(alignment: .leading, spacing: 10) {
                                BenefitRow(icon: "lock.shield.fill", text: "Deine Rooms und Matches bleiben erhalten")
                                BenefitRow(icon: "arrow.triangle.2.circlepath", text: "Passwort zurücksetzen möglich")
                                BenefitRow(icon: "iphone.and.arrow.forward", text: "Auf mehreren Geräten nutzbar")
                            }
                            .padding(.horizontal, 32)
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(WatchdTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(WatchdTheme.textSecondary)
                }
            }
        }
    }

    private func upgradeAccount() async {
        guard !email.isEmpty else {
            errorMessage = "Bitte E-Mail eingeben"
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Passwort muss mindestens 8 Zeichen lang sein"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwörter stimmen nicht überein"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        await authVM.upgradeAccount(email: email, password: password)

        if authVM.errorMessage == nil {
            dismiss()
        } else {
            errorMessage = authVM.errorMessage
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(WatchdTheme.iconMedium())
                .foregroundColor(WatchdTheme.primary)
                .frame(width: 24)

            Text(text)
                .font(WatchdTheme.caption())
                .foregroundColor(WatchdTheme.textSecondary)

            Spacer()
        }
    }
}

#Preview {
    UpgradeAccountView()
        .environmentObject(AuthViewModel.shared)
        .preferredColorScheme(.dark)
}
