import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(\.theme) private var theme
    @State private var activeSheet: AuthSheet?
    @State private var showGoogleUnavailable = false

    var body: some View {
        ZStack {
            theme.colors.base.ignoresSafeArea()

            AuthLanding(
                onGoogleTap: { showGoogleUnavailable = true },
                onRegisterTap: { activeSheet = .register },
                onLoginTap: { activeSheet = .login }
            )

            KeyboardWarmupView()
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .login:
                LoginSheetView(onRegisterTap: { activeSheet = .register })
            case .register:
                RegisterView()
            }
        }
        .alert("Noch nicht verfügbar", isPresented: $showGoogleUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Google Anmeldung wird in Phase 10 aktiviert.")
        }
    }
}

private enum AuthSheet: String, Identifiable {
    case login
    case register

    var id: String { rawValue }
}

// MARK: - Landing

private struct AuthLanding: View {
    @Environment(\.theme) private var theme
    let onGoogleTap: () -> Void
    let onRegisterTap: () -> Void
    let onLoginTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 0) {
                Text("W")
                    .font(theme.fonts.display(size: 76, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                Text("atchd")
                    .font(theme.fonts.display(size: 50, weight: .bold))
                    .foregroundColor(theme.colors.accent)
                    .padding(.bottom, 7)
            }
            .accessibilityLabel("Watchd")
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 28)
            .padding(.top, 48)

            Spacer(minLength: 72)

            VStack(spacing: 24) {
                RotatingHeroWord()

                Text("Zwei Menschen. Ein Film, auf den ihr beide Lust habt.")
                    .font(theme.fonts.body(size: 16, weight: .regular))
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 300)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)

            Spacer(minLength: 56)

            AuthActionDock(
                onGoogleTap: onGoogleTap,
                onRegisterTap: onRegisterTap,
                onLoginTap: onLoginTap
            )
        }
    }
}

private struct RotatingHeroWord: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentIndex = 0

    private let words = ["Zu zweit.", "Swipen.", "Match finden.", "Filmabend."]

    var body: some View {
        ZStack {
            Text(words[currentIndex])
                .id(currentIndex)
                .font(theme.fonts.display(size: 46, weight: .regular))
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    )
                )
                .accessibilityLabel(words[currentIndex].replacingOccurrences(of: ".", with: ""))
        }
        .frame(height: 66)
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_750_000_000)
                guard !Task.isCancelled else { return }

                withAnimation(theme.motion.easeOutExpo) {
                    currentIndex = (currentIndex + 1) % words.count
                }
            }
        }
    }
}

private struct AuthActionDock: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var currentNonce: String?

    let onGoogleTap: () -> Void
    let onRegisterTap: () -> Void
    let onLoginTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Sign in with Apple — native button styled to match the Velvet Hour dock
            SignInWithAppleButton(.continue) { request in
                let rawNonce = AppleAuthHelper.randomNonceString()
                currentNonce = rawNonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = AppleAuthHelper.sha256(rawNonce)
            } onCompletion: { result in
                Task { await handleAppleResult(result) }
            }
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel("Mit Apple fortfahren")

            ProviderAuthButton(
                title: "Mit Google fortfahren",
                icon: .letter("G"),
                style: .muted,
                isEnabled: true,
                action: onGoogleTap
            )
            .accessibilityHint("Google Anmeldung wird in Phase 10 aktiviert.")

            Button(action: onRegisterTap) {
                Text("Registrieren")
                    .font(theme.fonts.body(size: 17, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.colors.surfaceInput)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button(action: onLoginTap) {
                Text("Anmelden")
                    .font(theme.fonts.body(size: 17, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.colors.separator, lineWidth: 1)
                    )
            }
            .padding(.top, 4)

            if let msg = authVM.errorMessage {
                Text(msg)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.error)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(theme.colors.overlayDark)
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                        .stroke(theme.colors.overlayLight, lineWidth: 1)
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let identityToken = String(data: tokenData, encoding: .utf8),
                let codeData = credential.authorizationCode,
                let authorizationCode = String(data: codeData, encoding: .utf8),
                let rawNonce = currentNonce
            else {
                authVM.errorMessage = "Apple-Anmeldung fehlgeschlagen. Bitte versuche es erneut."
                return
            }

            let fullName = credential.fullName
            let name = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            // Store the stable Apple user ID for credential-state checks
            KeychainHelper.save(credential.user, forKey: KeychainHelper.appleUserIdKey)

            await authVM.signInWithApple(
                identityToken: identityToken,
                nonce: rawNonce,
                authorizationCode: authorizationCode,
                name: name.isEmpty ? nil : name
            )

        case .failure(let error):
            if let asError = error as? ASAuthorizationError, asError.code == .canceled {
                return
            }
            authVM.errorMessage = "Apple-Anmeldung fehlgeschlagen. Bitte versuche es erneut."
        }
    }
}

