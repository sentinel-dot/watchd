import SwiftUI

struct AuthView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showRegister = false

    var body: some View {
        ZStack {
            theme.colors.base.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    mast
                        .padding(.bottom, 36)

                    tagline
                        .padding(.bottom, 48)

                    LoginForm(onRegisterTap: { showRegister = true })
                        .padding(.bottom, 28)

                    Rectangle()
                        .fill(theme.colors.separator)
                        .frame(height: 1)
                        .padding(.bottom, 22)

                    bottomActions
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 28)
                .padding(.top, 72)
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(.keyboard, edges: .bottom)

            KeyboardWarmupView()
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
    }

    private var mast: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nº 01")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.8)
                .foregroundColor(theme.colors.accent)

            Text("Watchd.")
                .font(theme.fonts.displayHero)
                .italic()
                .foregroundColor(theme.colors.textPrimary)
        }
    }

    private var tagline: some View {
        HStack(alignment: .top, spacing: 14) {
            Rectangle()
                .fill(theme.colors.accent)
                .frame(width: 2, height: 44)

            Text("Zwei Meinungen, ein Abend.")
                .font(theme.fonts.body(size: 18, weight: .regular))
                .italic()
                .foregroundColor(theme.colors.textSecondary)
                .lineSpacing(3)
        }
    }

    private var bottomActions: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button(action: { showRegister = true }) {
                HStack(spacing: 6) {
                    Text("Noch kein Konto?")
                        .font(theme.fonts.bodyRegular)
                        .foregroundColor(theme.colors.textSecondary)
                    Text("Konto erstellen")
                        .font(theme.fonts.bodyMedium)
                        .foregroundColor(theme.colors.accent)
                }
            }

            // TODO Phase 9: SignInWithAppleButton
        }
    }
}

// MARK: - Login Form

private struct LoginForm: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    let onRegisterTap: () -> Void

    @State private var isEmailFocused = false
    @State private var isPasswordFocused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Anmelden")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.6)
                .foregroundColor(theme.colors.textTertiary)

            VStack(spacing: 4) {
                AuthField(
                    label: "E-Mail-Adresse",
                    icon: "envelope",
                    placeholder: "E-Mail",
                    text: $email,
                    keyboardType: .emailAddress,
                    textContentType: .username,
                    returnKeyType: .next,
                    accessibilityHint: "Nutze die E-Mail-Adresse deines Kontos.",
                    onSubmit: { isPasswordFocused = true },
                    isFocused: $isEmailFocused
                )
                AuthField(
                    label: "Passwort",
                    icon: "lock",
                    placeholder: "Passwort",
                    text: $password,
                    isSecure: true,
                    textContentType: .password,
                    returnKeyType: .go,
                    accessibilityHint: "Gib dein Kontopasswort ein.",
                    onSubmit: { Task { await authVM.login(email: email, password: password) } },
                    isFocused: $isPasswordFocused
                )
            }

            if let msg = authVM.errorMessage {
                Text(msg)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.error)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: "Anmelden", isLoading: authVM.isLoading) {
                Task { await authVM.login(email: email, password: password) }
            }
            .padding(.top, 2)

            Button(action: { showForgotPassword = true }) {
                Text("Passwort vergessen?")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
}

// MARK: - Register View

