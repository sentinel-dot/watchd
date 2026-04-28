import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    @State private var isEmailFocused = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.base.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Nº 04 · Passwort")
                                .font(theme.fonts.microCaption)
                                .textCase(.uppercase)
                                .tracking(1.8)
                                .foregroundColor(theme.colors.accent)
                            Text("Passwort vergessen?")
                                .font(theme.fonts.display(size: 32, weight: .regular))
                                .italic()
                                .foregroundColor(theme.colors.textPrimary)
                        }
                        .padding(.bottom, 28)

                        HStack(alignment: .top, spacing: 14) {
                            Rectangle()
                                .fill(theme.colors.accent)
                                .frame(width: 2, height: 42)
                            Text("Wir schicken dir einen Link per E-Mail.")
                                .font(theme.fonts.body(size: 16, weight: .regular))
                                .italic()
                                .foregroundColor(theme.colors.textSecondary)
                                .lineSpacing(3)
                        }
                        .padding(.bottom, 44)

                        AuthField(
                            label: "E-Mail-Adresse",
                            icon: "envelope", placeholder: "E-Mail", text: $email,
                            keyboardType: .emailAddress, textContentType: .emailAddress,
                            returnKeyType: .send,
                            accessibilityHint: "Wir senden den Link an diese Adresse.",
                            onSubmit: { Task { await sendResetLink() } },
                            isFocused: $isEmailFocused
                        )
                        .padding(.bottom, 20)

                        if let error = errorMessage {
                            Text(error)
                                .font(theme.fonts.caption)
                                .foregroundColor(theme.colors.error)
                                .padding(.bottom, 14)
                        }

                        if let success = successMessage {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(theme.colors.success)
                                    .padding(.top, 2)
                                Text(success)
                                    .font(theme.fonts.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.bottom, 14)
                        }

                        PrimaryButton(title: "Link senden", isLoading: isLoading) {
                            Task { await sendResetLink() }
                        }

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 32)
                }
                .scrollDismissesKeyboard(.interactively)
                .ignoresSafeArea(.keyboard, edges: .bottom)
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

    private func sendResetLink() async {
        guard !email.isEmpty else {
            errorMessage = "E-Mail fehlt."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let _ = try await APIService.shared.forgotPassword(email: email)
            successMessage = "Falls ein Konto zu dieser Adresse existiert, ist der Link unterwegs."
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ResetPasswordView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    let token: String

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var isNewPasswordFocused = false
    @State private var isConfirmPasswordFocused = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.base.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Nº 05 · Neu")
                                .font(theme.fonts.microCaption)
                                .textCase(.uppercase)
                                .tracking(1.8)
                                .foregroundColor(theme.colors.accent)
                            Text("Neues Passwort.")
                                .font(theme.fonts.display(size: 32, weight: .regular))
                                .italic()
                                .foregroundColor(theme.colors.textPrimary)
                        }
                        .padding(.bottom, 28)

                        HStack(alignment: .top, spacing: 14) {
                            Rectangle()
                                .fill(theme.colors.accent)
                                .frame(width: 2, height: 42)
                            Text("Mindestens acht Zeichen — der Rest liegt an dir.")
                                .font(theme.fonts.body(size: 16, weight: .regular))
                                .italic()
                                .foregroundColor(theme.colors.textSecondary)
                                .lineSpacing(3)
                        }
                        .padding(.bottom, 44)

                        VStack(spacing: 4) {
                            AuthField(
                                label: "Neues Passwort",
                                icon: "lock", placeholder: "Neues Passwort", text: $newPassword,
                                isSecure: true, textContentType: .newPassword,
                                returnKeyType: .next,
                                accessibilityHint: "Mindestens acht Zeichen.",
                                passwordRulesDescriptor: "minlength: 8;",
                                onSubmit: { isConfirmPasswordFocused = true },
                                isFocused: $isNewPasswordFocused
                            )
                            AuthField(
                                label: "Passwort bestätigen",
                                icon: "lock", placeholder: "Bestätigen", text: $confirmPassword,
                                isSecure: true,
                                returnKeyType: .done,
                                accessibilityHint: "Wiederhole dein neues Passwort.",
                                onSubmit: { Task { await resetPassword() } },
                                isFocused: $isConfirmPasswordFocused
                            )
                        }
                        .padding(.bottom, 20)

                        if let error = errorMessage {
                            Text(error)
                                .font(theme.fonts.caption)
                                .foregroundColor(theme.colors.error)
                                .padding(.bottom, 14)
                        }

                        PrimaryButton(title: "Passwort ändern", isLoading: isLoading) {
                            Task { await resetPassword() }
                        }

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 32)
                }
                .scrollDismissesKeyboard(.interactively)
                .ignoresSafeArea(.keyboard, edges: .bottom)
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

    private func resetPassword() async {
        guard newPassword.count >= 8 else {
            errorMessage = "Mindestens acht Zeichen, bitte."
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Die Passwörter stimmen nicht überein."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let _ = try await APIService.shared.resetPassword(token: token, newPassword: newPassword)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Forgot Password") {
    ForgotPasswordView()
        .environment(\.theme, .velvetHour)
        .preferredColorScheme(.dark)
}

#Preview("Reset Password") {
    ResetPasswordView(token: "test-token")
        .environment(\.theme, .velvetHour)
        .preferredColorScheme(.dark)
}
