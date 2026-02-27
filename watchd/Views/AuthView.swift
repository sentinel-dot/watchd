import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showRegister = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.94),
                    Color(red: 0.96, green: 0.93, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Text("🎬")
                        .font(.system(size: 70))
                    Text("watchd")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                    Text("Findet gemeinsam euren nächsten Film")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)

                LoginForm(onRegisterTap: { showRegister = true })
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
                    )
                    .padding(.horizontal, 24)
                
                Button(action: {
                    Task { await authVM.guestLogin() }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.dashed")
                            .font(.system(size: 15, weight: .medium))
                        Text("Als Gast fortfahren")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 28)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.06), radius: 12, y: 6)
                }
                .padding(.top, 20)
                .disabled(authVM.isLoading)

                Spacer()
            }
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

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 18) {
                Text("Willkommen zurück")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 14) {
                    AuthField(icon: "envelope.fill", placeholder: "E-Mail", text: $email, keyboardType: .emailAddress)
                    AuthField(icon: "lock.fill", placeholder: "Passwort", text: $password, isSecure: true)
                }

                if let msg = authVM.errorMessage {
                    Text(msg)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
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
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 6)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 20)
            
            Divider()
                .padding(.horizontal, 28)
            
            Button(action: onRegisterTap) {
                HStack(spacing: 6) {
                    Text("Noch kein Konto?")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    Text("Jetzt registrieren")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
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

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.94),
                        Color(red: 0.96, green: 0.93, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 20) {
                            Text("🎬")
                                .font(.system(size: 60))
                            
                            VStack(spacing: 6) {
                                Text("Konto erstellen")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                                Text("Werde Teil der watchd Community")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 32)
                        
                        VStack(spacing: 20) {
                            AuthField(icon: "person.fill", placeholder: "Name", text: $name)
                            AuthField(icon: "envelope.fill", placeholder: "E-Mail", text: $email, keyboardType: .emailAddress)
                            AuthField(icon: "lock.fill", placeholder: "Passwort (mind. 8 Zeichen)", text: $password, isSecure: true)
                            AuthField(icon: "lock.fill", placeholder: "Passwort bestätigen", text: $confirmPassword, isSecure: true)

                            if let msg = authVM.errorMessage {
                                Text(msg)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            PrimaryButton(title: "Registrieren", isLoading: authVM.isLoading) {
                                Task { 
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
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
                        )
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Zurück")
                                .font(.system(size: 17, weight: .regular))
                        }
                        .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                    }
                }
            }
        }
    }
}

// MARK: - Shared Components

struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    private var placeholderColor: Color {
        Color(red: 0.55, green: 0.55, blue: 0.55)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                .frame(width: 20)

            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(placeholderColor))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(placeholderColor))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color(red: 0.95, green: 0.93, blue: 0.91))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

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
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.85, green: 0.30, blue: 0.25),
                        Color(red: 0.90, green: 0.40, blue: 0.35)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(red: 0.85, green: 0.30, blue: 0.25).opacity(0.3), radius: 16, y: 8)
        }
        .disabled(isLoading)
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
