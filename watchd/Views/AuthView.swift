import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Sophisticated light gradient background
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

                VStack(spacing: 12) {
                    Text("🎬")
                        .font(.system(size: 72))
                    Text("watchd")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                    Text("Findet gemeinsam euren nächsten Film")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 48)

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        TabButton(title: "Anmelden", isSelected: selectedTab == 0) { selectedTab = 0 }
                        TabButton(title: "Registrieren", isSelected: selectedTab == 1) { selectedTab = 1 }
                    }
                    .padding(6)
                    .background(Color(red: 0.9, green: 0.88, blue: 0.86))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)

                    if selectedTab == 0 {
                        LoginForm()
                            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                    } else {
                        RegisterForm()
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
                )
                .padding(.horizontal, 24)

                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Login Form

private struct LoginForm: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 18) {
            AuthField(icon: "envelope.fill", placeholder: "E-Mail", text: $email, keyboardType: .emailAddress)
            AuthField(icon: "lock.fill", placeholder: "Passwort", text: $password, isSecure: true)

            if let msg = authVM.errorMessage {
                Text(msg)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            PrimaryButton(title: "Anmelden", isLoading: authVM.isLoading) {
                Task { await authVM.login(email: email, password: password) }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 32)
    }
}

// MARK: - Register Form

private struct RegisterForm: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 18) {
            AuthField(icon: "person.fill", placeholder: "Name", text: $name)
            AuthField(icon: "envelope.fill", placeholder: "E-Mail", text: $email, keyboardType: .emailAddress)
            AuthField(icon: "lock.fill", placeholder: "Passwort", text: $password, isSecure: true)

            if let msg = authVM.errorMessage {
                Text(msg)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            PrimaryButton(title: "Konto erstellen", isLoading: authVM.isLoading) {
                Task { await authVM.register(name: name, email: email, password: password) }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 32)
    }
}

// MARK: - Shared Components

private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color(red: 0.5, green: 0.5, blue: 0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isSelected ? 
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.30, blue: 0.25),
                            Color(red: 0.90, green: 0.40, blue: 0.35)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : 
                    LinearGradient(
                        colors: [Color.clear, Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: isSelected ? Color(red: 0.85, green: 0.30, blue: 0.25).opacity(0.3) : .clear, radius: 8, y: 4)
        }
    }
}

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