private enum ProviderIcon {
    case system(String)
    case letter(String)
}

private enum ProviderButtonStyle {
    case filled
    case muted
}

private struct ProviderAuthButton: View {
    @Environment(\.theme) private var theme
    let title: String
    let icon: ProviderIcon
    let style: ProviderButtonStyle
    let isEnabled: Bool
    let action: () -> Void

    private var foregroundColor: Color {
        switch style {
        case .filled:
            return theme.colors.base
        case .muted:
            return theme.colors.textPrimary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:
            return theme.colors.textPrimary
        case .muted:
            return theme.colors.surfaceCard
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                switch icon {
                case .system(let name):
                    Image(systemName: name)
                        .font(.system(size: 19, weight: .semibold))
                case .letter(let letter):
                    Text(letter)
                        .font(theme.fonts.body(size: 19, weight: .bold))
                }

                Text(title)
                    .font(theme.fonts.body(size: 17, weight: .semibold))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(isEnabled ? 1 : 0.72)
        }
        .disabled(!isEnabled)
    }
}

private struct LoginSheetView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel
    let onRegisterTap: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.base.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Anmelden.")
                                .font(theme.fonts.display(size: 36, weight: .regular))
                                .foregroundColor(theme.colors.textPrimary)
                        }
                        .padding(.bottom, 28)

                        Text("Weiter dort, wo euer Filmabend aufgehört hat.")
                            .font(theme.fonts.body(size: 16, weight: .regular))
                            .foregroundColor(theme.colors.textSecondary)
                            .lineSpacing(4)
                            .padding(.bottom, 42)

                        LoginForm(onRegisterTap: onRegisterTap)

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
                        Text("Zurück")
                            .font(theme.fonts.microCaption)
                            .textCase(.uppercase)
                            .tracking(1.4)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .onAppear { authVM.errorMessage = nil }
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
            VStack(spacing: 4) {
                AuthField(
                    label: "E-Mail-Adresse",
                    icon: "envelope",
                    placeholder: "deine@email.de",
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
                    placeholder: "••••••••",
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

            Button(action: onRegisterTap) {
                HStack(spacing: 6) {
                    Text("Noch kein Konto?")
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    Text("Konto erstellen")
                        .font(theme.fonts.body(size: 13, weight: .medium))
                        .foregroundColor(theme.colors.accent)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 2)
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
                            Text("Konto erstellen.")
                                .font(theme.fonts.display(size: 34, weight: .regular))
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
                                icon: "person", placeholder: "Dein Vorname", text: $name,
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
                                icon: "envelope", placeholder: "deine@email.de", text: $email,
                                keyboardType: .emailAddress, textContentType: .emailAddress,
                                returnKeyType: .next,
                                accessibilityHint: "Diese Adresse nutzt du später zum Anmelden.",
                                onSubmit: { isPasswordFocused = true },
                                isFocused: $isEmailFocused
                            )
                            AuthField(
                                label: "Passwort",
                                icon: "lock", placeholder: "••••••••", text: $password,
                                isSecure: true, textContentType: .newPassword,
                                returnKeyType: .next,
                                accessibilityHint: "Mindestens acht Zeichen.",
                                passwordRulesDescriptor: "minlength: 8;",
                                onSubmit: { isConfirmPasswordFocused = true },
                                isFocused: $isPasswordFocused
                            )
                            AuthField(
                                label: "Passwort bestätigen",
                                icon: "lock", placeholder: "••••••••", text: $confirmPassword,
                                isSecure: true,
                                returnKeyType: .join,
                                accessibilityHint: "Wiederhole dein neues Passwort.",
                                onSubmit: { Task { await register() } },
                                isFocused: $isConfirmPasswordFocused
                            )
                        }

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
            .onAppear { authVM.errorMessage = nil }
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