private struct RegisterView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var isNameFocused = false
    @State private var isEmailFocused = false
    @State private var isPasswordFocused = false
    @State private var isConfirmPasswordFocused = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.base.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Nº 02 · Konto")
                                .font(theme.fonts.microCaption)
                                .textCase(.uppercase)
                                .tracking(1.8)
                                .foregroundColor(theme.colors.accent)
                            Text("Konto erstellen.")
                                .font(theme.fonts.display(size: 34, weight: .regular))
                                .italic()
                                .foregroundColor(theme.colors.textPrimary)
                        }
                        .padding(.bottom, 28)

                        HStack(alignment: .top, spacing: 14) {
                            Rectangle()
                                .fill(theme.colors.accent)
                                .frame(width: 2, height: 42)
                            Text("Damit eure Matches und Favoriten erhalten bleiben.")
                                .font(theme.fonts.body(size: 16, weight: .regular))
                                .italic()
                                .foregroundColor(theme.colors.textSecondary)
                                .lineSpacing(3)
                        }
                        .padding(.bottom, 44)

                        VStack(spacing: 4) {
                            AuthField(
                                label: "Name",
                                icon: "person", placeholder: "Name", text: $name,
                                textContentType: .name,
                                returnKeyType: .next,
                                autocapitalizationType: .words,
                                autocorrectionType: .default,
                                spellCheckingType: .default,
                                accessibilityHint: "So sehen andere dich in Watchd.",
                                onSubmit: { isEmailFocused = true },
                                isFocused: $isNameFocused
                            )
                            AuthField(
                                label: "E-Mail-Adresse",
                                icon: "envelope", placeholder: "E-Mail", text: $email,
                                keyboardType: .emailAddress, textContentType: .emailAddress,
                                returnKeyType: .next,
                                accessibilityHint: "Diese Adresse nutzt du später zum Anmelden.",
                                onSubmit: { isPasswordFocused = true },
                                isFocused: $isEmailFocused
                            )
                            AuthField(
                                label: "Passwort",
                                icon: "lock", placeholder: "Passwort", text: $password,
                                isSecure: true, textContentType: .newPassword,
                                returnKeyType: .next,
                                accessibilityHint: "Mindestens acht Zeichen.",
                                passwordRulesDescriptor: "minlength: 8;",
                                onSubmit: { isConfirmPasswordFocused = true },
                                isFocused: $isPasswordFocused
                            )
                            AuthField(
                                label: "Passwort bestätigen",
                                icon: "lock", placeholder: "Bestätigen", text: $confirmPassword,
                                isSecure: true,
                                returnKeyType: .join,
                                accessibilityHint: "Wiederhole dein neues Passwort.",
                                onSubmit: { Task { await register() } },
                                isFocused: $isConfirmPasswordFocused
                            )
                        }

                        Text("Mindestens acht Zeichen.")
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.colors.textTertiary)
                            .padding(.top, 10)
                            .padding(.bottom, 18)

                        if let msg = authVM.errorMessage {
                            Text(msg)
                                .font(theme.fonts.caption)
                                .foregroundColor(theme.colors.error)
                                .padding(.bottom, 14)
                        }

                        PrimaryButton(title: "Konto erstellen", isLoading: authVM.isLoading) {
                            Task { await register() }
                        }
                        .padding(.bottom, 28)

                        legalNotice

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
                        Text("Zurück")
                            .font(theme.fonts.microCaption)
                            .textCase(.uppercase)
                            .tracking(1.4)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
        }
    }

    private var legalNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mit der Registrierung akzeptierst du")
                .font(theme.fonts.caption)
                .foregroundColor(theme.colors.textTertiary)
            HStack(spacing: 6) {
                NavigationLink(destination: TermsOfServiceView()) {
                    Text("Nutzungsbedingungen")
                        .font(theme.fonts.caption)
                        .underline()
                        .foregroundColor(theme.colors.accent)
                }
                Text("und")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.textTertiary)
                NavigationLink(destination: PrivacyPolicyView()) {
                    Text("Datenschutz")
                        .font(theme.fonts.caption)
                        .underline()
                        .foregroundColor(theme.colors.accent)
                }
                Text(".")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
        }
    }

    private func register() async {
        guard password == confirmPassword else {
            authVM.errorMessage = "Die Passwörter stimmen nicht überein."
            return
        }
        guard password.count >= 8 else {
            authVM.errorMessage = "Mindestens acht Zeichen, bitte."
            return
        }
        await authVM.register(name: name, email: email, password: password)
    }
}

// MARK: - Editorial Auth Field
//
// Underline-style input: no filled background, thin bottom-stroke, accent
// when focused. Shared by AuthView / PasswordResetViews.

struct AuthField: View {
    @Environment(\.theme) private var theme
    let label: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var textContentType: UITextContentType? = nil
    var returnKeyType: UIReturnKeyType = .done
    var autocapitalizationType: UITextAutocapitalizationType = .none
    var autocorrectionType: UITextAutocorrectionType = .no
    var spellCheckingType: UITextSpellCheckingType = .no
    var accessibilityHint: String? = nil
    var passwordRulesDescriptor: String? = nil
    var onSubmit: (() -> Void)? = nil
    var isFocused: Binding<Bool>? = nil

    private var focused: Bool { isFocused?.wrappedValue ?? false }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.3)
                .foregroundColor(focused ? theme.colors.accent : theme.colors.textTertiary)
                .animation(theme.motion.easeOutQuart, value: focused)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(focused ? theme.colors.accent : theme.colors.textTertiary)
                    .frame(width: 18)
                    .animation(theme.motion.easeOutQuart, value: focused)

                NativeTextField(
                    placeholder: placeholder,
                    text: $text,
                    keyboardType: keyboardType,
                    isSecure: isSecure,
                    textContentType: textContentType,
                    returnKeyType: returnKeyType,
                    autocapitalizationType: autocapitalizationType,
                    autocorrectionType: autocorrectionType,
                    spellCheckingType: spellCheckingType,
                    accessibilityLabel: label,
                    accessibilityHint: accessibilityHint,
                    passwordRulesDescriptor: passwordRulesDescriptor,
                    uiFont: resolveBodyUIFont(size: 16),
                    textColor: UIColor(theme.colors.textPrimary),
                    placeholderColor: UIColor(theme.colors.textTertiary),
                    onSubmit: onSubmit,
                    isFocused: isFocused
                )
            }
            .padding(.vertical, 14)

            Rectangle()
                .fill(focused ? theme.colors.accent : theme.colors.separator)
                .frame(height: 1)
                .animation(theme.motion.easeOutQuart, value: focused)
        }
    }

    private func resolveBodyUIFont(size: CGFloat) -> UIFont {
        if let name = theme.fonts.bodyFontName, let font = UIFont(name: name, size: size) {
            return font
        }
        return .systemFont(ofSize: size)
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel.shared)
        .environment(\.theme, .velvetHour)
        .preferredColorScheme(.dark)
}
