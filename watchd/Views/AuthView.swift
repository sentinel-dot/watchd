import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showRegister = false

    var body: some View {
        ZStack {
            WatchdTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    Text("watchd")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(WatchdTheme.primary)
                    Text("Findet gemeinsam euren nächsten Film")
                        .font(WatchdTheme.body())
                        .foregroundColor(WatchdTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 48)

                LoginForm(onRegisterTap: { showRegister = true })
                    .padding(.horizontal, 24)

                Button(action: {
                    Task { await authVM.guestLogin() }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.dashed")
                            .font(.system(size: 15, weight: .medium))
                        Text("Als Gast fortfahren")
                            .font(WatchdTheme.bodyMedium())
                    }
                    .foregroundColor(WatchdTheme.textSecondary)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 28)
                }
                .padding(.top, 20)
                .disabled(authVM.isLoading)

                Spacer()
            }
            // Keyboard slides over the spacers instead of pushing content up
            .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
    }
}

// MARK: - Login Form

private struct LoginForm: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    let onRegisterTap: () -> Void

    // Separate Bool focus states ensure .focused() lands directly on TextField/SecureField
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Text("Willkommen zurück")
                    .font(WatchdTheme.titleMedium())
                    .foregroundColor(WatchdTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 14) {
                    AuthField(
                        icon: "envelope.fill", placeholder: "E-Mail", text: $email,
                        keyboardType: .emailAddress, textContentType: .emailAddress,
                        submitLabel: .next, onSubmit: { isPasswordFocused = true },
                        focusState: $isEmailFocused
                    )
                    AuthField(
                        icon: "lock.fill", placeholder: "Passwort", text: $password,
                        isSecure: true, textContentType: .password,
                        submitLabel: .go,
                        onSubmit: { Task { await authVM.login(email: email, password: password) } },
                        focusState: $isPasswordFocused
                    )
                }

                if let msg = authVM.errorMessage {
                    Text(msg)
                        .font(WatchdTheme.caption())
                        .foregroundColor(WatchdTheme.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(title: "Anmelden", isLoading: authVM.isLoading) {
                    Task { await authVM.login(email: email, password: password) }
                }
                .padding(.top, 4)

                Button(action: { showForgotPassword = true }) {
                    Text("Passwort vergessen?")
                        .font(WatchdTheme.caption())
                        .foregroundColor(WatchdTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 6)
            }
            .padding(.horizontal, 28)
            .padding(.top, 32)
            .padding(.bottom, 24)

            Rectangle()
                .fill(WatchdTheme.separator)
                .frame(height: 1)
                .padding(.horizontal, 28)

            Button(action: onRegisterTap) {
                HStack(spacing: 6) {
                    Text("Noch kein Konto?")
                        .font(WatchdTheme.body())
                        .foregroundColor(WatchdTheme.textSecondary)
                    Text("Jetzt registrieren")
                        .font(WatchdTheme.bodyMedium())
                        .foregroundColor(WatchdTheme.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .background(WatchdTheme.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
}

// MARK: - Register View

private struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @FocusState private var isNameFocused: Bool
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @FocusState private var isConfirmPasswordFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                WatchdTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 20) {
                            Text("watchd")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(WatchdTheme.primary)

                            VStack(spacing: 6) {
                                Text("Konto erstellen")
                                    .font(WatchdTheme.titleLarge())
                                    .foregroundColor(WatchdTheme.textPrimary)
                                Text("Werde Teil der watchd Community")
                                    .font(WatchdTheme.body())
                                    .foregroundColor(WatchdTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 32)

                        VStack(spacing: 20) {
                            AuthField(
                                icon: "person.fill", placeholder: "Name", text: $name,
                                textContentType: .name,
                                submitLabel: .next, onSubmit: { isEmailFocused = true },
                                focusState: $isNameFocused
                            )
                            AuthField(
                                icon: "envelope.fill", placeholder: "E-Mail", text: $email,
                                keyboardType: .emailAddress, textContentType: .emailAddress,
                                submitLabel: .next, onSubmit: { isPasswordFocused = true },
                                focusState: $isEmailFocused
                            )
                            AuthField(
                                icon: "lock.fill", placeholder: "Passwort (mind. 8 Zeichen)", text: $password,
                                isSecure: true, textContentType: .newPassword,
                                submitLabel: .next, onSubmit: { isConfirmPasswordFocused = true },
                                focusState: $isPasswordFocused
                            )
                            AuthField(
                                icon: "lock.fill", placeholder: "Passwort bestätigen", text: $confirmPassword,
                                isSecure: true, textContentType: .newPassword,
                                submitLabel: .join,
                                onSubmit: { Task { await register() } },
                                focusState: $isConfirmPasswordFocused
                            )

                            if let msg = authVM.errorMessage {
                                Text(msg)
                                    .font(WatchdTheme.caption())
                                    .foregroundColor(WatchdTheme.primary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            PrimaryButton(title: "Registrieren", isLoading: authVM.isLoading) {
                                Task { await register() }
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 32)
                        .background(WatchdTheme.backgroundCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)

                        Spacer(minLength: 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Zurück")
                                .font(WatchdTheme.body())
                        }
                        .foregroundColor(WatchdTheme.primary)
                    }
                }
            }
        }
    }

    private func register() async {
        guard password == confirmPassword else {
            authVM.errorMessage = "Passwörter stimmen nicht überein"
            return
        }
        guard password.count >= 8 else {
            authVM.errorMessage = "Passwort muss mindestens 8 Zeichen lang sein"
            return
        }
        await authVM.register(name: name, email: email, password: password)
    }
}

// MARK: - Auth Field

struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var textContentType: UITextContentType? = nil
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil
    var focusState: FocusState<Bool>.Binding? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(WatchdTheme.textTertiary)
                .frame(width: 20)

            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(WatchdTheme.textTertiary))
                    .foregroundColor(WatchdTheme.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .textContentType(textContentType)
                    .submitLabel(submitLabel)
                    .onSubmit { onSubmit?() }
                    .optionallyFocused(focusState)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(WatchdTheme.textTertiary))
                    .foregroundColor(WatchdTheme.textPrimary)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                    .textContentType(textContentType)
                    .submitLabel(submitLabel)
                    .onSubmit { onSubmit?() }
                    .optionallyFocused(focusState)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(WatchdTheme.backgroundInput)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Focus Helper

private extension View {
    @ViewBuilder
    func optionallyFocused(_ binding: FocusState<Bool>.Binding?) -> some View {
        if let b = binding {
            self.focused(b)
        } else {
            self
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
