import SwiftUI

struct UpgradeAccountView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var isEmailFocused = false
    @State private var isPasswordFocused = false
    @State private var isConfirmFocused = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.base.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Nº 03 · Sichern")
                                .font(theme.fonts.microCaption)
                                .textCase(.uppercase)
                                .tracking(1.8)
                                .foregroundColor(theme.colors.accent)
                            Text("Konto sichern.")
                                .font(theme.fonts.display(size: 34, weight: .regular))
                                .italic()
                                .foregroundColor(theme.colors.textPrimary)
                        }
                        .padding(.bottom, 28)

                        HStack(alignment: .top, spacing: 14) {
                            Rectangle()
                                .fill(theme.colors.accent)
                                .frame(width: 2, height: 62)
                            Text("Damit euer Abend auch nach dem Logout euch gehört.")
                                .font(theme.fonts.body(size: 16, weight: .regular))
                                .italic()
                                .foregroundColor(theme.colors.textSecondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, 40)

                        VStack(spacing: 4) {
                            AuthField(
                                icon: "envelope", placeholder: "E-Mail", text: $email,
                                keyboardType: .emailAddress, textContentType: .emailAddress,
                                returnKeyType: .next, onSubmit: { isPasswordFocused = true },
                                isFocused: $isEmailFocused
                            )
                            AuthField(
                                icon: "lock", placeholder: "Passwort", text: $password,
                                isSecure: true, textContentType: .newPassword,
                                returnKeyType: .next, onSubmit: { isConfirmFocused = true },
                                isFocused: $isPasswordFocused
                            )
                            AuthField(
                                icon: "lock", placeholder: "Bestätigen", text: $confirmPassword,
                                isSecure: true, textContentType: .newPassword,
                                returnKeyType: .done, onSubmit: { Task { await upgradeAccount() } },
                                isFocused: $isConfirmFocused
                            )
                        }

                        Text("Mindestens acht Zeichen.")
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.colors.textTertiary)
                            .padding(.top, 10)
                            .padding(.bottom, 18)

                        if let error = errorMessage {
                            Text(error)
                                .font(theme.fonts.caption)
                                .foregroundColor(theme.colors.error)
                                .padding(.bottom, 14)
                        }

                        PrimaryButton(title: "Konto sichern", isLoading: isLoading) {
                            Task { await upgradeAccount() }
                        }
                        .padding(.bottom, 36)

                        benefits

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(theme.colors.base, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Abbrechen")
                            .font(theme.fonts.microCaption)
                            .textCase(.uppercase)
                            .tracking(1.4)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Was bleibt")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.6)
                .foregroundColor(theme.colors.textTertiary)
                .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 14) {
                BenefitRow(ordinal: "i", text: "Räume und Matches bleiben erhalten.")
                BenefitRow(ordinal: "ii", text: "Passwort lässt sich zurücksetzen.")
                BenefitRow(ordinal: "iii", text: "Ihr könnt euch auf jedem Gerät anmelden.")
            }
        }
    }

    private func upgradeAccount() async {
        guard !email.isEmpty else {
            errorMessage = "E-Mail fehlt."
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Mindestens acht Zeichen, bitte."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Die Passwörter stimmen nicht überein."
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
    @Environment(\.theme) private var theme
    let ordinal: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(ordinal)
                .font(theme.fonts.display(size: 14, weight: .regular))
                .italic()
                .foregroundColor(theme.colors.accent)
                .frame(width: 22, alignment: .leading)

            Text(text)
                .font(theme.fonts.bodyRegular)
                .foregroundColor(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    UpgradeAccountView()
        .environmentObject(AuthViewModel.shared)
        .environment(\.theme, .velvetHour)
        .preferredColorScheme(.dark)
}
