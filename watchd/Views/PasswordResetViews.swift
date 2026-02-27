import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    @FocusState private var isEmailFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                WatchdTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 52, weight: .medium))
                            .foregroundColor(WatchdTheme.primary)
                        Text("Passwort vergessen?")
                            .font(WatchdTheme.titleLarge())
                            .foregroundColor(WatchdTheme.textPrimary)
                        Text("Wir senden dir einen Link zum Zurücksetzen")
                            .font(WatchdTheme.body())
                            .foregroundColor(WatchdTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 12)

                    VStack(spacing: 18) {
                        AuthField(
                            icon: "envelope.fill", placeholder: "E-Mail", text: $email,
                            keyboardType: .emailAddress, textContentType: .emailAddress,
                            submitLabel: .send, onSubmit: { Task { await sendResetLink() } },
                            focusState: $isEmailFocused
                        )

                        if let error = errorMessage {
                            Text(error)
                                .font(WatchdTheme.caption())
                                .foregroundColor(WatchdTheme.primary)
                                .multilineTextAlignment(.center)
                        }

                        if let success = successMessage {
                            Text(success)
                                .font(WatchdTheme.caption())
                                .foregroundColor(WatchdTheme.success)
                                .multilineTextAlignment(.center)
                        }

                        PrimaryButton(title: "Link senden", isLoading: isLoading) {
                            Task { await sendResetLink() }
                        }
                    }
                    .padding(28)
                    .background(WatchdTheme.backgroundCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 60)
                .ignoresSafeArea(.keyboard)
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

    private func sendResetLink() async {
        guard !email.isEmpty else {
            errorMessage = "Bitte E-Mail eingeben"
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let _ = try await APIService.shared.forgotPassword(email: email)
            successMessage = "Falls diese E-Mail registriert ist, wurde ein Reset-Link gesendet."
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    let token: String

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    @FocusState private var isNewPasswordFocused: Bool
    @FocusState private var isConfirmPasswordFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                WatchdTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 52, weight: .medium))
                            .foregroundColor(WatchdTheme.primary)
                        Text("Neues Passwort")
                            .font(WatchdTheme.titleLarge())
                            .foregroundColor(WatchdTheme.textPrimary)
                        Text("Wähle ein sicheres Passwort")
                            .font(WatchdTheme.body())
                            .foregroundColor(WatchdTheme.textSecondary)
                    }
                    .padding(.bottom, 12)

                    VStack(spacing: 18) {
                        AuthField(
                            icon: "lock.fill", placeholder: "Neues Passwort", text: $newPassword,
                            isSecure: true, textContentType: .newPassword,
                            submitLabel: .next, onSubmit: { isConfirmPasswordFocused = true },
                            focusState: $isNewPasswordFocused
                        )
                        AuthField(
                            icon: "lock.fill", placeholder: "Passwort bestätigen", text: $confirmPassword,
                            isSecure: true, textContentType: .newPassword,
                            submitLabel: .done, onSubmit: { Task { await resetPassword() } },
                            focusState: $isConfirmPasswordFocused
                        )

                        if let error = errorMessage {
                            Text(error)
                                .font(WatchdTheme.caption())
                                .foregroundColor(WatchdTheme.primary)
                                .multilineTextAlignment(.center)
                        }

                        PrimaryButton(title: "Passwort ändern", isLoading: isLoading) {
                            Task { await resetPassword() }
                        }
                    }
                    .padding(28)
                    .background(WatchdTheme.backgroundCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 60)
                .ignoresSafeArea(.keyboard)
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

    private func resetPassword() async {
        guard newPassword.count >= 8 else {
            errorMessage = "Passwort muss mindestens 8 Zeichen lang sein"
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwörter stimmen nicht überein"
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
        .preferredColorScheme(.dark)
}

#Preview("Reset Password") {
    ResetPasswordView(token: "test-token")
        .preferredColorScheme(.dark)
}
